{{
    config(
        materialized='table'
    )
}}

with green_tripdata as (
    select 
        tripid,
        vendor_id,
        pickup_datetime,
        dropoff_datetime,
        store_and_fwd_flag,
        rate_code,
        passenger_count,
        trip_distance,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        imp_surcharge,
        total_amount,
        payment_type,
        CAST(pickup_location_id AS STRING) as pickup_location_id,
        CAST(dropoff_location_id AS STRING) as dropoff_location_id,
        data_file_year,
        data_file_month,
        'Green' as service_type
    from {{ ref('stg_staging__green_tripdata') }}
), 
yellow_tripdata as (
    select 
        tripid,
        vendor_id,
        pickup_datetime,
        dropoff_datetime,
        store_and_fwd_flag,
        rate_code,
        passenger_count,
        trip_distance,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        imp_surcharge,
        total_amount,
        payment_type,
        CAST(pickup_location_id AS STRING) as pickup_location_id,
        CAST(dropoff_location_id AS STRING) as dropoff_location_id,
        data_file_year,
        data_file_month,
        'Yellow' as service_type
    from {{ ref('staging_yellow_trip_data') }}
), 
trips_unioned as (
    select * from green_tripdata
    union all 
    select * from yellow_tripdata
), 
dim_zones as (
    select * from {{ ref('dim_zones') }}
    where borough != 'Unknown'
)

select 
    trips_unioned.tripid, 
    trips_unioned.vendor_id,
    trips_unioned.pickup_datetime,
    trips_unioned.dropoff_datetime,
    trips_unioned.store_and_fwd_flag,
    trips_unioned.rate_code,
    pickup_zone.borough as pickup_borough, 
    pickup_zone.zone as pickup_zone, 
    dropoff_zone.borough as dropoff_borough, 
    dropoff_zone.zone as dropoff_zone,
    trips_unioned.passenger_count,
    trips_unioned.trip_distance,
    trips_unioned.fare_amount,
    trips_unioned.extra,
    trips_unioned.mta_tax,
    trips_unioned.tip_amount,
    trips_unioned.tolls_amount,
    trips_unioned.imp_surcharge,
    trips_unioned.total_amount,
    trips_unioned.payment_type,
    trips_unioned.pickup_location_id,
    trips_unioned.dropoff_location_id,
    trips_unioned.data_file_year,
    trips_unioned.data_file_month,
    trips_unioned.service_type
from trips_unioned
inner join dim_zones as pickup_zone
on CAST(trips_unioned.pickup_location_id AS STRING) = CAST(pickup_zone.locationid AS STRING)
inner join dim_zones as dropoff_zone
on CAST(trips_unioned.dropoff_location_id AS STRING) = CAST(dropoff_zone.locationid AS STRING)

