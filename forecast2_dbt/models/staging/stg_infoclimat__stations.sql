with source as (

    select stations
    from {{ source('raw', 'infoclimat') }}

),

unnested as (

    select
        station->>'id' as station_id,
        station->>'name' as station_name,
        station->>'type' as station_type,
        (station->>'latitude')::numeric as latitude,
        (station->>'longitude')::numeric as longitude,
        (station->>'elevation')::numeric as elevation_m,
        station->'license'->>'source' as license_source,
        station->'license'->>'license' as license_type
    from source,
         jsonb_array_elements(stations) as station

)

select * from unnested