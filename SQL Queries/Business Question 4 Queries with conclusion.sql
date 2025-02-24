-- Use database to work upon.
USE Swiftcart;

SELECT * FROM clean_customer_profile LIMIT 10;

SELECT * FROM clean_transactions LIMIT 10;

SELECT * FROM clean_event_log LIMIT 10;

SELECT * FROM clean_cart_abandonment LIMIT 10;

/*
Question:
	Are there specific user segments or demographics that exhibit higher abandonment rates?
*/

## Q. Does any specific region play a crucial role in abandonment rate?

WITH cte AS (
SELECT 
	ca.customer_id,
    ct.customer_id AS trans_customer,
    ca.shipping_region
FROM clean_cart_abandonment ca
LEFT JOIN clean_transactions ct ON ca.customer_id = ct.customer_id )

SELECT 
	shipping_region,
    COUNT(customer_id) AS abandonment_count,
    COUNT(customer_id)/SUM(COUNT(customer_id)) OVER()*100 AS total_percent,
	ROUND( (SUM(CASE WHEN trans_customer IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS conversion_rate,
	ROUND( (SUM(CASE WHEN trans_customer IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS abandonment_rate
FROM cte
GROUP BY shipping_region
ORDER BY abandonment_count DESC;


/*
Conclusion:
	o 80% Abandonment rate are coming from major 3 regions with more than 4,500 abandonment cases. North America, Europe, Asia. 
    o (2,519) Number of abandonment count are more high solely in North America with 40% users, which creates a major gap to cater users on the platform.
*/

## Customer - Tier analysis

SELECT 
	cp.customer_tier,
    COUNT(1) AS cnt
FROM clean_cart_abandonment ca
JOIN clean_customer_profile cp ON ca.customer_id = cp.customer_id
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
GROUP BY cp.customer_tier
ORDER BY cnt DESC;

## Customer - Tenure analysis

SELECT 
	cp.customer_tenure,
    COUNT(1) AS cnt,
    COUNT(1)/SUM(COUNT(1)) OVER()*100 AS percentage
FROM clean_cart_abandonment ca
JOIN clean_customer_profile cp ON ca.customer_id = cp.customer_id
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
AND cp.customer_tier = 'Existing'
GROUP BY cp.customer_tenure
ORDER BY cnt DESC;

/*
Conclusion:
	o Abandoned rate is affected from 73% Existing users following with new users.
    o As the users get existed and tenured. The abandonment rate is getting increase and 6-12 months existed users are 66% abandonment rate.
*/
