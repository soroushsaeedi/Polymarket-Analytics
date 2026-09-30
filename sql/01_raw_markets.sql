USE polymarket;
GO

IF OBJECT_ID(N'raw.markets', N'U') IS NULL
CREATE TABLE raw.markets (
    market_id NVARCHAR(20) NOT NULL,
    payload NVARCHAR(MAX) NOT NULL,
    loaded_at DATETIME2(0) NOT NULL
        CONSTRAINT df_raw_markets_loaded_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT ck_raw_markets_payload CHECK (ISJSON(payload) = 1)
);
GO