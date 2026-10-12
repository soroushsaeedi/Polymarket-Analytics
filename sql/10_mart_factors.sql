USE polymarket;
GO
DROP VIEW IF EXISTS mart.factors;
GO
IF OBJECT_ID('mart.factors') IS NULL
CREATE TABLE mart.factors (
    market_id      NVARCHAR(20) PRIMARY KEY,
    yes_won        BIT,
    yes_price      DECIMAL(9,6),
    momentum_7d    DECIMAL(9,6),
    volatility_30d FLOAT,
    age_days       INT
);
GO
CREATE OR ALTER PROCEDURE mart.usp_load_factors AS
BEGIN
    SET NOCOUNT ON;

    SELECT market_id, price_date,
           yes_price - LAG(yes_price) OVER (PARTITION BY market_id
                                            ORDER BY price_date) AS daily_change
    INTO #changes
    FROM core.fact_price_daily;

    CREATE CLUSTERED INDEX ix_changes ON #changes (market_id, price_date);

    TRUNCATE TABLE mart.factors;

    INSERT INTO mart.factors
    SELECT s.market_id, s.yes_won, s.yes_price,
           s.yes_price - prev.yes_price,
           vol.volatility_30d,
           DATEDIFF(DAY, first_day.first_date, s.price_date)
    FROM mart.calibration_sample s
    OUTER APPLY (SELECT TOP (1) f.yes_price FROM core.fact_price_daily f
                 WHERE f.market_id = s.market_id
                   AND f.price_date <= DATEADD(DAY, -7, s.price_date)
                 ORDER BY f.price_date DESC) prev
    OUTER APPLY (SELECT STDEV(c.daily_change) AS volatility_30d FROM #changes c
                 WHERE c.market_id = s.market_id
                   AND c.price_date >  DATEADD(DAY, -30, s.price_date)
                   AND c.price_date <= s.price_date) vol
    OUTER APPLY (SELECT MIN(f.price_date) AS first_date FROM core.fact_price_daily f
                 WHERE f.market_id = s.market_id) first_day;
END;