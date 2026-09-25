with ichtegem as (

    select
        *,
        'IICHTE19' as station_id
    from {{ ref('stg_weather_underground__ichtegem') }}

),

la_madeleine as (

    select
        *,
        'ILAMAD25' as station_id
    from {{ ref('stg_weather_underground__la_madeleine') }}

),

unioned as (

    select * from ichtegem
    union all
    select * from la_madeleine

)

select * from unioned