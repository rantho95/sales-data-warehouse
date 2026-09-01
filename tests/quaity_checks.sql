/*
=========================================================================================
 Data Quality, Reconciliation & Integrity Checks — Sales Star Schema
=========================================================================================
 Script Purpose:
   This script performs data quality, reconciliation, and integrity checks across the
   Staging, Dim, and Fact schemas to validate the completeness, consistency, accuracy,
   and integrity of the data loaded into the data warehouse.
 
   The checks include:
     - Row-count reconciliation between staging, dimension, and fact tables
     - Validation of distinct business keys between staging and dimension tables
     - Referential integrity checks for foreign key relationships
     - Identification of staging records that were not loaded into the fact table
     - Validation of NULL and blank values in required columns
     - Validation of numeric data types and conversion failures
     - Validation of business rules for measure values
     - Detection of duplicate business keys in dimension tables
 
 Usage Notes:
   - Run these checks after the ETL loading process has completed.
   - Review the results to identify data quality or ETL issues.
   - Investigate and resolve any discrepancies before the data is consumed for
     reporting or analytics.
*/
USE DataWarehouse;
GO
 
-- =========================================================================================
-- SECTION 1: Reconciliation — row counts across stages
-- =========================================================================================
SELECT 'Staging.SalesRaw'  AS TableName, COUNT(*) AS RowCounts FROM Staging.SalesRaw
UNION ALL
SELECT 'dim.DimDate', COUNT(*) FROM dim.DimDate
UNION ALL
SELECT 'dim.DimGeography',  COUNT(*) FROM dim.DimGeography
UNION ALL
SELECT 'dim.DimProduct',    COUNT(*) FROM dim.DimProduct
UNION ALL
SELECT 'dim.DimCustomer',   COUNT(*) FROM dim.DimCustomer
UNION ALL
SELECT 'fact.FactSales',    COUNT(*) FROM fact.FactSales;
 
 
SELECT
    (SELECT COUNT(DISTINCT ProductID) FROM Staging.SalesRaw)  AS DistinctProductsInStaging,
    (SELECT COUNT(*) FROM dim.DimProduct)                      AS DimProductRows,
    (SELECT COUNT(DISTINCT CustomerID) FROM Staging.SalesRaw) AS DistinctCustomersInStaging,
    (SELECT COUNT(*) FROM dim.DimCustomer)                     AS DimCustomerRows;
 
-- =========================================================================================
-- SECTION 2: Referential Integrity — orphaned FK checks
-- =========================================================================================
 
-- FactSales rows whose ProductKey doesn't resolve to a DimProduct row
SELECT COUNT(*) AS OrphanedProductFKs
FROM fact.FactSales f
LEFT JOIN dim.DimProduct p ON p.ProductKey = f.ProductKey
WHERE p.ProductKey IS NULL;
 
-- FactSales rows whose CustomerKey doesn't resolve to a DimCustomer row
SELECT COUNT(*) AS OrphanedCustomerFKs
FROM fact.FactSales f
LEFT JOIN dim.DimCustomer c ON c.CustomerKey = f.CustomerKey
WHERE c.CustomerKey IS NULL;
 
-- FactSales rows whose DateKey doesn't resolve to a DimDate row
SELECT COUNT(*) AS OrphanedDateFKs
FROM fact.FactSales f
LEFT JOIN dim.DimDate d ON d.DateKey = f.DateKey
WHERE d.DateKey IS NULL;
 
-- DimCustomer rows whose GeographyKey doesn't resolve to a DimGeography row
SELECT COUNT(*) AS OrphanedGeographyFKs
FROM dim.DimCustomer c
LEFT JOIN dim.DimGeography g ON g.GeographyKey = c.GeographyKey
WHERE g.GeographyKey IS NULL;
 
-- Staging rows that failed to make it into FactSales at all

SELECT COUNT(*) AS StagingRowsMissingFromFact
FROM Staging.SalesRaw s
WHERE NOT EXISTS (
    SELECT 1
    FROM fact.FactSales f
    JOIN dim.DimProduct p  ON p.ProductKey = f.ProductKey
    JOIN dim.DimCustomer c ON c.CustomerKey = f.CustomerKey
    JOIN dim.DimDate d     ON d.DateKey = f.DateKey
    WHERE p.ProductID = TRIM(s.ProductID)
      AND c.CustomerID = TRIM(s.CustomerID)
      AND d.[Date] = TRY_CONVERT(DATE, s.[Date])
);
 
/* 
=========================================================================================
 SECTION 3: Column-Level Validation — nulls, blanks, type integrity
=========================================================================================
*/ 
-- DimCustomer — parsed name/email fields
SELECT COUNT(*) AS BadCustomerFields
FROM dim.DimCustomer
WHERE FirstName IS NULL OR TRIM(FirstName) = ''
   OR LastName  IS NULL OR TRIM(LastName)  = ''
   OR Email     IS NULL OR TRIM(Email)     = '';
 
-- DimProduct — required text fields and numeric fields
SELECT COUNT(*) AS BadProductFields
FROM dim.DimProduct
WHERE Product IS NULL OR TRIM(Product) = ''
   OR Category IS NULL OR TRIM(Category) = ''
   OR Segment  IS NULL OR TRIM(Segment)  = ''
   OR UnitCost IS NULL
   OR UnitPrice IS NULL;
 
-- DimGeography — required fields
SELECT COUNT(*) AS BadGeographyFields
FROM dim.DimGeography
WHERE ZipCode  IS NULL OR TRIM(ZipCode)  = ''
   OR City     IS NULL OR TRIM(City)     = ''
   OR State    IS NULL OR TRIM(State)    = ''
   OR Region   IS NULL OR TRIM(Region)   = ''
   OR District IS NULL OR TRIM(District) = ''
   OR Country  IS NULL OR TRIM(Country)  = '';
 
-- FactSales — nulls/junk in measure columns (post-cast)
SELECT COUNT(*) AS NullMeasuresInFact
FROM fact.FactSales
WHERE Units IS NULL OR UnitCost IS NULL OR UnitPrice IS NULL;
 
-- Staging.SalesRaw — pre-cast type-validity check on measures

SELECT
    SUM(CASE WHEN TRY_CAST(Units AS INT) IS NULL THEN 1 ELSE 0 END)                AS BadUnits,
    SUM(CASE WHEN TRY_CAST([UnitCost] AS DECIMAL(10,2)) IS NULL THEN 1 ELSE 0 END) AS BadUnitCost,
    SUM(CASE WHEN TRY_CAST([UnitPrice] AS DECIMAL(10,2)) IS NULL THEN 1 ELSE 0 END) AS BadUnitPrice
FROM Staging.SalesRaw;
 
-- Negative or zero values in measures — logically invalid even if numeric
SELECT COUNT(*) AS NonPositiveMeasures
FROM fact.FactSales
WHERE Units <= 0 OR UnitCost < 0 OR UnitPrice < 0;
 
--  Duplicate business keys in dimensions (should be impossible given UNIQUE
--  constraints, but confirms the constraints are actually doing their job)
SELECT ProductID, COUNT(*) FROM dim.DimProduct GROUP BY ProductID HAVING COUNT(*) > 1;
SELECT CustomerID, COUNT(*) FROM dim.DimCustomer GROUP BY CustomerID HAVING COUNT(*) > 1;
