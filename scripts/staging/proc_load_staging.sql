/*
==================================================================================================
Stored Procedure: Load Staging table (Source -> Staging)
==================================================================================================

Script Purpose:
    This stored procedure loads data into the 'staging' schema from external CSV file.
    It performs the following actions:
      - Truncates the staging table before loading data.
      - Uses the 'BULK INSERT' command to load data from csv file to staging table.

Paramaeters:
    None
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Staging.sp_LoadRawData
==================================================================================================
*/


CREATE OR ALTER PROCEDURE Staging.sp_LoadRawData
AS
BEGIN


	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY

			SET @batch_start_time = GETDATE()
			PRINT '============================================================================================'
			PRINT 'Importing the Staging Table'
			PRINT '============================================================================================'

			SET @start_time = GETDATE()
			PRINT'>> Truncating Table: Staging.SalesRaw'
			IF OBJECT_ID('Staging.SalesRaw', 'U') IS NOT NULL
			BEGIN
				TRUNCATE TABLE Staging.SalesRaw;
			END;

			PRINT'>> Inserting Data into: Staging.SalesRaw'
			BULK INSERT Staging.SalesRaw
			FROM 'C:\Users\USER\Music\Employee_data\Sales.csv'
			WITH (
				FIRSTROW = 2,
				FORMAT = 'CSV',
				FIELDTERMINATOR = ',',
				ROWTERMINATOR = '\n'
           
			)
			SET @end_time = GETDATE()
			PRINT '================================================================================================='
			PRINT '>> Load duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
			PRINT '>>---------------';

			SET @batch_end_time = GETDATE()
			PRINT '================================================================================================='
			PRINT 'Loading SalesRaw table is completed'
			PRINT '>>  - Total Load duration: '+ CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
			PRINT '>>---------------';
	END TRY

	BEGIN CATCH
	
	PRINT '==========================================================================================';
	PRINT 'ERROR OCCURRED DURING LOADING STAGING TABLE';
	PRINT 'Error Message: ' + ERROR_MESSAGE();
	PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
	PRINT 'Error Number: ' + CAST(ERROR_STATE() AS NVARCHAR(10));

	THROW;
	END CATCH;
END;


