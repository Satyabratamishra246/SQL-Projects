# Retail Sales Analysis using SQL

![Retail-Thumbnail](https://github.com/Satyabratamishra246/SQL-Projects/blob/715b9e457db65614b3f2c51dbfc6b86a3607a5d3/retail-sales-analysis/Retail-Thumbnail.png)

### Project Overview



### Objective


### Analysis

#### Understanding available data

```sql
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

```

Results:

transactions_id sale_date  sale_time        customer_id gender                                             age         category                                           quantiy     price_per_unit                          cogs                                    total_sale
--------------- ---------- ---------------- ----------- -------------------------------------------------- ----------- -------------------------------------------------- ----------- --------------------------------------- --------------------------------------- ---------------------------------------
1               2022-12-16 19:10:00.0000000 50          Male                                               34          Beauty                                             3           50.00                                   16.00                                   150.00
2               2022-06-24 10:07:00.0000000 104         Female                                             26          Clothing                                           2           500.00                                  135.00                                  1000.00
3               2022-06-14 07:08:00.0000000 114         Male                                               50          Electronics                                        1           30.00                                   8.10                                    30.00
4               2023-08-27 18:12:00.0000000 3           Male                                               37          Clothing                                           1           500.00                                  200.00                                  500.00
5               2023-09-05 22:10:00.0000000 3           Male                                               30          Beauty                                             2           50.00                                   24.00                                   100.00

total_null_rows
---------------
13

Deleted Successfully

(13 rows affected)

Total_Transactions
------------------
1987


Data_available_from Data_available_till
------------------- -------------------
2022-01-01          2023-12-31


Open_from        open_till
---------------- ----------------
06:01:00.0000000 23:00:00.0000000


Unique_Customers
----------------
155


Unique_genders
--------------------------------------------------
Male
Female


age_from    age_till
----------- -----------
18          64


min_quantity max_quantity
------------ ------------
1            4


min_price                               max_price
--------------------------------------- ---------------------------------------
25.00                                   500.00


min_cogs                                max_cogs
--------------------------------------- ---------------------------------------
6.25                                    620.00


min_sales                               max_sales
--------------------------------------- ---------------------------------------
25.00                                   2000.00


Unique_Categories
--------------------------------------------------
Beauty
Electronics
Clothing


#### Detailed Analysis



### Findings



### Reports


### Conclusion



### Author - Satyabrata Mishra

#### Connect with Me

<a href="https://www.linkedin.com/in/satyabrata-mishra246/" aria-label="LinkedIn">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/205f904846099c1c36a9b978d92e1d50cecc5e8c/images/linkedin-icon.png" alt="LinkedIn Icon" width="40" style="margin-right: 10px;">
</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://github.com/Satyabratamishra246" aria-label="GitHub">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/127c2319131cc8652f9666af9b926fd67fc15122/images/github-icon-white-bg.png" alt="GitHub Icon" width="40" style="margin-right: 10px;">
</a>