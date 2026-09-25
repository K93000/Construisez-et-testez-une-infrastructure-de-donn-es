with source as (

    select hourly
    from {{ source('raw', 'infoclimat') }}

),

stations_exploded as (

    select
        station_entry.key as station_id,
        station_entry.value as observations
    from source,
         jsonb_each(hourly) as station_entry
    where station_entry.key != '_params'

),

observations_exploded as (

    select
        station_id,
        jsonb_array_elements(observations) as obs
    from stations_exploded

)

select
    station_id,
    (obs->>'dh_utc')::timestamp as observed_at_utc,
    nullif(obs->>'temperature', '')::numeric as temperature_c,
    nullif(obs->>'point_de_rosee', '')::numeric as dew_point_c,
    nullif(obs->>'humidite', '')::numeric as humidity_pct,
    nullif(obs->>'pression', '')::numeric as pressure_hpa,
    nullif(obs->>'vent_moyen', '')::numeric as wind_speed_kmh,
    nullif(obs->>'vent_rafales', '')::numeric as wind_gust_kmh,
    nullif(obs->>'vent_direction', '')::numeric as wind_direction_deg,
    nullif(obs->>'pluie_1h', '')::numeric as precip_1h_mm,
    nullif(obs->>'pluie_3h', '')::numeric as precip_3h_mm,
    nullif(obs->>'visibilite', '')::numeric as visibility_m,
    nullif(obs->>'neige_au_sol', '')::numeric as snow_depth_cm,
    nullif(obs->>'nebulosite', '')::numeric as cloud_cover_octas,
    obs->>'temps_omm' as present_weather_code

from observations_exploded