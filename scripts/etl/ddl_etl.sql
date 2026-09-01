/*
==============================================================================================
 DDL Script: CREATE Staging Table
===============================================================================================
Script Purpose:
    This script creates tables in the schemas 'Dim' and 'Fact', existing tables are dropped before
    being recreated
    Run this script to redefine the DDL structure of the 'dim' and 'fact' tables.
================================================================================================
*/

USE DataWarehouse;
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
