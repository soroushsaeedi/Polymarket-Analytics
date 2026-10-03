USE polymarket;
GO

CREATE OR ALTER VIEW mart.calibration_sample AS
WITH one_per_event AS (
    SELECT market_id, closed_at, yes_won,
           ROW_NUMBER() OVER (PARTITION BY COALESCE(event_id, market_id)
                              ORDER BY volume_usd DESC) AS rn
    FROM core.dim_market
    WHERE yes_won IS NOT NULL AND closed_at IS NOT NULL
)
SELECT m.market_id, m.closed_at, m.yes_won, p.price_date, p.yes_price
FROM one_per_event m
CROSS APPLY (
    SELECT TOP (1) f.price_date, f.yes_price
    FROM core.fact_price_daily f
    WHERE f.market_id = m.market_id
      AND f.price_date <= CAST(DATEADD(DAY, -7,  m.closed_at) AS DATE)
      AND f.price_date >= CAST(DATEADD(DAY, -14, m.closed_at) AS DATE)
    ORDER BY f.price_date DESC
) p
WHERE m.rn = 1;