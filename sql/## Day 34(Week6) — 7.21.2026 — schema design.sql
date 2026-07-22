--PRACTICE DB CREATION

--For each product subcategory, the 3 highest-priced products. (Top-N per group.)

--WITH totalrevenue AS

--(

--SELECT	p.ProductSubcategoryID,
--		p.Name AS ProductName,
--		ps.name AS SubCategory,
--		SUM(p.listprice) AS Revenue
--FROM Production.Product P
--INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
--GROUP BY p.ProductSubcategoryID, p.name, ps.Name

--)
--,productranks AS

--(
--SELECT	productname,
--		subcategory,
--		Revenue,
--		ROW_NUMBER() OVER (PARTITION BY subcategory ORDER BY revenue DESC) AS ranking
--FROM totalrevenue
--)

--SELECT *
--FROM productranks
--WHERE ranking <= 3

--Running monthly cumulative revenue for 2013. (Mind the frame — RANGE vs ROWS.)


--WITH totalrevenue AS

--(
--	SELECT	MONTH(orderdate) AS Month,
--			SUM(TotalDue) AS TotalRevenue
--	FROM	sales.SalesOrderHeader
--	WHERE	Orderdate >= '2013-01-01' AND Orderdate < '2014-01-01'
--	GROUP BY	MONTH(orderdate)
--)

--SELECT	Month,
--		TotalRevenue,
--		SUM(TotalRevenue) OVER (ORDER BY MONTH ROWS UNBOUNDED PRECEDING) AS RunningTotal
--FROM	totalrevenue


--USE master;
--GO
--IF DB_ID('cre_portfolio_db') IS NOT NULL
--BEGIN
--    ALTER DATABASE cre_portfolio_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--    DROP DATABASE cre_portfolio_db;
--END
--GO
--CREATE DATABASE cre_portfolio_db;
--GO
--USE cre_portfolio_db;
--GO



DECLARE @Today DATE = '2024-12-15'

--CREATE TABLE dbo.property
--(

--	propertyid INT IDENTITY(1,1) PRIMARY KEY,
--	propertyname NVARCHAR(200) NOT NULL,
--	address NVARCHAR(500),
--	city NVARCHAR(100) NOT NULL,
--	province NVARCHAR(50) NOT NULL DEFAULT 'ON',
--	assetclass NVARCHAR(50) NOT NULL,
--	yearbuilt INT,
--	totalsquarefeet INT NOT NULL,
--	acquisitiondate DATE,
--	acquisitioncost MONEY,
--	CONSTRAINT ck_property_assetclass CHECK (assetclass IN ('retail','mixed-use','office','industrial','residential')),
--	CONSTRAINT cK_property_squarefeet CHECK (totalsquarefeet > 0)
--);

--CREATE TABLE dbo.tenant

--(

--	tenantid INT IDENTITY(1,1) PRIMARY KEY,
--	tenantname NVARCHAR(200) NOT NULL,
--	industry NVARCHAR(100),
--	anchortenant BIT NOT NULL DEFAULT 0,
--	contactemail NVARCHAR(200),
--	createddate DATE NOT NULL DEFAULT GETDATE()

--);

--CREATE TABLE dbo.Lease (
--    LeaseID INT IDENTITY(1,1) PRIMARY KEY,
--    PropertyID INT NOT NULL,
--    TenantID INT NOT NULL,
--    LeaseStartDate DATE NOT NULL,
--    LeaseEndDate DATE NOT NULL,
--    BaseMonthlyRent MONEY NOT NULL,
--    SquareFeetLeased INT NOT NULL,
--    SecurityDeposit MONEY,
--    RenewalOptions INT NOT NULL DEFAULT 0,
--    Status NVARCHAR(20) NOT NULL DEFAULT 'Active',
--    CONSTRAINT FK_Lease_Property FOREIGN KEY (PropertyID) REFERENCES dbo.Property(PropertyID),
--    CONSTRAINT FK_Lease_Tenant FOREIGN KEY (TenantID) REFERENCES dbo.Tenant(TenantID),
--    CONSTRAINT CK_Lease_Dates CHECK (LeaseEndDate > LeaseStartDate),
--    CONSTRAINT CK_Lease_Rent CHECK (BaseMonthlyRent > 0),
--    CONSTRAINT CK_Lease_Status CHECK (Status IN ('Active', 'Expired', 'Terminated'))
--);

---- Lease amendments
--CREATE TABLE dbo.LeaseAmendment (
--    AmendmentID INT IDENTITY(1,1) PRIMARY KEY,
--    LeaseID INT NOT NULL,
--    AmendmentDate DATE NOT NULL,
--    AmendmentType NVARCHAR(50) NOT NULL,
--    NewMonthlyRent MONEY,
--    NewEndDate DATE,
--    Notes NVARCHAR(500),
--    CONSTRAINT FK_LeaseAmendment_Lease FOREIGN KEY (LeaseID) REFERENCES dbo.Lease(LeaseID),
--    CONSTRAINT CK_LeaseAmendment_Type CHECK (
--        AmendmentType IN ('RentEscalation', 'Renewal', 'Expansion', 'Termination', 'Other')
--    )
--);

---- Monthly rent roll snapshot
--CREATE TABLE dbo.RentRoll (
--    RentRollID INT IDENTITY(1,1) PRIMARY KEY,
--    LeaseID INT NOT NULL,
--    SnapshotMonth DATE NOT NULL,
--    BilledAmount MONEY NOT NULL,
--    CollectedAmount MONEY NOT NULL,
--    CollectionStatus NVARCHAR(20) NOT NULL DEFAULT 'Collected',
--    CONSTRAINT FK_RentRoll_Lease FOREIGN KEY (LeaseID) REFERENCES dbo.Lease(LeaseID),
--    CONSTRAINT CK_RentRoll_Status CHECK (
--        CollectionStatus IN ('Collected', 'Partial', 'Outstanding', 'Writeoff')
--    ),
--    CONSTRAINT CK_RentRoll_Amounts CHECK (BilledAmount >= 0 AND CollectedAmount >= 0)
--);


--SELECT	TABLE_SCHEMA + '.' + TABLE_NAME AS tablename,
--		(SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) AS ColumnCount
--FROM	INFORMATION_SCHEMA.TABLES T
--WHERE	TABLE_TYPE = 'BASE TABLE'
--ORDER BY TABLE_NAME

--1. Lease has both `Status` and `EndDate`. If EndDate is in the past, should Status automatically be 'Expired'? Or independent? Argue one side in 3-4 sentences in a comment.
--it should be independent
--1) potentially a month to month tenant (no expiry date set)
--2) setting it as auto expire - the lease may be overlooked
--3) forces controls within to actually review leases


--2. Why is RentRoll a separate table rather than computed on demand from Lease? Write 2-3 sentences.
-- it should be separate
-- 1) cleaner tables
-- 2) easily reference rates for each of the leases
-- 3) less calculations in table to not make it overly complicated - performance implications if massive number of tenants

--3. The schema has no table for property managers, leasing agents, etc. If you'd add one, sketch (in comments) a `BusinessContact` table with PK/FK to Lease.

-- primary key would be businesscontactid > generate one as individuals join the company
-- FK should be to leases as leasingagentid to refer them back to the leases they brought then tie it back to the businesscontactid
-- FK should be to properties as propertymanagerid to refer them back to the properties they manage then tie it back to the businesscontactid

--4. If a real enterprise system has 30+ operational tables and we're modeling 5, list 4-5 categories of information being deliberately omitted.
-- gl accounts
-- accounts payable
-- accounts receivable
-- vendors
-- jobs/construction

--5. Identify 2 queries this schema makes FAST (well-indexed by PKs) and 2 that would be SLOW (need additional indexes).
--fast
-- 1)joins on leases and amendments
-- 2)joins on rent rolls and leases
--slow
-- 1)sorting by security deposits
-- 2) filtering by rents
-- 2)
