USE polymarket;
GO

CREATE OR ALTER VIEW stg.markets AS
WITH latest AS (
    SELECT payload,
           ROW_NUMBER() OVER (PARTITION BY market_id ORDER BY loaded_at DESC) AS rn
    FROM raw.markets
)
SELECT
    JSON_VALUE(payload, '$.id')                                          AS market_id,
    JSON_VALUE(payload, '$.events[0].id')                                AS event_id,
    JSON_VALUE(payload, '$.question')                                    AS question,
    JSON_VALUE(JSON_VALUE(payload, '$.outcomes'), '$[0]')                AS first_outcome,
    JSON_VALUE(JSON_VALUE(payload, '$.clobTokenIds'), '$[0]')            AS yes_token_id,
    TRY_CONVERT(DECIMAL(9,6),
        JSON_VALUE(JSON_VALUE(payload, '$.outcomePrices'), '$[0]'))      AS yes_final_price,
    TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(payload, '$.volumeNum'))       AS volume_usd,
    TRY_CONVERT(DATETIME2(0), LEFT(JSON_VALUE(payload, '$.closedTime'), 19)) AS closed_at
FROM latest
WHERE rn = 1;
GO