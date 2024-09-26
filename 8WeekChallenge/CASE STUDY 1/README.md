# Case Study 1: Danny's Diner

#### Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

#### Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

* sales
* menu
* members

#### Use the schema_query.sql file to create the above tables with data in your environment and write queries to answer the following questions: 



#### Q1. What is the total amount each customer spent at the restaurant?
```sql
SELECT sales.customer_id, SUM(menu.price) AS TotalSpent
FROM sales, menu
WHERE sales.product_id = menu.product_id
GROUP BY sales.customer_id;
```

#### Q2. How many days has each customer visited the restaurant?

```sql
SELECT	customer_id, COUNT(DISTINCT order_date) AS DaysVisited
FROM sales
GROUP BY customer_id;
```

#### Q3. What was the first item from the menu purchased by each customer?


```sql
SELECT Customer_id, product_name 
FROM
	(SELECT sales.customer_id
		, menu.product_name
		, sales.order_date
		, ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS Ordered_Sequence
	FROM sales, menu
	WHERE sales.product_id = menu.product_id
	) AnalysisTable
WHERE Ordered_Sequence = 1;
```

#### Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT TOP 1 menu.product_name
    , COUNT(sales.product_id) AS TopProductCount
FROM sales, menu
WHERE sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY TopProductCount DESC;
```

#### Bonus Question: How many times did each customer purchase the most purchased item on the menu?

```sql
SELECT customer_id, COUNT(product_id) AS TopProductCount
FROM sales
WHERE product_id IN (SELECT product_id
                    FROM 
                        (SELECT TOP 1 product_id, COUNT(product_id) AS ProductCount
                        FROM sales
                        GROUP BY product_id
                        ORDER BY ProductCount DESC
                        ) T
)
GROUP BY customer_id;
```

#### Q5. Which item was the most popular for each customer?

```sql
WITH CustomerProductCount AS (
    SELECT
        customer_id,
        product_id,
        COUNT(product_id) AS PurchaseCount
    FROM
        sales
    GROUP BY
        customer_id,
        product_id
),
RankedProducts AS (
    SELECT
        customer_id,
        product_id,
        PurchaseCount,
        RANK() OVER (PARTITION BY customer_id ORDER BY PurchaseCount DESC) AS rank
    FROM
        CustomerProductCount
)
SELECT
    customer_id,
    product_id,
    PurchaseCount AS TopProductCount
FROM
    RankedProducts
WHERE
    rank = 1;
```

#### Q6. Which item was purchased first by the customer after they became a member?

```sql
SELECT T.customer_id AS customer_id
    , menu.product_name
FROM
    (SELECT sales.customer_id
        , sales.product_id
        , ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS OrderedSequence
	FROM sales, members
    WHERE sales.customer_id = members.customer_id AND order_date > join_date
	) T, menu
WHERE OrderedSequence = 1 AND T.product_id = menu.product_id;
```

#### Q7. Which item was purchased just before the customer became a member?

```sql
SELECT T.customer_id AS customer_id
    , menu.product_name
FROM
    (SELECT sales.customer_id
        , sales.product_id
		, ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS OrderedSequence
        FROM sales, members
		WHERE sales.customer_id = members.customer_id AND order_date < join_date
	) T, menu
WHERE OrderedSequence = 1 AND T.product_id = menu.product_id;
```


#### Q8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT sales.customer_id
	, COUNT(sales.product_id) AS TotalItems
	, SUM(menu.price) AS AmountSpent
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.order_date < members.join_date AND members.customer_id = sales.customer_id
GROUP BY sales.customer_id;
```

#### Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
SELECT sales.customer_id
	, SUM(CASE
            WHEN menu.product_name = 'sushi' THEN menu.price*10*2
            ELSE menu.price*10 END) AS TotalPoints
FROM sales, menu
WHERE sales.product_id = menu.product_id
GROUP BY sales.customer_id;
```

#### Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
SELECT sales.customer_id
    , SUM(CASE
            WHEN DATEDIFF(DAY, members.join_date, sales.order_date) BETWEEN 0 AND 7 THEN menu.price*2*10
			WHEN menu.product_name = 'sushi' THEN menu.price*10*2
			ELSE menu.price*10 END) AS TotalPoints
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date <= '2021-01-31'
GROUP BY sales.customer_id
HAVING sales.customer_id IN ('A', 'B');
```



#### Bonus Question 1: create basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL

##### Join All The Things and Recreate the following table output using the available data:

____________________________________________________________
| customer_id |	order_date | product_name | price |	member |
|-------------|------------|--------------|-------|--------|
____________________________________________________________


```sql
SELECT sales.customer_id
	, sales.order_date
	, menu.product_name
	, menu.price
	, (CASE
        WHEN sales.order_date >= members.join_date THEN 'Y' ELSE 'N' END ) AS member
FROM sales
LEFT JOIN members ON members.customer_id = sales.customer_id
JOIN menu ON menu.product_id =sales.product_id;
```

#### Bonus Question 2: Rank All The Things. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

#### Recreate the following table output using the available data:
_______________________________________________________________________
| customer_id | order_date | product_name |	price |	member | ranking |
|-------------|-----------|--------------|--------|--------|---------|
_______________________________________________________________________

```sql

WITH RankedTable AS
		(SELECT 
			sales.customer_id
			, sales.order_date
			, menu.product_name
			, menu.price
			, members.join_date
			, (CASE WHEN sales.order_date >= members.join_date THEN 'Y' ELSE 'N' END ) AS member
			, RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS rnk
		FROM sales
		LEFT JOIN members ON members.customer_id = sales.customer_id
		JOIN menu ON menu.product_id = sales.product_id
		)
SELECT 
	RankedTable.customer_id
	, RankedTable.order_date
	, RankedTable.product_name
	, (CASE WHEN RankedTable.order_date >= join_date THEN rnk
		ELSE NULL END) AS rnk
FROM RankedTable;
```



--
--
--
--END