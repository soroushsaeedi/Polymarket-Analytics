USE polymarket;
GO

IF OBJECT_ID(N'core.dim_market', N'U') IS NULL
CREATE TABLE core.dim_market (
    market_id     NVARCHAR(20)   NOT NULL PRIMARY KEY,
    event_id      NVARCHAR(20)   NULL,
    question      NVARCHAR(1000) NOT NULL,
    yes_token_id  NVARCHAR(100)  NOT NULL,
    volume_usd    DECIMAL(18,2)  NULL,
    closed_at     DATETIME2(0)   NULL,
    yes_won       BIT            NULL
);

IF OBJECT_ID(N'core.dim_date', N'U') IS NULL
CREATE TABLE core.dim_date (
    date_key     DATE     NOT NULL PRIMARY KEY,
    year         SMALLINT NOT NULL,
    month        TINYINT  NOT NULL,
    day_of_week  TINYINT  NOT NULL
);

IF OBJECT_ID(N'core.fact_price_daily', N'U') IS NULL
CREATE TABLE core.fact_price_daily (
    market_id   NVARCHAR(20)  NOT NULL REFERENCES core.dim_market (market_id),
    price_date  DATE          NOT NULL REFERENCES core.dim_date (date_key),
    yes_price   DECIMAL(9,6)  NOT NULL,
    CONSTRAINT pk_fact_price_daily PRIMARY KEY (market_id, price_date)
);
GO