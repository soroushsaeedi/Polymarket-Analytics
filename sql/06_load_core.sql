USE polymarket;
GO

CREATE OR ALTER PROCEDURE core.usp_load_core
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    -- 1. Markets: Yes/No markets only
    MERGE core.dim_market AS tgt
    USING (
        SELECT market_id, event_id, question, yes_token_id, volume_usd, closed_at,
               CASE yes_final_price WHEN 1 THEN 1 WHEN 0 THEN 0 END AS yes_won
        FROM stg.markets
        WHERE first_outcome = N'Yes' AND yes_token_id IS NOT NULL
    ) AS src
    ON tgt.market_id = src.market_id
    WHEN MATCHED THEN UPDATE SET
        event_id = src.event_id, question = src.question, yes_token_id = src.yes_token_id,
        volume_usd = src.volume_usd, closed_at = src.closed_at, yes_won = src.yes_won
    WHEN NOT MATCHED THEN
        INSERT (market_id, event_id, question, yes_token_id, volume_usd, closed_at, yes_won)
        VALUES (src.market_id, src.event_id, src.question, src.yes_token_id,
                src.volume_usd, src.closed_at, src.yes_won);

    -- 2. Dates: add any day we haven't seen yet
    INSERT INTO core.dim_date (date_key, year, month, day_of_week)
    SELECT DISTINCT p.price_date, YEAR(p.price_date), MONTH(p.price_date), DATEPART(WEEKDAY, p.price_date)
    FROM stg.price_history AS p
    WHERE NOT EXISTS (SELECT 1 FROM core.dim_date AS d WHERE d.date_key = p.price_date);

    -- 3. Daily prices: valid prices only, one per market per day (the earliest snapshot)
    MERGE core.fact_price_daily AS tgt
    USING (
        SELECT market_id, price_date, yes_price
        FROM (
            SELECT p.market_id, p.price_date, p.yes_price,
                   ROW_NUMBER() OVER (PARTITION BY p.market_id, p.price_date ORDER BY p.price_ts) AS rn
            FROM stg.price_history AS p
            JOIN core.dim_market AS m ON m.market_id = p.market_id
            WHERE p.yes_price BETWEEN 0 AND 1
        ) AS x
        WHERE rn = 1
    ) AS src
    ON tgt.market_id = src.market_id AND tgt.price_date = src.price_date
    WHEN MATCHED AND tgt.yes_price <> src.yes_price THEN
        UPDATE SET yes_price = src.yes_price
    WHEN NOT MATCHED THEN
        INSERT (market_id, price_date, yes_price) VALUES (src.market_id, src.price_date, src.yes_price)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE;

    COMMIT;
END;
GO