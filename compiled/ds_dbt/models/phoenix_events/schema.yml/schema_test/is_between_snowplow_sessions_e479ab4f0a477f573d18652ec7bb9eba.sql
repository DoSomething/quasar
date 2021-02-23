
    WITH validation AS (
        SELECT
            session_duration_seconds AS field_to_test
        FROM
            "quasar_prod_warehouse"."public"."snowplow_sessions"
    ),
    validation_errors AS (
        SELECT
            field_to_test
        FROM
            validation
        WHERE
            field_to_test > 3600
            OR field_to_test < 0
    )
    SELECT
        count(*)
    FROM
        validation_errors
