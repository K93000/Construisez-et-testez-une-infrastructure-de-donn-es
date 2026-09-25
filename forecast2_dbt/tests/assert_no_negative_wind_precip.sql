-- Test métier : la vitesse du vent et les précipitations ne peuvent pas être négatives.

select
    observation_key,
    station_id,
    observed_at,
    wind_speed_kmh,
    precip_mm
from {{ ref('fact_weather_observations') }}
where wind_speed_kmh < 0
   or precip_mm < 0