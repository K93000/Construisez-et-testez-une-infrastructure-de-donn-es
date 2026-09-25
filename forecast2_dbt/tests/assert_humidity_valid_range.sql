-- Test métier : l'humidité relative doit être comprise entre 0 et 100%.

select
    observation_key,
    station_id,
    observed_at,
    humidity_pct
from {{ ref('fact_weather_observations') }}
where humidity_pct is not null
  and (humidity_pct < 0 or humidity_pct > 100)