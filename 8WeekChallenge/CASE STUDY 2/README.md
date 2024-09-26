# **Case Study 2: Pizza Runner**

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
SELECT
	customer_orders.pizza_id,
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










