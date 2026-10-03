USE polymarket;
GO
CREATE OR ALTER VIEW mart.calibration_buckets AS
SELECT LEAST(FLOOR(yes_price * 10), 9) / 10.0 AS bucket_low,
    COUNT(*)                                AS n,
    AVG(yes_price)                          AS avg_price,
    AVG(CAST(yes_won AS FLOAT))             AS win_rate
FROM mart.calibration_sample
GROUP BY LEAST(FLOOR(yes_price * 10), 9) / 10.0;