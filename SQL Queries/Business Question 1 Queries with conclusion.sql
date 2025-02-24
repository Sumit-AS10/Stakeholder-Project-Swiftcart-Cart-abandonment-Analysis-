
-- Use database to work upon.
USE Swiftcart;


/*
Question: 
	What are the critical drop-off points in the checkout process, and at what stage do most
    customers abandon their cart?
*/

/*
Potential causes:
	o Payment Failure
    o Limited Payment Options
    o High Shipping Cost
    o Delay Deliveries
    o Price Comparison
    o Unclear Product Description
    o Unclear Return & Refund Policies.

Hypothesis:
	o Longer time on platform, create friction to left the platform without making the purchase. (Longer time on platform = Less Engagement).
		Sub-Question:
			o Are equal number of customers proceeding for checkout or left the platform without checkout?
    o More time spend during checkout process, leads to create less chances to convert cart item into purchase.
*/

## Q. Longer time on platform, create friction to left the platform without making the purchase. (Longer time on platform = Less Engagement).

WITH cart_abandoned AS (
SELECT 
	customer_id,
    discount_count,
    number_of_items,
    abandoned_checkout,
    checkout_attempted,
    reason_for_abandonment,
    discount_applied,
    session_start
FROM clean_cart_abandonment ca
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id) )

, sessions AS (
SELECT 
	ca.*,
	cel.event_type,
    cel.s_no,
    TIMESTAMPDIFF(MINUTE, ca.session_start, MAX(cel.event_timestamp) OVER(PARTITION BY cel.customer_id)) AS session_duration
FROM cart_abandoned ca
JOIN clean_event_log cel ON ca.customer_id = cel.customer_id )

, session_cte AS (
SELECT 
	customer_id,
CASE WHEN session_duration BETWEEN 0 AND 9 THEN '0-10 Min'
    WHEN session_duration BETWEEN 10 AND 20 THEN '10-20 Min'
    WHEN session_duration BETWEEN 20 AND 30 THEN '20-30 Min'
    ELSE '30 Min+'
END AS session_category
FROM sessions )

SELECT session_category,
COUNT(DISTINCT customer_id) AS no_of_users,
COUNT(DISTINCT customer_id)/SUM(COUNT(DISTINCT customer_id)) OVER()*100 AS percentage
FROM session_cte
GROUP BY session_category
ORDER BY 3 DESC;

/*
Conclusion: 
	87% customers spending the time on platform up to 30 mins and still did not make any order. 
    Within 10 minutes buckets, 3 categories have more than 25% abandonment rate.
    
The hypothesis is correct, the long time spend on platform cause customer dissatisfaction and abandonment cart rate.
*/

## Q. Are equal number of customers proceeding for checkout or left the platform without checkout?

SELECT 
	checkout_attempted,
	COUNT(1) AS no_of_users
FROM clean_cart_abandonment ca
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
GROUP BY checkout_attempted;

/*
Conclusion:-
	o 3,162 users proceed for checkout and 1,485 users did not and left the cart abandonment.
    o What all the potential issues in before checkout and after checkout process?
*/


## Q. More time spend during checkout process, leads to create less chances to convert cart item into purchase.

WITH cart_abandoned AS (
SELECT 
	customer_id,
    session_start
FROM clean_cart_abandonment ca
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
AND checkout_attempted = 'TRUE' ) ## Users, who attempted the checkout

, checkouts AS (
SELECT 
	ca.*,
	cel.event_type,
    cel.s_no,
    TIMESTAMPDIFF(MINUTE, MIN(cel.event_timestamp) OVER(PARTITION BY cel.customer_id), MAX(cel.event_timestamp) OVER(PARTITION BY cel.customer_id)) AS checkout_duration
FROM cart_abandoned ca
JOIN clean_event_log cel ON ca.customer_id = cel.customer_id
WHERE cel.s_no BETWEEN 4 AND 6 ) ## Pages between checkout attempted and Purchase complete/Incomplete.

, checkout_cte AS (
SELECT 
	customer_id,
CASE
	WHEN checkout_duration BETWEEN 0 AND 4 THEN '0-5 Min'
	ELSE '5 Min+'
END AS checkout_category
FROM checkouts )

SELECT checkout_category,
COUNT(DISTINCT customer_id) AS no_of_users,
COUNT(DISTINCT customer_id)/SUM(COUNT(DISTINCT customer_id)) OVER()*100 AS percentage
FROM checkout_cte
GROUP BY checkout_category
ORDER BY 3 DESC;

/*
Conclusion:
	The Hypothesis are correct. 83.3%, (2.4K) users are spending time during checkout, 
    which is not beneficial for us and it leads to improve manual efforts from customer side to fill up the details.
*/



## Q. Reasons behind left the cart after spending long time during checkout process.

WITH cart_abandoned AS (
SELECT 
	customer_id,
    reason_for_abandonment,
    session_start
FROM clean_cart_abandonment ca
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
AND checkout_attempted = 'TRUE' ) ## Users, who proceed for checkout.

, checkouts AS (
SELECT 
	ca.*,
	cel.event_type,
    TIMESTAMPDIFF(MINUTE, MIN(cel.event_timestamp) OVER(PARTITION BY cel.customer_id), MAX(cel.event_timestamp) OVER(PARTITION BY cel.customer_id)) AS session_duration,
    TIMESTAMPDIFF(MINUTE, MIN(cel.event_timestamp) OVER(PARTITION BY cel.customer_id), MAX(cel.event_timestamp) OVER(PARTITION BY cel.customer_id)) AS checkout_duration
FROM cart_abandoned ca
JOIN clean_event_log cel ON ca.customer_id = cel.customer_id )

SELECT 
	reason_for_abandonment,
    COUNT(DISTINCT customer_id) AS no_of_users,
    COUNT(DISTINCT customer_id)/SUM(COUNT(DISTINCT customer_id)) OVER()*100 AS percentage
FROM checkouts
WHERE session_duration <= 30 AND checkout_duration < 5 ## Users, who spend up to 30 mins on platform and up to 5 mins during checkout.
GROUP BY reason_for_abandonment
ORDER BY 3 DESC;

/*
Conclusion:
	93.3% issues are occurring during checkout of 312 customers from 
    (Payment Issues, No Guest Checkout, High Shipping Costs).

	3 Reasons are more than 20% during checkout.

	High Shipping Costs = 34.7% (116)
	No Guest Checkout = 34.1% (114)
	Payment Issues = 24.5% (82)

	First two issues combine more than 68.8% during the checkout.

*/


## Q. Do users spending more time before adding items in the cart? From which stage does friction create between users and platform?

WITH tmp_abandoned AS (
  SELECT customer_id
  FROM clean_cart_abandonment ca
  WHERE NOT EXISTS ( SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
  AND checkout_attempted = 'FALSE' )
  
, checkouts AS (
SELECT 
	cel.customer_id,
	cel.event_type,
    cel.event_timestamp,
    TIMESTAMPDIFF(MINUTE, MIN(cel.event_timestamp) OVER(PARTITION BY cel.customer_id), MAX(cel.event_timestamp) OVER(PARTITION BY cel.customer_id)) AS session_duration
FROM tmp_abandoned ca
JOIN clean_event_log cel ON ca.customer_id = cel.customer_id )

, tmp_funnel AS (
SELECT 
    customer_id,
    MIN(CASE WHEN event_type = 'session_start' THEN event_timestamp END) AS session_time,
    MIN(CASE WHEN event_type = 'page_view' THEN event_timestamp END) AS page_view,
    MIN(CASE WHEN event_type = 'add_to_cart' THEN event_timestamp END) AS cart_time,
    MIN(CASE WHEN event_type = 'page_description' THEN event_timestamp END) AS page_description,
    MIN(CASE WHEN event_type = 'review_check' THEN event_timestamp END) AS review_time,
    MIN(CASE WHEN event_type = 'product_availability' THEN event_timestamp END) AS product_availability,
    MIN(CASE WHEN event_type = 'recommend_page' THEN event_timestamp END) AS recommend_time
FROM checkouts
WHERE session_duration <= 30 ## Users, who spent up to 30 mins on platform and abandoned the cart.
GROUP BY customer_id )

, tmp_funnel_summary AS (
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN session_time IS NOT NULL THEN 1 ELSE 0 END) AS session_start,
    SUM(CASE WHEN page_view IS NOT NULL THEN 1 ELSE 0 END) AS page_view,
    SUM(CASE WHEN cart_time IS NOT NULL THEN 1 ELSE 0 END) AS add_to_cart,
    SUM(CASE WHEN page_description IS NOT NULL THEN 1 ELSE 0 END) AS page_description,
    SUM(CASE WHEN review_time IS NOT NULL THEN 1 ELSE 0 END) AS review_check,
    SUM(CASE WHEN product_availability IS NOT NULL THEN 1 ELSE 0 END) AS product_availability,
    SUM(CASE WHEN recommend_time IS NOT NULL THEN 1 ELSE 0 END) AS recommend_page
FROM tmp_funnel )

SELECT event_type, no_of_users, drop_off_percentage_change
FROM (
  -- Stage 1: session_start (base stage; no previous stage to compare)
  SELECT 
    'session_start' AS event_type, 
    total_customers AS no_of_users, 
    '0.00%' AS drop_off_percentage_change
  FROM tmp_funnel_summary  
UNION ALL
  -- Stage 2: page_view drop-off from session_start
  SELECT 
    'page_view' AS event_type, 
    page_view AS count, 
    CONCAT(ROUND(((total_customers - page_view) / total_customers) * 100, 2), '%') AS percentage_change
  FROM tmp_funnel_summary
UNION ALL  
  -- Stage 3: add_to_cart drop-off from page_view
  SELECT 
    'add_to_cart' AS event_type, 
    add_to_cart AS count, 
    CONCAT(ROUND(((page_view - add_to_cart) / page_view) * 100, 2), '%') AS percentage_change
  FROM tmp_funnel_summary
UNION ALL  
  -- Stage 4: page_description drop-off from add_to_cart
  SELECT 
    'page_description' AS event_type, 
    page_description AS count, 
    CONCAT(ROUND(((add_to_cart - page_description) / add_to_cart) * 100, 2), '%') AS percentage_change
  FROM tmp_funnel_summary
UNION ALL  
  -- Stage 5: review_check drop-off from page_description
  SELECT 
    'review_check' AS event_type, 
    review_check AS count, 
    CONCAT(ROUND(((page_description - review_check) / page_description) * 100, 2), '%') AS percentage_change
  FROM tmp_funnel_summary
UNION ALL  
  -- Stage 6: product_availability drop-off from review_check
  SELECT 
    'product_availability' AS event_type, 
    product_availability AS count, 
    CONCAT(ROUND(((review_check - product_availability) / review_check) * 100, 2), '%') AS percentage_change
  FROM tmp_funnel_summary
UNION ALL  
  -- Stage 7: recommend_page drop-off from product_availability
  SELECT 
    'recommend_page' AS event_type, 
    recommend_page AS count, 
    CONCAT(ROUND(((product_availability - recommend_page) / product_availability) * 100, 2), '%') AS percentage_change
  FROM tmp_funnel_summary ) t;

/*
Conclusion:
	From the Page Description stage, the drop-off rate is increasing significantly. At the page description 18.56% users are dropping after adding item in the cart.
    At the review section page the major drop-off rate is making the friction. 
Page Description might have unnecessary details with poorly designed and unappealing return & refund policies.
Or the product complete and comprehensive details are not accessing to the users easily, that build trust-issue and one of the reason to be turned out a complete purchase.

*/

## Q. What could be the reason behind to let the cart abandonment before proceeding checkout?
WITH cart_abandoned AS (
SELECT 
	customer_id,
    reason_for_abandonment,
    session_start
FROM clean_cart_abandonment ca
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
AND checkout_attempted = 'FALSE' ) ## Users, who did not attempt for checkout.

, checkouts AS (
SELECT 
	ca.*,
	cel.event_type,
    TIMESTAMPDIFF(MINUTE, MIN(cel.event_timestamp) OVER(PARTITION BY cel.customer_id), MAX(cel.event_timestamp) OVER(PARTITION BY cel.customer_id)) AS session_duration
FROM cart_abandoned ca
JOIN clean_event_log cel ON ca.customer_id = cel.customer_id )

SELECT 
	reason_for_abandonment,
    COUNT(DISTINCT customer_id) AS no_of_users,
    COUNT(DISTINCT customer_id)/SUM(COUNT(DISTINCT customer_id)) OVER()*100 AS percentage
FROM checkouts
WHERE session_duration <= 30
GROUP BY reason_for_abandonment
ORDER BY 3 DESC;

/*
Conclusion:
	91% issues are occurring from 2 main reasons behind abandoned the cart. (Change Mind, Total Order Value N/A). 
	Total 1,195 users are abandoning their cart without checkout. This could lead more revenue loss in future.
*/
