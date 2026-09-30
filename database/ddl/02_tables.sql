-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 02: Tables
-- Run connected AS urbancart, AFTER 01_sequences.sql.
-- Tables are created in dependency order: entities with no foreign keys
-- first, so every FK constraint below can reference a table that
-- already exists. Column names, types, and constraints match the
-- Phase 2 logical data model exactly. Each CHECK/UNIQUE/FK constraint
-- is commented with the business rule (BRx) it enforces, from Phase 2.
-- =====================================================================

-- ---------------------------------------------------------------------
-- CUSTOMER — no dependencies
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    customer_id         NUMBER          PRIMARY KEY,
    first_name          VARCHAR2(50)    NOT NULL,
    last_name           VARCHAR2(50)    NOT NULL,
    email                VARCHAR2(100)   NOT NULL,
    phone                VARCHAR2(20),
    address              VARCHAR2(200),
    city                 VARCHAR2(50),
    province             VARCHAR2(50),
    postal_code          VARCHAR2(10),
    registration_date    DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uk_customer_email UNIQUE (email)              -- BR3
);

-- ---------------------------------------------------------------------
-- CATEGORY — no dependencies
-- ---------------------------------------------------------------------
CREATE TABLE category (
    category_id     NUMBER          PRIMARY KEY,
    category_name   VARCHAR2(50)    NOT NULL,
    description     VARCHAR2(200),
    CONSTRAINT uk_category_name UNIQUE (category_name)       -- BR15
);

-- ---------------------------------------------------------------------
-- PRODUCT — depends on CATEGORY
-- ---------------------------------------------------------------------
CREATE TABLE product (
    product_id       NUMBER          PRIMARY KEY,
    category_id      NUMBER          NOT NULL,
    product_name     VARCHAR2(100)   NOT NULL,
    description      VARCHAR2(500),
    unit_price       NUMBER(10,2)    NOT NULL,
    stock_quantity   NUMBER          NOT NULL,
    reorder_level    NUMBER          DEFAULT 10 NOT NULL,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id)  -- BR2
        REFERENCES category (category_id),
    CONSTRAINT chk_product_price CHECK (unit_price > 0),      -- BR14
    CONSTRAINT chk_product_stock CHECK (stock_quantity >= 0)  -- BR6
);

-- ---------------------------------------------------------------------
-- ORDERS — depends on CUSTOMER
-- (named "orders", not "order", because ORDER is a reserved SQL word)
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id        NUMBER          PRIMARY KEY,
    customer_id     NUMBER          NOT NULL,
    order_date      DATE            DEFAULT SYSDATE NOT NULL,
    order_status    VARCHAR2(20)    DEFAULT 'Pending' NOT NULL,
    total_amount    NUMBER(10,2)    DEFAULT 0 NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)   -- BR1
        REFERENCES customer (customer_id),
    CONSTRAINT chk_order_status CHECK (order_status IN         -- BR13
        ('Pending','Processing','Packed','Shipped','Delivered','Cancelled'))
);

-- ---------------------------------------------------------------------
-- ORDER_ITEM — depends on ORDERS and PRODUCT
-- ---------------------------------------------------------------------
CREATE TABLE order_item (
    order_item_id   NUMBER          PRIMARY KEY,
    order_id        NUMBER          NOT NULL,
    product_id      NUMBER          NOT NULL,
    quantity        NUMBER          NOT NULL,
    unit_price      NUMBER(10,2)    NOT NULL,
    CONSTRAINT fk_orderitem_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT fk_orderitem_product FOREIGN KEY (product_id)
        REFERENCES product (product_id),
    CONSTRAINT chk_orderitem_qty CHECK (quantity > 0)          -- BR5
);

-- ---------------------------------------------------------------------
-- PAYMENT — depends on ORDERS (one payment per order, so order_id
-- is both a foreign key and unique)
-- ---------------------------------------------------------------------
CREATE TABLE payment (
    payment_id       NUMBER          PRIMARY KEY,
    order_id         NUMBER          NOT NULL,
    payment_date     DATE            DEFAULT SYSDATE NOT NULL,
    payment_method   VARCHAR2(20)    NOT NULL,
    amount           NUMBER(10,2)    NOT NULL,
    payment_status   VARCHAR2(20)    DEFAULT 'Pending' NOT NULL,
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT uk_payment_order UNIQUE (order_id),             -- 1:1 with ORDERS
    CONSTRAINT chk_payment_method CHECK (payment_method IN ('Card','EFT','Mobile')),
    CONSTRAINT chk_payment_status CHECK (payment_status IN ('Pending','Confirmed','Failed','Refunded')),
    CONSTRAINT chk_payment_amount CHECK (amount > 0)           -- BR14
);

-- ---------------------------------------------------------------------
-- SHIPMENT — depends on ORDERS (one shipment per order)
-- ---------------------------------------------------------------------
CREATE TABLE shipment (
    shipment_id       NUMBER          PRIMARY KEY,
    order_id          NUMBER          NOT NULL,
    shipment_date     DATE,
    courier_name      VARCHAR2(50),
    tracking_number   VARCHAR2(50),
    delivery_status   VARCHAR2(20)    DEFAULT 'Processing' NOT NULL,
    delivery_date     DATE,
    CONSTRAINT fk_shipment_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT uk_shipment_order UNIQUE (order_id),            -- 1:1 with ORDERS
    CONSTRAINT chk_shipment_status CHECK (delivery_status IN
        ('Processing','Packed','Shipped','Delivered'))
);
