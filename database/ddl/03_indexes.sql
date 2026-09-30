-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 03: Indexes
-- Run connected AS urbancart, AFTER 02_tables.sql.
-- Oracle does NOT automatically index foreign-key columns (unlike PK/
-- UNIQUE columns, which get an index for free). Leaving FK columns
-- unindexed is a classic performance and locking problem in production
-- Oracle systems, so every FK below gets an explicit index.
-- payment.order_id and shipment.order_id already have an index from
-- their UNIQUE constraints (uk_payment_order, uk_shipment_order), so
-- they are not repeated here.
-- =====================================================================

-- Foreign-key indexes
CREATE INDEX idx_product_category   ON product (category_id);
CREATE INDEX idx_orders_customer    ON orders (customer_id);
CREATE INDEX idx_orderitem_order    ON order_item (order_id);
CREATE INDEX idx_orderitem_product  ON order_item (product_id);

-- Reporting/lookup indexes — support the views in 07_views.sql and
-- common API query patterns (filter by status, filter/sort by date)
CREATE INDEX idx_orders_date        ON orders (order_date);
CREATE INDEX idx_orders_status      ON orders (order_status);
CREATE INDEX idx_payment_status     ON payment (payment_status);
CREATE INDEX idx_shipment_status    ON shipment (delivery_status);
CREATE INDEX idx_product_stock      ON product (stock_quantity, reorder_level);
