--USE master;
--GO

--CREATE DATABASE practice_sandbox;
--GO

--USE practice_sandbox;
--GO

--CREATE TABLE	dbo.property (
--				PropertyID INT IDENTITY(1,1) PRIMARY KEY,
--				PropertyName NVARCHAR(200) NOT NULL,
--				Address NVARCHAR(500),
--				AssetClass NVARCHAR(50)
--				);

--CREATE TABLE	dbo.tenant (
--				TenantID INT IDENTITY(1,1) PRIMARY KEY,
--				TenantName NVARCHAR(200) NOT NULL,
--				ContactEmail NVARCHAR(200)
--				);

--CREATE TABLE	dbo.lease (
--				LeaseID INT IDENTITY(1,1) PRIMARY KEY,
--				TenantID INT NOT NULL,
--				PropertyID INT NOT NULL,
--				StartDate DATE NOT NULL,
--				EndDate DATE NOT NULL,
--				MonthlyRent MONEY NOT NULL,
--				CONSTRAINT FK_lease_tenant FOREIGN KEY (TenantID) REFERENCES dbo.tenant(TenantID),
--				CONSTRAINT FK_lease_property FOREIGN KEY (PropertyID) REFERENCES dbo.property(PropertyID)
--				);

--DROP TABLE dbo.lease;
--DROP TABLE dbo.tenant;
--DROP TABLE dbo.property;


--CREATE TABLE dbo.property
--(
--	PropertyID INT IDENTITY(1,1) PRIMARY KEY,
--	PropertyName NVARCHAR(200) NOT NULL,
--	Address NVARCHAR(500),
--	City NVARCHAR(100),
--	AssetClass NVARCHAR(50),
--	YearBuilt INT,
--	SquareFeet INT
--);

--CREATE TABLE dbo.tenant
--(
--	TenantID INT IDENTITY(1,1) PRIMARY KEY,
--	TenantName NVARCHAR(200) NOT NULL,
--	ContactEmail NVARCHAR(200),
--	Industry NVARCHAR(200)
--);

--CREATE TABLE dbo.lease
--(
--	LeaseID INT IDENTITY(1,1) PRIMARY KEY,
--	TenantID INT NOT NULL,
--	PropertyID INT NOT NULL,
--	StartDate DATE NOT NULL,
--	EndDate DATE NOT NULL,
--	MonthlyRent MONEY NOT NULL,
--	SecurityDeposit MONEY,
--	RenewalOptions INT DEFAULT 0,
--	CONSTRAINT FK_lease_tenant FOREIGN KEY (TenantID) REFERENCES dbo.tenant(TenantID),
--	CONSTRAINT FK_lease_property FOREIGN KEY (PropertyID) REFERENCES dbo.property(PropertyID)
--);


--INSERT INTO dbo.property (PropertyName, Address, City, AssetClass, YearBuilt, SquareFeet)
--VALUES
--	('The Centre','5000 Herbert Street','Toronto','Mixed-use',1985,500000),
--	('Circle One','67 Tyrion Drive','Toronto','Retail',2021,250000),
--	('Sheep Centre','25 Tasya Avenue','Toronto','Mixed-use',2000,600000);

--INSERT INTO dbo.Tenant (TenantName, ContactEmail, Industry)
--VALUES
--    ('Acme Logistics Inc', 'leasing@acmelogistics.com', 'Logistics'),
--    ('Northwind Distribution', 'realestate@northwind.com', 'Distribution'),
--    ('Mainline Retail Co', 'leases@mainline.com', 'Retail'),
--    ('Quality Office Services', 'office@qualityoffice.com', 'Professional Services');

--INSERT INTO dbo.Lease (TenantID, PropertyID, StartDate, EndDate, MonthlyRent, SecurityDeposit, RenewalOptions)
--VALUES
--    (1, 1, '2023-01-01', '2028-12-31', 12500, 25000, 2),
--    (2, 2, '2024-03-01', '2029-02-28', 18750, 37500, 3),
--    (3, 3, '2022-06-15', '2027-06-14', 8200, 16400, 1),
--    (4, 1, '2025-09-01', '2030-08-31', 14500, 29000, 2);

--SELECT	l.leaseid,
--		t.tenantname,
--		p.propertyname,
--		p.city,
--		l.startdate,
--		l.enddate,
--		l.monthlyrent,
--		l.monthlyrent*12 AS AnnualRent
--FROM	dbo.lease l
--INNER JOIN dbo.tenant t ON l.tenantid = t.tenantid
--INNER JOIN dbo.property p ON l.propertyid = p.propertyid
--ORDER BY l.monthLyrent DESC;

--INSERT INTO dbo.Lease (TenantID, PropertyID, StartDate, EndDate, MonthlyRent)
--VALUES (999, 1, '2025-01-01', '2030-12-31', 5000);

--**🧠 AI-free zone — Self-test (20 min):** No AI:

--1. **Schema critique exercise.** Imagine a company stores invoices like this:
--   ```
--   Invoice(InvoiceID, InvoiceDate, VendorName, VendorAddress, VendorPhone,
--           PropertyName, Amount, GLCode, GLDescription)
--   ```
--   List 3 normalization problems with this design. Write your answer in a comment. (Hint: where will the same data appear in multiple places? What happens when a vendor's phone number changes?)
-- 
-- Invoice (InvoiceID,InvoiceDate,VendorID, PropertyID, Amount, GLID)
-- Vendor (VendorID, VendorName, VendorAddress, VendorPhone)
-- Property (PropertyID, PropertyName)
-- GL (GLID, Glcode, GLDescription)


--2. **Design exercise.** Sketch (in comments or as `CREATE TABLE` statements) a normalized schema for AP invoices at a commercial real estate firm. Tables to consider: Vendor, Invoice, InvoiceLineItem, Property, GLAccount. Define primary keys and foreign keys.

--CREATE TABLE dbo.vendor
--(
--	VendorID INT IDENTITY(1,1) PRIMARY KEY,
--	VendorName NVARCHAR(200) NOT NULL,
--	ContactEmail NVARCHAR(200)
--);


--CREATE TABLE dbo.GLAcct
--(
--	GLAccountID INT IDENTITY(1,1) PRIMARY KEY,
--	GLDescription NVARCHAR(200) NOT NULL
--);

--CREATE TABLE dbo.invoice
--(
--	InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
--	VendorID INT NOT NULL,
--	PropertyID INT NOT NULL,
--	InvoiceDate DATE NOT NULL,
--	InvoiceLineItem MONEY NOT NULL,
--	GLAccountID INT NOT NULL,
--	CONSTRAINT FK_vendor FOREIGN KEY (VendorID) REFERENCES dbo.vendor(vendorID),
--	CONSTRAINT FK_property FOREIGN KEY (PropertyID) REFERENCES dbo.property(PropertyID)
--	CONSTRAINT FK_gl FOREIGN KEY (GLAccountID) REFERENCES dbo.GLAcct(GLAccountID)
--);

--3. Add a new table `dbo.LeaseAmendment` to your sandbox that records amendments to leases. Required columns: AmendmentID (PK), LeaseID (FK), AmendmentDate, AmendmentDescription, NewMonthlyRent (nullable — only set if rent changes). Add a foreign key to Lease.

--CREATE TABLE dbo.LeaseAmendment
--(
--	AmendmentID INT IDENTITY(1,1) PRIMARY KEY,
--	LeaseID INT NOT NULL,
--	AmendmentDate DATE NOT NULL,
--	AmendmentDesc NVARCHAR(250) NOT NULL,
--	NewMonthlyRent MONEY,
--	CONSTRAINT FK_lease_tenant_amendment FOREIGN KEY (LeaseID) REFERENCES dbo.lease(LeaseID)
--);


--4. Insert 2 sample amendments. Then write a query that shows each lease with its amendments (LEFT JOIN — some leases have no amendments).
--INSERT INTO dbo.leaseamendment (LeaseID, AmendmentDate, Amendmentdesc, NewmonthlyRent)
--VALUES
--	(1,'2026-07-14','First Amendment',5000),
--	(2,'2026-07-21','First Amendment',6000);

--SELECT *
--FROM dbo.lease l
--LEFT JOIN dbo.leaseamendment la ON l.leaseid = la.leaseid

