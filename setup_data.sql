--format & read in order data
WITH order_data AS (
	SELECT 
      		  orderId		AS order_id
		, customerId 		AS customer_id
		, orderDate 		AS order_date
		, product 		AS product
		, shippingMethod 	AS shipping_method
		, paymentMethod 	AS payment_method
		, orderStatus 		AS order_status
		, discountUsed = 1 	AS is_discount_used
	FROM order_data_source
	)

--format & read in support data
, customer_support_data AS (
	SELECT
		  orderId 		AS order_id
		, customerId 		AS customer_id
		, topic			AS topic
		, CSAT 			AS csat
	FROM customer_support_data_source
	)

--format & read in customer data
, customer_data AS (
	SELECT
		  customerId 		AS customer_id
		, acquisitionSource 	AS acquisition_source
		, shippingLocation 	AS shipping_location
		, marketable = 1	AS is_marketable
	FROM customer_data_source
	)

--format & read in product data
, product_data AS (
	SELECT
		  product 		AS product
		, price 		AS price
		, COGS 			AS cogs
	FROM product_data_source
	)

-- create wide dataset for analysis, add custom dimensions
, order_data_wide AS (
	SELECT
      		  o.order_id
		, o.customer_id
		, c.acquisition_source
		, c.shipping_locations
		, c.is_marketable
		, o.order_date
		, o.product
		, p.price
		, p.cogs
		, o.shipping_method
		, o.payment_method
		, o.order_status
		, o.is_discount_used
		, s.order_id IS NOT NULL AS has_support_ticket
		, s.topic
		, s.csat
	FROM order_data o 
		LEFT JOIN customer_support_data s 	ON o.order_id = s.order_id
		LEFT JOIN customer_data c 		ON o.customer_id = c.customer_id
		LEFT JOIN product_data p 		ON o.product = p.product
	)

-- add next order information (I forget without running the code if we can do this in the previous CTE. I think we can but separating just in case!)
SELECT
	  *
	, LEAD(order_id)   OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS next_order_id
	, LEAD(product)    OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS next_product
	, LEAD(price)      OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS next_price
	, LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS next_order_date
FROM order_data_wide
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) = 1
