-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 07: Views
-- Run connected AS urbancart, AFTER 06_procedures.sql.
-- These three views satisfy LFR-7.1–7.3 from the engineering brief.
-- The Spring Boot reporting endpoints are thin wrappers around these —
-- if a report ever needs a new filter/join, it's added here, not
-- reimplemented as a JPQL query in the Java service layer.
-- =====================================================================

-- ---------------------------------------------------------------------
-- v_order_status — one row per order: who placed it, its totals, and
-- its current payment/delivery state. This is what Customer Service
-- and the /api/orders/{id} endpoint both read from.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_order_status AS
SELECT o.order_id,
       c.customer_id,
       c.first_name || ' ' || c.last_name          AS customer_name,
       o.order_date,
       o.order_status,
       o.total_amount,
       p.payment_status,
       s.delivery_status,
       s.tracking_number,
       (SELECT COUNT(*) FROM order_item oi WHERE oi.order_id = o.order_id) AS item_count
  FROM orders o
  JOIN customer c ON c.customer_id = o.customer_id
  LEFT JOIN payment  p ON p.order_id = o.order_id
  LEFT JOIN shipment s ON s.order_id = o.order_id;

-- ---------------------------------------------------------------------
-- v_low_stock — products at or below their reorder level. Feeds
-- Warehouse's replenishment workflow and the Spring Boot low-stock
-- endpoint, which additionally ranks these by urgency using a
-- PriorityQueue (see engineering brief, §7) rather than the view's
-- default row order.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_low_stock AS
SELECT p.product_id,
       p.product_name,
       cat.category_name,
       p.stock_quantity,
       p.reorder_level
  FROM product p
  JOIN category cat ON cat.category_id = p.category_id
 WHERE p.stock_quantity < p.reorder_level;

-- ---------------------------------------------------------------------
-- v_sales_by_category — units sold and revenue per category. Only
-- counts order items belonging to orders with a Confirmed payment, so
-- "sales" reflects money actually received, not just carts created.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_sales_by_category AS
SELECT cat.category_name,
       SUM(oi.quantity)                AS total_units_sold,
       SUM(oi.quantity * oi.unit_price) AS total_revenue
  FROM order_item oi
  JOIN product  p   ON p.product_id = oi.product_id
  JOIN category cat ON cat.category_id = p.category_id
  JOIN payment  pay ON pay.order_id = oi.order_id
 WHERE pay.payment_status = 'Confirmed'
 GROUP BY cat.category_name;
