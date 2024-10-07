-- Understanding available data

SELECT TOP 5 * FROM dbo.[Retail Sales];


-- look for null values

SELECT COUNT(*) AS total_null_rows FROM dbo.[Retail Sales]
WHERE 
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantiy IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

-- Since the total null rows count is low we can remove them from our analysis

DELETE FROM dbo.[Retail Sales]
WHERE 
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantiy IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

SELECT COUNT(transactions_id) AS Total_Transactions FROM dbo.[Retail Sales];
SELECT MIN(sale_date) AS  Data_available_from, MAX(sale_date) AS Data_available_till  FROM dbo.[Retail Sales];
SELECT MIN(sale_time) AS  Open_from, MAX(sale_time) AS open_till  FROM dbo.[Retail Sales];
SELECT COUNT(DISTINCT customer_id) AS Unique_Customers FROM dbo.[Retail Sales];
SELECT DISTINCT gender AS Unique_genders FROM dbo.[Retail Sales];
SELECT MIN(age) AS  age_from, MAX(age) AS age_till  FROM dbo.[Retail Sales];
SELECT MIN(quantiy) AS  min_quantity, MAX(quantiy) AS max_quantity  FROM dbo.[Retail Sales];
SELECT MIN(price_per_unit) AS  min_price, MAX(price_per_unit) AS max_price  FROM dbo.[Retail Sales];
SELECT MIN(cogs) AS  min_cogs, MAX(cogs) AS max_cogs FROM dbo.[Retail Sales];
SELECT MIN(total_sale) AS  min_sales, MAX(total_sale) AS max_sales  FROM dbo.[Retail Sales];
SELECT DISTINCT category AS Unique_Categories FROM dbo.[Retail Sales];





