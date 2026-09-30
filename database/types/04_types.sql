-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 04: Types
-- Run connected AS urbancart, AFTER 03_indexes.sql, BEFORE procedures.
-- place_order (06_procedures.sql) needs to accept a variable-length
-- list of {product_id, quantity} pairs in one call, so an order and
-- all its line items can be created inside a single transaction. Plain
-- PL/SQL procedures can't accept an arbitrary-length list of records
-- as a single IN parameter without a purpose-built collection type —
-- hence the two schema-level types below.
-- =====================================================================

-- One requested line item: a product and how many units of it.
CREATE OR REPLACE TYPE order_item_type AS OBJECT (
    product_id  NUMBER,
    quantity    NUMBER
);
/

-- A variable-length list of order_item_type — this is the type
-- place_order's p_items parameter actually uses.
CREATE OR REPLACE TYPE order_item_tab AS TABLE OF order_item_type;
/
