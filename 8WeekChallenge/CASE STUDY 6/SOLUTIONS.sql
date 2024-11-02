-- Digital Analysis

-- Q1. How many users are there?

SELECT COUNT( DISTINCT user_id) AS total_users FROM users;


-- Q2. How many cookies does each user have on average?

SELECT AVG(cookie_count) AS average_cookies
FROM (SELECT user_id, COUNT(cookie_id) AS cookie_count
        FROM users
        GROUP BY user_id
) AS T


-- Q3. What is the unique number of visits by all users per month?

SELECT 
    MONTH(event_time) AS month,
    COUNT(DISTINCT visit_id) AS unique_visits
FROM 
    events
GROUP BY 
    MONTH(event_time)
ORDER BY 
    month;


-- Q4. What is the number of events for each event type?

SELECT event_name, COUNT(events.event_type) AS no_of_events
FROM events
JOIN event_identifier ON event_identifier.event_type = events.event_type
GROUP BY event_name;

-- Q5. What is the percentage of visits which have a purchase event?

WITH TotalVisits AS (
    SELECT DISTINCT visit_id
    FROM Events
),
PurchaseVisits AS (
    SELECT DISTINCT visit_id
    FROM Events
    WHERE event_type = 3
)

SELECT 
    (SELECT COUNT(*) FROM PurchaseVisits) * 100.0 / (SELECT COUNT(*) FROM TotalVisits) AS purchase_visit_percentage
;

-- Q6. What is the percentage of visits which view the checkout page but do not have a purchase event?


WITH CheckoutVisits AS (
    SELECT DISTINCT visit_id
    FROM Events
    WHERE page_id = 12
),
PurchaseVisits AS (
    SELECT DISTINCT visit_id
    FROM Events
    WHERE event_type = 3
),
CheckoutWithoutPurchase AS (
    SELECT visit_id
    FROM CheckoutVisits
    WHERE visit_id NOT IN (SELECT visit_id FROM PurchaseVisits)
),
TotalVisits AS (
    SELECT DISTINCT visit_id
    FROM Events
)

SELECT 
    COUNT(DISTINCT cwp.visit_id) * 100.0 / COUNT(DISTINCT tv.visit_id) AS percentage_checkout_without_purchase
FROM 
    CheckoutWithoutPurchase cwp,
    TotalVisits tv
;

-- Q7. What are the top 3 pages by number of views?

SELECT TOP 3 page_name, COUNT(*) AS total_views
FROM events
JOIN page_hierarchy ON events.page_id = page_hierarchy.page_id
JOIN event_identifier ON event_identifier.event_type = events.event_type
WHERE event_identifier.event_name = 'Page View'
GROUP BY page_name
ORDER BY total_views DESC;

-- Q8. What is the number of views and cart adds for each product category?

SELECT
    page_hierarchy.product_category,
    COUNT(CASE WHEN event_identifier.event_name = 'Page View' THEN 1 END) AS total_views,
    COUNT(CASE WHEN event_identifier.event_name = 'Add to Cart' THEN 1 END) AS total_cart_adds
FROM events
JOIN page_hierarchy ON events.page_id = page_hierarchy.page_id
JOIN event_identifier ON event_identifier.event_type = events.event_type
WHERE page_hierarchy.product_category IS NOT NULL
GROUP BY page_hierarchy.product_category;

-- Q9. What are the top 3 products by purchases?

SELECT TOP 3
    ph.product_id,
    ph.page_name AS product_name,
    COUNT(e.event_type) AS total_purchases
FROM 
    events e
JOIN 
    page_hierarchy ph ON e.page_id = ph.page_id
WHERE 
    e.cookie_id IN (
        SELECT DISTINCT cookie_id 
        FROM events 
        JOIN event_identifier ei ON events.event_type = ei.event_type
        WHERE ei.event_name = 'Purchase'
    )
    AND ph.product_id IS NOT NULL
    AND e.event_type = 2
GROUP BY 
    ph.product_id, ph.page_name
ORDER BY 
    total_purchases DESC;


--  Product Funnel Analysis

-- Using a single SQL query - create a new output table which has the following details:

-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?


-- Product level stats table 
WITH visits_with_purchase AS (
    SELECT visit_id 
    FROM events
    JOIN event_identifier ON event_identifier.event_type = events.event_type
    WHERE event_identifier.event_name = 'Purchase'
), events_with_flag AS (
    SELECT
        e.visit_id,
        ph.page_name,
        ei.event_name,
        CASE WHEN visit_id IN (SELECT visit_id FROM visits_with_purchase) THEN 1 ELSE 0 END AS purchase_flag
    FROM events e
    JOIN page_hierarchy ph ON ph.page_id = e.page_id
    JOIN event_identifier ei ON ei.event_type = e.event_type
)
SELECT
    page_name,
    COUNT(CASE WHEN event_name = 'Page View' THEN 1 END) AS product_views,
    COUNT(CASE WHEN event_name = 'Add to Cart' THEN 1 END) AS added_to_cart,
    COUNT(CASE WHEN event_name = 'Add to Cart' AND purchase_flag = 0 THEN 1 END) AS abandoned,
    COUNT(CASE WHEN event_name = 'Add to Cart' AND purchase_flag = 1 THEN 1 END) AS purchased
INTO product_level_statistics
FROM events_with_flag
WHERE page_name NOT IN ('Home Page', 'All Products', 'Checkout', 'Confirmation')
GROUP BY page_name;




-- category level stats

WITH visits_with_purchase AS (
    SELECT visit_id 
    FROM events
    JOIN event_identifier ON event_identifier.event_type = events.event_type
    WHERE event_identifier.event_name = 'Purchase'
), events_with_flag AS (
    SELECT
        e.visit_id,
        ph.product_category,
        ei.event_name,
        CASE WHEN visit_id IN (SELECT visit_id FROM visits_with_purchase) THEN 1 ELSE 0 END AS purchase_flag
    FROM events e
    JOIN page_hierarchy ph ON ph.page_id = e.page_id
    JOIN event_identifier ei ON ei.event_type = e.event_type
)
SELECT
    product_category,
    COUNT(CASE WHEN event_name = 'Page View' THEN 1 END) AS product_views,
    COUNT(CASE WHEN event_name = 'Add to Cart' THEN 1 END) AS added_to_cart,
    COUNT(CASE WHEN event_name = 'Add to Cart' AND purchase_flag = 0 THEN 1 END) AS abandoned,
    COUNT(CASE WHEN event_name = 'Add to Cart' AND purchase_flag = 1 THEN 1 END) AS purchased
INTO category_level_statistics 
FROM events_with_flag
WHERE product_category IS NOT NULL
GROUP BY product_category;


-- Q1. Which product had the most views, cart adds and purchases?

SELECT TOP 1 'Most Viewed' AS metric, page_name AS product_name
FROM product_level_statistics
ORDER BY product_views DESC

SELECT TOP 1 'Most Added to Cart' AS metric, page_name AS product_name
FROM product_level_statistics
ORDER BY added_to_cart DESC

SELECT TOP 1 'Most Purchased' AS metric, page_name AS product_name
FROM product_level_statistics
ORDER BY purchased DESC

-- Q2. Which product was most likely to be abandoned?

SELECT TOP 1
    page_name AS product_name,
    abandoned,
    added_to_cart,
    CAST(abandoned AS FLOAT) / added_to_cart AS abandonment_rate
FROM 
    product_level_statistics
WHERE 
    added_to_cart > 0
ORDER BY 
    abandonment_rate DESC;

-- Q3. Which product had the highest view to purchase percentage?

SELECT TOP 1
    page_name AS product_name,
    product_views,
    purchased,
    CAST(purchased AS FLOAT) / product_views * 100 AS view_to_purchase_percentage
FROM 
    product_level_statistics
WHERE 
    product_views > 0
ORDER BY 
    view_to_purchase_percentage DESC;

-- Q4. What is the average conversion rate from view to cart add?

SELECT 
    (SUM(added_to_cart) * 100.0) / SUM(product_views) AS average_view_to_cart_add_conversion_rate
FROM 
    product_level_statistics
WHERE 
    product_views > 0;

-- Q5. What is the average conversion rate from cart add to purchase?

SELECT 
    (SUM(purchased) * 100.0) / SUM(added_to_cart) AS average_cart_add_to_purchase_conversion_rate
FROM 
    product_level_statistics
WHERE 
    added_to_cart > 0;

-- Campaigns Analysis


-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:

-- user_id
-- visit_id
-- visit_start_time: the earliest event_time for each visit
-- page_views: count of page views for each visit
-- cart_adds: count of product cart add events for each visit
-- purchase: 1/0 flag if a purchase event exists for each visit
-- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- impression: count of ad impressions for each visit
-- click: count of ad clicks for each visit
-- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)


-- Solution

WITH visits_with_purchase AS (
    SELECT visit_id 
    FROM events
    JOIN event_identifier ON event_identifier.event_type = events.event_type
    WHERE event_identifier.event_name = 'Purchase'
),
campaign_analysis AS (
    SELECT
        e.visit_id,
        u.user_id,
        MIN(e.event_time) AS visit_start_time,
        COUNT(CASE WHEN ei.event_name = 'Page View' THEN 1 END) AS page_views,
        COUNT(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 END) AS cart_adds,
        CASE WHEN visit_id IN (SELECT visit_id FROM visits_with_purchase) THEN 1 ELSE 0 END AS purchase,
        COUNT(CASE WHEN ei.event_name = 'Ad Impression' THEN 1 END) AS impression,
        COUNT(CASE WHEN ei.event_name = 'Ad Click' THEN 1 END) AS click,
        STRING_AGG(CASE WHEN ph.page_name NOT IN ('Home Page', 'All Products', 'Checkout', 'Confirmation') AND ei.event_name = 'Add to Cart' THEN ph.page_name END, ',') WITHIN GROUP (ORDER BY e.sequence_number) AS cart_products
    FROM events e
    JOIN users u ON u.cookie_id = e.cookie_id
    JOIN event_identifier ei ON ei.event_type = e.event_type
    JOIN page_hierarchy ph ON ph.page_id = e.page_id
    GROUP BY e.visit_id, u.user_id
)
SELECT
    ca.user_id,
    ca.visit_id,
    ca.visit_start_time,
    ca.page_views,
    ca.cart_adds,
    ca.purchase,
    ci.campaign_name,
    ca.impression,
    ca.click,
    ca.cart_products
INTO campaign_analysis_table
FROM campaign_analysis ca
LEFT JOIN campaign_identifier ci ON ca.visit_start_time BETWEEN ci.start_date AND ci.end_date;


SELECT * FROM campaign_analysis_table;

-- Does clicking on an impression lead to higher purchase rates?

WITH purchase_analysis AS (
    SELECT 
        COUNT(CASE WHEN click > 0 AND purchase = 1 THEN 1 END) AS purchases_with_click,
        COUNT(CASE WHEN click > 0 THEN 1 END) AS total_clicks,
        COUNT(CASE WHEN click = 0 AND purchase = 1 THEN 1 END) AS purchases_without_click,
        COUNT(CASE WHEN click = 0 THEN 1 END) AS total_no_clicks
    FROM campaign_analysis_table
)
SELECT 
    purchases_with_click,
    total_clicks,
    purchases_without_click,
    total_no_clicks,
    CASE WHEN total_clicks > 0 THEN (purchases_with_click * 1.0 / total_clicks) END AS purchase_rate_with_click,
    CASE WHEN total_no_clicks > 0 THEN (purchases_without_click * 1.0 / total_no_clicks) END AS purchase_rate_without_click
FROM purchase_analysis;

-- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression?
-- What if we compare them with users who just an impression but do not click?

WITH purchase_data AS (
    SELECT 
        u.user_id,
        COUNT(CASE WHEN ei.event_name = 'Purchase' THEN 1 END) AS total_purchases,
        COUNT(CASE WHEN ei.event_name = 'Ad Impression' THEN 1 END) AS total_impressions,
        COUNT(CASE WHEN ei.event_name = 'Ad Click' THEN 1 END) AS total_clicks
    FROM events e
    JOIN event_identifier ei ON ei.event_type = e.event_type
    JOIN users u ON u.cookie_id = e.cookie_id
    GROUP BY u.user_id
),

grouped_data AS (
    SELECT 
        user_id,
        total_purchases,
        total_impressions,
        total_clicks,
        CASE 
            WHEN total_clicks > 0 THEN 'Clicked'
            WHEN total_impressions > 0 THEN 'Impression Only'
            ELSE 'No Impression'
        END AS user_group
    FROM purchase_data
)

SELECT 
    user_group,
    COUNT(user_id) AS user_count,
    SUM(total_purchases) AS total_purchases,
    CAST(SUM(total_purchases) AS FLOAT) / NULLIF(COUNT(user_id), 0) AS purchase_rate
FROM grouped_data
GROUP BY user_group
ORDER BY user_group;

-- What metrics can you use to quantify the success or failure of each campaign compared to eachother?


-- Calculate Click-Through Rate (CTR)

WITH campaign_clicks AS (
    SELECT 
        ci.campaign_name,
        COUNT(CASE WHEN ei.event_name = 'Ad Click' THEN 1 END) AS total_clicks,
        COUNT(CASE WHEN ei.event_name = 'Ad Impression' THEN 1 END) AS total_impressions
    FROM 
        events e
    JOIN
        event_identifier ei ON e.event_type = ei.event_type
    JOIN 
        campaign_identifier ci ON e.event_time BETWEEN ci.start_date AND ci.end_date
    GROUP BY 
        ci.campaign_name
)
SELECT 
    campaign_name,
    total_clicks,
    total_impressions,
    (total_clicks * 1.0 / NULLIF(total_impressions, 0)) * 100 AS click_through_rate
FROM 
    campaign_clicks;


-- Specific Insights from campaign_analysis_table

SELECT TOP 10 * FROM campaign_analysis_table;

-- Q1. Busiest Hours of the day

SELECT
    DATEPART(HOUR, visit_start_time) AS hour_of_day,
    COUNT(visit_id) AS visits
FROM campaign_analysis_table
GROUP BY DATEPART(HOUR, visit_start_time)
ORDER BY visits DESC;

-- Q2. Average Order Quantity, and page views

SELECT
    AVG(page_views) AS avg_page_views,
    AVG(CASE WHEN purchase = 1 THEN cart_adds END) AS avg_order_quantity
FROM campaign_analysis_table;

-- Q3. Average Order Quantity during each promotion

SELECT
    campaign_name,
    AVG(CASE WHEN purchase = 1 THEN cart_adds END) AS avg_order_quantity
FROM campaign_analysis_table
GROUP BY campaign_name;

-- Q4. popular product

SELECT value, COUNT(*) AS ItemCount
FROM campaign_analysis_table
CROSS APPLY STRING_SPLIT(cart_products, ',')
GROUP BY [value]
ORDER BY ItemCount DESC;

-- Q5. Montly purchases

SELECT DATENAME(MONTH, visit_start_time) AS month, COUNT(*) AS total_purchases
FROM campaign_analysis_table
GROUP BY DATENAME(MONTH, visit_start_time)
ORDER BY total_purchases DESC;