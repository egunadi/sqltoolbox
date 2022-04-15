---------------------------------------------------------------------
-- Mastering T-SQL Querying Fundamentals
-- © Itzik Ben-Gan, SolidQ
-- Advanced T-SQL training: http://tsql.solidq.com
---------------------------------------------------------------------

USE TSQLV4; -- http://tsql.solidq.com/SampleDatabases/TSQLV4.zip

---------------------------------------------------------------------
-- Logical Query Processing
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Logical Query Processing Example
---------------------------------------------------------------------

-- Create and populate tables dbo.Customers and dbo.Orders
SET NOCOUNT ON;
USE tempdb;

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
  DROP TABLE dbo.Orders;

IF OBJECT_ID(N'dbo.Customers', N'U') IS NOT NULL
  DROP TABLE dbo.Customers;

CREATE TABLE dbo.Customers
(
  custid  CHAR(5)     NOT NULL,
  city    VARCHAR(10) NOT NULL,
  CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
  orderid INT     NOT NULL,
  custid  CHAR(5) NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid),
  CONSTRAINT PK_Orders_Customers FOREIGN KEY(custid)
    REFERENCES dbo.Customers(custid)
);
GO

INSERT INTO dbo.Customers(custid, city) VALUES('FISSA', 'Madrid');
INSERT INTO dbo.Customers(custid, city) VALUES('FRNDO', 'Madrid');
INSERT INTO dbo.Customers(custid, city) VALUES('KRLOS', 'Madrid');
INSERT INTO dbo.Customers(custid, city) VALUES('MRPHS', 'Zion');

INSERT INTO dbo.Orders(orderid, custid) VALUES(1, 'FRNDO');
INSERT INTO dbo.Orders(orderid, custid) VALUES(2, 'FRNDO');
INSERT INTO dbo.Orders(orderid, custid) VALUES(3, 'KRLOS');
INSERT INTO dbo.Orders(orderid, custid) VALUES(4, 'KRLOS');
INSERT INTO dbo.Orders(orderid, custid) VALUES(5, 'KRLOS');
INSERT INTO dbo.Orders(orderid, custid) VALUES(6, 'MRPHS');
INSERT INTO dbo.Orders(orderid, custid) VALUES(7, NULL);

-- Return the customer ID and number of orders for customers
-- from Madrid who placed fewer than 3 orders.
-- Sort the result by the number of orders.

SELECT C.custid, COUNT(O.orderid) AS numorders
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.custid = O.custid
WHERE C.city = 'Madrid'
GROUP BY C.custid
HAVING COUNT(O.orderid) < 3
ORDER BY numorders;

-- Multi-row assignment with a variable
SET NOCOUNT ON;
USE tempdb;
GO

-- Create a table called T1 and populate it with sample data
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  col1   INT IDENTITY NOT NULL,
  col2   VARCHAR(100) NOT NULL,
  filler CHAR(2000) NULL,
  CONSTRAINT PK_T1 PRIMARY KEY CLUSTERED(col1)
);

INSERT INTO dbo.T1(col2)
  SELECT 'String ' + CAST(n AS VARCHAR(10))
  FROM TSQL2012.dbo.GetNums(1, 100) AS Nums;
GO

-- Test 1, with ORDER BY
DECLARE @s AS VARCHAR(MAX);
SET @s = '';

SELECT @s = @s + col2 + ';'
FROM dbo.T1
ORDER BY col1;

SELECT @s;
GO

-- Test 2, with ORDER BY, after adding covering nc index
CREATE NONCLUSTERED INDEX idx_nc_col2 ON dbo.T1(col2, col1);
GO

DECLARE @s AS VARCHAR(MAX);
SET @s = '';

SELECT @s = @s + col2 + ';'
FROM dbo.T1
ORDER BY col1;

SELECT @s;
GO

---------------------------------------------------------------------
-- CROSS Joins
---------------------------------------------------------------------

-- SQL-92
USE TSQLV4;

SELECT C.custid, E.empid
FROM Sales.Customers AS C
  CROSS JOIN HR.Employees AS E;

-- SQL-89
SELECT C.custid, E.empid
FROM Sales.Customers AS C, HR.Employees AS E;

-- Self Cross-Join
SELECT
  E1.empid, E1.firstname, E1.lastname,
  E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1 
  CROSS JOIN HR.Employees AS E2;
GO

-- All numbers from 1 - 1000

-- Auxiliary table of digits
USE TSQLV4;

DROP TABLE IF EXISTS dbo.Digits;

CREATE TABLE dbo.Digits(digit INT NOT NULL PRIMARY KEY);

INSERT INTO dbo.Digits(digit)
  VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SELECT digit FROM dbo.Digits;
GO

-- All numbers from 1 - 1000
SELECT D3.digit * 100 + D2.digit * 10 + D1.digit + 1 AS n
FROM         dbo.Digits AS D1
  CROSS JOIN dbo.Digits AS D2
  CROSS JOIN dbo.Digits AS D3
ORDER BY n;

---------------------------------------------------------------------
-- INNER Joins
---------------------------------------------------------------------

-- SQL-92
USE TSQLV4;

SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
  INNER JOIN Sales.Orders AS O
    ON E.empid = O.empid;

-- SQL-89
SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E, Sales.Orders AS O
WHERE E.empid = O.empid;
GO

-- Inner Join Safety
/*
SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
  INNER JOIN Sales.Orders AS O;
GO
*/

SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E, Sales.Orders AS O;
GO

---------------------------------------------------------------------
-- More Join Examples
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Composite Joins
---------------------------------------------------------------------

-- Audit table for updates against OrderDetails
USE TSQLV4;

DROP TABLE IF EXISTS Sales.OrderDetailsAudit;

CREATE TABLE Sales.OrderDetailsAudit
(
  lsn        INT NOT NULL IDENTITY,
  orderid    INT NOT NULL,
  productid  INT NOT NULL,
  dt         DATETIME NOT NULL,
  loginname  sysname NOT NULL,
  columnname sysname NOT NULL,
  oldval     SQL_VARIANT,
  newval     SQL_VARIANT,
  CONSTRAINT PK_OrderDetailsAudit PRIMARY KEY(lsn),
  CONSTRAINT FK_OrderDetailsAudit_OrderDetails
    FOREIGN KEY(orderid, productid)
    REFERENCES Sales.OrderDetails(orderid, productid)
);

SELECT OD.orderid, OD.productid, OD.qty,
  ODA.dt, ODA.loginname, ODA.oldval, ODA.newval
FROM Sales.OrderDetails AS OD
  INNER JOIN Sales.OrderDetailsAudit AS ODA
    ON OD.orderid = ODA.orderid
    AND OD.productid = ODA.productid
WHERE ODA.columnname = N'qty';

---------------------------------------------------------------------
-- Non-Equi Joins
---------------------------------------------------------------------

-- Unique pairs of employees
SELECT
  E1.empid, E1.firstname, E1.lastname,
  E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
  INNER JOIN HR.Employees AS E2
    ON E1.empid < E2.empid;

---------------------------------------------------------------------
-- Multi-Join Queries
---------------------------------------------------------------------

SELECT
  C.custid, C.companyname, O.orderid,
  OD.productid, OD.qty
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid;

---------------------------------------------------------------------
-- Fundamentals of Outer Joins 
---------------------------------------------------------------------

-- Customers and their orders, including customers with no orders
SELECT C.custid, C.companyname, O.orderid
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid;

-- Customers with no orders
SELECT C.custid, C.companyname
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.orderid IS NULL;

---------------------------------------------------------------------
-- SQL Graph
---------------------------------------------------------------------

-- Cleanup
SET NOCOUNT ON;
USE tempdb;

DROP TABLE IF EXISTS dbo.AppsJobs, dbo.Applicants, dbo.Jobs;
GO

-- Set X, e.g., Applicants
CREATE TABLE dbo.Applicants
(
  applicantid VARCHAR(10) NOT NULL CONSTRAINT PK_Applicants PRIMARY KEY,
  applicantname VARCHAR(20) NOT NULL
) AS NODE;

INSERT INTO dbo.Applicants(applicantid, applicantname) VALUES
  ('A', 'Applicant A'),
  ('B', 'Applicant B'),
  ('C', 'Applicant C'),
  ('D', 'Applicant D');

SELECT $node_id, applicantid, applicantname FROM dbo.Applicants;

-- Set Y, e.g., Jobs
CREATE TABLE dbo.Jobs
(
  jobid INT NOT NULL CONSTRAINT PK_Jobs PRIMARY KEY,
  jobdesc VARCHAR(20) NOT NULL
) AS NODE;

INSERT INTO dbo.Jobs(jobid, jobdesc) VALUES
  (1, 'Job 1'),
  (2, 'Job 2'),
  (3, 'Job 3'),
  (4, 'Job 4');

SELECT $node_id, jobid, jobdesc FROM dbo.Jobs;

-- Graph G = (X, Y, E), e.g., possible applicant-job connections
CREATE TABLE dbo.AppsJobs AS EDGE; -- can have properties like weight

INSERT INTO dbo.AppsJobs($from_id, $to_id)
  SELECT X.$node_id, Y.$node_id
  FROM ( VALUES('A', 1),
               ('A', 2),
               ('B', 1),
               ('B', 3),
               ('C', 3),
               ('C', 4),
               ('D', 3) ) AS XY(applicantid, jobid)
    INNER JOIN dbo.Applicants AS X
      ON XY.applicantid = X.applicantid
    INNER JOIN dbo.Jobs AS Y
      ON XY.jobid = Y.jobid;

SELECT $edge_id, $from_id, $to_id
FROM dbo.AppsJobs;

-- All applicant-to-job relationships
SELECT applicantid, applicantname, jobid, jobdesc
FROM dbo.Applicants AS App, dbo.AppsJobs AS [Qualified For], dbo.Jobs AS Job
WHERE MATCH(App-([Qualified For])->Job);

-- Current functionality can be achieved with junction table and basic joins
SELECT applicantid, applicantname, jobid, jobdesc
FROM dbo.Applicants AS A
  INNER JOIN dbo.AppsJobs AS AJ
    ON A.$node_id = AJ.$from_id
  INNER JOIN dbo.Jobs AS J
    ON AJ.$to_id = J.$node_id;
GO

---------------------------------------------------------------------
-- Beyond the Fundamentals of Outer Joins
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Including Missing Values
---------------------------------------------------------------------

SELECT DATEADD(day, n-1, CAST('20140101' AS DATE)) AS orderdate
FROM dbo.Nums
WHERE n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate;

SELECT DATEADD(day, Nums.n - 1, CAST('20140101' AS DATE)) AS orderdate,
  O.orderid, O.custid, O.empid
FROM dbo.Nums
  LEFT OUTER JOIN Sales.Orders AS O
    ON DATEADD(day, Nums.n - 1, CAST('20140101' AS DATE)) = O.orderdate
WHERE Nums.n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate;

---------------------------------------------------------------------
-- Filtering Attributes from Non-Preserved Side of Outer Join
---------------------------------------------------------------------

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.orderdate >= '20160101';

---------------------------------------------------------------------
-- Using Outer Joins in a Multi-Join Query
---------------------------------------------------------------------

SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid;

-- Option 1: use outer join all along
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
  LEFT OUTER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid;

-- Option 2: change join order
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
  RIGHT OUTER JOIN Sales.Customers AS C
     ON O.custid = C.custid;

-- Option 3: use parentheses
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
  LEFT OUTER JOIN
      (Sales.Orders AS O
         INNER JOIN Sales.OrderDetails AS OD
           ON O.orderid = OD.orderid)
    ON C.custid = O.custid;

---------------------------------------------------------------------
-- Using the COUNT Aggregate with Outer Joins
---------------------------------------------------------------------

SELECT C.custid, COUNT(*) AS numorders
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
GROUP BY C.custid;

SELECT C.custid, COUNT(O.orderid) AS numorders
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
GROUP BY C.custid;

---------------------------------------------------------------------
-- Self-Contained Subqueries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Scalar Subqueries
---------------------------------------------------------------------

-- Order with the maximum order ID
USE TSQLV4;

DECLARE @maxid AS INT = (SELECT MAX(orderid)
                         FROM Sales.Orders);

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = @maxid;
GO

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = (SELECT MAX(O.orderid)
                 FROM Sales.Orders AS O);

-- Scalar subquery expected to return one value
SELECT orderid
FROM Sales.Orders
WHERE empid = 
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'C%');
GO

SELECT orderid
FROM Sales.Orders
WHERE empid = 
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'D%');
GO

SELECT orderid
FROM Sales.Orders
WHERE empid = 
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'A%');

---------------------------------------------------------------------
-- Multi-Valued Subqueries
---------------------------------------------------------------------

SELECT orderid
FROM Sales.Orders
WHERE empid IN
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'D%');

SELECT O.orderid
FROM HR.Employees AS E
  INNER JOIN Sales.Orders AS O
    ON E.empid = O.empid
WHERE E.lastname LIKE N'D%';

-- Orders placed by US customers
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN
  (SELECT C.custid
   FROM Sales.Customers AS C
   WHERE C.country = N'USA');

-- Customers who placed no orders
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN
  (SELECT O.custid
   FROM Sales.Orders AS O);

-- Missing order IDs
USE TSQLV4;
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders(orderid INT NOT NULL CONSTRAINT PK_Orders PRIMARY KEY);

INSERT INTO dbo.Orders(orderid)
  SELECT orderid
  FROM Sales.Orders
  WHERE orderid % 2 = 0;

SELECT n
FROM dbo.Nums
WHERE n BETWEEN (SELECT MIN(O.orderid) FROM dbo.Orders AS O)
            AND (SELECT MAX(O.orderid) FROM dbo.Orders AS O)
  AND n NOT IN (SELECT O.orderid FROM dbo.Orders AS O);

-- CLeanup
DROP TABLE IF EXISTS dbo.Orders;

---------------------------------------------------------------------
-- Correlated Subqueries
---------------------------------------------------------------------

-- Orders with maximum order ID for each customer
-- Correlated Subquery
USE TSQLV4;

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE orderid =
  (SELECT MAX(O2.orderid)
   FROM Sales.Orders AS O2
   WHERE O2.custid = O1.custid);

SELECT MAX(O2.orderid)
FROM Sales.Orders AS O2
WHERE O2.custid = 85;

-- Percentage of customer total
SELECT orderid, custid, val,
  CAST(100. * val / (SELECT SUM(O2.val)
                     FROM Sales.OrderValues AS O2
                     WHERE O2.custid = O1.custid)
       AS NUMERIC(5,2)) AS pct
FROM Sales.OrderValues AS O1
ORDER BY custid, orderid;

---------------------------------------------------------------------
-- EXISTS
---------------------------------------------------------------------

-- Customers from Spain who placed orders
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
  AND EXISTS
    (SELECT * FROM Sales.Orders AS O
     WHERE O.custid = C.custid);

-- Customers from Spain who didn't place Orders
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
  AND NOT EXISTS
    (SELECT * FROM Sales.Orders AS O
     WHERE O.custid = C.custid);

---------------------------------------------------------------------
-- Beyond the Fundamentals of Subqueries
-- (Optional, Advanced)
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Returning "Previous" or "Next" Value
---------------------------------------------------------------------
SELECT orderid, orderdate, empid, custid,
  (SELECT MAX(O2.orderid)
   FROM Sales.Orders AS O2
   WHERE O2.orderid < O1.orderid) AS prevorderid
FROM Sales.Orders AS O1;

SELECT orderid, orderdate, empid, custid,
  (SELECT MIN(O2.orderid)
   FROM Sales.Orders AS O2
   WHERE O2.orderid > O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;

---------------------------------------------------------------------
-- Running Aggregates
---------------------------------------------------------------------

SELECT orderyear, qty
FROM Sales.OrderTotalsByYear;

SELECT orderyear, qty,
  (SELECT SUM(O2.qty)
   FROM Sales.OrderTotalsByYear AS O2
   WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM Sales.OrderTotalsByYear AS O1
ORDER BY orderyear;

---------------------------------------------------------------------
-- Misbehaving Subqueries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- NULL Trouble
---------------------------------------------------------------------

-- Customers who didn't place orders

-- Using NOT IN
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
                    FROM Sales.Orders AS O);

-- Add a row to the Orders table with a NULL custid
INSERT INTO Sales.Orders
  (custid, empid, orderdate, requireddate, shippeddate, shipperid,
   freight, shipname, shipaddress, shipcity, shipregion,
   shippostalcode, shipcountry)
  VALUES(NULL, 1, '20160212', '20160212',
         '20160212', 1, 123.00, N'abc', N'abc', N'abc',
         N'abc', N'abc', N'abc');

-- Following returns an empty set
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
                    FROM Sales.Orders AS O);

-- Exclude NULLs explicitly
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid 
                    FROM Sales.Orders AS O
                    WHERE O.custid IS NOT NULL);

-- Using NOT EXISTS
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
  (SELECT * 
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid);

-- Cleanup
DELETE FROM Sales.Orders WHERE custid IS NULL;
GO

---------------------------------------------------------------------
-- Substitution Error in a Subquery Column Name
---------------------------------------------------------------------

-- Create and populate table Sales.MyShippers
DROP TABLE IF EXISTS Sales.MyShippers;

CREATE TABLE Sales.MyShippers
(
  shipper_id  INT          NOT NULL,
  companyname NVARCHAR(40) NOT NULL,
  phone       NVARCHAR(24) NOT NULL,
  CONSTRAINT PK_MyShippers PRIMARY KEY(shipper_id)
);

INSERT INTO Sales.MyShippers(shipper_id, companyname, phone)
  VALUES(1, N'Shipper GVSUA', N'(503) 555-0137'),
	      (2, N'Shipper ETYNR', N'(425) 555-0136'),
				(3, N'Shipper ZHISN', N'(415) 555-0138');
GO

-- Shippers who shipped orders to customer 43

-- Bug
SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT shipper_id
   FROM Sales.Orders
   WHERE custid = 43);
GO

-- The safe way using aliases, bug identified
SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT O.shipper_id
   FROM Sales.Orders AS O
   WHERE O.custid = 43);
GO

-- Bug corrected
SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT O.shipperid
   FROM Sales.Orders AS O
   WHERE O.custid = 43);

-- Cleanup
DROP TABLE IF EXISTS Sales.MyShippers;

---------------------------------------------------------------------
-- Table Expressions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Derived Tables
---------------------------------------------------------------------

USE TSQLV4;

SELECT *
FROM (SELECT custid, companyname
      FROM Sales.Customers
      WHERE country = N'USA') AS USACusts;

---------------------------------------------------------------------
-- Assigning Column Aliases
---------------------------------------------------------------------

-- Following fails
/*
SELECT
  YEAR(orderdate) AS orderyear,
  COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY orderyear;
*/
GO

-- Query with a Derived Table using Inline Aliasing Form
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
      FROM Sales.Orders) AS D
GROUP BY orderyear;

SELECT YEAR(orderdate) AS orderyear, COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY YEAR(orderdate);

-- External column aliasing
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate), custid
      FROM Sales.Orders) AS D(orderyear, custid)
GROUP BY orderyear;
GO

---------------------------------------------------------------------
-- Using Arguments
---------------------------------------------------------------------

-- Yearly Count of Customers handled by Employee 3
DECLARE @empid AS INT = 3;

SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
      FROM Sales.Orders
      WHERE empid = @empid) AS D
GROUP BY orderyear;
GO

---------------------------------------------------------------------
-- Nesting
---------------------------------------------------------------------

-- Query with Nested Derived Tables
SELECT orderyear, numcusts
FROM (SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
      FROM (SELECT YEAR(orderdate) AS orderyear, custid
            FROM Sales.Orders) AS D1
      GROUP BY orderyear) AS D2
WHERE numcusts > 70;

SELECT YEAR(orderdate) AS orderyear, COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY YEAR(orderdate)
HAVING COUNT(DISTINCT custid) > 70;

---------------------------------------------------------------------
-- Multiple References
---------------------------------------------------------------------

-- Multiple Derived Tables Based on the Same Query
SELECT Cur.orderyear, 
  Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
  Cur.numcusts - Prv.numcusts AS growth
FROM (SELECT YEAR(orderdate) AS orderyear,
        COUNT(DISTINCT custid) AS numcusts
      FROM Sales.Orders
      GROUP BY YEAR(orderdate)) AS Cur
  LEFT OUTER JOIN
     (SELECT YEAR(orderdate) AS orderyear,
        COUNT(DISTINCT custid) AS numcusts
      FROM Sales.Orders
      GROUP BY YEAR(orderdate)) AS Prv
    ON Cur.orderyear = Prv.orderyear + 1;

---------------------------------------------------------------------
-- Common Table Expressions
---------------------------------------------------------------------

WITH USACusts AS
(
  SELECT custid, companyname
  FROM Sales.Customers
  WHERE country = N'USA'
)
SELECT * FROM USACusts;

---------------------------------------------------------------------
-- Assigning Column Aliases
---------------------------------------------------------------------

-- Inline column aliasing
WITH C AS
(
  SELECT YEAR(orderdate) AS orderyear, custid
  FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

-- External column aliasing
WITH C(orderyear, custid) AS
(
  SELECT YEAR(orderdate), custid
  FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;
GO

---------------------------------------------------------------------
-- Using Arguments
---------------------------------------------------------------------

DECLARE @empid AS INT = 3;

WITH C AS
(
  SELECT YEAR(orderdate) AS orderyear, custid
  FROM Sales.Orders
  WHERE empid = @empid
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;
GO

---------------------------------------------------------------------
-- Defining Multiple CTEs
---------------------------------------------------------------------

WITH C1 AS
(
  SELECT YEAR(orderdate) AS orderyear, custid
  FROM Sales.Orders
),
C2 AS
(
  SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
  FROM C1
  GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70;

---------------------------------------------------------------------
-- Multiple References
---------------------------------------------------------------------

WITH YearlyCount AS
(
  SELECT YEAR(orderdate) AS orderyear,
    COUNT(DISTINCT custid) AS numcusts
  FROM Sales.Orders
  GROUP BY YEAR(orderdate)
)
SELECT Cur.orderyear, 
  Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
  Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
  LEFT OUTER JOIN YearlyCount AS Prv
    ON Cur.orderyear = Prv.orderyear + 1;

---------------------------------------------------------------------
-- Recursive CTEs (Optional, Advanced)
---------------------------------------------------------------------

WITH EmpsCTE AS
(
  SELECT empid, mgrid, firstname, lastname
  FROM HR.Employees
  WHERE empid = 2
  
  UNION ALL
  
  SELECT C.empid, C.mgrid, C.firstname, C.lastname
  FROM EmpsCTE AS P
    INNER JOIN HR.Employees AS C
      ON C.mgrid = P.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;

---------------------------------------------------------------------
-- Views
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Views Described
---------------------------------------------------------------------

-- Creating USACusts View
DROP VIEW IF EXISTS Sales.USACusts;
GO
CREATE VIEW Sales.USACusts
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

SELECT custid, companyname
FROM Sales.USACusts;
GO

---------------------------------------------------------------------
-- Views and ORDER BY
---------------------------------------------------------------------

-- ORDER BY in a View is not Allowed
/*
ALTER VIEW Sales.USACusts
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO
*/

-- Instead, use ORDER BY in Outer Query
SELECT custid, companyname, region
FROM Sales.USACusts
ORDER BY region;
GO

-- Do not Rely on TOP 
ALTER VIEW Sales.USACusts
AS

SELECT TOP (100) PERCENT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO

-- Query USACusts
SELECT custid, companyname, region
FROM Sales.USACusts;
GO

-- DO NOT rely on OFFSET-FETCH, even if for now the engine does return rows in rder
ALTER VIEW Sales.USACusts
AS

SELECT 
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region
OFFSET 0 ROWS;
GO

-- Query USACusts
SELECT custid, companyname, region
FROM Sales.USACusts;
GO

---------------------------------------------------------------------
-- View Options
---------------------------------------------------------------------

---------------------------------------------------------------------
-- ENCRYPTION
---------------------------------------------------------------------

ALTER VIEW Sales.USACusts
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));
GO

ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

EXEC sp_helptext 'Sales.USACusts';
GO

---------------------------------------------------------------------
-- SCHEMABINDING
---------------------------------------------------------------------

ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

-- Try a schema change
/*
ALTER TABLE Sales.Customers DROP COLUMN address;
*/
GO

---------------------------------------------------------------------
-- CHECK OPTION
---------------------------------------------------------------------

-- Notice that you can insert a row through the view
INSERT INTO Sales.USACusts(
  companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax)
 VALUES(
  N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE',
  N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');

-- But when you query the view, you won't see it
SELECT custid, companyname, country
FROM Sales.USACusts
WHERE companyname = N'Customer ABCDE';

-- You can see it in the table, though
SELECT custid, companyname, country
FROM Sales.Customers
WHERE companyname = N'Customer ABCDE';
GO

-- Add CHECK OPTION to the View
ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
WITH CHECK OPTION;
GO

-- Notice that you can't insert a row through the view
/*
INSERT INTO Sales.USACusts(
  companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax)
 VALUES(
  N'Customer FGHIJ', N'Contact FGHIJ', N'Title FGHIJ', N'Address FGHIJ',
  N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');
*/
GO

-- Cleanup
DELETE FROM Sales.Customers
WHERE custid > 91;

DROP VIEW IF EXISTS Sales.USACusts;
GO

---------------------------------------------------------------------
-- Inline User Defined Functions
---------------------------------------------------------------------

-- Creating GetCustOrders function
USE TSQLV4;
DROP FUNCTION IF EXISTS dbo.GetCustOrders;
GO
CREATE FUNCTION dbo.GetCustOrders
  (@cid AS INT) RETURNS TABLE
AS
RETURN
  SELECT orderid, custid, empid, orderdate, requireddate,
    shippeddate, shipperid, freight, shipname, shipaddress, shipcity,
    shipregion, shippostalcode, shipcountry
  FROM Sales.Orders
  WHERE custid = @cid;
GO

-- Test Function
SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS O;

SELECT O.orderid, O.custid, OD.productid, OD.qty
FROM dbo.GetCustOrders(1) AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid;
GO

-- Cleanup
DROP FUNCTION IF EXISTS dbo.GetCustOrders;
GO

---------------------------------------------------------------------
-- APPLY
---------------------------------------------------------------------

SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
  CROSS JOIN HR.Employees AS E;

SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
  CROSS APPLY HR.Employees AS E;

-- 3 most recent orders for each customer
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
  CROSS APPLY
    (SELECT TOP (3) orderid, empid, orderdate, requireddate 
     FROM Sales.Orders AS O
     WHERE O.custid = C.custid
     ORDER BY orderdate DESC, orderid DESC) AS A;

-- With OFFSET-FETCH
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
  CROSS APPLY
    (SELECT orderid, empid, orderdate, requireddate 
     FROM Sales.Orders AS O
     WHERE O.custid = C.custid
     ORDER BY orderdate DESC, orderid DESC
     OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY) AS A;

-- 3 most recent orders for each customer, preserve customers
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
  OUTER APPLY
    (SELECT TOP (3) orderid, empid, orderdate, requireddate 
     FROM Sales.Orders AS O
     WHERE O.custid = C.custid
     ORDER BY orderdate DESC, orderid DESC) AS A;

-- Creation Script for the Function TopOrders
DROP FUNCTION IF EXISTS dbo.TopOrders;
GO
CREATE FUNCTION dbo.TopOrders
  (@custid AS INT, @n AS INT)
  RETURNS TABLE
AS
RETURN
  SELECT TOP (@n) orderid, empid, orderdate, requireddate 
  FROM Sales.Orders
  WHERE custid = @custid
  ORDER BY orderdate DESC, orderid DESC;
GO

SELECT
  C.custid, C.companyname,
  A.orderid, A.empid, A.orderdate, A.requireddate 
FROM Sales.Customers AS C
  CROSS APPLY dbo.TopOrders(C.custid, 3) AS A;

---------------------------------------------------------------------
-- Set Operators
---------------------------------------------------------------------

SET NOCOUNT ON
USE TSQLV4;

---------------------------------------------------------------------
-- The UNION Operator
---------------------------------------------------------------------

-- The UNION ALL Multiset Operator
SELECT country, region, city FROM HR.Employees
UNION ALL
SELECT country, region, city FROM Sales.Customers;

-- The UNION Distinct Set Operator
SELECT country, region, city FROM HR.Employees
UNION
SELECT country, region, city FROM Sales.Customers;

---------------------------------------------------------------------
-- The INTERSECT Operator
---------------------------------------------------------------------

-- The INTERSECT Distinct Set Operator
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- The INTERSECT ALL Multiset Operator (Optional, Advanced)
SELECT
  ROW_NUMBER() 
    OVER(PARTITION BY country, region, city
         ORDER     BY (SELECT 0)) AS rownum,
  country, region, city
FROM HR.Employees

INTERSECT

SELECT
  ROW_NUMBER() 
    OVER(PARTITION BY country, region, city
         ORDER     BY (SELECT 0)),
  country, region, city
FROM Sales.Customers;

WITH INTERSECT_ALL
AS
(
  SELECT
    ROW_NUMBER() 
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)) AS rownum,
    country, region, city
  FROM HR.Employees

  INTERSECT

  SELECT
    ROW_NUMBER() 
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)),
    country, region, city
  FROM Sales.Customers
)
SELECT country, region, city
FROM INTERSECT_ALL;

---------------------------------------------------------------------
-- The EXCEPT Operator
---------------------------------------------------------------------

-- The EXCEPT Distinct Set Operator

-- Employees EXCEPT Customers
SELECT country, region, city FROM HR.Employees
EXCEPT
SELECT country, region, city FROM Sales.Customers;

-- Customers EXCEPT Employees
SELECT country, region, city FROM Sales.Customers
EXCEPT
SELECT country, region, city FROM HR.Employees;

-- The EXCEPT ALL Multiset Operator (Optional, Advanced)
WITH EXCEPT_ALL
AS
(
  SELECT
    ROW_NUMBER() 
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)) AS rownum,
    country, region, city
  FROM HR.Employees

  EXCEPT

  SELECT
    ROW_NUMBER() 
      OVER(PARTITION BY country, region, city
           ORDER     BY (SELECT 0)),
    country, region, city
  FROM Sales.Customers
)
SELECT country, region, city
FROM EXCEPT_ALL;

---------------------------------------------------------------------
-- Precedence
---------------------------------------------------------------------

-- INTERSECT Precedes EXCEPT
SELECT country, region, city FROM Production.Suppliers
EXCEPT
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- Using Parenthesis
(SELECT country, region, city FROM Production.Suppliers
 EXCEPT
 SELECT country, region, city FROM HR.Employees)
INTERSECT
SELECT country, region, city FROM Sales.Customers;

---------------------------------------------------------------------
-- Circumventing Unsupported Logical Phases
-- (Optional, Advanced)
---------------------------------------------------------------------

-- Number of distinct locations
-- that are either employee or customer locations in each country
SELECT country, COUNT(*) AS numlocations
FROM (SELECT country, region, city FROM HR.Employees
      UNION
      SELECT country, region, city FROM Sales.Customers) AS U
GROUP BY country;

-- Two most recent orders for employees 3 and 5
SELECT empid, orderid, orderdate
FROM (SELECT TOP (2) empid, orderid, orderdate
      FROM Sales.Orders
      WHERE empid = 3
      ORDER BY orderdate DESC, orderid DESC) AS D1

UNION ALL

SELECT empid, orderid, orderdate
FROM (SELECT TOP (2) empid, orderid, orderdate
      FROM Sales.Orders
      WHERE empid = 5
      ORDER BY orderdate DESC, orderid DESC) AS D2;

---------------------------------------------------------------------
-- Recent T-SQL Additions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- DROP IF EXISTS, CREATE OR ALTER
---------------------------------------------------------------------

-- instead of
IF OBJECT_ID(N'dbo.T1', N'U') IS NOT NULL DROP TABLE dbo.T1;
IF OBJECT_ID(N'dbo.T2', N'U') IS NOT NULL DROP TABLE dbo.T2;
-- use
DROP TABLE /* VIEW, FUNCTION, PROC, … */ IF EXISTS dbo.T1, dbo.T2;

-- CREATE OR ALTER
CREATE OR ALTER VIEW dbo.MyView
AS

SELECT 'Isn''t It?' AS [This is great!];
GO

SELECT * FROM dbo.MyView;

---------------------------------------------------------------------
-- TRIM
---------------------------------------------------------------------

DECLARE @str AS VARCHAR(100) = '   abc   ';

-- instead of
SELECT LTRIM(RTRIM(@str));
-- use
SELECT TRIM(@str);

---------------------------------------------------------------------
-- STRING_SPLIT
---------------------------------------------------------------------

USE TSQLV4;
GO

CREATE OR ALTER FUNCTION dbo.GetOrders(@arr AS VARCHAR(8000)) RETURNS TABLE
AS
RETURN
  SELECT O.orderid, O.orderdate, O.custid, O.empid
  FROM Sales.Orders AS O
    INNER JOIN STRING_SPLIT(@arr, ',') AS S
      ON O.orderid = CAST(S.value AS INT);
GO

SELECT orderid, orderdate, custid, empid
FROM dbo.GetOrders('10248,10249,10250') AS O;

---------------------------------------------------------------------
-- STRING_AGG
---------------------------------------------------------------------

SELECT custid,
  STRING_AGG(orderid, ',') WITHIN GROUP(ORDER BY orderdate DESC, orderid DESC) AS custorders
FROM Sales.Orders
GROUP BY custid;

---------------------------------------------------------------------
-- DATEDIFF_BIG
---------------------------------------------------------------------

-- fails
SELECT DATEDIFF(ms, '19710212', '20260212');

-- succeeds
SELECT DATEDIFF_BIG(ms, '19710212', '20260212');

---------------------------------------------------------------------
-- AT TIME ZONE
---------------------------------------------------------------------

-- Get time zone info
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info;

-- Converting non-datetimeoffset values
-- behavior similar to TODATETIMEOFFSET
SELECT
  CAST('20160212 12:00:00.0000000' AS DATETIME2)
    AT TIME ZONE 'Pacific Standard Time' AS val1,
  CAST('20160812 12:00:00.0000000' AS DATETIME2)
    AT TIME ZONE 'Pacific Standard Time' AS val2;

-- Converting datetimeoffset values
-- behavior similar to SWITCHOFFSET
SELECT
  CAST('20160212 12:00:00.0000000 -05:00' AS DATETIMEOFFSET)
    AT TIME ZONE 'Pacific Standard Time' AS val1,
  CAST('20160812 12:00:00.0000000 -04:00' AS DATETIMEOFFSET)
    AT TIME ZONE 'Pacific Standard Time' AS val2;

---------------------------------------------------------------------
-- Temporal Tables
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Creating new temporal tables
---------------------------------------------------------------------

-- Sample database and cleanup
SET NOCOUNT ON;
IF DB_ID(N'TemporalDB') IS NULL CREATE DATABASE TemporalDB;
GO
USE TemporalDB;
GO
IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
BEGIN
  IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Employees', N'U'), N'TableTemporalType') = 2
    ALTER TABLE dbo.Employees SET ( SYSTEM_VERSIONING = OFF );
  IF OBJECT_ID(N'dbo.EmployeesHistory', N'U') IS NOT NULL
    DROP TABLE dbo.EmployeesHistory;
  DROP TABLE dbo.Employees;
END;
GO

-- Creating a new system-versioned temporal table and letting SQL Server create the history table
CREATE TABLE dbo.Employees
(
  empid INT NOT NULL
    CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED,
  mgrid INT NULL
    CONSTRAINT FK_Employees_mgr_emp REFERENCES dbo.Employees,
  empname VARCHAR(25) NOT NULL,
  sysstart DATETIME2(0) GENERATED ALWAYS AS ROW START NOT NULL,
  sysend DATETIME2(0) GENERATED ALWAYS AS ROW END NOT NULL,
  PERIOD FOR SYSTEM_TIME (sysstart, sysend)
)
WITH ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.EmployeesHistory ) );
GO

CREATE UNIQUE CLUSTERED INDEX ix_Employees
  ON dbo.Employees(empid, sysstart, sysend);
GO

-- To make a regular table a system-versioned temporal table use ALTER TABLE (don't run this)
/*
BEGIN TRAN;

-- Add required period columns and designation
ALTER TABLE dbo.Employees ADD
  sysstart DATETIME2(0) GENERATED ALWAYS AS ROW START NOT NULL
    CONSTRAINT DFT_Employees_sysstart DEFAULT('19000101'),
  sysend DATETIME2(0) GENERATED ALWAYS AS ROW END NOT NULL
    CONSTRAINT DFT_Employees_sysend DEFAULT('99991231 23:59:59'),
  PERIOD FOR SYSTEM_TIME (sysstart, sysend);

-- Remove temporary DEFAULT constraints
ALTER TABLE dbo.Employees
  DROP CONSTRAINT DFT_Employees_sysstart, DFT_Employees_sysend;

-- Turn system versioning on
ALTER TABLE dbo.Employees
  SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.EmployeesHistory ) );

COMMIT TRAN;
*/

-- To apply a change that isn't allowed while system-versioning is on (don't run this)
/*
BEGIN TRAN;

-- Turn system versioning off
ALTER TABLE dbo.Employees SET ( SYSTEM_VERSIONING = OFF );

... apply your change here ...

-- Turn system versioning back on
ALTER TABLE dbo.Employees
  SET ( SYSTEM_VERSIONING = ON
        ( HISTORY_TABLE = dbo.EmployeesHistory,
          DATA_CONSISTENCY_CHECK = ON ) );

COMMIT TRAN;
*/

---------------------------------------------------------------------
-- Modifying data
---------------------------------------------------------------------

-- Add rows at T1 (2016-04-26 19:54:04 UTC)
INSERT INTO dbo.Employees(empid, mgrid, empname)
  VALUES(1, NULL, 'David'),
        (2, 1, 'Eitan');

-- Add more rows in an explicit transaction that started at T2 (BEGIN TRAN statement time) (2016-04-26 19:54:20)
BEGIN TRAN;

  PRINT 'Transaction start time: ' + CONVERT(CHAR(19), SYSDATETIME(), 121);

  INSERT INTO dbo.Employees(empid, mgrid, empname)
    VALUES(4, 2, 'Seraph'),
          (5, 2, 'Jiru');
  
  WAITFOR DELAY '00:00:05';

  INSERT INTO dbo.Employees(empid, mgrid, empname)
    VALUES(6, 2, 'Steve');

  PRINT 'Transaction end time: ' + CONVERT(CHAR(19), SYSDATETIME(), 121);

COMMIT TRAN;

-- Add more rows at T3 (2016-04-26 20:01:41)
INSERT INTO dbo.Employees(empid, mgrid, empname)
  VALUES(8, 5, 'Lilach'),
        (10, 5, 'Sean'),
        (3, 1, 'Ina'),
        (7, 3, 'Aaron'),
        (9, 7, 'Rita'),
        (11, 7, 'Gabriel'),
        (12, 9, 'Emilia'),
        (13, 9, 'Michael'),
        (14, 9, 'Didi');

-- Show table contents
SELECT *
FROM dbo.Employees;

-- History table empty at this point
SELECT *
FROM dbo.EmployeesHistory;

-- Make some changes at T4 (2016-04-26 20:11:01)
BEGIN TRAN;

  DELETE FROM dbo.Employees
  WHERE empid IN (13, 14);

  UPDATE dbo.Employees
    SET mgrid = 3
  WHERE empid IN(9, 11);

COMMIT TRAN;

-- Make some more changes at T5 (2016-04-26 21:32:20)
BEGIN TRAN;

  UPDATE dbo.Employees
    SET mgrid = 4
  WHERE empid IN(7, 9);

  UPDATE dbo.Employees
    SET mgrid = 3
  WHERE empid = 6;

  UPDATE dbo.Employees
    SET mgrid = 6
  WHERE empid = 11;

  DELETE FROM dbo.Employees
  WHERE empid = 12;

COMMIT TRAN;

-- Show current table contents
SELECT *
FROM dbo.Employees;

-- Show history table contents
SELECT *
FROM dbo.EmployeesHistory;

---------------------------------------------------------------------
-- Create sample data to be consistent with examples in module
---------------------------------------------------------------------

-- Create TemporalDB database and drop tables if exist
SET NOCOUNT ON;
IF DB_ID(N'TemporalDB') IS NULL CREATE DATABASE TemporalDB;
GO
USE TemporalDB;
GO
IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
BEGIN
  IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Employees', N'U'), N'TableTemporalType') = 2
    ALTER TABLE dbo.Employees SET ( SYSTEM_VERSIONING = OFF );
  IF OBJECT_ID(N'dbo.EmployeesHistory', N'U') IS NOT NULL
    DROP TABLE dbo.EmployeesHistory;
  DROP TABLE dbo.Employees;
END;
GO

-- Create and populate Employees table
CREATE TABLE dbo.Employees
(
  empid INT NOT NULL
    CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED,
  mgrid INT NULL
    CONSTRAINT FK_Employees_mgr_emp REFERENCES dbo.Employees,
  empname VARCHAR(25) NOT NULL,
  sysstart DATETIME2(0) NOT NULL,
  sysend DATETIME2(0) NOT NULL
);

CREATE UNIQUE CLUSTERED INDEX ix_Employees
  ON dbo.Employees(empid, sysstart, sysend);

INSERT INTO dbo.Employees(empid, mgrid, empname, sysstart, sysend) VALUES
  (1 , NULL, 'David'  , '2016-04-26 19:54:04', '9999-12-31 23:59:59'),
  (2 , 1   , 'Eitan'  , '2016-04-26 19:54:04', '9999-12-31 23:59:59'),
  (3 , 1   , 'Ina'    , '2016-04-26 20:01:41', '9999-12-31 23:59:59'),
  (4 , 2   , 'Seraph' , '2016-04-26 19:54:20', '9999-12-31 23:59:59'),
  (5 , 2   , 'Jiru'   , '2016-04-26 19:54:20', '9999-12-31 23:59:59'),
  (6 , 3   , 'Steve'  , '2016-04-26 21:32:20', '9999-12-31 23:59:59'),
  (7 , 4   , 'Aaron'  , '2016-04-26 21:32:20', '9999-12-31 23:59:59'),
  (8 , 5   , 'Lilach' , '2016-04-26 20:01:41', '9999-12-31 23:59:59'),
  (9 , 4   , 'Rita'   , '2016-04-26 21:32:20', '9999-12-31 23:59:59'),
  (10, 5   , 'Sean'   , '2016-04-26 20:01:41', '9999-12-31 23:59:59'),
  (11, 6   , 'Gabriel', '2016-04-26 21:32:20', '9999-12-31 23:59:59');

-- Create and populate EmployeesHistory table
CREATE TABLE dbo.EmployeesHistory
(
  empid INT NOT NULL,
  mgrid INT NULL,
  empname VARCHAR(25) NOT NULL,
  sysstart DATETIME2(0) NOT NULL,
  sysend DATETIME2(0) NOT NULL
);

CREATE CLUSTERED INDEX ix_EmployeesHistory
  ON dbo.EmployeesHistory(sysend, sysstart)
  WITH (DATA_COMPRESSION = PAGE);

INSERT INTO dbo.EmployeesHistory(empid, mgrid, empname, sysstart, sysend) VALUES
(6 , 2, 'Steve'  , '2016-04-26 19:54:20', '2016-04-26 21:32:20'),
(7 , 3, 'Aaron'  , '2016-04-26 20:01:41', '2016-04-26 21:32:20'),
(9 , 7, 'Rita'   , '2016-04-26 20:01:41', '2016-04-26 20:11:01'),
(9 , 3, 'Rita'   , '2016-04-26 20:11:01', '2016-04-26 21:32:20'),
(11, 7, 'Gabriel', '2016-04-26 20:01:41', '2016-04-26 20:11:01'),
(11, 3, 'Gabriel', '2016-04-26 20:11:01', '2016-04-26 21:32:20'),
(12, 9, 'Emilia' , '2016-04-26 20:01:41', '2016-04-26 21:32:20'),
(13, 9, 'Michael', '2016-04-26 20:01:41', '2016-04-26 20:11:01'),
(14, 9, 'Didi'   , '2016-04-26 20:01:41', '2016-04-26 20:11:01');

-- Enable system versioning
ALTER TABLE dbo.Employees ADD
  PERIOD FOR SYSTEM_TIME (sysstart, sysend);

ALTER TABLE dbo.Employees
  SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.EmployeesHistory ) );
GO

---------------------------------------------------------------------
-- Querying Data
---------------------------------------------------------------------

-- Without the FOR SYSTEM_TIME clause, queries against the current table
-- are accessed and optimized as usual and history table is ignored
SELECT *
FROM dbo.Employees;

-- Query with FOR SYSTEM_TIME AS OF @datetime
-- sysstart <= @datetime AND sysend > @datetime
DECLARE @datetime AS DATETIME2(0) = '2016-04-26 20:11:01';

SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF @datetime;

-- Equivalent to using the following query
SELECT *
FROM dbo.Employees
WHERE sysstart <= @datetime
  AND sysend > @datetime
  
UNION ALL

SELECT *
FROM dbo.EmployeesHistory
WHERE sysstart <= @datetime
  AND sysend > @datetime;
GO

-- FOR SYSTEM_TIME FROM @start TO @end 
-- sysstart < @end AND sysend > @start
-- Validity interval starts before input interval ends and ends after input interval starts

SELECT *
FROM dbo.Employees
  FOR SYSTEM_TIME FROM '2016-04-26 20:00:00' TO '2016-04-26 20:01:41';

SELECT *
FROM dbo.Employees
  FOR SYSTEM_TIME BETWEEN '2016-04-26 20:00:00' AND '2016-04-26 20:01:41';

-- FOR SYSTEM_TIME CONTAINED IN(@start, @end)
-- sysstart >= @start AND sysend <= @end
-- Validity interval starts on or after input interval starts and ends on or before input interval ends

SELECT *
FROM dbo.Employees
  FOR SYSTEM_TIME CONTAINED IN('2016-04-26 20:00:00', '2016-04-26 20:20:00');

-- To get all versions
SELECT *
FROM dbo.Employees FOR SYSTEM_TIME ALL;

---------------------------------------------------------------------
-- Beyond the Fundamentals(as time permits)
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Window Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Window Functions, Described
---------------------------------------------------------------------

USE TSQLV4;

SELECT empid, ordermonth, val,
  SUM(val) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

---------------------------------------------------------------------
-- Ranking Window Functions
---------------------------------------------------------------------

SELECT orderid, custid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  RANK()       OVER(ORDER BY val) AS rank,
  DENSE_RANK() OVER(ORDER BY val) AS dense_rank,
  NTILE(10)    OVER(ORDER BY val) AS ntile
FROM Sales.OrderValues
ORDER BY val;

SELECT orderid, custid, val,
  ROW_NUMBER() OVER(PARTITION BY custid
                    ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;

SELECT DISTINCT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues;

SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;

---------------------------------------------------------------------
-- Offset Window Functions
---------------------------------------------------------------------

-- LAG and LEAD
SELECT custid, orderid, val,
  LAG(val)  OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS prevval,
  LEAD(val) OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

-- FIRST_VALUE and LAST_VALUE
SELECT custid, orderid, val,
  FIRST_VALUE(val) OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN UNBOUNDED PRECEDING
                                 AND CURRENT ROW) AS firstval,
  LAST_VALUE(val)  OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN CURRENT ROW
                                 AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

---------------------------------------------------------------------
-- Aggregate Window Functions
---------------------------------------------------------------------

SELECT orderid, custid, val,
  SUM(val) OVER() AS totalvalue,
  SUM(val) OVER(PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;

SELECT orderid, custid, val,
  100. * val / SUM(val) OVER() AS pctall,
  100. * val / SUM(val) OVER(PARTITION BY custid) AS pctcust
FROM Sales.OrderValues;

SELECT empid, ordermonth, val,
  SUM(val) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

---------------------------------------------------------------------
-- Pivoting Data
---------------------------------------------------------------------

-- Code to Create and Populate the Orders Table
USE TSQLV4;

DROP TABLE IF EXISTS dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
  orderid   INT        NOT NULL,
  orderdate DATE       NOT NULL,
  empid     INT        NOT NULL,
  custid    VARCHAR(5) NOT NULL,
  qty       INT        NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
VALUES
  (30001, '20140802', 3, 'A', 10),
  (10001, '20141224', 2, 'A', 12),
  (10005, '20141224', 1, 'B', 20),
  (40001, '20150109', 2, 'A', 40),
  (10006, '20150118', 1, 'C', 14),
  (20001, '20150212', 2, 'B', 12),
  (40005, '20160212', 3, 'A', 10),
  (20002, '20160216', 1, 'C', 20),
  (30003, '20160418', 2, 'B', 15),
  (30004, '20140418', 3, 'C', 22),
  (30007, '20160907', 3, 'D', 30);

SELECT * FROM dbo.Orders;

-- Query against Orders, grouping by employee and customer
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

---------------------------------------------------------------------
-- Pivoting with a Grouped Query
---------------------------------------------------------------------

-- Query against Orders, grouping by employee, pivoting customers,
-- aggregating sum of quantity
SELECT empid,
  SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
  SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
  SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
  SUM(CASE WHEN custid = 'D' THEN qty END) AS D  
FROM dbo.Orders
GROUP BY empid;

---------------------------------------------------------------------
-- Pivoting with the PIVOT Operator
---------------------------------------------------------------------

-- Logical equivalent of previous query using the native PIVOT operator
SELECT empid, A, B, C, D
FROM (SELECT empid, custid, qty
      FROM dbo.Orders) AS D
  PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

-- Query demonstrating the problem with implicit grouping
SELECT empid, A, B, C, D
FROM dbo.Orders
  PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

-- Logical equivalent of previous query
SELECT empid,
  SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
  SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
  SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
  SUM(CASE WHEN custid = 'D' THEN qty END) AS D  
FROM dbo.Orders
GROUP BY orderid, orderdate, empid;

-- Query against Orders, grouping by customer, pivoting employees,
-- aggregating sum of quantity
SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty
      FROM dbo.Orders) AS D
  PIVOT(SUM(qty) FOR empid IN([1], [2], [3])) AS P;

---------------------------------------------------------------------
-- Unpivoting Data
---------------------------------------------------------------------

-- Code to create and populate the EmpCustOrders table
USE TSQLV4;

DROP TABLE IF EXISTS dbo.EmpCustOrders;

CREATE TABLE dbo.EmpCustOrders
(
  empid INT NOT NULL
    CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
  A VARCHAR(5) NULL,
  B VARCHAR(5) NULL,
  C VARCHAR(5) NULL,
  D VARCHAR(5) NULL
);

INSERT INTO dbo.EmpCustOrders(empid, A, B, C, D)
  SELECT empid, A, B, C, D
  FROM (SELECT empid, custid, qty
        FROM dbo.Orders) AS D
    PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

SELECT * FROM dbo.EmpCustOrders;

---------------------------------------------------------------------
-- Unpivoting with the APPLY Operator
---------------------------------------------------------------------

-- Unpivot Step 1: generate copies
SELECT *
FROM dbo.EmpCustOrders
  CROSS JOIN (VALUES('A'),('B'),('C'),('D')) AS C(custid);

-- Unpivot Step 2: extract elements
/*
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
  CROSS JOIN (VALUES('A', A),('B', B),('C', C),('D', D)) AS C(custid, qty);
*/

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
  CROSS APPLY (VALUES('A', A),('B', B),('C', C),('D', D)) AS C(custid, qty);

-- Unpivot Step 3: eliminate NULLs
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
  CROSS APPLY (VALUES('A', A),('B', B),('C', C),('D', D)) AS C(custid, qty)
WHERE qty IS NOT NULL;

---------------------------------------------------------------------
-- Unpivoting with the UNPIVOT Operator
---------------------------------------------------------------------

-- Query using the native UNPIVOT operator
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
  UNPIVOT(qty FOR custid IN(A, B, C, D)) AS U;
  
---------------------------------------------------------------------
-- Grouping Sets
---------------------------------------------------------------------

-- Four queries, each with a different grouping set
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

SELECT empid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid;

SELECT custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY custid;

SELECT SUM(qty) AS sumqty
FROM dbo.Orders;

-- Unifying result sets of four queries
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid

UNION ALL

SELECT empid, NULL, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid

UNION ALL

SELECT NULL, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY custid

UNION ALL

SELECT NULL, NULL, SUM(qty) AS sumqty
FROM dbo.Orders;

---------------------------------------------------------------------
-- GROUPING SETS Subclause
---------------------------------------------------------------------

-- Using the GROUPING SETS subclause
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY
  GROUPING SETS
  (
    (empid, custid),
    (empid),
    (custid),
    ()
  );

---------------------------------------------------------------------
-- CUBE Subclause
---------------------------------------------------------------------

-- Using the CUBE subclause
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

---------------------------------------------------------------------
-- ROLLUP Subclause
---------------------------------------------------------------------

-- Using the ROLLUP subclause
SELECT 
  YEAR(orderdate) AS orderyear,
  MONTH(orderdate) AS ordermonth,
  DAY(orderdate) AS orderday,
  SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));

---------------------------------------------------------------------
-- GROUPING and GROUPING_ID Function
---------------------------------------------------------------------

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

SELECT
  GROUPING(empid) AS grpemp,
  GROUPING(custid) AS grpcust,
  empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

SELECT
  GROUPING_ID(empid, custid) AS groupingset,
  empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

---------------------------------------------------------------------
-- Recursive CTEs
---------------------------------------------------------------------

WITH EmpsCTE AS
(
  SELECT empid, mgrid, firstname, lastname
  FROM HR.Employees
  WHERE empid = 2
  
  UNION ALL
  
  SELECT C.empid, C.mgrid, C.firstname, C.lastname
  FROM EmpsCTE AS P
    JOIN HR.Employees AS C
      ON C.mgrid = P.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;