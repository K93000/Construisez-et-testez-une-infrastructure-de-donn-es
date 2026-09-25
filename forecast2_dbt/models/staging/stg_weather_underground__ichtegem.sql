with source as (

    select *
    from {{ source('raw', 'weather_underground_ichtegem') }}
    where "Time" is not null and "Time" != ''

),

cleaned as (

    select
        ("Date" || ' ' || "Time")::timestamp as observed_at_local,
        substring("Temperature" from '^-?[0-9.]+')::numeric as temperature_f,
        substring("Dew_Point" from '^-?[0-9.]+')::numeric as dew_point_f,
        substring("Humidity" from '^-?[0-9.]+')::numeric as humidity_pct,
        "Wind" as wind_direction_cardinal,
        substring("Speed" from '^-?[0-9.]+')::numeric as wind_speed_mph,
        substring("Gust" from '^-?[0-9.]+')::numeric as wind_gust_mph,
        substring("Pressure" from '^-?[0-9.]+')::numeric as pressure_inhg,
        substring("Precip__Rate_" from '^-?[0-9.]+')::numeric as precip_rate_in,
        substring("Precip__Accum_" from '^-?[0-9.]+')::numeric as precip_accum_in,
        "UV" as uv_index,
        substring("Solar" from '^-?[0-9.]+')::numeric as solar_radiation_wm2

    from source

)

select
    observed_at_local,
    temperature_f,
    round((temperature_f - 32) * 5/9, 2) as temperature_c,
    dew_point_f,
    round((dew_point_f - 32) * 5/9, 2) as dew_point_c,
    humidity_pct,
    wind_direction_cardinal,
    wind_speed_mph,
    round(wind_speed_mph * 1.60934, 2) as wind_speed_kmh,
    wind_gust_mph,
    round(wind_gust_mph * 1.60934, 2) as wind_gust_kmh,
    pressure_inhg,
    round(pressure_inhg * 33.8639, 2) as pressure_hpa,
    precip_rate_in,
    round(precip_rate_in * 25.4, 2) as precip_rate_mm,
    precip_accum_in,
    round(precip_accum_in * 25.4, 2) as precip_accum_mm,
    uv_index,
    solar_radiation_wm2

from cleaned