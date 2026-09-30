USE polymarket;
GO

CREATE OR ALTER VIEW stg.price_history AS
WITH latest AS (
    SELECT market_id, token_id, payload,
           ROW_NUMBER() OVER (PARTITION BY token_id ORDER BY loaded_at DESC) AS rn
    FROM raw.price_history
)
SELECT
    l.market_id,
    l.token_id,
    CAST(DATEADD(SECOND, j.t, '1970-01-01') AS DATE) AS price_date,
    j.p AS yes_price
FROM latest AS l
CROSS APPLY OPENJSON(l.payload)
    WITH (t BIGINT '$.t', p DECIMAL(9,6) '$.p') AS j
WHERE l.rn = 1;
GO