# Forecast 2.0 – Pipeline ELT de données météo (GreenCoop)

Pipeline ELT qui ingère, transforme et contrôle la qualité de données météorologiques issues de nouvelles sources (InfoClimat et Weather Underground), afin d'alimenter les modèles de prévision de la demande d'électricité de l'équipe Data Science de GreenCoop.

---

## 1. Architecture

```
Sources (fichiers JSON / XLSX hébergés sur GitHub, dossier data/)
        │
        ▼
Airbyte (EC2, déployé via abctl)  ──►  PostgreSQL (AWS RDS, eu-west-3)
                                              │
                                              ▼
                                   dbt (conteneur Docker sur ECS Fargate)
                                   staging → intermediate → marts + tests
```

| Composant | Rôle | Hébergement |
|---|---|---|
| Airbyte | Extraction et chargement des données brutes | EC2 (abctl) |
| PostgreSQL | Stockage des données brutes et transformées | AWS RDS |
| dbt | Transformation, documentation, tests de qualité | ECS Fargate (image ECR) |
| EventBridge Scheduler | Planification : syncs Airbyte à 5h, dbt à 6h | AWS |
| CloudWatch + SNS | Logs, alarme en cas d'échec dbt, alerte e-mail | AWS |
| SSM Parameter Store | Stockage sécurisé du mot de passe de la base | AWS |

### Modèle de données (schéma en étoile)

- `dim_weather_stations` : stations météo (InfoClimat et Weather Underground)
- `dim_date` : dimension calendaire
- `fact_weather_observations` : observations météo, unités harmonisées en système métrique

### Couches dbt

- **staging** : nettoyage et typage de chaque source (`stg_infoclimat__*`, `stg_weather_underground__*`)
- **intermediate** : union des deux stations Weather Underground
- **marts** : tables finales du schéma en étoile

### Contrôle qualité

- Tests génériques déclarés dans `models/marts/schema.yml` (unicité, non-nullité, relations)
- Tests personnalisés dans `tests/` :
  - `assert_temperature_plausible` : températures dans une plage réaliste
  - `assert_humidity_valid_range` : humidité comprise entre 0 et 100 %
  - `assert_no_negative_wind_precip` : pas de vent ni de précipitations négatifs

---

## 2. Contenu du projet

```
.
├── data/                       Fichiers sources lus par Airbyte (via URL GitHub)
├── forecast2_dbt/              Projet dbt
│   ├── models/                 staging / intermediate / marts
│   ├── tests/                  Tests de qualité personnalisés
│   ├── Dockerfile              Image dbt (identique à celle déployée sur ECS)
│   ├── profiles.yml            Connexion lue depuis des variables d'environnement
│   └── dbt.env.example         Modèle de variables pour exécuter dbt hors Docker
├── docker-compose.yml          PostgreSQL + dbt pour un test en local
├── .env.example                Modèle de variables d'environnement
├── forecast2_dump.sql          Données prêtes à charger (fourni dans le zip)
└── fix_weather_underground.py  Script de correction des fichiers Weather Underground
```

---

## 3. Tester le projet en local

La version de production tourne sur AWS, dont l'accès est restreint. Le test en local reproduit la même chaîne de transformation avec Docker, en chargeant directement les données via un dump SQL (pas besoin d'installer Airbyte).

### Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et démarré
- Le port 5432 libre (sinon, modifier `POSTGRES_PORT` dans `.env`)

### Étape 1 – Créer le fichier de configuration

Copier `.env.example` en `.env` à la racine du projet :

```bash
# Windows (PowerShell)
Copy-Item .env.example .env

# macOS / Linux
cp .env.example .env
```

Les valeurs par défaut conviennent pour un test local.

### Étape 2 – Démarrer PostgreSQL

```bash
docker compose up -d postgres
```

Attendre quelques secondes que la base soit prête (`docker ps` doit afficher `healthy` pour `forecast2_postgres`).

### Étape 3 – Charger les données

```bash
docker cp forecast2_dump.sql forecast2_postgres:/tmp/dump.sql
docker exec forecast2_postgres psql -U user -d postgres -f /tmp/dump.sql
```

> Si vous avez modifié `POSTGRES_USER` ou `POSTGRES_DB` dans `.env`, adaptez `-U` et `-d`.
> Des messages du type `role "..." does not exist` peuvent apparaître : ils concernent uniquement les droits de l'environnement d'origine et n'empêchent pas le chargement des données.

### Étape 4 – Lancer dbt (transformations + tests)

```bash
docker compose run --rm dbt build
```

La commande construit l'image dbt, exécute tous les modèles puis tous les tests.

**Résultat attendu** : la dernière ligne indique `ERROR=0`, avec l'ensemble des modèles et tests en `PASS` (identique à l'exécution en production sur ECS).

### Étape 5 – Vérifier les tables (optionnel)

```bash
docker exec -it forecast2_postgres psql -U user -d postgres
```

puis, par exemple :

```sql
SELECT COUNT(*) FROM fact_weather_observations;
SELECT * FROM dim_weather_stations;
```

Taper `\q` pour quitter.

### Arrêter et nettoyer

```bash
docker compose down -v
```

L'option `-v` supprime aussi le volume de données.

---

## 4. Ingestion complète avec Airbyte (optionnel)

Airbyte n'est plus distribué sous forme de docker-compose : il se déploie avec l'outil officiel `abctl`.

```bash
abctl local install
abctl local credentials
```

L'interface est ensuite accessible sur http://localhost:8000. Il faut y créer :

- **3 sources** de type *File* (HTTPS Public Web), pointant vers les fichiers du dossier `data/` de ce dépôt GitHub (1 JSON InfoClimat, 2 XLSX Weather Underground)
- **1 destination** PostgreSQL pointant vers la base locale
- **3 connexions** source → destination, puis lancer une synchronisation

Une fois les données chargées, reprendre à l'étape 4.

---

## 5. Sécurité

- Aucun secret n'est versionné : les fichiers `.env`, `dbt.env` et les clés SSH sont exclus via `.gitignore`.
- En production, le mot de passe de la base est stocké dans AWS SSM Parameter Store et injecté dans la tâche ECS.
- L'accès à la base RDS est limité par Security Group.

---

## 6. Pistes d'amélioration

- Rotation automatique du mot de passe RDS (AWS Secrets Manager)
- Connexion à de vraies API météo à la place des fichiers statiques
- Publication de la documentation dbt (`dbt docs generate`)
