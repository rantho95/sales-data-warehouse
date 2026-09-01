# Sales Data Warehouse

A SQL Server data warehouse project built from a raw sales CSV dataset. The project demonstrates an end-to-end data warehousing workflow — from raw data ingestion and transformation, through dimensional modeling, ETL processing, and data quality validation.

The primary goal of this project was not simply to build a pipeline that runs, but to make defensible data modeling and transformation decisions based on the actual characteristics of the source data.

Project Objective

The objective of this project is to develop a sales data warehouse using Microsoft SQL Server that consolidates raw sales data into a structured, analytical data model suitable for reporting and business analysis.

The warehouse follows a dimensional modeling approach, using a star schema to make the data easier to query and consume for analytical workloads.

Project Requirements
Data Ingestion
Import the source sales data provided as a CSV file.
Preserve the raw source data in a staging environment before transformation.
Handle source-data inconsistencies and conversion issues during the ETL process.
Data Quality
Identify and resolve data quality issues before loading the analytical model.
Validate NULL and blank values.
Validate data types and conversion failures.
Identify duplicate records.
Validate business keys and referential integrity.
Apply business rules to identify logically invalid values.
Reconcile records between staging and the final fact table.
Data Integration & Modeling
Transform the source data into a structured dimensional model.
Implement a star schema consisting of dimension and fact tables.
Use surrogate keys for dimensional entities.
Maintain source business keys for traceability.
Separate reusable geographic information into its own dimension where appropriate.
Scope
The warehouse represents the latest available dataset only.
Historical versioning and slowly changing dimension implementation are outside the scope of this project.
The model is nevertheless designed so that historization could be introduced in the future.
Documentation
Document the warehouse architecture and data model.
Explain important modeling and transformation decisions.
Document known limitations and assumptions.
Provide sufficient context for both technical and analytical users to understand the model.
Architecture

   
### Schema	Purpose
1. Staging	Holds raw source data before transformation
2. Dim	Contains dimension tables used for analytical slicing and filtering
3. Fact	Contains measurable sales events
4. etl	Contains stored procedures responsible for loading and processing warehouse data
    Data Model

The final analytical layer uses a star schema centered on fact.FactSales.

Fact Table

fact.FactSales — contains the measurable sales events and foreign keys linking each transaction to its dimensions.

Key measures: Units, UnitCost, UnitPrice.

Dimension Tables
dim.DimDate —> provides the calendar context required for time-based analysis.
dim.DimProduct —> contains product related descriptive attributes and product-level measures such as cost and selling price.
dim.DimCustomer —> contains customer attributes such as name, email, and the customer's geographic reference.
dim.DimGeography —> contains reusable geographic attributes: ZipCode, City, State, Region, District, Country.
Key Design Decisions

Several decisions in this project required more than simply following a predefined template. The source data was analyzed first, and the warehouse design was adapted where the evidence supported it.

1. Schemas are organized by table role, not business domain. The database uses separate schemas for Staging, Dim, Fact, and etl rather than organizing tables by business domain. This dataset represents a single business process — sales — so there's no strong domain boundary that would justify splitting tables into multiple business-domain schemas. Organizing by warehouse role instead makes the architecture easier to understand and gives each schema a clear responsibility:

Staging → Source data
Dim     → Descriptive entities
Fact    → Business events and measures
etl     → Data-loading processes

2. Geography was modeled as a separate dimension. DimGeography was created as its own dimension rather than storing geographic attributes directly in DimCustomer. This was based on analyzing the source data first, not assumed: the dataset has roughly 282,596 customers, but only 29,189 distinct combinations of ZipCode/City/State/Region/District/Country. That means many customers share the same geographic information — keeping geography in its own dimension avoids repeating the same descriptive attributes across a large number of customer records, and gives the model a reusable geographic entity for analytical queries.

3. Surrogate keys were used for dimensions. The dimension tables use integer surrogate keys (ProductKey, CustomerKey, GeographyKey, DateKey) as their actual primary keys, while retaining the original business keys (ProductID, CustomerID) with uniqueness constraints for traceability. This gives faster integer-based joins, separates warehouse identifiers from source-system identifiers, and — most importantly — supports Slowly Changing Dimensions (SCD) if historization is introduced later. A future customer dimension, for example, could hold multiple versions of the same CustomerID, each with a different CustomerKey, preserving historical attribute changes.

4. Exact duplicate fact records were removed. The source dataset has no unique transaction identifier and no time-of-day precision, so it wasn't possible to definitively determine whether a repeated row was a genuine separate purchase or an accidental duplication in the source export. 133 exact full-row duplicates were identified. Since the fact table is meant to represent distinct sales events, these were treated as accidental duplicates and removed — verified with a before/after reconciliation (675,368 → 675,235 rows, 133 removed), rather than assumed or silently dropped without documentation.


5. TRUNCATE vs. DELETE in the ETL process. The ETL process accounts for SQL Server's foreign-key behavior when clearing tables before reloading. A common assumption is that tables can simply be truncated in "child-before-parent" order — but SQL Server blocks TRUNCATE TABLE on any table referenced by a foreign key constraint, even if the referencing table is empty. The reload strategy reflects this: fact.FactSales (referenced by nothing) uses TRUNCATE TABLE; dimensions referenced by foreign-key relationships (DimCustomer, DimGeography, DimProduct, DimDate) use DELETE FROM instead. This respects the database's referential constraints while still providing a fully repeatable reload process.

Data Quality & Validation

A dedicated data quality validation script runs after the ETL process completes, checking:

Row-count reconciliation across staging, dimension, and fact tables
Distinct business-key reconciliation between staging and dimensions
Referential integrity — orphaned foreign key checks across every relationship
Staging-to-fact completeness
NULL and blank values in required columns
Data-type conversion failures
Negative or zero measure values (business-rule validation)
Duplicate business keys in dimension tables

The goal is to make sure a successful ETL run doesn't automatically mean the resulting data is correct:

ETL successfully executed  ≠  Data is necessarily correct

Data quality validation is a separate, explicit layer of assurance before the warehouse is consumed for reporting and analytics. See sql/tests/data_quality_checks.sql — as of the last full run, every check passes cleanly.

## How to Run
sql
-- 1. Create the database, schemas, and tables
:r init_database.sql

-- 2. Load the raw CSV into staging
EXEC Staging.sp_Load_Sales_Data;

-- 3. Clean, standardize, and normalize into dimensions and fact
EXEC etl.sp_NormalizeSales;


Technology Stack
Microsoft SQL Server / T-SQL
SQL Server Management Studio (SSMS)
Dimensional Modeling / Star Schema
ETL via T-SQL stored procedures


This project focuses not only on implementing the technical components of a warehouse, but on understanding the source data, documenting assumptions, validating transformation decisions, and designing a model that can support real analytical workloads.

License

This project is licensed under the MIT License. You are free to use, modify, and share this project with proper attribution.
