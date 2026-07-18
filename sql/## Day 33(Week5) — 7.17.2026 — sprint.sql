
----NON SARGARBLE
--SELECT	YEAR(orderdate) AS OrderYear,
--		MONTH(orderdate) AS OrderMonth,
--		SUM(totaldue) AS Revenue
--FROM	sales.SalesOrderHeader
--WHERE	YEAR(orderdate) = 2013
--GROUP BY	YEAR(orderdate), MONTH(orderdate)
--ORDER BY orderyear, ordermonth

----SARGABLE
--SELECT	YEAR(orderdate) AS OrderYear,
--		MONTH(orderdate) AS OrderMonth,
--		SUM(totaldue) AS Revenue
--FROM	sales.SalesOrderHeader
--WHERE	orderdate >= '2013-01-01' AND orderdate < '2014-01-01'
--GROUP BY	YEAR(orderdate), MONTH(orderdate)
--ORDER BY orderyear, ordermonth

--**Problem 1 — Design exercise: AP invoice schema (45 min)**

--Design a normalized schema for the AP system at a commercial real estate firm. Required entities (at minimum):
--- Vendor (master vendor list)
--- Property (where the invoice applies)
--- Invoice (header — one per invoice)
--- InvoiceLineItem (detail — one or more per invoice)
--- GLAccount (master chart of accounts)
--- Invoice Payment (one or more payments may settle an invoice over time)

--For each table:
--- Primary key
--- Foreign keys to related tables
--- Reasonable columns
--- Notes (in comments) on data types and any constraints

--Write the `CREATE TABLE` statements in your sandbox. Test by inserting a few sample rows that demonstrate the relationships.
--This is the kind of design exercise you may face when evaluating a vendor's proposed schema or when proposing one yourself. The goal isn't perfection — it's defensible structure.


--USE practice_sandbox;
--GO

--CREATE TABLE dbo.vendor
--(

--	VendorID INT IDENTITY(1,1) PRIMARY KEY,
--	VendorName NVARCHAR(200) NOT NULL,
--	Address NVARCHAR(500)
--);

--CREATE TABLE dbo.invoiceheader
--(
--	InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
--	Invoice NVARCHAR(200) NOT NULL,
--	InvoicePayment MONEY
--);

--CREATE TABLE dbo.invoicedetails
--(
--	InvoiceDetailID INT IDENTITY(1,1) PRIMARY KEY,
--	InvoiceLineItem MONEY,
--	InvoiceID INT,
--	Glaccountid INT,
--	PropertyID INT,
--	CONSTRAINT FK_invoiceheader FOREIGN KEY (InvoiceID) REFERENCES dbo.invoiceheader(InvoiceID),
--	CONSTRAINT FK_property FOREIGN KEY (PropertyID) REFERENCES dbo.property(PropertyID)
--);
	
--CREATE TABLE dbo.account
--(
--	GLaccountID INT IDENTITY(1,1) PRIMARY KEY,
--	GLAccountNumber NVARCHAR(6) NOT NULL,
--	GLName NVARCHAR (200) NOT NULL
--);


--ALTER TABLE dbo.invoicedetails
--ADD InvoiceDate DATE;

--ALTER TABLE dbo.invoiceheader
--ADD vendorID INT;
--ALTER TABLE dbo.invoicedetails
--ADD vendorID INT;

--UPDATE dbo.invoicedetails
--SET InvoiceDate = '2026-07-18'
--WHERE InvoiceDetailID = 1

--UPDATE dbo.invoiceheader
--SET VendorID = 1
--WHERE Invoiceid = 1

--CREATE TABLE dbo.accountspayable
--(
--	apid INT IDENTITY(1,1) PRIMARY KEY,
--	InvoiceID INT NOT NULL,
--	VendorID INT NOT NULL,
--	PropertyID INT NOT NULL,
--	AmountPaidToDate MONEY NOT NULL,
--	OustandingBalance MONEY NOT NULL
--);



--INSERT INTO dbo.vendor(VendorName,Address)
--VALUES
--	('Vendor1','1 Cineplex Street, Richmond hill, Ontario, LXXXXX');

--INSERT INTO dbo.invoiceheader (Invoice,InvoicePayment)
--VALUES
--	('Invoice1',5000);

--INSERT INTO dbo.account (GLAccountNumber,GLname)
--VALUES
--	('600000','CA Expense 1')

--INSERT INTO dbo.invoicedetails (InvoiceLineItem,InvoiceID,Glaccountid,PropertyID)
--VALUES
--	('5000',1,1,1);

--INSERT INTO dbo.accountspayable(InvoiceID,VendorID,PropertyID,AmountPaidtoDate,OustandingBalance)
--VALUES	(1,1,1,2500,2500)


--**Problem 2 — Create a view that abstracts complexity (30 min)**

--Using your AP schema from Problem 1, create a view `dbo.vw_OpenInvoices` that returns one row per open (unpaid) invoice with: InvoiceID, VendorName, PropertyName, InvoiceDate, DueDate, InvoiceTotal, AmountPaidToDate, OutstandingBalance, DaysOverdue.

--"Open" = OutstandingBalance > 0. "DaysOverdue" should be 0 if not past due.

--This is the kind of view you'd hand to the AP team's reporting tools.

--CREATE VIEW dbo.vw_openvinvoices AS

--SELECT
--	ih.invoiceid,
--	v.vendorname,
--	id.invoicedate,
--	p.PropertyName,
--	ap.amountpaidtodate,
--	ap.oustandingbalance,
--	DATEDIFF(DAY,id.invoicedate,GETDATE()) AS daysoverdue
--FROM dbo.invoiceheader ih
--INNER JOIN dbo.vendor v ON ih.vendorid = v.vendorid
--INNER JOIN dbo.invoicedetails id ON ih.invoiceid = id.invoiceid
--INNER JOIN dbo.property p ON id.propertyid = p.PropertyID
--INNER JOIN dbo.accountspayable ap ON ih.invoiceid = ap.invoiceid

--SELECT * FROM dbo.vw_openvinvoices



--**Problem 3 — Create a parameterized procedure (30 min)**

--Create `dbo.usp_GetVendorInvoiceSummary @VendorID INT, @AsOfDate DATE = NULL` that returns one row per vendor (or for the specific vendor if @VendorID given) with: VendorID, VendorName, InvoiceCount, TotalBilled, TotalPaid, TotalOutstanding.
--If @AsOfDate is null, use today's date.
--> **Data-date note:** your sandbox sample data is dated 2023–2030 (some of it in the future relative to today). That's fine here — unlike AdventureWorks, this is data you invent — but be aware when testing "as of today": if all your invoices are future-dated, an as-of-today filter may return nothing. Either seed some past-dated invoices, or test with an explicit `@AsOfDate` like '2027-01-01' so you can see the logic work. This is itself a small architect lesson: always sanity-check that your test data actually exercises the logic.
--Test it with a couple of vendor IDs.


--CREATE PROCEDURE dbo.usp_GetVendorInvoicSummary
--@VendorID INT,
--@AsOfDate DATE NULL
--AS
--	BEGIN
--	SELECT	v.VendorID,
--			v.VendorName,
--			id.invoicedate,
--			COUNT(id.invoiceID) AS InvoiceCount,
--			SUM(id.invoicelineitem) AS Totalbilled,
--			SUM(ap.amountpaidtodate) AS Totalpaid,
--			SUM(ap.oustandingbalance) AS TotalOutstanding
--	FROM	dbo.invoicedetails id
--	INNER JOIN dbo.accountspayable ap ON id.invoiceid = ap.invoiceid
--	INNER JOIN dbo.vendor v ON ap.vendorid = v.vendorid
--	WHERE @AsOfDate = id.invoicedate
--	GROUP BY v.vendorid,v.vendorname,id.invoicedate
--	END;
--GO

--EXEC dbo.usp_GetVendorInvoicSummary @VendorID = 1, @AsOfDate = '2026-07-18';

--**Problem 4 — Index design (20 min)**

--For the view `vw_OpenInvoices` from Problem 2, propose 2 indexes that would speed up common queries against it. Write the `CREATE INDEX` statements. In a comment, explain which queries each index helps and why.

--(Hint: think about which columns the view's underlying query filters and joins on.)

