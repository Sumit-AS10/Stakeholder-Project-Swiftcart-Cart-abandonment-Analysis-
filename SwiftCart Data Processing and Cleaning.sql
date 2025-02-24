
-- Swift Cart Project

-- * Create new database.
CREATE DATABASE IF NOT EXISTS temp_swiftcart;

-- * Use existing database to work upon.
USE temp_swiftcart;

-- * Import the tables into the database through "Import Data Wizard"

/*
Now our tables are imported.
We do have 4 tables.

Transactions
Event_log
Cart_abandonment
Customer_profile
*/

/*
--** Transactions table column description: **--

order_id: Contain unique order id for each transaction
session_id: the unique session id for each transaction.
customer_id: The id refers to the customer, who made transaction and it establish the relationship with customer_profile, cart_abandonment and event_log table.
order_timestamp: It refers date on which the transaction was made.
total_price: The total order amount.
number_of_items: The number of items were purchased in each transaction.
payment_method: The method were used for transaction.
shipping_region: The region belongs to the transaction order.
device_type: Which device was used for the transaction.
order_status: It refers, whether the order was completed, failed, pending.
order_value_category: It is categorized based on the total order amount, eg: low, high, medium, premium.


--** Event_log table column description: **--

event_id: Shows unique event id for each event type while using the platform application or website.
session_id: It represent the session through out the user experience journey on the platform.
customer_id: The customer, who used the platform.
event_timestamp: Each event records the date and timestamp for each session. 
event_type: Each event type represent the page, where customer spend their time. 
device_type: Which device was used for the platform.
event_details: It explain the same details for the user during the session, from session started to complete the purchase.


--** Cart Abandonment table column description: **--

session_id: It refers each unique session id for cart before completing the purchase.
customer_id: The customer who add the cart in the cart before purchasing it.
device_type: The device was used during on the platform.
first_item_added: The date and timestamp, when the first item was added into the cart.
last_item_added: The date and timestamp, when last item was added into the cart.
time_spent_in_cart: The duration in minutes between first item and last item.
discount_count: The number category defines, how many times a customer applied discounts.
item_category: Name of the categories were added into the cart.
number_of_items: Number of items were added into the cart.
total_price: The cart value including all added items.
currency: The currency was used during the purchase.
shipping_region: The region belongs to the user location.
abandoned_checkout: It returns TRUE or FALSE boolean values, which shows whether customer left the cart abandoned or not before proceeding for checkout.
checkout_attempted: It returns TRUE or FALSE boolean values, which shows whether customer attempted in the payment section or not, just left the cart abandoned.
payment_method: The source of paying the order amount.
reason_for_abandonment: It tells the reasons to be abandoned the cart due to customer willing issues or platform glitches.
marketing_source: The source, through which customer was engaged to use the platform.


--** Customer profile table column description: **--

customer_id: It refers unique identify customer.
signup_date: The date on which customer singed up on the platform.
preferred_device: The device was used for the sign-up.
region: The customer belongs which region (Location).
preferred_marketing_source: The source of reaching out on the platform by the customer. 
*/

-- Data Cleaning and Processing:

-- Update the date datatype from "String" to "Date" using "STR_TO_DATE()" Function.
UPDATE Transactions
SET order_timestamp = 
	STR_TO_DATE(order_timestamp, '%d-%m-%Y %H:%i');


-- Rename the column "Event_Log" table.

ALTER TABLE event_log
RENAME COLUMN timestamp TO event_timestamp; -- Timestamp to event_timestamp. Because, in SQL Timestamp is a function as well. In order to avoid ambiguty.


-- Update the event_timestamp datatype "String" to "Data/Time" using "STR_TO_DATE()" Function.

UPDATE event_log
SET event_timestamp = 
	STR_TO_DATE(event_timestamp, '%d-%m-%Y %H:%i');
        
-- Update the first_item_added and last_item_added and session_start datatype "String" to "Date/Time" using "STR_TO_DATE()" Function.

UPDATE cart_abandonment
SET first_item_added = 
	STR_TO_DATE(first_item_added, '%d-%m-%Y %H:%i');

UPDATE cart_abandonment
SET last_item_added = 
	STR_TO_DATE(last_item_added, '%d-%m-%Y %H:%i');


UPDATE cart_abandonment
SET session_start = 
	STR_TO_DATE(session_start, '%d-%m-%Y %H:%i');
    
-- Update the signup_date datatype "String" to "Data/Time" using "STR_TO_DATE()" Function.
UPDATE customer_profile
SET signup_date = 
	STR_TO_DATE(signup_date, '%d-%m-%Y %H:%i');
    

-- Handling Missing Values

SELECT *
FROM Transactions
WHERE order_id IS NULL OR session_id IS NULL OR customer_id IS NULL
OR order_timestamp IS NULL OR total_price IS NULL OR number_of_items IS NULL
OR payment_method IS NULL OR shipping_region IS NULL OR device_type IS NULL 
OR order_value_category IS NULL;
-------- There is no NULL values in the Transaction table.


SELECT *
FROM cart_abandonment 
WHERE session_id IS NULL OR customer_id IS NULL OR device_type IS NULL
OR first_item_added IS NULL OR last_item_added IS NULL OR discount_count IS NULL
OR item_category IS NULL OR number_of_items IS NULL OR total_price IS NULL
OR shipping_region IS NULL OR abandoned_checkout IS NULL OR checkout_attempted IS NULL
OR payment_method IS NULL OR reason_for_abandonment IS NULL OR marketing_source IS NULL;
-------- There is no NULL values in the cart_abandonment table. However, I found few columns having Blank records instead of NULL.

SELECT *
FROM cart_abandonment 
WHERE session_id = '' OR customer_id = '' OR device_type = ''
OR first_item_added = '' OR last_item_added = '' OR discount_count = ''
OR item_category = '' OR number_of_items = '' OR total_price = ''
OR shipping_region = '' OR abandoned_checkout = '' OR checkout_attempted = ''
OR payment_method = '' OR reason_for_abandonment = '' OR marketing_source = '';

## 2 Columns (Payment_method & reason_for_abandonment) have "" Blank records. Despite having more than 20% records in the dataset.
## We will not remove it, insead of replace with "Not Available" for our further analysis and report to Data Engineering team to get fixed this blank records issue.

## Create a new temporary table called "cust" to filter out those customers, who made successful orders, the reason for abanaondment should be "No Reason"
## Otherwise, wherever the blank values without any complete purchasing "Not Available".
CREATE TEMPORARY TABLE cust
SELECT customer_id FROM Transactions;

UPDATE cart_abandonment c1
JOIN cust c2 ON c1.customer_id = c2.customer_id
SET c1.reason_for_abandonment = 'No Reason'
WHERE c1.reason_for_abandonment = '';


## Replace the "Not Available" values in the payment method, wherever the blank values.
UPDATE cart_abandonment
SET payment_method = 'Not Available'
WHERE payment_method = '';


-- Remove non-essential columns for reducing the table volume and maintain data accuracy.

-- Customer_profile table.

ALTER TABLE customer_profile
DROP COLUMN total_orders,
DROP COLUMN lifetime_value,
DROP COLUMN average_order_value,
DROP COLUMN preferred_payment_method;

-- Transactions table.

ALTER TABLE Transactions
DROP COLUMN order_status; -- The column contains only one value "Completed".

-- Cart_Abandonment table.

ALTER TABLE cart_abandonment
DROP COLUMN time_spent_in_cart,
DROP COLUMN currency;


-- EDA (Exploratory Data Analysis).

-- Descriptive Analysis.
-- Min(), Max(), Mean(), Median(), Mode().


## Transactions table.
SELECT MIN(total_price) AS min_price, -- Minimum price is 11.59, something is wrong?
MAX(total_price) AS max_price,
ROUND(AVG(total_price),2) AS avg_order_price,
MIN(number_of_items) AS min_no_items,
MAX(number_of_items) AS max_no_items
FROM Transactions;

-- Medium.

WITH cte AS (
SELECT total_price,
AVG(total_price) OVER() AS avg_price,
ROW_NUMBER() OVER(ORDER BY total_price) AS rn_asc,
ROW_NUMBER() OVER(ORDER BY total_price DESC) AS rn_desc
FROM Transactions )

SELECT DISTINCT avg_price,
total_price AS median_price
FROM cte
WHERE ABS(CAST(rn_asc AS DECIMAL) - CAST(rn_desc AS DECIMAL)) <= 1;

-- Mode

SELECT mode_price, frequency
FROM (
SELECT total_price AS mode_price, -- mode price is $29.47 and frequency is 3.
COUNT(1) AS frequency, 
ROW_NUMBER() OVER(ORDER BY COUNT(1) DESC) AS cnt
FROM Transactions
GROUP BY total_price ) a
WHERE cnt = 1;


## Let's find out minimum total price.

SELECT number_of_items, -- The number of quantity is 1. There are many categories which items price starting around $8.88 or more than that.
total_price
FROM Transactions
WHERE total_price = (SELECT MIN(total_price) FROM Transactions)
OR number_of_items = (SELECT MIN(number_of_items) FROM Transactions);

/*
Avg price is 167.41, whereas Median price is 141.92
*/

## Cart_abandonment table

SELECT MIN(TIMESTAMPDIFF(minute, first_item_added, last_item_added)) AS min_time_spent_in_minute,
MAX(TIMESTAMPDIFF(minute, first_item_added, last_item_added)) AS max_time_spent_in_minute, -- 173 minutes for cart. Something is wrong.
AVG(TIMESTAMPDIFF(minute, first_item_added, last_item_added)) AS avg_time_spend,
MIN(number_of_items) AS min_no_items,
MAX(number_of_items) AS max_no_items,
AVG(number_of_items) AS avg_no_items,
MIN(total_price) AS min_cart_price, -- minimum cart value might be fissy?
MAX(total_price) AS max_cart_price,
AVG(total_price) AS avg_cart_price
FROM cart_abandonment;

-- Median

SELECT AVG(time_spent_in_cart) AS median_time_spent,
AVG(number_of_items) AS median_number_items,
AVG(total_price) AS median_price
FROM (
SELECT TIMESTAMPDIFF(minute, first_item_added, last_item_added) AS time_spent_in_cart,
ROW_NUMBER() OVER(ORDER BY TIMESTAMPDIFF(minute, first_item_added, last_item_added)) AS ts_asc,
ROW_NUMBER() OVER(ORDER BY TIMESTAMPDIFF(minute, first_item_added, last_item_added) DESC) AS ts_desc,
number_of_items,
ROW_NUMBER() OVER(ORDER BY number_of_items) AS ni_asc,
ROW_NUMBER() OVER(ORDER BY number_of_items DESC) AS ni_desc,
total_price,
ROW_NUMBER() OVER(ORDER BY total_price) AS tp_asc,
ROW_NUMBER() OVER(ORDER BY total_price DESC) AS tp_desc
FROM cart_abandonment ) a
WHERE ABS(CAST(ts_asc AS DECIMAL) - CAST(ts_desc AS DECIMAL) ) <= 1
OR ABS(CAST(ni_asc AS DECIMAL) - CAST(ni_desc AS DECIMAL) ) <= 1
OR ABS(CAST(tp_asc AS DECIMAL) - CAST(tp_desc AS DECIMAL) ) <= 1;

-- Mode

SELECT time_spent_in_cart, number_of_items, 
total_price
FROM (
SELECT time_spent_in_cart,
ROW_NUMBER() OVER(ORDER BY COUNT(time_spent_in_cart) DESC) AS time_spent_cnt,
number_of_items,
ROW_NUMBER() OVER(ORDER BY COUNT(number_of_items) DESC) AS number_items_cnt,
total_price,
ROW_NUMBER() OVER(ORDER BY COUNT(total_price) DESC) AS total_price_cnt
FROM cart_abandonment
GROUP BY time_spent_in_cart, number_of_items, total_price) a
WHERE time_spent_cnt = 1 OR number_items_cnt = 1
OR total_price_cnt = 1;

-- Let's figure out the maximum time_spent_in_cart value.

SELECT *,
TIMESTAMPDIFF(MINUTE, first_item_added, last_item_added) AS time_spent_in_cart_in_minute
FROM cart_abandonment 
WHERE TIMESTAMPDIFF(minute, first_item_added, last_item_added) = (SELECT MAX(TIMESTAMPDIFF(minute, first_item_added, last_item_added)) FROM cart_abandonment);
/*
Many customers spent 20 minutes in the cart to make finalize the orders. There is no issue or outlier reflect in the dataset.
*/

-- Feature Engineering 

-- Add few columns in required tables.

-- Let's start with Cart Abandonment Table.

/*
Because, few customers did not receive the discounts while shopping on platform, It might cause to lost the customer engagement with us and loyalty. 
We need to create a new column, where the value will define, whether the given discount was applied on shopping or not.
*/


ALTER TABLE cart_abandonment
ADD COLUMN discount_applied VARCHAR(5);

UPDATE cart_abandonment
SET discount_applied = CASE WHEN discount_count = 0 THEN 'FALSE' ELSE 'TRUE' END;


/*
Difference between first_item_added time and last_item_added time in minutes.
*/

ALTER TABLE cart_abandonment
ADD COLUMN cart_spent_time INT;

UPDATE cart_abandonment
SET cart_spent_time = TIMESTAMPDIFF(MINUTE, first_item_added, last_item_added);

-- Customer Profile table.
/*
Customers tiers might cause behind the abandoned cart for us. Which is why as per the company policy,
customer will be categorized between "NEW CUSTOMERS" and "EXISTING CUSTOMERS".

Also, The tenurity of the customer may follow the same friction to loss the revenue.
We will create another new column to define the customers tenurity in monthly buckets.

The following monthly buckets are:

1-3 Months customers.
3-6 Months customers.
6-12 Months customers.
1+ Year customers.
*/


## Let's Add 2 new columns "Customer Tier" and "Customer Tenure".

ALTER TABLE customer_profile
ADD COLUMN customer_tier VARCHAR(20);

ALTER TABLE customer_profile
ADD COLUMN customer_tenure VARCHAR(20);


## Our objective is derived from 2024 and earlier customers subscription. We need to create a single temporary table
## to update the existing table with new columns.


## Create new temporary table with maximum subscription date in 2024.
CREATE TEMPORARY TABLE customer_tier_table AS
WITH cte AS (
SELECT MAX(DATE(signup_date)) AS max_date
FROM customer_profile
WHERE YEAR(signup_date) < 2025 )

SELECT t1.customer_id,
	CASE 
		WHEN DATE(t1.signup_date) >= DATE_SUB(t2.max_date, INTERVAL 90 DAY) THEN 'New'
		ELSE 'Existing'
	END AS customer_tier
FROM customer_profile t1
CROSS JOIN cte t2 ;


## Update the customer_profile table and update new values in "customer tier" column JOIN with Temporary "Customer Tier" table.
UPDATE customer_profile cp
JOIN customer_tier_table t ON cp.customer_id = t.customer_id
SET cp.customer_tier = t.customer_tier;

## After updating the table, Drop the temporary table.
DROP TEMPORARY TABLE customer_tier;


## Create Temporary table "Customer Tier" and Create new column customer_tier with logic building.
CREATE TEMPORARY TABLE customer_tenure AS 
WITH cte AS (
SELECT MAX(DATE(signup_date)) AS max_date
FROM customer_profile
WHERE YEAR(signup_date) < 2025 )

SELECT t1.customer_id,
	CASE 
		WHEN DATE(t1.signup_date) >= DATE_SUB(t2.max_date, INTERVAL 3 MONTH) THEN '1-3 month'
		WHEN DATE(t1.signup_date) >= DATE_SUB(t2.max_date, INTERVAL 6 MONTH)
		AND
			 DATE(t1.signup_date) < DATE_SUB(t2.max_date, INTERVAL 3 MONTH) THEN '3-6 month'
		WHEN DATE(t1.signup_date) >= DATE_SUB(t2.max_date, INTERVAL 12 MONTH)
		AND
			 DATE(t1.signup_date) < DATE_SUB(t2.max_date, INTERVAL 6 MONTH) THEN '6-12 month'
		ELSE '1 Year'
	END AS customer_tenure
FROM customer_profile t1
CROSS JOIN customer_tenure t2;

## Update the customer_profile table and update the new values in "customer tenure" column JOIN with Temporary "Customer Tenure" table.
UPDATE customer_profile cp
JOIN customer_tenure t ON cp.customer_id = t.customer_id
SET cp.customer_tenure = t.customer_tenure;

## After updating the table, Drop the Temporary table.
DROP TEMPORARY TABLE customer_tenure;



-- Find Outliers in Transactions table.

WITH cte AS (
SELECT customer_id,total_price,
(total_price - AVG(total_price) OVER())/STD(total_price) OVER() AS outliers
FROM Transactions )
SELECT customer_id, total_price -- 31 records are outliers
FROM cte
WHERE outliers > 2.576 OR outliers < -2.576;


## Let's remove this outliers.
CREATE TEMPORARY TABLE outlier_detect AS 
WITH cte AS (
SELECT customer_id,total_price,
(total_price - AVG(total_price) OVER())/STD(total_price) OVER() AS outliers
FROM Transactions )
SELECT customer_id, total_price -- 31 records are outliers
FROM cte
WHERE outliers > 2.576 OR outliers < -2.576;

DELETE t1
FROM Transactions t1
JOIN outlier_detect t2 ON t1.customer_id = t2.customer_id
WHERE t1.total_price = t2.total_price;

## After deleting the records, drop the temporary table.
DROP TEMPORARY TABLE outlier_detect;

-- Find outliers in cart_abandonment table.
WITH cte AS (
SELECT customer_id, total_price,
(total_price - AVG(total_price) OVER())/STD(total_price) OVER() AS outliers
FROM cart_abandonment )

SELECT * -- 155 records are outliers in total_price column
FROM cte
WHERE outliers > 2.576 OR outliers < -2.576;

WITH cte AS (
SELECT cart_spent_time,
(cart_spent_time - AVG(cart_spent_time) OVER())/STD(cart_spent_time) OVER() AS outliers
FROM cart_abandonment )

SELECT * -- No outliers
FROM cte
WHERE outliers > 2.576 OR outliers < -2.576;

-- Let's remove the outliers.
CREATE TEMPORARY TABLE outlier_detect_cart AS 
WITH cte AS (
SELECT customer_id, total_price,
(total_price - AVG(total_price) OVER())/STD(total_price) OVER() AS outliers
FROM cart_abandonment )
SELECT * -- 155 records are outliers
FROM cte
WHERE outliers > 2.576 OR outliers < -2.576;

DELETE t1
FROM cart_abandonment t1
JOIN outlier_detect_cart t2 ON t1.customer_id = t2.customer_id
WHERE t1.total_price = t2.total_price;

## Drop temporary table.
DROP TEMPORARY TABLE outlier_detect_cart;


-- Filter the records and work on 2024 data only.
## Make the copy of the data and work on it.

## Create new database and use it.
CREATE DATABASE IF NOT EXISTS Swiftcart;

USE Swiftcart;

## Create a copy of data and store in new database.
CREATE TABLE clean_Transactions AS 
SELECT *
FROM temp_swiftcart.transactions
WHERE YEAR(order_timestamp) = 2024;

CREATE TABLE clean_event_log AS 
SELECT *
FROM temp_swiftcart.event_log
WHERE YEAR(event_timestamp) = 2024;

CREATE TABLE clean_cart_abandonment AS 
SELECT *
FROM temp_swiftcart.cart_abandonment 
WHERE YEAR(first_item_added) = 2024 AND YEAR(last_item_added) = 2024;

CREATE TABLE clean_customer_profile AS 
SELECT *
FROM temp_swiftcart.customer_profile;

