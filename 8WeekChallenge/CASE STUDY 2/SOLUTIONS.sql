-- Viewing and Analyzing Available Data

SELECT * FROM customer_orders;

SELECT * FROM runner_orders;


SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'customer_orders';

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'runner_orders';

-- Correcting customer_orders
UPDATE customer_orders
SET exclusions = (CASE WHEN exclusions IN ('null', '' ) THEN NULL ELSE exclusions END);

UPDATE customer_orders
SET extras = (CASE WHEN extras IN ('null', '' ) THEN NULL ELSE extras END);

-- Converting pickup_time to datetime
UPDATE runner_orders
SET pickup_time = TRY_CONVERT(DATETIME, pickup_time, 120);

-- Converting distance to decimal
ALTER TABLE runner_orders
ADD distance DECIMAL(10, 2);

UPDATE runner_orders
SET distance = CASE
    WHEN distance LIKE '%km%' THEN 
        TRY_CONVERT(DECIMAL(10, 2), REPLACE(REPLACE(distance, 'km', ''), ' ', ''))
    WHEN distance LIKE '%[0-9]%' THEN 
        TRY_CONVERT(DECIMAL(10, 2), REPLACE(distance, ' ', ''))
    ELSE 
        NULL
END;

-- Convert Duration to Int for better calculations
ALTER TABLE runner_orders
ADD duration_minutes INT;

UPDATE runner_orders
SET duration_minutes = CASE
    WHEN duration LIKE '%minute%' OR duration LIKE '%mins%' THEN 
        TRY_CONVERT(INT, REPLACE(REPLACE(REPLACE(duration, 'minutes', ''), 'mins', ''), 'minute', ''))
    WHEN duration LIKE '%[0-9]%' THEN 
        TRY_CONVERT(INT, REPLACE(duration, ' ', ''))
    ELSE 
        NULL
END;

ALTER TABLE runner_orders
DROP COLUMN duration;

-- Correcting null representation in runner_orders
UPDATE runner_orders
SET cancellation = CASE
    WHEN LOWER(cancellation) IN ('null', '') THEN NULL
    ELSE cancellation
END;

-- Ensure empty strings are set to NULL for `cancellation`
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '';

-- Views All Tables

SELECT * FROM customer_orders;
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;
SELECT * FROM runner_orders;
SELECT * FROM runners;


-- GROUP A - Pizza Metrics

-- Q1. How many pizzas were ordered?

SELECT COUNT(pizza_id) AS TotalPizzas
FROM customer_orders;

-- Q2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS UniqueOrders
FROM customer_orders;

-- Q3. How many successful orders were delivered by each runner?

SELECT runner_id,
	COUNT(CASE WHEN cancellation IS NULL THEN 1 END) AS SuccessfullOrders
FROM runner_orders
GROUP BY runner_id;

-- Q4. How many of each type of pizza was delivered?

SELECT
	customer_orders.pizza_id,
	COUNT(CASE WHEN runner_orders.cancellation IS NULL THEN 1 END) AS SuccessfullOrders
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id
GROUP BY customer_orders.pizza_id;

-- Q5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_orders.customer_id,
	COUNT(CASE WHEN CAST(pizza_names.pizza_name AS VARCHAR(MAX)) = 'Vegetarian' THEN 1 END) AS VegetarianCount,
	COUNT(CASE WHEN CAST(pizza_names.pizza_name AS VARCHAR(MAX)) = 'Meatlovers' THEN 1 END) AS MeatloversCount
FROM customer_orders, pizza_names
WHERE customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_orders.customer_id;

-- Q6. What was the maximum number of pizzas delivered in a single order?

SELECT TOP 1
	COUNT(CASE WHEN runner_orders.cancellation IS NULL THEN 1 END) AS DeliveredPizzaCount
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id
GROUP BY customer_orders.order_id
ORDER BY DeliveredPizzaCount DESC;

-- Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_orders.customer_id,
	COUNT(CASE WHEN runner_orders.cancellation IS NULL AND customer_orders.exclusions IS NULL AND customer_orders.extras IS NULL THEN 1 END) AS NoChangePizzas,
	COUNT(CASE WHEN runner_orders.cancellation IS NULL AND (customer_orders.exclusions IS NOT NULL OR customer_orders.extras IS NOT NULL) THEN 1 END) AS AtleastOneChangePizzas
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id
GROUP BY customer_orders.customer_id;

-- Q8. How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(CASE WHEN runner_orders.cancellation IS NULL AND (customer_orders.exclusions IS NOT NULL AND customer_orders.extras IS NOT NULL) THEN 1 END) AS Both
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id;

-- Q9. What was the total volume of pizzas ordered for each hour of the day?

SELECT DATEPART(HOUR, order_time) AS HourOfDay,
	COUNT(pizza_id) AS PizzasCount
FROM customer_orders
GROUP BY DATEPART(HOUR, order_time);

-- Q10. What was the volume of orders for each day of the week?

SELECT DATENAME(WEEKDAY, order_time) AS HourOfDay,
	COUNT(pizza_id) AS PizzasCount
FROM customer_orders
GROUP BY DATENAME(WEEKDAY, order_time);


-- GROUP B - Runner and Customer Experience

-- Q1. How many runners signed up for each 1 week period?

SELECT DATEDIFF(DAY, '2021-01-01', registration_date) / 7 + 1 AS WeekNumber,
	COUNT(runner_id) AS RunnerCount
FROM runners
GROUP BY DATEDIFF(DAY, '2021-01-01', registration_date) / 7 + 1;

-- Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT AVG(DATEDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time) ) AS AVGTimeToPick
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.cancellation IS NULL;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT COUNT(customer_orders.order_id) AS PizzaCount,
	AVG(DATEDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time) ) AS AvgPrepTime
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.cancellation IS NULL
GROUP BY customer_orders.order_id
ORDER BY AvgPrepTime DESC;

-- Q4. What was the average distance travelled for each customer?

SELECT customer_orders.customer_id,
	AVG(runner_orders.distance_km) AS AvgDistance
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.cancellation IS NULL
GROUP BY customer_orders.customer_id;

-- Q5. What was the difference between the longest and shortest delivery times for all orders?

WITH DeliveryTime AS (
SELECT DATEDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time) + runner_orders.duration_minutes AS DelTime
FROM runner_orders, customer_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.duration_minutes IS NOT NULL
)

SELECT MAX(DelTime) - MIN(DelTime) AS TimeDiff
FROM DeliveryTime

-- Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT * FROM runner_orders

SELECT
	*
	, runner_orders.distance_km/(CAST(runner_orders.duration_minutes AS DECIMAL(4, 2))/60)  AS SpeedInKMperHOur
FROM runner_orders
WHERE
	cancellation IS NULL
ORDER BY
	SpeedInKMperHOur DESC;

-- Q7. What is the successful delivery percentage for each runner?

SELECT
	runner_orders.runner_id
	, COUNT(CASE WHEN runner_orders.cancellation IS NULL THEN 1 END)/CAST(COUNT(runner_orders.runner_id) AS DECIMAL(4, 2)) * 100 AS SuccessPercentage
FROm
	runner_orders
GROUP BY
	runner_orders.runner_id;

-- Group C - Ingredient Optimization

-- Q1. What are the standard ingredients for each pizza?

SELECT
	T.pizza_id
	, STRING_AGG(CAST(pizza_toppings.topping_name AS VARCHAR(MAX)),  ',') AS standard_ingredients
FROM 
	(
	SELECT 
		pizza_recipes.pizza_id,
		TRIM(value) AS topping
	FROM pizza_recipes
	CROSS APPLY STRING_SPLIT(CONVERT(varchar(max), pizza_recipes.toppings), ',')
	) T
JOIN
	pizza_toppings ON T.topping = pizza_toppings.topping_id
GROUP BY
	T.pizza_id

-- Q2. What was the most commonly added extra?

SELECT TOP 1
	CAST(pizza_toppings.topping_name AS VARCHAR(MAX)) as mostusedtopping
	, COUNT(pizza_toppings.topping_id) AS cnt
FROM
	(
		SELECT
			CAST(value AS INT) AS extras
		FROM
			customer_orders
		CROSS APPLY STRING_SPLIT(CONVERT(varchar(max), extras), ',')
	) T
JOIN pizza_toppings ON T.extras = pizza_toppings.topping_id
GROUP BY
	CAST(pizza_toppings.topping_name AS VARCHAR(MAX))
ORDER BY cnt DESC

-- Q3. What was the most common exclusion?

SELECT TOP 1
	CAST(pizza_toppings.topping_name AS VARCHAR(MAX)) as commonexclusion
	, COUNT(pizza_toppings.topping_id) AS cnt
FROM
	(
		SELECT
			CAST(value AS INT) AS exclusion
		FROM
			customer_orders
		CROSS APPLY STRING_SPLIT(CONVERT(varchar(max), exclusions), ',')
	) T
JOIN pizza_toppings ON T.exclusion = pizza_toppings.topping_id
GROUP BY
	CAST(pizza_toppings.topping_name AS VARCHAR(MAX))
ORDER BY cnt DESC

-- Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:

--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT * FROM customer_orders;

SELECT
	*
	,pn.pizza_name
	, CASE WHEN exclusions IS NOT NULL THEN STRING_SPLIT(CONVERT(varchar(max), co.exclusions), ',') END AS exclusion_list
FROM
	customer_orders co
JOIN
	pizza_names pn ON co.pizza_id = pn.pizza_id;


SELECT
    *,
    CASE
        WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 
            pn.pizza_name + ' - Exclude ' + ex.exclusion_list + ' - Extra ' + ex2.extra_list
        WHEN co.exclusions IS NOT NULL THEN 
            pn.pizza_name + ' - Exclude ' + ex.exclusion_list
        WHEN co.extras IS NOT NULL THEN 
            pn.pizza_name + ' - Extra ' + ex2.extra_list
        ELSE 
            pn.pizza_name
    END AS order_item_description
FROM
    customer_orders co
JOIN
    (SELECT pizza_id, CAST(pizza_name AS VARCHAR(MAX)) AS pizza_name FROM pizza_names) pn ON co.pizza_id = pn.pizza_id
LEFT JOIN (
    SELECT 
        co.order_id,
        STRING_AGG(CAST(pt.topping_name AS VARCHAR(MAX)), ', ') AS exclusion_list
    FROM 
        customer_orders co
    CROSS APPLY STRING_SPLIT(CAST(co.exclusions AS VARCHAR(MAX)), ',') s
    JOIN (SELECT topping_id, CAST(topping_name AS VARCHAR(MAX)) AS topping_name FROM pizza_toppings) pt ON CAST(s.value AS INT) = pt.topping_id
    GROUP BY co.order_id
) ex ON co.order_id = ex.order_id
LEFT JOIN (
    SELECT 
        co.order_id,
        STRING_AGG(CAST(pt.topping_name AS VARCHAR(MAX)), ', ') AS extra_list
    FROM 
        customer_orders co
    CROSS APPLY STRING_SPLIT(CAST(co.extras AS VARCHAR(MAX)), ',') s
    JOIN (SELECT topping_id, CAST(topping_name AS VARCHAR(MAX)) AS topping_name FROM pizza_toppings) pt ON CAST(s.value AS INT) = pt.topping_id
    GROUP BY co.order_id
) ex2 ON co.order_id = ex2.order_id
ORDER BY 
    co.order_id;


-- D. Pricing and Ratings

-- Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes
-- how much money has Pizza Runner made so far if there are no delivery fees?

SELECT * FROM pizza_runner.dbo.customer_orders

SELECT * FROM pizza_runner.dbo.pizza_names

SELECT
	SUM(CASE WHEN CAST(pizza_name AS VARCHAR(MAX))= 'Meatlovers' THEN 12
			WHEN CAST(pizza_name AS VARCHAR(MAX)) = 'Vegetarian' THEN 10 END) AS TotalSales
FROM pizza_runner.dbo.runner_orders
JOIN pizza_runner.dbo.customer_orders
	ON customer_orders.order_id = runner_orders.order_id
JOIN pizza_runner.dbo.pizza_names
	ON customer_orders.pizza_id = pizza_names.pizza_id
WHERE cancellation IS NULL

-- Q2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
WITH Pizza_sales AS 
	(
	SELECT
		SUM(CASE WHEN CAST(pizza_name AS VARCHAR(MAX))= 'Meatlovers' THEN 12
				WHEN CAST(pizza_name AS VARCHAR(MAX)) = 'Vegetarian' THEN 10 END) AS TotalSales
	FROM pizza_runner.dbo.runner_orders
	JOIN pizza_runner.dbo.customer_orders
		ON customer_orders.order_id = runner_orders.order_id
	JOIN pizza_runner.dbo.pizza_names
		ON customer_orders.pizza_id = pizza_names.pizza_id
	WHERE cancellation IS NULL
	),
Extra_sales AS
	(
	SELECT
		SUM(CASE WHEN CAST(pizza_toppings.topping_name AS VARCHAR(MAX)) = 'Cheese' THEN 2 ELSE 1 END) AS ExtraSales
	FROM 
		(
		SELECT
			customer_orders.order_id
			, cancellation
			, value as topping_id
		FROM pizza_runner.dbo.runner_orders
		JOIN pizza_runner.dbo.customer_orders
			ON customer_orders.order_id = runner_orders.order_id
		JOIN pizza_runner.dbo.pizza_names
			ON customer_orders.pizza_id = pizza_names.pizza_id
			CROSS APPLY STRING_SPLIT(extras, ',')
		WHERE cancellation IS NULL
		) T
	JOIN pizza_toppings ON T.topping_id = pizza_toppings.topping_id
	)
SELECT 
    (SELECT TotalSales FROM Pizza_sales) + (SELECT ExtraSales FROM Extra_sales) AS TotalSales;



