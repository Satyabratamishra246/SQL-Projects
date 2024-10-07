# **Case Study 2: Pizza Runner**

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" alt="Danny's Diner" height="500">

### **Introduction**

Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.


### **Available Data**

Because Danny had a few years of experience as a data scientist - he was very aware that data was going to be critical for his business’ growth.

He has data in the following tables:

* runners
* customer_orders
* runner_orders
* pizza_names
* pizza_recipes
* pizza_toppings

However he requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

#### Use The SCHEMA_QUERY.SQL for Replicating the Available Dataset In Your Environment.


### **Cleaning The Data**

**1. Correcting customer_orders**

```sql
UPDATE customer_orders
SET exclusions = (CASE WHEN exclusions IN ('null', '' ) THEN NULL ELSE exclusions END);

UPDATE customer_orders
SET extras = (CASE WHEN extras IN ('null', '' ) THEN NULL ELSE extras END);

```
**2. Converting pickup_time to datetime**
```sql

UPDATE runner_orders
SET pickup_time = TRY_CONVERT(DATETIME, pickup_time, 120);

```
**3. Converting distance to decimal**

```sql
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

```
**4. Convert Duration to Int for better calculations**
```sql

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
```

**5. Correcting null representation in runner_orders**

```sql
UPDATE runner_orders
SET cancellation = CASE
    WHEN LOWER(cancellation) IN ('null', '') THEN NULL
    ELSE cancellation
END;
```

**6. Ensure empty strings are set to NULL for `cancellation`**
```sql
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '';
```
### **Case Study Questions**

#### **Group A. Pizza Metrics**

**Q1. How many pizzas were ordered?**

```sql
SELECT COUNT(pizza_id) AS TotalPizzas
FROM customer_orders;
```

**Q2. How many unique customer orders were made?**

```sql
SELECT COUNT(DISTINCT order_id) AS UniqueOrders
FROM customer_orders;
```

**Q3. How many successful orders were delivered by each runner?**

```sql
SELECT runner_id,
	COUNT(CASE WHEN cancellation IS NULL THEN 1 END) AS SuccessfullOrders
FROM runner_orders
GROUP BY runner_id;
```

**Q4. How many of each type of pizza was delivered?**

```sql
SELECT customer_orders.pizza_id,
	COUNT(CASE WHEN runner_orders.cancellation IS NULL THEN 1 END) AS SuccessfullOrders
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id
GROUP BY customer_orders.pizza_id;
```

**Q5. How many Vegetarian and Meatlovers were ordered by each customer?**

```sql
SELECT customer_orders.customer_id,
	COUNT(CASE WHEN CAST(pizza_names.pizza_name AS VARCHAR(MAX)) = 'Vegetarian' THEN 1 END) AS VegetarianCount,
	COUNT(CASE WHEN CAST(pizza_names.pizza_name AS VARCHAR(MAX)) = 'Meatlovers' THEN 1 END) AS MeatloversCount
FROM customer_orders, pizza_names
WHERE customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_orders.customer_id;
```

**Q6. What was the maximum number of pizzas delivered in a single order?**

```sql
SELECT TOP 1
	COUNT(CASE WHEN runner_orders.cancellation IS NULL THEN 1 END) AS DeliveredPizzaCount
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id
GROUP BY customer_orders.order_id
ORDER BY DeliveredPizzaCount DESC;
```
**Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**

```sql
SELECT customer_orders.customer_id,
	COUNT(CASE WHEN runner_orders.cancellation IS NULL AND customer_orders.exclusions IS NULL AND customer_orders.extras IS NULL THEN 1 END) AS NoChangePizzas,
	COUNT(CASE WHEN runner_orders.cancellation IS NULL AND (customer_orders.exclusions IS NOT NULL OR customer_orders.extras IS NOT NULL) THEN 1 END) AS AtleastOneChangePizzas
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id
GROUP BY customer_orders.customer_id;
```

**Q8. How many pizzas were delivered that had both exclusions and extras?**

```sql
SELECT COUNT(CASE WHEN runner_orders.cancellation IS NULL AND (customer_orders.exclusions IS NOT NULL AND customer_orders.extras IS NOT NULL) THEN 1 END) AS Both
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id;
```

**Q9. What was the total volume of pizzas ordered for each hour of the day?**
```sql

SELECT DATEPART(HOUR, order_time) AS HourOfDay,
	COUNT(pizza_id) AS PizzasCount
FROM customer_orders
GROUP BY DATEPART(HOUR, order_time);
```
**Q10. What was the volume of orders for each day of the week?**
```sql

SELECT DATENAME(WEEKDAY, order_time) AS HourOfDay,
	COUNT(pizza_id) AS PizzasCount
FROM customer_orders
GROUP BY DATENAME(WEEKDAY, order_time);
```

#### **GROUP B - Runner and Customer Experience**

**Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**
```sql
SELECT DATEDIFF(DAY, '2021-01-01', registration_date) / 7 + 1 AS WeekNumber,
	COUNT(runner_id) AS RunnerCount
FROM runners
GROUP BY DATEDIFF(DAY, '2021-01-01', registration_date) / 7 + 1;
```
**Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?**
```sql
SELECT AVG(DATEDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time) ) AS AVGTimeToPick
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.cancellation IS NULL;
```

**Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?**
```sql
SELECT COUNT(customer_orders.order_id) AS PizzaCount,
	AVG(DATEDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time) ) AS AvgPrepTime
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.cancellation IS NULL
GROUP BY customer_orders.order_id
ORDER BY AvgPrepTime DESC;
```

**Q4. What was the average distance travelled for each customer?**
```sql
SELECT customer_orders.customer_id,
	AVG(runner_orders.distance_km) AS AvgDistance
FROM customer_orders, runner_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.cancellation IS NULL
GROUP BY customer_orders.customer_id;
```

**Q5. What was the difference between the longest and shortest delivery times for all orders?**
```sql
WITH DeliveryTime AS (
SELECT DATEDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time) + runner_orders.duration_minutes AS DelTime
FROM runner_orders, customer_orders
WHERE customer_orders.order_id = runner_orders.order_id AND runner_orders.duration_minutes IS NOT NULL
)

SELECT MAX(DelTime) - MIN(DelTime) AS TimeDiff
FROM DeliveryTime
```
**Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**
```sql
SELECT runner_orders.distance_km/(CAST(runner_orders.duration_minutes AS DECIMAL(4, 2))/60)  AS SpeedInKMperHOur
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY SpeedInKMperHOur DESC;
```
**Q7. What is the successful delivery percentage for each runner?**
```sql
SELECT runner_orders.runner_id, 
	COUNT(CASE WHEN runner_orders.cancellation IS NULL THEN 1 END)/CAST(COUNT(runner_orders.runner_id) AS DECIMAL(4, 2)) * 100 AS SuccessPercentage
FROm runner_orders
GROUP BY runner_orders.runner_id;
```
#### **C. Ingredient Optimisation**

**Q1. What are the standard ingredients for each pizza?**
```sql
SELECT T.pizza_id,
    STRING_AGG(CAST(pizza_toppings.topping_name AS VARCHAR(MAX)),  ',') AS standard_ingredients
FROM (SELECT pizza_recipes.pizza_id,
		TRIM(value) AS topping
		FROM pizza_recipes
		CROSS APPLY STRING_SPLIT(CONVERT(varchar(max), pizza_recipes.toppings), ',')
	) T
JOIN pizza_toppings ON T.topping = pizza_toppings.topping_id
GROUP BY T.pizza_id;
```
**Q2. What was the most commonly added extra?**

```sql
SELECT TOP 1
	CAST(pizza_toppings.topping_name AS VARCHAR(MAX)) as mostusedtopping,
	COUNT(pizza_toppings.topping_id) AS cnt
FROM(SELECT CAST(value AS INT) AS extras
		FROM customer_orders
		CROSS APPLY STRING_SPLIT(CONVERT(varchar(max), extras), ',')
	) T
JOIN pizza_toppings ON T.extras = pizza_toppings.topping_id
GROUP BY CAST(pizza_toppings.topping_name AS VARCHAR(MAX))
ORDER BY cnt DESC;
```

**Q3. What was the most common exclusion?**
```sql
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
ORDER BY cnt DESC;
```
**Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:**

* Meat Lovers
* Meat Lovers - Exclude Beef
* Meat Lovers - Extra Bacon
* Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

**Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients**

* For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

**Q6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?**


#### **D. Pricing and Ratings**

**Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes how much money has Pizza Runner made so far if there are no delivery fees?**

```sql
SELECT
	SUM(CASE WHEN CAST(pizza_name AS VARCHAR(MAX))= 'Meatlovers' THEN 12
			WHEN CAST(pizza_name AS VARCHAR(MAX)) = 'Vegetarian' THEN 10 END) AS TotalSales
FROM pizza_runner.dbo.runner_orders
JOIN pizza_runner.dbo.customer_orders
	ON customer_orders.order_id = runner_orders.order_id
JOIN pizza_runner.dbo.pizza_names
	ON customer_orders.pizza_id = pizza_names.pizza_id
WHERE cancellation IS NULL;
```

**Q2. What if there was an additional $1 charge for any pizza extras?**
* Add cheese is $1 extra.
```sql
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
```

**Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.**

```sql

```


**Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?**

* customer_id
* order_id
* runner_id
* rating
* order_time
* pickup_time
* Time between order and pickup
* Delivery duration
* Average speed
* Total number of pizzas

```sql

```

**Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?**

```sql

```

#### **E. Bonus Questions**

**If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?**

```sql

```


## Author - Satyabrata Mishra

### Connect with Me

<a href="https://www.linkedin.com/in/satyabrata-mishra246/" aria-label="LinkedIn">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/205f904846099c1c36a9b978d92e1d50cecc5e8c/images/linkedin-icon.png" alt="LinkedIn Icon" width="40" style="margin-right: 10px;">
</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://github.com/Satyabratamishra246" aria-label="GitHub">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/127c2319131cc8652f9666af9b926fd67fc15122/images/github-icon-white-bg.png" alt="GitHub Icon" width="40" style="margin-right: 10px;">
</a>








