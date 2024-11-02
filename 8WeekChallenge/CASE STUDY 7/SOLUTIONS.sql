-- High Level Sales Analysis

-- Q1. What was the total quantity sold for all products?

SELECT SUM(qty) AS total_qty FROM sales;

-- Q2. What is the total generated revenue for all products before discounts?

SELECT
    SUM(s.qty * pp.price) AS total_revenue
FROM sales s
JOIN product_prices pp ON pp.product_id = s.prod_id;

-- Q3. What was the total discount amount for all products?

SELECT SUM(discount) AS total_discount FROM sales;


-- Transaction Analysis

-- Q1. How many unique transactions were there?

SELECT COUNT(DISTINCT txn_id) as total_unique_transactions FROM sales;

-- Q2. What is the average unique products purchased in each transaction?

SELECT AVG(products_count) AS avg_products_purchased FROM (
    SELECT
        txn_id,
        COUNT(prod_id) AS products_count
    FROM sales
    GROUP BY txn_id
) AS T


-- Q3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

WITH RevenuePerTransaction AS (
    SELECT
        txn_id,
        SUM(s.qty * pp.price) AS transaction_revenue
    FROM sales s
    JOIN product_prices pp ON pp.product_id = s.prod_id
    GROUP BY txn_id
)
SELECT TOP 1
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY transaction_revenue) OVER () AS percentile_25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY transaction_revenue) OVER () AS percentile_50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY transaction_revenue) OVER () AS percentile_75
FROM RevenuePerTransaction;

-- Q4. What is the average discount value per transaction?

SELECT AVG(transaction_discount) AS avg_discount_value
FROM (
    SELECT txn_id, SUM(discount) AS transaction_discount
    FROM sales
    GROUP BY txn_id
) AS T;

-- Q5. What is the percentage split of all transactions for members vs non-members?

SELECT 
    COUNT(CASE WHEN member = 't' THEN 1 END) * 100.0 / COUNT(*) AS member_percentage,
    COUNT(CASE WHEN member = 'f' THEN 1 END) * 100.0 / COUNT(*) AS non_member_percentage
FROM sales;

-- Q6. What is the average revenue for member transactions and non-member transactions?

SELECT 
    AVG(CASE WHEN s.member = 't' THEN s.qty * pp.price END) AS avg_member_revenue,
    AVG(CASE WHEN s.member = 'f' THEN s.qty * pp.price END) AS avg_non_member_revenue
FROM sales s
JOIN product_prices pp ON s.prod_id = pp.product_id;


-- Product Analysis

-- Q1. What are the top 3 products by total revenue before discount?

SELECT TOP 3
    pd.product_name,
    SUM(s.qty * pp.price) AS product_revenue
FROM sales s
JOIN product_prices pp ON s.prod_id = pp.product_id
JOIN product_details pd ON pd.product_id = s.prod_id
GROUP BY pd.product_name
ORDER BY product_revenue DESC;

-- Q2. What is the total quantity, revenue and discount for each segment?

SELECT
    pd.segment_name,
    SUM(s.qty) AS total_qty,
    SUM(s.qty * pp.price) AS total_revenue,
    SUM(discount) AS total_discount
FROM sales s
JOIN product_prices pp ON s.prod_id = pp.product_id
JOIN product_details pd ON pd.product_id = s.prod_id
GROUP BY pd.segment_name;

-- Q3. What is the top selling product for each segment?
WITH ranked_products AS (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * pp.price) AS total_revenue,
        RANK() OVER(PARTITION BY pd.segment_name ORDER BY SUM(s.qty * pp.price) DESC) AS Rnk
    FROM sales s
    JOIN product_prices pp ON s.prod_id = pp.product_id
    JOIN product_details pd ON pd.product_id = s.prod_id
    GROUP BY pd.segment_name, pd.product_name
)
SELECT
    segment_name,
    product_name,
    total_revenue
FROM ranked_products
WHERE Rnk = 1;

-- Q4. What is the total quantity, revenue and discount for each category?

SELECT
    pd.category_name,
    SUM(s.qty) AS total_qty,
    SUM(s.qty * pp.price) AS total_revenue,
    SUM(discount) AS total_discount
FROM sales s
JOIN product_prices pp ON s.prod_id = pp.product_id
JOIN product_details pd ON pd.product_id = s.prod_id
GROUP BY pd.category_name;

-- Q5. What is the top selling product for each category?

WITH ranked_products AS (
    SELECT
        pd.category_name,
        pd.product_name,
        SUM(s.qty * pp.price) AS total_revenue,
        RANK() OVER(PARTITION BY pd.category_name ORDER BY SUM(s.qty * pp.price) DESC) AS Rnk
    FROM sales s
    JOIN product_prices pp ON s.prod_id = pp.product_id
    JOIN product_details pd ON pd.product_id = s.prod_id
    GROUP BY pd.category_name, pd.product_name
)
SELECT
    category_name,
    product_name,
    total_revenue
FROM ranked_products
WHERE Rnk = 1;

-- Q6. What is the percentage split of revenue by product for each segment?

WITH segment_revenue AS (
    SELECT
        pd.segment_name,
        SUM(s.qty * pp.price) AS total_segment_revenue
    FROM sales s
    JOIN product_prices pp ON s.prod_id = pp.product_id
    JOIN product_details pd ON pd.product_id = s.prod_id
    GROUP BY pd.segment_name
),
product_revenue AS (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * pp.price) AS product_revenue
    FROM sales s
    JOIN product_prices pp ON s.prod_id = pp.product_id
    JOIN product_details pd ON pd.product_id = s.prod_id
    GROUP BY pd.segment_name, pd.product_name
)
SELECT
    pr.segment_name,
    pr.product_name,
    pr.product_revenue,
    (pr.product_revenue * 100.0 / sr.total_segment_revenue) AS percentage_split
FROM product_revenue pr
JOIN segment_revenue sr ON pr.segment_name = sr.segment_name
ORDER BY pr.segment_name, percentage_split DESC;

-- Q7. What is the percentage split of revenue by segment for each category?

WITH category_revenue AS (
    SELECT
        pd.category_name,
        pd.segment_name,
        SUM(s.qty * pp.price) AS segment_revenue
    FROM sales s
    JOIN product_prices pp ON s.prod_id = pp.product_id
    JOIN product_details pd ON pd.product_id = s.prod_id
    GROUP BY pd.category_name, pd.segment_name
),
total_category_revenue AS (
    SELECT
        category_name,
        SUM(segment_revenue) AS total_revenue
    FROM category_revenue
    GROUP BY category_name
)
SELECT
    cr.category_name,
    cr.segment_name,
    cr.segment_revenue,
    (cr.segment_revenue * 100.0 / tr.total_revenue) AS percentage_split
FROM category_revenue cr
JOIN total_category_revenue tr ON cr.category_name = tr.category_name
ORDER BY cr.category_name, percentage_split DESC;


-- Q8. What is the percentage split of total revenue by category?

WITH total_revenue AS (
    SELECT 
        SUM(s.qty * pp.price) AS overall_revenue
    FROM sales s
    JOIN product_prices pp ON s.prod_id = pp.product_id
),
category_revenue AS (
    SELECT
        pd.category_name,
        SUM(s.qty * pp.price) AS category_total_revenue
    FROM sales s
    JOIN product_prices pp ON s.prod_id = pp.product_id
    JOIN product_details pd ON pd.product_id = s.prod_id
    GROUP BY pd.category_name
)
SELECT
    cr.category_name,
    cr.category_total_revenue,
    (cr.category_total_revenue * 100.0 / tr.overall_revenue) AS percentage_split
FROM category_revenue cr
CROSS JOIN total_revenue tr
ORDER BY cr.category_total_revenue DESC;


-- Q9. What is the total transaction “penetration” for each product?
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

WITH total_transactions AS (
    SELECT COUNT(DISTINCT txn_id) AS total_txns
    FROM sales
),
product_transactions AS (
    SELECT
        s.prod_id,
        COUNT(DISTINCT s.txn_id) AS product_txns
    FROM sales s
    GROUP BY s.prod_id
)
SELECT
    pt.prod_id,
    pt.product_txns,
    tt.total_txns,
    (pt.product_txns * 1.0 / tt.total_txns) AS penetration
FROM product_transactions pt
CROSS JOIN total_transactions tt
ORDER BY penetration DESC;

-- Q10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WITH product_combinations AS (
    SELECT
        txn_id,
        STRING_AGG(prod_id, ',') AS product_ids, -- Combine product IDs as a string
        COUNT(DISTINCT prod_id) AS product_count
    FROM sales
    WHERE qty >= 1
    GROUP BY txn_id
    HAVING COUNT(DISTINCT prod_id) >= 3
),
combination_counts AS (
    SELECT
        product_ids,
        COUNT(*) AS combination_count
    FROM product_combinations
    GROUP BY product_ids
)
SELECT TOP 1
    product_ids,
    combination_count
FROM combination_counts
ORDER BY combination_count DESC;

