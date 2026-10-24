-- 1. SETTING THINGS UP

CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

-- had wizard issue so truncated the table with few data rows
TRUNCATE TABLE sales_analysis;
select count(*) as row_count from sales_analysis; -- 0 rows now

SHOW VARIABLES LIKE 'local_infile'; -- checking local_infile is ON or not for data importation from csv

-- importing csv using load data infile method
LOAD DATA LOCAL INFILE 'C:/Users/tomer/OneDrive/Desktop/data analysis/Portfolio/Data Analyst Portfolio/P03_Sales_Price_Customer_Excel_SQL_PBI/sales_analysis.csv'
INTO TABLE sales_analysis
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from sales_analysis LIMIT 10; -- data import completed

-- 2. DATA VALIDATION

SELECT MIN(order_date) from sales_analysis;
SELECT MAX(order_date) from sales_analysis;

-- checking financial columns null values
SELECT
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(order_date IS NULL) AS missing_order_date,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(currency IS NULL) AS missing_currency,
    SUM(net_sales_usd IS NULL) AS missing_net_sales,
    SUM(profit_usd IS NULL) AS missing_profit
FROM sales_analysis;

-- checking duplicates
select order_id, count(*) as occurences
from sales_analysis
group by order_id
having count(*) > 1;

-- checking calculations of net sales
select count(*) as mismatched_rows
from sales_analysis
where ABS( net_sales_usd - (gross_sales_usd - discount_amount_usd + shipping_cost_usd + tax_amount_usd) > 0.1);

-- checking calculations of profit
select count(*) as mismatched_rows
from sales_analysis
where abs(profit_usd - (net_sales_usd -product_cost_usd - shipping_cost_usd)>0.1);

-- num of records in each order status
SELECT order_status, COUNT(*) AS row_count
FROM sales_analysis
GROUP BY order_status
order by row_count DESC;

-- num of records in each currency
SELECT currency, COUNT(*) AS row_count
FROM sales_analysis
GROUP BY currency 
order by row_count DESC;

-- 3. OVERALL KPIs

-- Key findings:
-- Completed net sales: $138,719,388.74
-- Completed profit: $57,756,699.21
-- Profit margin: 41.64%
-- Completed orders: 113,559
-- Unique customers: 24748

SELECT
    ROUND(SUM(net_sales_usd),2) as total_net_sales,
    ROUND(SUM(profit_usd),2) as total_profit,
    ROUND(SUM(profit_usd)/SUM(net_sales_usd) * 100 , 2) as profit_margin_percentage,
    (SELECT COUNT(order_id) from sales_analysis where order_status = 'Completed') as total_orders,
    (SELECT COUNT(DISTINCT customer_id) from sales_analysis where order_status = 'Completed') as total_customers
FROM sales_analysis
WHERE order_status = 'Completed';

SELECT
    ROUND(SUM(net_sales_usd),2) as total_net_sales,
    ROUND(SUM(profit_usd),2) as total_profit,
    ROUND(SUM(profit_usd)/SUM(net_sales_usd) * 100 , 2) as profit_margin_percentage,
    COUNT(order_id) as total_orders,
    COUNT(DISTINCT customer_id) as total_customers
FROM sales_analysis
WHERE order_status = 'Completed';

-- 4. Monthly Trends

-- a) Monthly Orders
-- The maximum orders are recorded in the months of NOV-DEC every year
-- The number of orders are the least in the first two months

SELECT `Year_Month`, COUNT(order_id) as monthly_orders
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY `Year_Month`
ORDER BY monthly_orders DESC;

-- b) monthly unique customers
-- The months of Nov-Dec records the highest number of unique customers
-- The number of customers in first two months are the lowest

SELECT `Year_Month`, COUNT(DISTINCT customer_id) as monthly_customers
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY `Year_Month`
ORDER BY monthly_customers DESC;

-- c) Sales vs Profit
-- FY 2021 - 2025, the high-sales months are Nov & Dec whereas February shows the lowest sales
-- Profit margin percentage in Nov-Dec is significantly lower that of February
-- This shows that Higher Sales are not contributing to higher profit

SELECT `Year_Month`,
ROUND(SUM(net_sales_usd),2) as total_net_sales,
ROUND(SUM(profit_usd),2) as total_profit,
ROUND(SUM(profit_usd) / SUM(net_sales_usd) * 100,2) AS profit_margin_percentage
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY `Year_Month`
ORDER BY `Year_Month`;

-- d) Sales/Profit vs Discount Rate
-- Each year showed that maximum discounts were offered in the last two months
-- This indicates that high discount rate can be the reason for lower profit margin percentage or even the reason why the sales were highest in last two months each year

SELECT `Year_Month`,
ROUND(SUM(net_sales_usd),2) as total_net_sales,
ROUND(SUM(profit_usd),2) as total_profit,
ROUND(SUM(discount_amount_usd) / SUM(gross_sales_usd) * 100,2) AS discount_rate,
ROUND(SUM(profit_usd) / SUM(net_sales_usd) * 100,2) AS profit_margin_percentage
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY `Year_Month`
ORDER BY `Year_Month`;

-- e) Average Order value

SELECT `Year_Month`, COUNT(order_id) as monthly_order,
ROUND(SUM(net_sales_usd)/COUNT(order_id),2) as net_AOV
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY `Year_Month`
ORDER BY net_AOV;

-- f) Month Over Month (MoM) analysis with Profit and net sales
-- Indicates towards a strong seasonal pattern
-- January shows sharp decline in sales which further declines in february.
-- November records highest increase in sales but MoM profit mostly shows decline 

WITH monthly AS (
SELECT `Year_Month`,SUM(net_sales_usd) AS total_net_sales,
SUM(profit_usd) AS total_profit
FROM sales_analysis
WHERE order_status='Completed'
GROUP BY `Year_Month`
)
SELECT `Year_Month`,ROUND(total_profit,2) AS total_profit,ROUND((total_profit-LAG(total_profit) OVER(ORDER BY `Year_Month`))/LAG(total_profit) OVER(ORDER BY `Year_Month`)*100,2) AS profit_mom_growth,
ROUND(total_net_sales,2) AS total_net_sales,ROUND((total_net_sales-LAG(total_net_sales) OVER(ORDER BY `Year_Month`))/LAG(total_net_sales) OVER(ORDER BY `Year_Month`)*100,2) AS net_sales_mom_growth
FROM monthly
ORDER BY `Year_Month`;

-- g) Year over Year analysis with Profit and net sales
-- Year-over-year sales and profit generally move in the same direction

WITH monthly AS (
SELECT `Year_Month`,SUM(net_sales_usd) AS total_net_sales,SUM(profit_usd) AS total_profit
FROM sales_analysis
WHERE order_status='Completed'
GROUP BY `Year_Month`
)
SELECT `Year_Month`,ROUND(total_profit,2) AS total_profit,ROUND((total_profit-LAG(total_profit,12) OVER(ORDER BY `Year_Month`))/LAG(total_profit,12) OVER(ORDER BY `Year_Month`)*100,2) AS profit_yoy_growth,ROUND(total_net_sales,2) AS total_net_sales,ROUND((total_net_sales-LAG(total_net_sales,12) OVER(ORDER BY `Year_Month`))/LAG(total_net_sales,12) OVER(ORDER BY `Year_Month`)*100,2) AS net_sales_yoy_growth
FROM monthly
ORDER BY `Year_Month`;

-- 5. Regional Analysis

-- South region takes the top place across sales, customers and orders while North region takes the lowest spot
-- North region records the highest profit margin (45%) even after contributing to the sales the least
-- This indicates that higher regional sales volume does not necessarily translate into higher profitability

SELECT region, ROUND(SUM(net_sales_usd),2) as total_sales, ROUND(SUM(profit_usd),2) as total_profit,
ROUND((SUM(profit_usd)/SUM(net_sales_usd)) * 100 ,2) as profit_margin_percentage, COUNT(order_id) as total_orders, COUNT(DISTINCT customer_id) as unique_customers
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY region
ORDER BY total_sales DESC;

-- North region has the highest AOV which indicates the lower net sales is influenced by lesser orders
-- South region has lowest AOV while having the highest sales

SELECT region,COUNT(order_id) AS total_orders,ROUND(SUM(net_sales_usd)/COUNT(order_id),2) AS net_aov
FROM sales_analysis
WHERE order_status='Completed'
GROUP BY region
ORDER BY net_aov DESC;

-- 6. Sales Channel Analysis

-- Mobile App is the biggest contibutor across sales, profit, orders and customers but the profit margin is same in each sales channel

SELECT sales_channel, ROUND(SUM(net_sales_usd),2) as total_sales, ROUND(SUM(profit_usd),2) as total_profit,
ROUND((SUM(profit_usd)/SUM(net_sales_usd)) * 100 ,2) as profit_margin_percentage,
COUNT(order_id) as total_orders, COUNT(DISTINCT customer_id) as total_customers
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY sales_channel
ORDER BY total_sales;

-- social media contributes lowest to sales, profit, orders and customers but has relatively high AOV and the highest profit 
SELECT sales_channel , COUNT(order_id) AS total_orders, ROUND(SUM(net_sales_usd)/COUNT(order_id),2) AS net_aov
FROM  sales_analysis
WHERE order_status = 'Completed'
GROUP BY sales_channel
ORDER BY net_aov;

-- 7. Customer Segment Analysis

-- Consumer segment of customers dominates across sales, profit, profit margin, oders and customers
-- Business segment is the lowest contributor but has similar profit margin to Consumer

SELECT customer_segment, ROUND(SUM(net_sales_usd),2) as total_sales, ROUND(SUM(profit_usd),2) as total_profit,
ROUND((SUM(profit_usd)/SUM(net_sales_usd)) * 100 ,2) as profit_margin_percentage,
COUNT(order_id) as total_orders, COUNT(DISTINCT customer_id) as total_customers
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY customer_segment
ORDER BY total_sales DESC;

-- Premium and VIP customers generates lower profit margin as compared to their higher sales while having nearly same AOV as rest

SELECT customer_segment , COUNT(order_id) AS total_orders, ROUND(SUM(net_sales_usd)/COUNT(order_id),2) AS net_aov
FROM  sales_analysis
WHERE order_status = 'Completed'
GROUP BY customer_segment
ORDER BY net_aov;


-- 8. PRICING vs DISCOUNT ANALYSIS

-- a) Discount rate vs Sales & Profit Margin
-- The disocunt rate was around 33% in Nov and Dec, the high sales months
-- Higher discount rates coincide with lower profit margins

SELECT `Year_Month`,ROUND(SUM(net_sales_usd),2) AS total_net_sales,ROUND(SUM(profit_usd),2) AS total_profit,ROUND(SUM(discount_amount_usd)/SUM(gross_sales_usd)*100,2) AS discount_rate,ROUND(SUM(profit_usd)/SUM(net_sales_usd)*100,2) AS profit_margin_percentage
FROM sales_analysis
WHERE order_status='Completed'
GROUP BY `Year_Month`
ORDER BY discount_rate DESC;

-- c) Correalation between discount rate and monthly profit margin percentage

-- monthly discount rate and profit margin have a correalation of -0.977 which indicates strong negative relationship between two


WITH monthly AS (SELECT `Year_Month`,SUM(discount_amount_usd) /SUM(gross_sales_usd) * 100 AS monthly_discount_rate,
SUM(profit_usd) /SUM(net_sales_usd) * 100 AS monthly_profit_margin
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY `Year_Month`
)

SELECT
ROUND((COUNT(*) * SUM(monthly_discount_rate * monthly_profit_margin) - SUM(monthly_discount_rate) * SUM(monthly_profit_margin))
/
SQRT((COUNT(*) * SUM(monthly_discount_rate * monthly_discount_rate) - POW(SUM(monthly_discount_rate), 2))
*
(COUNT(*) * SUM(monthly_profit_margin * monthly_profit_margin) - POW(SUM(monthly_profit_margin), 2))),3) AS discount_margin_correlation
FROM monthly;

-- c) Dicount rate vs Profit margin among customer segments

-- VIP and Premium segments had higher discount rate and lower profit margin than Business and Consumer customers
-- This indicates that higher discounts might be one of the reasons for lower profitability

SELECT customer_segment, ROUND(SUM(net_sales_usd),2) as total_sales, ROUND(SUM(profit_usd),2) as total_profit, ROUND(SUM(discount_amount_usd)/SUM(gross_sales_usd)*100,2) AS discount_rate, ROUND((SUM(profit_usd)/SUM(net_sales_usd)) * 100 ,2) as profit_margin_percentage
FROM sales_analysis
WHERE order_status = 'Completed'
GROUP BY customer_segment
ORDER BY discount_rate DESC;

-- 9) Customer Behaviour

-- a) average orders per customers

select ROUND(COUNT(order_id)/COUNT(DISTINCT customer_id),2) as avg_order_per_cust
from sales_analysis
where order_status = 'Completed';

-- b) what percent of total customers that placed an order are repeat and one time

-- 95.04% of customers placed more than one completed order while 4.96% of customers placed only one order
-- this indicates high repeat share in purchases

WITH customer_orders AS (SELECT customer_id,COUNT(order_id) AS order_count FROM sales_analysis WHERE order_status='Completed' GROUP BY customer_id)
SELECT CASE WHEN order_count=1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,COUNT(*) AS total_customers,ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM customer_orders),2) AS customer_percentage
FROM customer_orders
GROUP BY customer_type;

-- c) How many completed orders and net sales do the repeat customers contribute to as compared with one-time customers?

-- Repeat customers account for 98.95% of net sales, compared with 95.04% of customers.

WITH customer_orders AS (SELECT customer_id,COUNT(order_id) AS order_count,SUM(net_sales_usd) AS customer_sales FROM sales_analysis WHERE order_status='Completed' GROUP BY customer_id)
SELECT CASE WHEN order_count=1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,COUNT(*) AS total_customers,SUM(order_count) AS total_orders,ROUND(SUM(customer_sales),2) AS total_net_sales,ROUND(SUM(customer_sales)*100.0/(SELECT SUM(customer_sales) FROM customer_orders),2) AS sales_percentage
FROM customer_orders
GROUP BY customer_type;

-- d) avg net sales per customer by repeat status?

-- each repeat customer has a average cumulative net sales of $5,835.73 while one-time customer has $1,187.55.

WITH customer_orders AS (SELECT customer_id,COUNT(order_id) AS order_count,SUM(net_sales_usd) AS customer_sales FROM sales_analysis WHERE order_status='Completed' GROUP BY customer_id)
SELECT CASE WHEN order_count=1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,COUNT(*) AS total_customers,ROUND(SUM(customer_sales),2) AS total_net_sales,ROUND(AVG(customer_sales),2) AS avg_net_sales_per_customer
FROM customer_orders
GROUP BY customer_type;

-- e) avg net sales per customer by customer segments?

-- The difference between avg sales per customer between the highest and lowest segment is around 2.9%
-- this indicates there isnt any major differences between segments

SELECT customer_segment,COUNT(DISTINCT customer_id) AS total_customers,ROUND(SUM(net_sales_usd),2) AS total_net_sales,ROUND(SUM(net_sales_usd)/COUNT(DISTINCT customer_id),2) AS avg_net_sales_per_customer,ROUND(SUM(profit_usd)/COUNT(DISTINCT customer_id),2) AS avg_profit_per_customer
FROM sales_analysis
WHERE order_status='Completed'
GROUP BY customer_segment
ORDER BY avg_net_sales_per_customer DESC;

-- 9) Order Status Analysis

-- a) how much percentage does each order status takes of the total records

-- 82.22% of order records are completed, while 17.78% are returned, cancelled, or pending.

SELECT order_status,COUNT(*) AS total_orders,ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM sales_analysis),2) AS order_percentage
FROM sales_analysis
GROUP BY order_status
ORDER BY total_orders DESC;

-- b) net sales and profit by order status

SELECT order_status, ROUND(SUM(net_sales_usd),2) AS recorded_net_sales, ROUND(SUM(profit_usd),2) AS recorded_profit
FROM sales_analysis
GROUP BY order_status
ORDER BY recorded_net_sales DESC;

-- 11) FINAL INSIGHTS

-- a) Sales shows seasonality:
-- Sales in November and December are consistently the highest each year while January and February reports the lower sales each year.
-- Sales rise sharply in the month of November every year but the profitablity sees only slight change
-- Suggestion: Evaluating pricing, discounting and product costs during peak season so profit margin increases more in November and December

-- b) Higher Discounting is followed by lower profit margin:
-- Monthly discount rate and profit margin have a strong negative
-- correlation (Pearson r = -0.977).
-- Correlation does not establish causation.

-- c) Regional performance:
-- South has the highest total sales (about $40.83M), while North has the highest profit margin (45.48%) despite having the lowest regional sales.

-- d) Mobile App is the largest sales channel:
-- Mobile App contributes $55.25M of net sales and has highest order count but the profit margin across all sales channel is nearly 41%

-- e) Repeat customers contribute nearly all net sales
-- Repeat customers account for 95.04% of customers and 98.95% of net sales

-- f) Customer segments:
-- Consumer has the highest average net sales and profit per customer.
-- Average net sales per customer are relatively similar across segments.

-- g) Order status:
-- 82.22% of records are completed; 17.78% are returned, cancelled, or pending.
