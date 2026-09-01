/* 
================================================================================================
CREATE DATABASE AND SCHEMAS
================================================================================================
Script Purpose:
  This script creates a new database named 'DataWarehouse' after checking if it's not existing first.
  If the database does not exist, it gets created. Additionally, the script sets up four schemas within
  the database: 'etl','Staging','Dim','fact'.
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



