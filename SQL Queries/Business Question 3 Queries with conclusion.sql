-- Use database to work upon.
USE Swiftcart;

SELECT * FROM clean_customer_profile LIMIT 10;

SELECT * FROM clean_transactions LIMIT 10;

SELECT * FROM clean_event_log LIMIT 10;

SELECT * FROM clean_cart_abandonment LIMIT 10;


/*
Question:
	What is the impact of applied discounts and shipping costs on the decision to complete a purchase?
*/

/*
Hypothesis:
	o Less applied discounts leads less conversion rate.
	o Shipping cost are high due to unavailable discount at the moment for engaging users.
*/

## Q. Does less available discounts affect conversion rate and increase abandonment rate?

SELECT 
  discount_applied,
  COUNT(*) AS total_sessions,
  SUM(CASE WHEN abandoned_checkout = 'TRUE' THEN 1 ELSE 0 END) AS converted_sessions,
  SUM(CASE WHEN abandoned_checkout = 'FALSE' THEN 1 ELSE 0 END) AS abandoned_sessions,
  ROUND( (SUM(CASE WHEN abandoned_checkout = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS conversion_rate,
  ROUND( (SUM(CASE WHEN abandoned_checkout = 'FALSE' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS abandonment_rate
FROM clean_cart_abandonment
GROUP BY discount_applied;


/*
Conclusion:
	o Users with abandonment rate 27.8% without discounts is more than as compare to discount availability 12.5%.
    o Conversion Rate is 87.4% successful with discounts availability.
    
Hypothesis is true, where discounts are not available, leads to increase abandonment rate as compare with discount availability.
*/

## Q. Does available discount help reducing shipping cost in different region?

SELECT 
	shipping_region,
    COUNT(1) AS no_reasons,
    COUNT(1)/SUM(COUNT(1)) OVER()*100 AS percentage
FROM clean_cart_abandonment
WHERE reason_for_abandonment = 'High Shipping Cost' AND discount_applied = 'TRUE'
GROUP BY shipping_region
ORDER BY no_reasons DESC;

SELECT 
	shipping_region,
    COUNT(1) AS no_reasons,
    COUNT(1)/SUM(COUNT(1)) OVER()*100 AS percentage
FROM clean_cart_abandonment
WHERE reason_for_abandonment = 'High Shipping Cost' AND discount_applied = 'FALSE'
GROUP BY shipping_region
ORDER BY no_reasons DESC;

/*
Conclusion:
	o 2 Out of 6 regions are having issue in despite of discount availability.
    o 3 Out of 6 regions are having "High Shipping Cost" issue due to unavailability of discounts.
    o North America is the common region in both discount "Availability/Unavailability" following with Europe and Asia. However, Apart from north america, europe
		and asia regions are varying counts.
	o Majorly High Shipping cost cases are coming from North America region.
*/

## Q. Identify the bundle discount affect on conversion rate and abandonment rate? How is it correlated? 
WITH items AS (
SELECT 
	ca.customer_id,
    ct.customer_id AS trans_customer,
	CASE WHEN ca.number_of_items BETWEEN 1 AND 4 THEN 'Up to 4 items'
		ELSE 'More than 4 items'
    END AS items_category,
    abandoned_checkout,
    discount_applied
FROM clean_cart_abandonment ca
LEFT JOIN clean_transactions ct ON ca.customer_id = ct.customer_id )

SELECT 
	items_category,
	COUNT(*) AS total_sessions,
	SUM(CASE WHEN trans_customer IS NULL THEN 1 ELSE 0 END) AS converted_sessions,
	SUM(CASE WHEN trans_customer IS NOT NULL THEN 1 ELSE 0 END) AS abandoned_sessions,
	ROUND( (SUM(CASE WHEN trans_customer IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS conversion_rate,
	ROUND( (SUM(CASE WHEN trans_customer IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS abandonment_rate
FROM items
GROUP BY items_category
ORDER BY items_category DESC;

/*
Conclusion:
	o The discounts are majorly applied up to 4 products. More than 4 products are not guaranteed to have discounts.
    o Where discounts are not available the abandonment rate are high in both item categories. However, most sessions happened for 
		up to 4 items (5,306 Sessions) with 75% Conversion rate.
*/

