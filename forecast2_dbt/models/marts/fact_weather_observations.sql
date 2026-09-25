{{ config(
    materialized='table',
    indexes=[
      {'columns': ['station_key']},
      {'columns': ['date_key']},
      {'columns': ['observed_at']}
    ],
    post_hook=[
      "ALTER TABLE {{ this }} ADD PRIMARY KEY (observation_key)"
    ]
) }}

with infoclimat_obs as (

    select
        station_id,
        observed_at_utc as observed_at,
        temperature_c,
        dew_point_c,
        humidity_pct,
        pressure_hpa,
        wind_speed_kmh,
        wind_gust_kmh,
        wind_direction_deg,
        null::text as wind_direction_cardinal,
        coalesce(precip_1h_mm, precip_3h_mm) as precip_mm,
        null::numeric as precip_accum_mm,
        visibility_m,
        snow_depth_cm,
        cloud_cover_octas,
        null::numeric as uv_index,
        null::numeric as solar_radiation_wm2,
        'InfoClimat' as network

    from {{ ref('stg_infoclimat__observations') }}

),

weather_underground_obs as (

    select
        station_id,
        observed_at_local as observed_at,
        temperature_c,
        dew_point_c,
        humidity_pct,
        pressure_hpa,
        wind_speed_kmh,
        wind_gust_kmh,
        null::numeric as wind_direction_deg,
        wind_direction_cardinal,
        precip_rate_mm as precip_mm,
        precip_accum_mm,
        null::numeric as visibility_m,
        null::numeric as snow_depth_cm,
        null::numeric as cloud_cover_octas,
        uv_index,
        solar_radiation_wm2,
        'Weather Underground' as network

    from {{ ref('int_weather_underground__unioned') }}

),

unioned as (

    select * from infoclimat_obs
    union all
    select * from weather_underground_obs

)

select
    row_number() over (order by unioned.station_id, unioned.observed_at) as observation_key,
    dim_station.station_key,
    dim_date.date_key,
    unioned.station_id,
    unioned.observed_at,
    unioned.temperature_c,
    unioned.dew_point_c,
    unioned.humidity_pct,
    unioned.pressure_hpa,
    unioned.wind_speed_kmh,
    unioned.wind_gust_kmh,
    unioned.wind_direction_deg,
    unioned.wind_direction_cardinal,
    unioned.precip_mm,
    unioned.precip_accum_mm,
    unioned.visibility_m,
    unioned.snow_depth_cm,
    unioned.cloud_cover_octas,
    unioned.uv_index,
    unioned.solar_radiation_wm2

from unioned
left join {{ ref('dim_weather_stations') }} as dim_station
    on unioned.station_id = dim_station.station_id
left join {{ ref('dim_date') }} as dim_date
    on unioned.observed_at::date = dim_date.full_date