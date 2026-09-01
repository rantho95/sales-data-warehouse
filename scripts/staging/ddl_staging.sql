/*
==============================================================================================
 DDL Script: CREATE Staging Table
===============================================================================================
Script Purpose:
    This script creates a table in the 'Staging' schema, droping existing table if it already 
    exists.
    Run this script to re-define the DDL structure of the 'Staging' tables.
================================================================================================
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
