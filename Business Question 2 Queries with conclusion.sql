-- Use database to work upon.
USE Swiftcart;

SELECT * FROM clean_customer_profile LIMIT 10;

SELECT * FROM clean_transactions LIMIT 10;

SELECT * FROM clean_event_log LIMIT 10;

SELECT * FROM clean_cart_abandonment LIMIT 10;


/*
Question:
	How does the user’s device affect their likelihood to abandon the cart? What could be the potential reasons with devices affecting user engagement?
*/

/*
Different devices Pros/Cons:
	o Access of Navigation
    o More Engagement
    o Access of connectivity 
    o Visibility size
    
Hypothesis:
	o Mobile users are more growing on the platform than other devices.
	o Users who prefer mobile device for shopping are spending more time on platform than other devices and abandon the cart.
		Sub-Question:
			o What are the reasons occurring while shopping and how devices are effecting user engagement with same issues?
*/

## Q. Are mobile users more growing on the platform then other devices?

## Before jumping to the final verdict of the question. We need to verify how many users do prefer mobile devices and other devices for shopping?

WITH devices AS (
SELECT 
	preferred_device,
    COUNT(1) AS no_users,
	COUNT(1)/SUM(COUNT(1)) OVER()*100 AS users_percentage
FROM clean_customer_profile
WHERE YEAR(signup_date) = 2024
GROUP BY preferred_device )

SELECT 
	preferred_device,
    no_users,
	users_percentage
FROM devices
ORDER BY no_users DESC;

## Monthly and yearly different devices trend over the time.
WITH devices AS (
SELECT 	
	DATE_FORMAT(signup_date, '%m-%Y') AS month_year,
    preferred_device,
    COUNT(1) AS cnt
FROM clean_customer_profile
WHERE YEAR(signup_date) < 2025
GROUP BY DATE_FORMAT(signup_date, '%m-%Y'), preferred_device) 

SELECT 
	month_year,
    SUM(CASE WHEN preferred_device = 'Mobile' THEN cnt END) AS mobile,
    SUM(CASE WHEN preferred_device = 'Desktop' THEN cnt END) AS desktop,
    SUM(CASE WHEN preferred_device = 'Tablet' THEN cnt END) AS tablet
FROM devices
GROUP BY month_year
ORDER BY CASE WHEN RIGHT(month_year,4) = '2023' THEN 0 ELSE 1 END, month_year;


## Weekly trends
WITH devices AS (
SELECT 	
	WEEKOFYEAR(signup_date) AS weekly,
    preferred_device,
    COUNT(1) AS cnt
FROM clean_customer_profile
WHERE YEAR(signup_date) < 2025
GROUP BY WEEKOFYEAR(signup_date), preferred_device )

SELECT
	weekly,
	SUM(CASE WHEN preferred_device = 'Mobile' THEN cnt END) AS mobiles,
    SUM(CASE WHEN preferred_device = 'Desktop' THEN cnt END) AS desktops,
    SUM(CASE WHEN preferred_device = 'Tablet' THEN cnt END) AS tablets
FROM devices
GROUP BY weekly
ORDER BY weekly;

/*
Conclusion:

	o Device preference percentage:
		Sub-Points:
				o Mobile users are preferring around 49% for shopping and it's obvious in this M-commerce (Mobile-Commerce).
				o Desktop is competing with mobile users for preferred devices. Moreover, the least preferred device is tablet and hardly used for shopping.
				o Both Mobile and Desktop users more than 80%.
    
    o Monthly and Weekly Trend:
		Sub-Points:
				o Over the month tablet users have not event touched 100 counts in a single month in 2023-24
				o Mobile and Desktop are constantly growing and fluctuate in few months. However, users are more likely prefer mobile devices for shopping.
				o Weekly trend has the similar story. However, in last 2 months (Nov 24, Dec 24). Mobile users are growing exponentially along with desktop.
*/

## Q. Do Users, who prefer mobile device for shopping are spending more time on platform than other devices and abandon the cart?

WITH abandon_customers AS (
SELECT 
	customer_id,
    device_type,
    session_start
FROM clean_cart_abandonment ca
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id) )

, sessions AS (
SELECT 
	customer_id,
    MAX(event_timestamp) AS max_session
FROM clean_event_log
GROUP BY customer_id )

, devices AS (
SELECT 
    ac.customer_id,
    ac.device_type,
    CASE 
		WHEN TIMESTAMPDIFF(MINUTE, ac.session_start, s.max_session) BETWEEN 0 AND 10 THEN '1-10 Min'
        WHEN TIMESTAMPDIFF(MINUTE, ac.session_start, s.max_session) BETWEEN 11 AND 20 THEN '10-20 Min'
        WHEN TIMESTAMPDIFF(MINUTE, ac.session_start, s.max_session) BETWEEN 21 AND 30 THEN '20-30 Min'
        ELSE '30+ Min'
	END AS session_duration
FROM abandon_customers ac
JOIN sessions s ON ac.customer_id = s.customer_id )

SELECT 
    session_duration,
	device_type,
    COUNT(1) AS cnt
FROM devices
GROUP BY device_type, session_duration
ORDER BY device_type, session_duration;

/*
Conclusion:
	o Mobile and Desktop both devices are preferred for shopping, which does not provide any uniqueness and exponential growth rate.
    o Tablet users as always spend less number of log in on platform.
    o Up to 20-30 Mins spending time with Mobile and Desktop devices reflect getting less engage when time ups. However mobile users are having 
		48% engagement up to 30 mins and desktop users are having 40% engagement, along with 10% tablet users.
*/


## Q. What potential 3 reasons which create friction while shopping and engage less customers on platform?

WITH abandon_reasons AS (
SELECT 
	device_type, 
    reason_for_abandonment,
    COUNT(1) AS no_cnt,
    ROUND(COUNT(1)/SUM(COUNT(1)) OVER(PARTITION BY device_type)*100,2) AS percentage
FROM clean_cart_abandonment ca
WHERE NOT EXISTS (SELECT 1 FROM clean_transactions ct WHERE ca.customer_id = ct.customer_id)
GROUP BY device_type, reason_for_abandonment )

SELECT 
	device_type,
    reason_for_abandonment,
    no_cnt,
    percentage
FROM (
SELECT 
	device_type,
    reason_for_abandonment,
    no_cnt,
    percentage,
    ROW_NUMBER() OVER(PARTITION BY device_type ORDER BY no_cnt DESC) AS rn
FROM abandon_reasons ) t
WHERE rn <= 3;

/*
Conclusion:
	o 3 Major reasons are blocking cart items converting into order. (High Shipping Cost, No Guest Checkout, Change Mind).
	o High Shipping Cost and No Guest Checkout are not likely affected by devices. However, Change mind might cause of different devices.
	o 26.7% Users have change mind reason following other reasons. 
*/


























































































