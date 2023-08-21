---Cleaning Data

---Total Records = 541909
---135080 Records have NULL CustomerID
---406829 Records have CustomerID

WITH online_retail AS 
	(SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [Online_Retail].[dbo].[online_retail]
	  WHERE CustomerID IS NOT NULL),

---397884 Records with Quanitity and Unit Price
quantity_unit_price AS
	(SELECT *
	FROM online_retail
	WHERE Quantity > 0 AND UnitPrice > 0),

---Duplicate Check
dup_check AS
	(SELECT *, ROW_NUMBER()OVER(PARTITION BY InvoiceNO, StockCode, Quantity
								ORDER BY InvoiceDate ASC) AS dup_flag
	FROM quantity_unit_price)

---392669 Clean Data
---5215 Duplicate Records 
SELECT * 
INTO #online_retail_main
FROM dup_check
WHERE dup_flag = 1;

---Clean Data
---BEGIN COHORT ANALYSIS
SELECT *
FROM #online_retail_main;

---Unique Identifier(CustomerID)
---Initial Start Date(First Invoice Date)
---Revenue Data

SELECT CustomerID, 
	MIN(InvoiceDate) AS first_purchase_date, 
	DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)),1) AS cohort_date
INTO #cohort
FROM #online_retail_main
GROUP BY CustomerID;

SELECT *
FROM #cohort;

---Create Cohort Index 
SELECT year_month_diff.*,
	cohort_index = (year_diff * 12) + (month_diff + 1)
INTO #cohort_retention
FROM
	(SELECT invoice_cohort.*,
		year_diff = (invoice_year - cohort_year),
		month_diff = (invoice_month - cohort_month)
	FROM
		(SELECT m.*,
			c.cohort_date,
			YEAR(m.InvoiceDate) AS invoice_year,
			MONTH(m.InvoiceDate) AS invoice_month,
			YEAR(c.cohort_date) AS cohort_year,
			MONTH(c.cohort_date) AS cohort_month
		FROM #online_retail_main AS m
		LEFT JOIN #cohort AS c
		ON m.CustomerID = c.CustomerID) AS invoice_cohort) AS year_month_diff;
---Where CustomerID = 13093

---Save CSV for Tableau
SELECT *
FROM #cohort_retention;

---Pivot Data to see Cohort Table
SELECT *
INTO #cohort_pivot
FROM
	(SELECT DISTINCT(CustomerID),
		cohort_date,
		cohort_index
	FROM #cohort_retention) AS tbl
PIVOT(COUNT(CustomerID) for cohort_index IN 
	([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])) AS pivot_table;

SELECT *
FROM #cohort_pivot
ORDER BY cohort_date

SELECT cohort_date,
	1.0*[1]/[1]*100 AS [1], 
	1.0*[2]/[1]*100 AS [2],
	1.0*[3]/[1]*100 AS [3], 
	1.0*[4]/[1]*100 AS [4],
	1.0*[5]/[1]*100 AS [5], 
	1.0*[6]/[1]*100 AS [6],
	1.0*[7]/[1]*100 AS [7], 
	1.0*[8]/[1]*100 AS [8],
	1.0*[9]/[1]*100 AS [9], 
	1.0*[10]/[1]*100 AS [10],
	1.0*[11]/[1]*100 AS [11], 
	1.0*[12]/[1]*100 AS [12],
	1.0*[13]/[1]*100 AS [13]
FROM #cohort_pivot
ORDER BY cohort_date;
