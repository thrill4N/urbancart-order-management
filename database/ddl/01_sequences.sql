-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 01: Sequences
-- Run connected AS urbancart.
-- One sequence per entity's surrogate primary key. These are called
-- explicitly (seq_name.NEXTVAL) inside the stored procedures built in
-- Phase 3, rather than via BEFORE INSERT triggers — this keeps every
-- trigger in the project doing genuine business-rule work (see Phase 2
-- business rules table) instead of boilerplate key generation.
-- =====================================================================

CREATE SEQUENCE seq_customer    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_category    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_product     START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_orders      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_order_item  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_payment     START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_shipment    START WITH 1 INCREMENT BY 1 NOCACHE;
