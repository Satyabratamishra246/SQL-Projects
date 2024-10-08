# **Case Study 3: Foodie-Fi**

<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png" alt="Foodie-Fi" height="500">

### **Introduction**

Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.


### **Available Data**

Table 1: plans

* plan_id
* plan_name
* price

Table 2: subscriptions

* customer_id
* plan_id
* start_date

#### Use The SCHEMA_QUERY.SQL for Replicating the Available Dataset In Your Environment.


## Case Study Questions

### A. Customer Journey

Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 1
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```
Customer Journey: The above customer started with a trial plan and then moved to the basic monthly plan right after the trial period was over

```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 29
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```
Customer Journey: This customer started with a trial and then moved to the pro monthly plan right after the trial period was over

```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 61
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```
Customer Journey: This customer started with a trial, then moved to the basic monthly plan right after the trial period was over and after few months moved to pro annual plan


```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 211
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```

Customer Journey: This customer started with a trial, then moved to the basic monthly plan right after the trial period was over and after few months moved to pro annual plan

```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 355
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```
Customer Journey: This customer started with a trial and then moved to the pro monthly plan right after the trial period was over

```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 461
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```
Customer Journey: This customer started with a trial, then moved to the basic monthly plan right after the trial period was over and after few months got churned

```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 679
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```
Customer Journey: This customer started with a trial, moved to the pro monthly plan right after the trial period was over and after few months got churned

```sql
SELECT customer_id, plans.plan_name, subscriptions.start_date
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE customer_id = 873
ORDER BY subscriptions.customer_id, subscriptions.start_date;

```
Customer Journey: This customer started with a trial, moved to the pro monthly plan right after the trial period was over and fter few months moved to pro annual plan

### B. Data Analysis Questions


##### Q1. How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT(DISTINCT customer_id) AS total_uniques_customers_till_date FROM subscriptions;
```

##### Q2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

```sql
SELECT DATEFROMPARTS(YEAR(s.start_date), MONTH(s.start_date), 1) AS start_of_month,
    COUNT(*) AS trial_plan_count
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'Trial'
GROUP BY DATEFROMPARTS(YEAR(s.start_date), MONTH(s.start_date), 1)
ORDER BY start_of_month;

```
##### Q3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

```sql
SELECT plans.plan_name, COUNT(plans.plan_id) AS plan_count
FROM subscriptions 
JOIN plans ON plans.plan_id = subscriptions.plan_id
WHERE YEAR(start_date) > 2020
GROUP BY plans.plan_name;
```

##### Q4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```sql
SELECT COUNT(DISTINCT subscriptions.customer_id) AS customer_count,
    COUNT(CASE WHEN plans.plan_name = 'churn' THEN 1 END) AS churned_customers_count,
    (CAST(COUNT(CASE WHEN plans.plan_name = 'churn' THEN 1 END) AS FLOAT) / CAST(NULLIF(COUNT(DISTINCT subscriptions.customer_id), 0) AS FLOAT ) * 100) AS percentage_churned
FROM subscriptions
JOIN plans ON plans.plan_id = subscriptions.plan_id;
```
##### Q5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
SELECT COUNT(CASE WHEN T.plan_name = 'trial' THEN 1 END) AS trial_count,
    COUNT(CASE WHEN T.plan_name = 'trial' AND T.next_plan = 'churn' THEN 1 END) AS churned_after_trial,
    ROUND( CAST(COUNT(CASE WHEN T.plan_name = 'trial' AND T.next_plan = 'churn' THEN 1 END) AS FLOAT)/COUNT(CASE WHEN T.plan_name = 'trial' THEN 1 END) * 100, 0) AS churn_percentage
FROM (SELECT subscriptions.customer_id,
        plans.plan_name,
        LEAD(plans.plan_name) OVER(PARTITION BY subscriptions.customer_id ORDER BY subscriptions.start_date) AS next_plan
	FROM subscriptions
    JOIN plans ON subscriptions.plan_id = plans.plan_id
	) T
```
##### Q6. What is the number and percentage of customer plans after their initial free trial?

```sql
WITH plan_and_next_plan AS
    (SELECT subscriptions.customer_id,
        plans.plan_name,
        LEAD(plans.plan_name) OVER(PARTITION BY subscriptions.customer_id ORDER BY subscriptions.start_date) AS next_plan
    FROM subscriptions
    JOIN plans ON subscriptions.plan_id = plans.plan_id
	)
SELECT T.next_plan,
    COUNT(T.plan_name) AS plan_after_trials,
    CAST(COUNT(T.plan_name) AS FLOAT)/ (SELECT COUNT(customer_id) FROM plan_and_next_plan WHERE plan_name = 'trial') * 100 AS percentage
FROM plan_and_next_plan T
WHERE T.plan_name = 'trial'
GROUP BY T.next_plan;
```
##### Q7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

```sql
WITH analysis AS 
    (SELECT customer_id,
        plan_id,
        start_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS plan_sequence
	FROM subscriptions
    WHERE start_date < '2020-12-31'
    )
SELECT plans.plan_name,
    COUNT(customer_id) AS customer_count,
    CAST(COUNT(customer_id) AS FLOAT)/ (SELECT COUNT(customer_id) FROM analysis WHERE plan_sequence = 1) * 100 AS percentage
FROM analysis
JOIN plans ON analysis.plan_id = plans.plan_id
WHERE plan_sequence = 1
GROUP BY plans.plan_name;
```
##### Q8. How many customers have upgraded to an annual plan in 2020?

```sql
SELECT COUNT(customer_id) AS upgrades_count
FROM subscriptions
JOIN plans ON subscriptions.plan_id = plans.plan_id
WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31' AND
    plan_name = 'pro annual';
```

##### Q9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```sql
WITH pro__annual_customers AS
    (SELECT customer_id,
        plans.plan_name,
        start_date
    FROM subscriptions
    JOIN plans ON subscriptions.plan_id = plans.plan_id
    WHERE plan_name = 'pro annual'
    )
SELECT AVG(DATEDIFF(DAY, s.start_date, p.start_date)) AS avg_days
FROM subscriptions s
JOIN plans ON s.plan_id = plans.plan_id
JOIN pro__annual_customers p ON s.customer_id = p.customer_id
WHERE plans.plan_name = 'trial';

-- better solution

SELECT AVG(DATEDIFF(DAY, s1.start_date, s2.start_date)) AS avg_days
FROM subscriptions s1
JOIN subscriptions s2 ON s1.customer_id = s2.customer_id
JOIN plans p1 ON s1.plan_id = p1.plan_id
JOIN plans p2 ON s2.plan_id = p2.plan_id
WHERE p1.plan_name = 'trial' AND p2.plan_name = 'pro annual';
```

##### Q10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

```sql
WITH day_taken AS
    (SELECT s1.customer_id,
        DATEDIFF(DAY, s1.start_date, s2.start_date) AS days_taken,
        (CASE
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 0 AND 30 THEN '0-30'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 31 AND 60 THEN '31-60'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 61 AND 90 THEN '61-90'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 91 AND 120 THEN '91-120'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 121 AND 150 THEN '121-150'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 151 AND 180 THEN '151-180'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 181 AND 210 THEN '181-210'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 211 AND 240 THEN '211-240'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 241 AND 270 THEN '241-270'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 271 AND 300 THEN '271-300'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 301 AND 330 THEN '301-330'
            WHEN DATEDIFF(DAY, s1.start_date, s2.start_date) BETWEEN 331 AND 360 THEN '331-360'
            ELSE '>360' END
        ) AS period
    FROM subscriptions s1
    JOIN subscriptions s2 ON s1.customer_id = s2.customer_id
    JOIN plans p1 ON s1.plan_id = p1.plan_id
    JOIN plans p2 ON s2.plan_id = p2.plan_id
    WHERE p1.plan_name = 'trial' AND p2.plan_name = 'pro annual'
    )
SELECT period, COUNT(customer_id) AS customer_count
FROM day_taken
GROUP BY period;
```
##### Q11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
SELECT COUNT(customer_id) AS downgrades_count
FROM
    (SELECT subscriptions.customer_id,
            plans.plan_name,
            LEAD(plans.plan_name) OVER(PARTITION BY subscriptions.customer_id ORDER BY subscriptions.start_date) AS next_plan,
            LEAD(subscriptions.start_date) OVER(PARTITION BY subscriptions.customer_id ORDER BY subscriptions.start_date) AS next_plan_start_date
    FROM subscriptions
	JOIN plans ON subscriptions.plan_id = plans.plan_id
	) T
WHERE T.plan_name = 'pro monthly' AND 
    T.next_plan = 'basic monthly' AND
    T.next_plan_start_date BETWEEN '2020-01-01' AND '2020-12-31';
```

### C. Challenge Payment Question

The Foodie-Fi team wants to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

* monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
* upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
* upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
* once a customer churns they will no longer make payments


```sql


```

### D. Outside The Box Questions

The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

* How would you calculate the rate of growth for Foodie-Fi?
* What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
* What are some key customer journeys or experiences that you would analyse further to improve customer retention?
* If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
* What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?




## Author - Satyabrata Mishra

### Connect with Me

<a href="https://www.linkedin.com/in/satyabrata-mishra246/" aria-label="LinkedIn">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/205f904846099c1c36a9b978d92e1d50cecc5e8c/images/linkedin-icon.png" alt="LinkedIn Icon" width="40" style="margin-right: 10px;">
</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://github.com/Satyabratamishra246" aria-label="GitHub">
  <img src="https://github.com/Satyabratamishra246/github.io/blob/127c2319131cc8652f9666af9b926fd67fc15122/images/github-icon-white-bg.png" alt="GitHub Icon" width="40" style="margin-right: 10px;">
</a>