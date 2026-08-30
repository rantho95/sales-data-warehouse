/* 
================================================================================================
CREATE DATABASE, SCHEMAS, AND TBALES
================================================================================================
Script Purpose:
  This script creates a new database named 'DataWarehouse' after checking if it's not existing first.
  If the database does not exist, it gets created. Additionally, the script sets up four schemas within
  the database: 'etl','Staging','Dim','fact'.

  The script also creates tables in each of the schemas labeled above, dropping existing tables if they already
  exists.

  Run this script to re-define the DDL structure of the tables
*/

USE master;

--Create the 'DataWarehouse' database if it does not exist
IF DB_ID('DataWarehouse') IS NULL
BEGIN
    CREATE DATABASE DataWarehouse;
    PRINT '>> Database created: DataWarehouse';
END
ELSE
BEGIN
    PRINT '>> The database already exists';
END
  
USE DataWarehouse;

--Create Schemas
CREATE SCHEMA etl;
GO
CREATE SCHEMA Staging; 
GO
CREATE SCHEMA Dim;
GO
CREATE SCHEMA fact;
GO

/*
=========================================================================================
 DDL STAGE: CREATE ALL TABLES
=========================================================================================
*/

-- Create staging Table

USE DataWarehouse;
GO

/*
=========================================================================================
 DDL STAGE: CREATE ALL TABLES
=========================================================================================
*/

USE DataWarehouse;
GO
-- Create staging Table
PRINT'>> Droping Table: Staging.SalesRaw'
IF OBJECT_ID('Staging.SalesRaw', 'U') IS NOT NULL
	DROP TABLE Staging.SalesRaw;

CREATE TABLE Staging.SalesRaw (
    ProductID       NVARCHAR(10),
    [Date]          NVARCHAR(30),
    CustomerID      NVARCHAR(10),
    CampaignID      NVARCHAR(10),
    Units           NVARCHAR(10),
    Product         NVARCHAR(20),
    Category        NVARCHAR(20),
    Segment         NVARCHAR(20),
    ManufacturerID  NVARCHAR(10),
    Manufacturer    NVARCHAR(20),
    UnitCost        NVARCHAR(20),
    UnitPrice       NVARCHAR(20),
    ZipCode         NVARCHAR(10),
    EmailName       NVARCHAR(100),
    City            NVARCHAR(50),
    State           NVARCHAR(5),
    Region          NVARCHAR(15),
    District        NVARCHAR(20),
    Country         NVARCHAR(5)
);
GO

--Create Date table
PRINT'>> Droping Table: dim.DimDate'
IF OBJECT_ID('dim.DimDate', 'U') IS NOT NULL
	DROP TABLE dim.DimDate;

CREATE TABLE dim.DimDate (
    DateKey       INT NOT NULL PRIMARY KEY,   -- smart key, format YYYYMMDD
    [Date]        DATE  NULL,
    [Year]        INT  NULL,
    [Quarter]     INT NULL,
    [Month]       INT  NULL,
    MonthName     NVARCHAR(10) NULL,
    [Day]         INT  NULL,
    DayOfWeek     INT NULL,
    DayName       NVARCHAR(10) NULL,
    IsWeekend     BIT  NULL
);
GO

-- Create DimProduct Table
PRINT'>> Droping Table: dim.DimProduct'
IF OBJECT_ID('dim.DimProduct ', 'U') IS NOT NULL
	DROP TABLE dim.DimProduct;

CREATE TABLE dim.DimProduct (
	ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID  NVARCHAR(10) NOT NULL UNIQUE,
    Product    NVARCHAR(100) NULL,
    Category   NVARCHAR(30) NULL,
    Segment    NVARCHAR(30) NULL,
	UnitCost   DECIMAL(10,2) NULL,
	UnitPrice  DECIMAL(10,2)  NULL
);
GO

-- Create DimCustomer Table
PRINT'>> Droping Table: dim.DimCustomer'
IF OBJECT_ID('dim.DimCustomer ', 'U') IS NOT NULL
	DROP TABLE dim.DimCustomer;

CREATE TABLE dim.DimCustomer (
	CustomerKey  INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID   NVARCHAR(10) NOT NULL UNIQUE,
    FirstName    NVARCHAR(50) NULL,
    LastName     NVARCHAR(50) NULL,
    Email        NVARCHAR(100) NULL,
	GeographyKey INT NOT NULL REFERENCES dim.DimGeography(GeographyKey)
 
);
GO

---- Create DimGeography Table
PRINT'>> Droping Table: dim.DimGeography'
IF OBJECT_ID('dim.DimGeography ', 'U') IS NOT NULL
	DROP TABLE dim.DimGeography;

CREATE TABLE dim.DimGeography (
    GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
    ZipCode      NVARCHAR(10) NULL,
    City         NVARCHAR(50) NULL,
    State        NVARCHAR(5) NULL,
    Region       NVARCHAR(20) NULL,
    District     NVARCHAR(20) NULL,
	[Country] NVARCHAR(20) NULL,
    CONSTRAINT UQ_DimGeography UNIQUE (ZipCode, City, State, Region, District)
);
GO

---- Create Fact Table
PRINT'>> Droping Table: fact.FactSales'
IF OBJECT_ID('fact.FactSales', 'U') IS NOT NULL
	DROP TABLE fact.FactSales;

CREATE TABLE fact.FactSales (
    SalesKey        INT IDENTITY(1,1) PRIMARY KEY,
    DateKey         INT  NOT NULL REFERENCES dim.DimDate(DateKey),
    ProductKey      INT  NOT NULL REFERENCES dim.DimProduct(ProductKey),
    CustomerKey     INT  NOT NULL REFERENCES dim.DimCustomer(CustomerKey),
    Units           INT            NULL,
    UnitCost        DECIMAL(10,2)  NULL,
    UnitPrice       DECIMAL(10,2)  NULL,
    dwh_create_date DATETIME2      NULL DEFAULT GETDATE()
);
GO

