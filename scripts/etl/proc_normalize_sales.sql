/*
=======================================================================================================
 Stored procedure: Load Dim and Fact tables (Staging -> ETL)
=======================================================================================================
 Script Purpose:
      This stored procedure performs the ETL (Extract, Transform, Load) process to populate the both 
      'Dim' and 'fact' schema tables from 'Staging' schema.
  Actions Performed:
      - Truncates all Dimension and fact tables
      - Inserts transformed  and cleansed data from Staging table to Dimension and fact tables

  Parameters:
      None
      This stored procedure does not accept any parameters or return any values

  Usage Example:
      EXEC etl.sp_NormalizeSales
=======================================================================================================
*/
exec etl.sp_NormalizeSales

CREATE OR ALTER PROCEDURE etl.sp_NormalizeSales
AS
BEGIN
    
 
    PRINT '>>============================================================================================';
    PRINT '>>  Normalizing Staging.SalesRaw into dim and fact tables';
    PRINT '>>============================================================================================';
	
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
    BEGIN TRY
        BEGIN TRANSACTION
 
		SET @batch_start_time = GETDATE()
        --Truncate in FK-safe order: fact first, then dependents, then parents
    
        PRINT '>> Truncating fact.FactSales';
        TRUNCATE TABLE fact.FactSales;
 
		PRINT '>> Clearing dim.DimCustomer';
        DELETE FROM dim.DimCustomer;

		PRINT '>> Clearinge dim.DimGeography';
        DELETE FROM dim.DimGeography;

        PRINT '>> Clearing dim.DimProduct';
        DELETE FROM dim.DimProduct;
 
        PRINT '>> Clearing dim.DimDate';
		DELETE FROM dim.DimDate;	
 
        ---------------------------------------------------------------------
        -- Load data into dim.DimGeography
        ---------------------------------------------------------------------
		SET @start_time = GETDATE()
        -- 2a. DimGeography (no dependencies)
        PRINT '>> Inserting into dim.DimGeography';
        INSERT INTO dim.DimGeography (ZipCode, City, State, Region, District, Country)
        SELECT
            t.ZipCode,
            LEFT(t.City, CHARINDEX(',', t.City + ',') - 1) AS City,
            t.State,
            t.Region,
            t.District,
            t.Country
        FROM
        (
            SELECT *, ROW_NUMBER() OVER (
                PARTITION BY ZipCode, City, State, Region, District, Country
                ORDER BY (SELECT NULL)
            ) AS ranks
            FROM Staging.SalesRaw
            WHERE ZipCode IS NOT NULL
        ) t
        WHERE t.ranks = 1;
		SET @end_time = GETDATE()
		PRINT '================================================================================================='
		PRINT 'Loading data into DimGeography is completed'
		PRINT '>> Load duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------------';
		
		---------------------------------------------------------------------
        -- Load data into dim.DimProduct
        ---------------------------------------------------------------------
		SET @start_time = GETDATE()
        PRINT '>> Inserting into dim.DimProduct';
        INSERT INTO dim.DimProduct (ProductID, Product, Category, Segment, UnitCost, UnitPrice)
        SELECT
            TRIM(t.ProductID),
            TRIM(t.Product),
            TRIM(t.Category),
            TRIM(t.Segment),
            TRY_CAST(NULLIF(TRIM(t.UnitCost), '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(TRIM(t.UnitPrice), '') AS DECIMAL(10,2))
        FROM
        (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY (SELECT NULL)) AS ranks
            FROM Staging.SalesRaw
            WHERE ProductID IS NOT NULL
        ) t
        WHERE t.ranks = 1;
		SET @end_time = GETDATE()
		PRINT '================================================================================================='
		PRINT 'Loading data into DimProduct is completed'
		PRINT '>> Load duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------------';
		

		---------------------------------------------------------------------
        -- Load data into dim.DimDate
        ---------------------------------------------------------------------
		SET @start_time = GETDATE()
        PRINT '>> Inserting into dim.DimDate';
        DECLARE @StartDate DATE = '2011-01-01';
        DECLARE @EndDate   DATE = '2017-01-01';
 
        ;WITH Date_CTE AS (
            SELECT @StartDate AS [Date]
            UNION ALL
            SELECT DATEADD(DAY, 1, [Date])
            FROM Date_CTE
            WHERE [Date] < @EndDate
        )
        INSERT INTO dim.DimDate (DateKey, [Date], [Year], [Quarter], [Month], MonthName, [Day], DayOfWeek, DayName, IsWeekend)
        SELECT
            CONVERT(INT, FORMAT([Date], 'yyyyMMdd')),
            [Date],
            YEAR([Date]),
            DATEPART(QUARTER, [Date]),
            MONTH([Date]),
            DATENAME(MONTH, [Date]),
            DAY([Date]),
            DATEPART(WEEKDAY, [Date]),
            DATENAME(WEEKDAY, [Date]),
            CASE WHEN DATEPART(WEEKDAY, [Date]) IN (1, 7) THEN 1 ELSE 0 END
        FROM Date_CTE
        OPTION (MAXRECURSION 0);
		SET @end_time = GETDATE()
		PRINT '================================================================================================='
		PRINT 'Loading data into DimDate is completed'
		PRINT '>> Load duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------------';
		
		---------------------------------------------------------------------
        -- Load data into dim.DimCustomer
        ---------------------------------------------------------------------
		SET @start_time = GETDATE()
        -- 2d. DimCustomer (depends on DimGeography)
        PRINT '>> Inserting into dim.DimCustomer';
        INSERT INTO dim.DimCustomer (CustomerID, LastName, FirstName, Email, GeographyKey)
        SELECT
            t.CustomerID,
            ISNULL(TRIM(SUBSTRING(t.EmailName, CHARINDEX(':', t.EmailName)+1, CHARINDEX(',', t.EmailName) - CHARINDEX(':', t.EmailName) - 1)), '') AS LastName,
            ISNULL(TRIM(RIGHT(t.EmailName, LEN(t.EmailName) - CHARINDEX(',', t.EmailName) - 1)), '') AS FirstName,
            ISNULL(TRIM(REPLACE(REPLACE(LEFT(t.EmailName, CHARINDEX(':', t.EmailName)-1), '(', ''), ')', '')), '') AS Email,
            g.GeographyKey
        FROM
        (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY (SELECT NULL)) AS ranks
            FROM Staging.SalesRaw
            WHERE CustomerID IS NOT NULL
        ) t
        JOIN dim.DimGeography g
            ON g.ZipCode = t.ZipCode
            AND g.City = LEFT(t.City, CHARINDEX(',', t.City + ',') - 1)
            AND g.State = t.State
            AND g.Region = t.Region
            AND g.District = t.District
            AND g.Country = t.Country
        WHERE t.ranks = 1;
		SET @end_time = GETDATE()
		PRINT '================================================================================================='
		PRINT 'Loading data into DimCustomer is completed'
		PRINT '>> Load duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------------';


		---------------------------------------------------------------------
        -- Load data into fact.FactSales
        ---------------------------------------------------------------------
		SET @start_time = GETDATE()
        PRINT '>> Inserting into fact.FactSales';
        INSERT INTO fact.FactSales (DateKey, ProductKey, CustomerKey, Units, UnitCost, UnitPrice)
        SELECT
            d.DateKey,
            p.ProductKey,
            c.CustomerKey,
            TRY_CAST(NULLIF(TRIM(s.Units), '') AS INT),
            TRY_CAST(NULLIF(TRIM(s.[UnitCost]), '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(TRIM(s.[UnitPrice]), '') AS DECIMAL(10,2))
        FROM
        (
            SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY ProductID, [Date], CustomerID, CampaignID, Units, [UnitCost], [UnitPrice],
                                    ZipCode, [EmailName], City, State, Region, District, Country
                       ORDER BY (SELECT NULL)
                   ) AS ranks
            FROM Staging.SalesRaw
        ) s
        JOIN dim.DimDate d ON d.[Date] = TRY_CONVERT(DATE, s.[Date])
        JOIN dim.DimProduct p ON p.ProductID = TRIM(s.ProductID)
        JOIN dim.DimCustomer c ON c.CustomerID = TRIM(s.CustomerID)
        WHERE s.ranks = 1;
		SET @end_time = GETDATE()
		PRINT '================================================================================================='
		PRINT 'Loading data into factSales is completed'
		PRINT '>> Load duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------------';
 
		SET @batch_end_time = GETDATE()
		PRINT '================================================================================================================';
		PRINT 'Loading all tables is completed'
		PRINT '>>  - Total Load duration: '+ CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '>>==============================================================================================================';
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
 
        PRINT '==========================================================================================';
        PRINT 'ERROR OCCURRED DURING SALES NORMALIZATION';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: '  + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State: '   + CAST(ERROR_STATE() AS NVARCHAR(10));
 
 
        THROW;
    END CATCH;
END;
GO
 
