-- Test métier : la température doit être dans une plage physiquement plausible
-- pour un climat tempéré (Hauts-de-France / Belgique), avec marge de sécurité.
-- Ce test échoue si des lignes sont retournées.

select
    observation_key,
    station_id,
    observed_at,
    temperature_c
from {{ ref('fact_weather_observations') }}
where temperature_c is not null
  and (temperature_c < -30 or temperature_c > 45)