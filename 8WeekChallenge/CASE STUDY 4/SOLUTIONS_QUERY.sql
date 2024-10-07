SELECT * FROM Data_Bank.dbo.regions
SELECT * FROM Data_Bank.dbo.customer_nodes
SELECT * FROM Data_Bank.dbo.customer_transactions

-- A. Customer Nodes Exploration

--Q1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

--Q2. What is the number of nodes per region?

SELECT COUNT(DISTINCT node_id)/COUNT(DISTINCT region_id) AS node_per_region
FROM customer_nodes;

SELECT region_id,
    COUNT(DISTINCT node_id) AS nodes_per_region
FROM customer_nodes
GROUP BY region_id;

--Q3. How many customers are allocated to each region?

SELECT region_id,
    COUNT(DISTINCT customer_id) customers_count
FROM customer_nodes
GROUP BY region_id
ORDER BY region_id;

--Q4. How many days on average are customers reallocated to a different node?

WITH node_allocations AS (
    SELECT customer_id,
        node_id,
        DATEDIFF(day, start_date, end_date) AS duration
    FROM customer_nodes
    WHERE end_date < '9999-12-31' -- Exclude ongoing allocations
	--ORDER BY customer_id
),
reallocations AS (
    SELECT customer_id,
        node_id,
        SUM(duration) AS total_days,
        COUNT(*) AS realloc_count
    FROM node_allocations
    GROUP BY customer_id, node_id
)

SELECT AVG(total_days) AS avg_days_per_reallocation
FROM reallocations;

--Q5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region? 

--Will be solving soon

-- B. Customer Transactions

--Q1. What is the unique count and total amount for each transaction type?

SELECT customer_transactions.txn_type
	, COUNT(customer_id) AS transactions_count
	, COUNT(DISTINCT customer_id) AS unique_customers
	, SUM(customer_transactions.txn_amount) AS total_amount
FROM
	customer_transactions
GROUP BY customer_transactions.txn_type;

-- Q2. What is the average total historical deposit counts and amounts for all customers?

WITH customer_deposits AS (
	SELECT customer_id
		, COUNT(CASE WHEN txn_type = 'deposit' THEN txn_amount END) AS total_deposit_count
		, SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount END) AS total_deposit_amount
	FROM customer_transactions
	GROUP BY customer_id
	)
SELECT AVG(total_deposit_count) AS avg_total_deposit_count
	, AVG(total_deposit_amount) AS avg_total_deposit_amount
FROM customer_deposits;

-- Q3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?


WITH count_table AS (
    SELECT customer_id,
        FORMAT(CAST(txn_date AS DATE), 'MMM-yyyy') AS date,
        COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
        COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
        COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id,
        FORMAT(CAST(txn_date AS DATE), 'MMM-yyyy')
)
SELECT date,
    COUNT(customer_id) AS customers_count
FROM count_table
WHERE deposit_count > 1 AND (withdrawal_count >= 1 OR purchase_count >= 1)
GROUP BY date;

-- Q4. What is the closing balance for each customer at the end of the month?

WITH monthly_transactions AS (
    SELECT
        customer_id,
        EOMONTH(txn_date) AS end_of_month,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS monthly_balance 
    FROM customer_transactions
    GROUP BY customer_id, EOMONTH(txn_date)
),
cumulative_balance AS (
    SELECT
        customer_id,
        end_of_month,
        monthly_balance,
        SUM(monthly_balance) OVER(PARTITION BY customer_id ORDER BY end_of_month) AS closing_balance
    FROM monthly_transactions
)

SELECT
    customer_id,
    end_of_month,
    closing_balance
FROM cumulative_balance;



	


