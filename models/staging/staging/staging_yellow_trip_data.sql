{{ config(materialized='view') }}

with tripdata as 
(
  select *,
    row_number() over(partition by vendor_id, pickup_datetime) as rn
  from {{ source('staging', 'yellow_tripdata') }}
  where vendor_id is not null 
)
select
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['vendor_id', 'pickup_datetime']) }} as tripid,    
    {{ dbt.safe_cast("vendor_id", api.Column.translate_type("string")) }} as vendor_id,

    -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropoff_datetime as timestamp) as dropoff_datetime,
    
    -- trip info
    store_and_fwd_flag,
    {{ dbt.safe_cast("passenger_count", api.Column.translate_type("integer")) }} as passenger_count,
    cast(trip_distance as numeric) as trip_distance,
    

    -- payment info
    {{ dbt.safe_cast("rate_code", api.Column.translate_type("string")) }} as rate_code,
    cast(fare_amount as numeric) as fare_amount,
    cast(extra as numeric) as extra,
    cast(mta_tax as numeric) as mta_tax,
    cast(tip_amount as numeric) as tip_amount,
    cast(tolls_amount as numeric) as tolls_amount,
    cast(airport_fee as numeric) as airport_fee,
    cast(imp_surcharge as numeric) as imp_surcharge,
    cast(total_amount as numeric) as total_amount,
    coalesce({{ dbt.safe_cast("payment_type", api.Column.translate_type("string")) }}, 'Unknown') as payment_type,

    -- location info
    {{ dbt.safe_cast("pickup_location_id", api.Column.translate_type("string")) }} as pickup_location_id,
    {{ dbt.safe_cast("dropoff_location_id", api.Column.translate_type("string")) }} as dropoff_location_id,

    -- data file info
    {{ dbt.safe_cast("data_file_year", api.Column.translate_type("integer")) }} as data_file_year,
    {{ dbt.safe_cast("data_file_month", api.Column.translate_type("integer")) }} as data_file_month

from tripdata
where rn = 1

-- dbt build --select <model_name> --vars '{'is_test_run': 'false'}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}