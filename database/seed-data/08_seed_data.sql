-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 08: Seed Data
-- Run connected AS urbancart, AFTER 07_views.sql.
-- Part A seeds reference data (categories, customers, products) with
-- explicit IDs for readability, then restarts the matching sequences
-- above those IDs so anything created afterwards through the
-- procedures never collides with seed data.
-- Part B places demo orders through place_order / confirm_payment /
-- create_shipment / update_shipment_status — not raw INSERTs — so the
-- seed data itself is proof the Phase 3 business logic works, and the
-- resulting rows land in a realistic mix of states for the views to
-- report on.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Part A: reference data
-- ---------------------------------------------------------------------

INSERT INTO category (category_id, category_name, description) VALUES
    (1, 'Clothing', 'Apparel for men, women, and children');
INSERT INTO category (category_id, category_name, description) VALUES
    (2, 'Electronics', 'Small electronics and accessories');
INSERT INTO category (category_id, category_name, description) VALUES
    (3, 'Home & Living', 'Household and home decor items');
INSERT INTO category (category_id, category_name, description) VALUES
    (4, 'Beauty & Personal Care', 'Personal care and grooming products');

INSERT INTO customer (customer_id, first_name, last_name, email, phone, address, city, province, postal_code) VALUES
    (1, 'Thabo', 'Mokoena', 'thabo.mokoena@example.com', '0821234567', '12 Church St', 'Pretoria', 'Gauteng', '0002');
INSERT INTO customer (customer_id, first_name, last_name, email, phone, address, city, province, postal_code) VALUES
    (2, 'Lindiwe', 'Nkosi', 'lindiwe.nkosi@example.com', '0837654321', '48 Jorissen St', 'Johannesburg', 'Gauteng', '2001');
INSERT INTO customer (customer_id, first_name, last_name, email, phone, address, city, province, postal_code) VALUES
    (3, 'Pieter', 'van der Merwe', 'pieter.vdm@example.com', '0715558899', '3 Lenchen Ave', 'Centurion', 'Gauteng', '0157');
INSERT INTO customer (customer_id, first_name, last_name, email, phone, address, city, province, postal_code) VALUES
    (4, 'Aisha', 'Patel', 'aisha.patel@example.com', '0823332211', '21 Duncan St', 'Pretoria', 'Gauteng', '0083');
INSERT INTO customer (customer_id, first_name, last_name, email, phone, address, city, province, postal_code) VALUES
    (5, 'Sipho', 'Dlamini', 'sipho.dlamini@example.com', '0796665544', '9 Anderson St', 'Midrand', 'Gauteng', '1685');

INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (1, 1, 'Men''s Denim Jacket', 'Classic blue denim jacket', 599.99, 25, 5);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (2, 1, 'Women''s Summer Dress', 'Lightweight floral summer dress', 449.50, 18, 5);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (3, 2, 'Wireless Earbuds', 'Bluetooth 5.3 in-ear earbuds with case', 799.00, 12, 5);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (4, 2, 'Portable Bluetooth Speaker', 'Compact waterproof speaker', 649.00, 8, 5);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (5, 3, 'Stainless Steel Kettle', '1.7L electric kettle', 349.00, 3, 10);  -- below reorder level on purpose
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (6, 3, 'Cotton Bath Towel Set', 'Set of 4 bath towels', 259.00, 40, 10);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (7, 3, 'Scented Candle Set', 'Set of 3 soy wax candles', 189.00, 30, 8);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (8, 1, 'Men''s Sneakers', 'Everyday casual sneakers', 899.00, 15, 5);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (9, 4, 'Facial Skincare Set', 'Cleanser, toner, and moisturiser set', 429.00, 20, 6);
INSERT INTO product (product_id, category_id, product_name, description, unit_price, stock_quantity, reorder_level) VALUES
    (10, 2, 'Electric Hair Trimmer', 'Rechargeable grooming trimmer', 549.00, 4, 10); -- below reorder level on purpose

-- Push the sequences well past the manually seeded IDs so procedure-
-- generated rows never collide with this reference data.
ALTER SEQUENCE seq_category RESTART START WITH 100;
ALTER SEQUENCE seq_customer RESTART START WITH 100;
ALTER SEQUENCE seq_product  RESTART START WITH 100;

COMMIT;

-- ---------------------------------------------------------------------
-- Part B: demo orders, run through the real procedures
-- ---------------------------------------------------------------------

-- Demo order 1 — full lifecycle: placed, paid, shipped, delivered
DECLARE
    v_items       order_item_tab := order_item_tab(
        order_item_type(1, 2),   -- 2x Men's Denim Jacket
        order_item_type(3, 1)    -- 1x Wireless Earbuds
    );
    v_order_id    NUMBER;
    v_shipment_id NUMBER;
    v_total       NUMBER;
BEGIN
    place_order(p_customer_id => 1, p_payment_method => 'Card', p_items => v_items, p_order_id => v_order_id);

    SELECT total_amount INTO v_total FROM orders WHERE order_id = v_order_id;
    confirm_payment(p_order_id => v_order_id, p_amount_paid => v_total);

    create_shipment(
        p_order_id => v_order_id, p_courier_name => 'CourierGuy',
        p_tracking_number => 'CG1001', p_shipment_id => v_shipment_id
    );
    update_shipment_status(p_shipment_id => v_shipment_id, p_new_status => 'Shipped');
    update_shipment_status(p_shipment_id => v_shipment_id, p_new_status => 'Delivered');
END;
/

-- Demo order 2 — placed but intentionally left unpaid, to show the
-- Pending state in v_order_status
DECLARE
    v_items    order_item_tab := order_item_tab(order_item_type(2, 1)); -- 1x Summer Dress
    v_order_id NUMBER;
BEGIN
    place_order(p_customer_id => 2, p_payment_method => 'EFT', p_items => v_items, p_order_id => v_order_id);
END;
/

-- Demo order 3 — paid but not yet shipped, to show the Processing state
DECLARE
    v_items    order_item_tab := order_item_tab(order_item_type(4, 3)); -- 3x Bluetooth Speaker
    v_order_id NUMBER;
    v_total    NUMBER;
BEGIN
    place_order(p_customer_id => 3, p_payment_method => 'Mobile', p_items => v_items, p_order_id => v_order_id);
    SELECT total_amount INTO v_total FROM orders WHERE order_id = v_order_id;
    confirm_payment(p_order_id => v_order_id, p_amount_paid => v_total);
END;
/

-- Demo order 4 — a second customer, second confirmed order, so
-- v_sales_by_category has more than one order's worth of revenue
DECLARE
    v_items    order_item_tab := order_item_tab(
        order_item_type(9, 2),   -- 2x Facial Skincare Set
        order_item_type(6, 1)    -- 1x Bath Towel Set
    );
    v_order_id NUMBER;
    v_total    NUMBER;
BEGIN
    place_order(p_customer_id => 4, p_payment_method => 'Card', p_items => v_items, p_order_id => v_order_id);
    SELECT total_amount INTO v_total FROM orders WHERE order_id = v_order_id;
    confirm_payment(p_order_id => v_order_id, p_amount_paid => v_total);
END;
/
