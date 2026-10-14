/*==============================================================================
  PROJECT SETUP - DATABASE AND SCHEMAS
  ------------------------------------------------------------------------------
  Run this script first, once, before anything else.

  Creates the DataWarehouse database and the three Medallion schemas:
     bronze - raw landing zone, data exactly as the source sent it
     silver - cleaned, standardised, typed and de-duplicated
     Gold   - business-ready dimension and fact views for reporting
==============================================================================*/

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA Gold;
GO
