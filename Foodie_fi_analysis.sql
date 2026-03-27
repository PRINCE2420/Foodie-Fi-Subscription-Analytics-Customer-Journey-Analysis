use dbo;
SELECT * FROM plans;
SELECT * FROM subscriptions;

#How many customers has Foodie-Fi ever had?

SELECT count(DISTINCT customer_id) from subscriptions;

#What is the monthly distribution of trial plan start_date values for our dataset? — Use the start of the month as the group by value

SElECT date_format(s.start_date, '%Y-%m-01') AS month_start,
count(*) AS trial_count
FROM subscriptions s
JOIN plans p 
  ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY date_format(s.start_date, '%Y-%m-01')
ORDER BY month_start;

# What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.

SELECT p.plan_name,COUNT(*) AS num_of_events
FROM subscriptions AS s 
JOIN plans AS p 
ON s.plan_id = p.plan_id
WHERE s.start_date > '2020-12-31'
GROUP BY p.plan_name ;

# What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT COUNT(distinct s.customer_id) AS customer_count, 
ROUND(COUNT(DISTINCT s.customer_id)*100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)  , 1) AS customer_percent
FROM subscriptions AS s
JOIN plans AS p 
ON s.plan_id = p.plan_id
WHERE plan_name = 'churn' ;

# How many customers have churned straight after their initial free trial? — what percentage is this rounded to the nearest whole number?

WITH ranked_plans AS (SELECT s.customer_id, p.plan_name, s.start_date,
LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id)

SELECT COUNT(DISTINCT customer_id) AS churn_after_trial,
ROUND(COUNT(DISTINCT customer_id) * 100.0 /(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),0) AS percentage
FROM ranked_plans
WHERE plan_name = 'trial'
AND next_plan = 'churn';

# What is the number and percentage of customer plans after their initial free trial?

WITH ranked_plans AS (SELECT s.customer_id, p.plan_name, s.start_date,
LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id)

SELECT next_plan , COUNT(DISTINCT customer_id) AS customer_count,
ROUND(COUNT(DISTINCT customer_id) * 100.0 /(SELECT COUNT(DISTINCT customer_id) FROM subscriptions as s 
JOIN plans p 
ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'),1) AS percentage
FROM ranked_plansTables
WHERE plan_name = 'trial'
GROUP BY next_plan
ORDER BY customer_count DESC;


#How many customers have upgraded to an annual plan in 2020?

SELECT COUNT(DISTINCT s.customer_id) AS annual_upgrades
FROM subscriptions s
JOIN plans p ON
s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual'
AND YEAR(s.start_date) = 2020;

#How many days on average does it take a customer to an annual plan from the day they join Foodie-Fi?

WITH journey AS (SELECT s.customer_id,MIN(CASE WHEN p.plan_name = 'trial' THEN s.start_date END) AS trial_date,
MIN(CASE WHEN p.plan_name = 'pro annual' THEN s.start_date END) AS annual_date
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id
GROUP BY s.customer_id)
SELECT ROUND(AVG(DATEDIFF(annual_date, trial_date)),1) AS avg_days_to_annual
FROM journey
WHERE annual_date IS NOT NULL;

#How many customers downgraded from a pro-monthly to a basic monthly plan in 2020?

WITH ranked_plans AS (SELECT s.customer_id,p.plan_name,s.start_date,
LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan,
LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id)
SELECT COUNT(DISTINCT customer_id) AS downgrade_count
FROM ranked_plans
WHERE plan_name = 'pro monthly'
AND next_plan = 'basic monthly'
AND YEAR(next_date) = 2020;
















