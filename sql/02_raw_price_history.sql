USE polymarket;
GO

IF OBJECT_ID(N'raw.price_history', N'U') IS NULL
CREATE TABLE raw.price_history (
    market_id  NVARCHAR(20)  NOT NULL,
    token_id   NVARCHAR(100) NOT NULL,
    payload    NVARCHAR(MAX) NOT NULL,
    loaded_at  DATETIME2(0)  NOT NULL
        CONSTRAINT df_raw_price_history_loaded_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT ck_raw_price_history_payload CHECK (ISJSON(payload) = 1)
);
GO