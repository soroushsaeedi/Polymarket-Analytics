USE polymarket;
GO

CREATE OR ALTER VIEW core.dq_checks AS
SELECT N'price outside 0-1' AS check_name, N'error' AS severity, COUNT(*) AS failed
FROM core.fact_price_daily
WHERE yes_price < 0 OR yes_price > 1

UNION ALL
SELECT N'market without prices', N'error', COUNT(*)
FROM core.dim_market AS m
WHERE NOT EXISTS (SELECT 1 FROM core.fact_price_daily AS f WHERE f.market_id = m.market_id)

UNION ALL
SELECT N'market without closed_at', N'error', COUNT(*)
FROM core.dim_market
WHERE closed_at IS NULL

UNION ALL
SELECT N'price after market closed', N'warning', COUNT(*)
FROM core.fact_price_daily AS f
JOIN core.dim_market AS m ON m.market_id = f.market_id
WHERE f.price_date > CAST(m.closed_at AS DATE)

UNION ALL
SELECT N'market with missing days', N'warning', COUNT(*)
FROM (
    SELECT market_id
    FROM core.fact_price_daily
    GROUP BY market_id
    HAVING DATEDIFF(DAY, MIN(price_date), MAX(price_date)) + 1 > COUNT(*)
) AS g

UNION ALL
SELECT N'market without clear outcome', N'info', COUNT(*)
FROM core.dim_market
WHERE yes_won IS NULL;
GO