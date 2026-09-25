{{ config(
    materialized='table',
    indexes=[
      {'columns': ['full_date'], 'unique': true}
    ],
    post_hook=[
      "ALTER TABLE {{ this }} ADD PRIMARY KEY (date_key)"
    ]
) }}

with date_spine as (

    select generate_series(
        least(
            (select min(observed_at_utc)::date from {{ ref('stg_infoclimat__observations') }}),
            (select min(observed_at_local)::date from {{ ref('int_weather_underground__unioned') }})
        ),
        greatest(
            (select max(observed_at_utc)::date from {{ ref('stg_infoclimat__observations') }}),
            (select max(observed_at_local)::date from {{ ref('int_weather_underground__unioned') }})
        ),
        interval '1 day'
    )::date as full_date

)

select
    row_number() over (order by full_date) as date_key,
    full_date,
    extract(year from full_date) as year,
    extract(month from full_date) as month,
    extract(day from full_date) as day,
    to_char(full_date, 'Day') as day_of_week

from date_spine