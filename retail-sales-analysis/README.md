# Retail Sales Analysis using SQL

![Retail-Thumbnail](https://github.com/Satyabratamishra246/SQL-Projects/blob/715b9e457db65614b3f2c51dbfc6b86a3607a5d3/retail-sales-analysis/Retail-Thumbnail.png)

### Project Overview

This case study focuses on analyzing retail sales data to gain insights into customer behavior, sales trends, and product performance. The dataset used for this analysis contains transactional data including details such as sale date, sale time, customer demographics, product categories, quantities sold, prices, and costs of goods sold (COGS). The goal is to derive actionable insights that can inform business strategies and decision-making.

### Objective

The primary objectives of this analysis are:

* To understand the overall data and ensure its quality by handling null values
* To explore key business metrics such as Customer Lifetime Value (CLTV), Average Order Value (AOV), and profitability across different product categories
* To analyze sales trends across various time dimensions (hourly, daily, monthly, quarterly, and yearly).
* To identify customer loyalty and repeat purchase rates.
* To rank customers based on their sales contributions across different dimensions such as time periods, age groups, and product categories.

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
#### Business Questions & Analysis


##### Q1. What is the customer lifetime value (CLTV) for each customer?

```sql
SELECT customer_id,
    SUM(total_sale) AS CLTV
FROM dbo.[Retail Sales]
GROUP BY customer_id
ORDER BY CLTV DESC;
```

##### Q2. What is the average order value (AOV) by customer segment?

```sql
SELECT category,
    AVG(total_sale) AS AOV
FROM dbo.[Retail Sales]
GROUP BY category;
```

##### Q3. How does the sales volume fluctuate throughout the day?

```sql
SELECT DATEPART(HOUR, sale_time) AS sale_hour,
    SUM(total_sale) AS total_sales
FROM dbo.[Retail Sales]
GROUP BY DATEPART(HOUR, sale_time)
ORDER BY sale_hour;

-- We can also categorize time of the day into morning, afternoon and evening

WITH cte AS (
    SELECT
        CASE
            WHEN DATEPART(HOUR, sale_time) < 12 THEN 'Morning'
            WHEN DATEPART(HOUR, sale_time) >= 17 THEN 'Evening'
            ELSE 'Afternoon' END AS Shift,
            total_sale
    FROM dbo.[Retail Sales]
)

SELECT shift, SUM(total_sale) AS Total_Sales
FROM cte
GROUP BY Shift
ORDER BY Total_Sales DESC;
```

##### Q4. What are the most and least profitable product categories?
```sql
SELECT category,
    SUM((total_sale - cogs)) AS profit
FROM dbo.[Retail Sales]
GROUP BY category
ORDER BY profit DESC;
```
##### Q5. How does the average sales value per transaction differ across different days of the week in relation to total sales?

```sql
SELECT DATENAME(WEEKDAY, sale_date) AS day_of_week,
    AVG(total_sale) AS Avg_Sales,
    SUM(total_sale) AS Total_Sales
FROM dbo.[Retail Sales]
GROUP BY DATENAME(WEEKDAY, sale_date)
ORDER BY Avg_Sales DESC;
```
##### Q6. What is the repeat purchase rate, and which customer segments show the highest loyalty?

```sql
WITH CustomerPurchaseCounts AS (
    SELECT customer_id, COUNT(transactions_id) AS PurchaseCount, category
    FROM dbo.[Retail Sales]
    GROUP BY customer_id, category
),
TotalCustomers AS (
    SELECT COUNT(DISTINCT customer_id) AS Total_Customers FROM dbo.[Retail Sales]
),
LoyalCustomers AS (
    SELECT category, COUNT(*) AS Loyal_Customers
    FROM CustomerPurchaseCounts
    WHERE PurchaseCount > 1
    GROUP BY category
)
SELECT 
    lc.category,
    lc.Loyal_Customers,
    (lc.Loyal_Customers * 100.0 / (SELECT Total_Customers FROM TotalCustomers)) AS Repeat_Purchase_Rate
FROM LoyalCustomers lc
ORDER BY lc.Loyal_Customers DESC;
```

##### Q7. What is the trend of total sales over time monthly?

```sql
SELECT FORMAT(sale_date, 'yyyy-MM') AS Month, SUM(total_sale) AS Total_Sales
FROM dbo.[Retail Sales]
GROUP BY FORMAT(sale_date, 'yyyy-MM')
ORDER BY [Month];
```
##### Q8. What is the total sales revenue for each customer age group?
```sql
SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        WHEN age > 55 THEN '55+'
    END AS Age_Group,
    SUM(total_sale) AS Total_Sales_Revenue
FROM dbo.[Retail Sales]
GROUP BY 
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        WHEN age > 55 THEN '55+'
    END
ORDER BY Total_Sales_Revenue DESC;
```
##### Q9. analyze category-wise sales trends over time.

```sql
-- Monthly Sales and Profits Trends by Category

SELECT 
    category, 
    DATEPART(YEAR, sale_date) AS Year,
    DATEPART(MONTH, sale_date) AS Month,
    SUM(total_sale) AS Total_Sales,
    SUM(total_sale - cogs) AS Profit
FROM dbo.[Retail Sales]
GROUP BY 
    category, 
    DATEPART(YEAR, sale_date), 
    DATEPART(MONTH, sale_date)
ORDER BY 
    category, 
    Year, 
    Month;

-- Quarterly Sales and Profits Trends by Category

SELECT 
    category, 
    DATEPART(YEAR, sale_date) AS Year,
    DATEPART(QUARTER, sale_date) AS Quarter,
    SUM(total_sale) AS Total_Sales,
    SUM(total_sale - cogs) AS Profit
FROM dbo.[Retail Sales]
GROUP BY 
    category, 
    DATEPART(YEAR, sale_date), 
    DATEPART(QUARTER, sale_date)
ORDER BY 
    category, 
    Year, 
    Quarter;

-- Yearly Sales and profits Trends by Category

SELECT 
    category, 
    DATEPART(YEAR, sale_date) AS Year,
    SUM(total_sale) AS Total_Sales,
    SUM(total_sale - cogs) AS Profit
FROM dbo.[Retail Sales]
GROUP BY 
    category, 
    DATEPART(YEAR, sale_date)
ORDER BY 
    category, 
    Year;

```
##### Q10 - To create a comprehensive report that ranks customers based on various dimensions (year, quarter, month, age group, and category)

```sql
WITH RankedSales AS (
    SELECT 
        customer_id,
        category,
        DATEPART(YEAR, sale_date) AS sale_year,
        DATEPART(QUARTER, sale_date) AS sale_quarter,
        DATEPART(MONTH, sale_date) AS sale_month,
        CASE 
            WHEN age BETWEEN 0 AND 17 THEN '0-17'
            WHEN age BETWEEN 18 AND 24 THEN '18-24'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 44 THEN '35-44'
            WHEN age BETWEEN 45 AND 54 THEN '45-54'
            WHEN age BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END AS age_group,
        SUM(total_sale) AS total_sales,
        RANK() OVER (PARTITION BY DATEPART(YEAR, sale_date) ORDER BY SUM(total_sale) DESC) AS rank_by_year,
        RANK() OVER (PARTITION BY DATEPART(YEAR, sale_date), DATEPART(QUARTER, sale_date) ORDER BY SUM(total_sale) DESC) AS rank_by_quarter,
        RANK() OVER (PARTITION BY DATEPART(YEAR, sale_date), DATEPART(MONTH, sale_date) ORDER BY SUM(total_sale) DESC) AS rank_by_month,
        RANK() OVER (PARTITION BY category ORDER BY SUM(total_sale) DESC) AS rank_by_category,
        RANK() OVER (PARTITION BY CASE 
                                    WHEN age BETWEEN 0 AND 17 THEN '0-17'
                                    WHEN age BETWEEN 18 AND 24 THEN '18-24'
                                    WHEN age BETWEEN 25 AND 34 THEN '25-34'
                                    WHEN age BETWEEN 35 AND 44 THEN '35-44'
                                    WHEN age BETWEEN 45 AND 54 THEN '45-54'
                                    WHEN age BETWEEN 55 AND 64 THEN '55-64'
                                    ELSE '65+'
                                  END ORDER BY SUM(total_sale) DESC) AS rank_by_age_group
    FROM 
        dbo.[Retail Sales]
    GROUP BY 
        customer_id, category, DATEPART(YEAR, sale_date), DATEPART(QUARTER, sale_date), DATEPART(MONTH, sale_date), 
        CASE 
            WHEN age BETWEEN 0 AND 17 THEN '0-17'
            WHEN age BETWEEN 18 AND 24 THEN '18-24'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 44 THEN '35-44'
            WHEN age BETWEEN 45 AND 54 THEN '45-54'
            WHEN age BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END
)
SELECT 
    customer_id,
    category,
    sale_year,
    sale_quarter,
    sale_month,
    age_group,
    total_sales,
    rank_by_year,
    rank_by_quarter,
    rank_by_month,
    rank_by_category,
    rank_by_age_group
FROM 
    RankedSales
WHERE 
    rank_by_year = 1 OR 
    rank_by_quarter = 1 OR 
    rank_by_month = 1 OR  
    rank_by_category = 1 OR 
    rank_by_age_group = 1
ORDER BY 
    total_sales DESC;
```

### Findings

##### Data Exploration and Quality Check

* The dataset contains complete transactional records spanning from the earliest to the latest sale dates.
* Null values were minimal and were removed to maintain data quality.
* The dataset includes diverse customer demographics and product categories.

##### Business Metrics Analysis

###### Customer Lifetime Value (CLTV):
* Identified the top customers contributing the highest lifetime value to the business.
###### Average Order Value (AOV):
* Calculated the average order value by product category, revealing which categories drive higher sales per transaction.
###### Sales Volume Fluctuations:
* Analyzed sales volume by hour, showing peak sales hours and categorizing sales shifts into morning, afternoon, and evening.
###### Profitability by Product Category:
* Determined the most and least profitable product categories based on total sales minus COGS.
###### Sales Value per Transaction by Day of the Week:
* Identified variations in average sales value and total sales across different days of the week.
###### Customer Loyalty and Repeat Purchases
* Calculated repeat purchase rates and identified customer segments showing the highest loyalty based on repeat purchases.
###### Sales Trends Analysis
* Monthly, Quarterly, and Yearly Trends: Analyzed total sales and profits trends over time, providing insights into seasonal and long-term sales patterns.
###### Customer Ranking
* Developed a comprehensive ranking system to identify top customers based on various dimensions such as year, quarter, month, age group, and category.


### Conclusion

This analysis provided valuable insights into customer behavior, sales trends, and product performance, which can be leveraged to optimize business strategies. Key takeaways include:

* Identifying high-value customers and product categories to focus marketing and sales efforts
* Understanding sales patterns to optimize staffing, inventory, and promotions
* Enhancing customer retention strategies by recognizing loyal customer segments
* Using time-based sales trends to anticipate demand and adjust business operations accordingly
* The findings from this analysis serve as a robust foundation for data-driven decision-making and strategic planning in the retail business context


### Author - Satyabrata Mishra

#### Connect with Me

<a href="https://www.linkedin.com/in/satyabrata-mishra246/" aria-label="LinkedIn">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/205f904846099c1c36a9b978d92e1d50cecc5e8c/images/linkedin-icon.png" alt="LinkedIn Icon" width="40" style="margin-right: 10px;">
</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://github.com/Satyabratamishra246" aria-label="GitHub">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/127c2319131cc8652f9666af9b926fd67fc15122/images/github-icon-white-bg.png" alt="GitHub Icon" width="40" style="margin-right: 10px;">
</a>