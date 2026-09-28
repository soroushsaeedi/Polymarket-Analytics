-- Create the database and the four pipeline layers.
-- Safe to re-run: every object is created only if it doesn't exist yet.

IF DB_ID(N'polymarket') IS NULL
    CREATE DATABASE polymarket;
GO

ALTER DATABASE polymarket SET RECOVERY SIMPLE;
GO

USE polymarket;
GO

IF SCHEMA_ID(N'raw')  IS NULL EXEC(N'CREATE SCHEMA raw');   -- API responses exactly as received
IF SCHEMA_ID(N'stg')  IS NULL EXEC(N'CREATE SCHEMA stg');   -- parsed and typed, not yet modeled
IF SCHEMA_ID(N'core') IS NULL EXEC(N'CREATE SCHEMA core');  -- star schema: dimensions + facts
IF SCHEMA_ID(N'mart') IS NULL EXEC(N'CREATE SCHEMA mart');  -- analysis results for Power BI / Excel
GO