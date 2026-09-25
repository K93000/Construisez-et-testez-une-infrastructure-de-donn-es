{{ config(
    materialized='table',
    indexes=[
      {'columns': ['station_id'], 'unique': true}
    ],
    post_hook=[
      "ALTER TABLE {{ this }} ADD PRIMARY KEY (station_key)"
    ]
) }}

with infoclimat_stations as (

    select
        station_id,
        station_name,
        'InfoClimat' as network,
        station_type,
        latitude,
        longitude,
        elevation_m,
        null as city,
        null as hardware,
        null as software,
        license_source,
        license_type
    from {{ ref('stg_infoclimat__stations') }}

),

weather_underground_stations as (

    select 'ILAMAD25' as station_id, 'La Madeleine' as station_name, 'Weather Underground' as network,
           'amateur' as station_type, 50.659 as latitude, 3.07 as longitude, 23 as elevation_m,
           'La Madeleine' as city, 'other' as hardware, 'EasyWeatherPro_V5.1.6' as software,
           null as license_source, null as license_type

    union all

    select 'IICHTE19', 'WeerstationBS', 'Weather Underground',
           'amateur', 51.092, 2.999, 15,
           'Ichtegem', 'other', 'EasyWeatherV1.6.6',
           null, null

),

unioned as (

    select * from infoclimat_stations
    union all
    select * from weather_underground_stations

)

select
    row_number() over (order by station_id) as station_key,
    *
from unioned