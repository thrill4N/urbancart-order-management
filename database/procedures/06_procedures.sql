-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 06: Procedures
-- Run connected AS urbancart, AFTER 05_triggers.sql.
-- These four procedures are the only supported write path for the
-- order lifecycle — the Spring Boot API layer calls these rather than
-- issuing raw INSERT/UPDATE statements, so every order/payment/
-- shipment transition goes through the same validated path regardless
-- of which client calls it.
-- =====================================================================

-- ---------------------------------------------------------------------
-- place_order (BR1, BR4, BR10)
-- Creates an order header, its line items, and its initial Pending
-- payment record, all in one transaction. If any line item fails the
-- stock-check trigger (BR7), the whole order is rolled back — an
-- order is never left half-created.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE place_order (
    p_customer_id    IN  NUMBER,
    p_payment_method IN  VARCHAR2,
    p_items          IN  order_item_tab,
    p_order_id       OUT NUMBER
) IS
    v_price NUMBER(10,2);
BEGIN
    -- BR4: an order must contain at least one item
    IF p_items IS NULL OR p_items.COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'An order must contain at least one item.');
    END IF;

    -- BR1: customer_id is a NOT NULL FK, so an invalid customer fails
    -- here with a clear FK violation rather than silently succeeding
    INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount)
    VALUES (seq_orders.NEXTVAL, p_customer_id, SYSDATE, 'Pending', 0)
    RETURNING order_id INTO p_order_id;

    FOR i IN 1 .. p_items.COUNT LOOP
        -- price is captured at time of order, not looked up again later,
        -- so historical orders stay accurate even if the catalogue price changes
        SELECT unit_price INTO v_price
          FROM product
         WHERE product_id = p_items(i).product_id;

        INSERT INTO order_item (order_item_id, order_id, product_id, quantity, unit_price)
        VALUES (seq_order_item.NEXTVAL, p_order_id, p_items(i).product_id, p_items(i).quantity, v_price);
        -- trg_orderitem_before_insert checks stock (BR7)
        -- trg_orderitem_stock_decrement reduces stock (BR8)
        -- trg_orderitem_total_amount updates orders.total_amount (BR9)
    END LOOP;

    -- BR10: every order gets exactly one Pending payment record at creation
    INSERT INTO payment (payment_id, order_id, payment_date, payment_method, amount, payment_status)
    VALUES (seq_payment.NEXTVAL, p_order_id, SYSDATE, p_payment_method, 0, 'Pending');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END place_order;
/

-- ---------------------------------------------------------------------
-- confirm_payment (BR11)
-- Confirms a Pending payment. Refuses to confirm if the amount paid
-- doesn't match the order's total, or if the payment was already
-- resolved (Confirmed/Failed/Refunded) — confirm_payment is a one-way
-- transition from Pending only.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE confirm_payment (
    p_order_id    IN NUMBER,
    p_amount_paid IN NUMBER
) IS
    v_total  NUMBER(10,2);
    v_status VARCHAR2(20);
BEGIN
    SELECT total_amount INTO v_total FROM orders WHERE order_id = p_order_id;
    SELECT payment_status INTO v_status FROM payment WHERE order_id = p_order_id;

    IF v_status != 'Pending' THEN
        RAISE_APPLICATION_ERROR(-20020, 'Payment for order ' || p_order_id || ' is already ' || v_status || '.');
    END IF;

    -- BR11: payment amount must equal the order's total
    IF p_amount_paid != v_total THEN
        RAISE_APPLICATION_ERROR(
            -20021,
            'Amount paid (' || p_amount_paid || ') does not match order total (' || v_total || ').'
        );
    END IF;

    UPDATE payment
       SET amount = p_amount_paid,
           payment_status = 'Confirmed',
           payment_date = SYSDATE
     WHERE order_id = p_order_id;

    -- move the order out of Pending now that it's paid for
    UPDATE orders SET order_status = 'Processing'
     WHERE order_id = p_order_id AND order_status = 'Pending';

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END confirm_payment;
/

-- ---------------------------------------------------------------------
-- create_shipment (BR12)
-- Only succeeds if the order's payment is Confirmed. This is the
-- procedural half of the payment-before-shipment rule; BR13's trigger
-- is the second, independent line of defence if this check were ever
-- bypassed.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE create_shipment (
    p_order_id        IN  NUMBER,
    p_courier_name    IN  VARCHAR2,
    p_tracking_number IN  VARCHAR2,
    p_shipment_id     OUT NUMBER
) IS
    v_status VARCHAR2(20);
BEGIN
    SELECT payment_status INTO v_status FROM payment WHERE order_id = p_order_id;

    IF v_status != 'Confirmed' THEN
        RAISE_APPLICATION_ERROR(
            -20030,
            'Cannot create shipment: payment for order ' || p_order_id || ' is not Confirmed.'
        );
    END IF;

    INSERT INTO shipment (shipment_id, order_id, shipment_date, courier_name, tracking_number, delivery_status)
    VALUES (seq_shipment.NEXTVAL, p_order_id, SYSDATE, p_courier_name, p_tracking_number, 'Processing')
    RETURNING shipment_id INTO p_shipment_id;

    UPDATE orders SET order_status = 'Packed' WHERE order_id = p_order_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END create_shipment;
/

-- ---------------------------------------------------------------------
-- update_shipment_status
-- Progresses a shipment (Processing -> Packed -> Shipped -> Delivered)
-- and keeps orders.order_status in sync. trg_orders_status_guard
-- (BR13) still fires on the orders update inside here, so this
-- procedure gets the same protection as any other caller would.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE update_shipment_status (
    p_shipment_id IN NUMBER,
    p_new_status  IN VARCHAR2
) IS
    v_order_id NUMBER;
BEGIN
    UPDATE shipment
       SET delivery_status = p_new_status,
           delivery_date = CASE WHEN p_new_status = 'Delivered' THEN SYSDATE ELSE delivery_date END
     WHERE shipment_id = p_shipment_id
    RETURNING order_id INTO v_order_id;

    IF v_order_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20040, 'Shipment ' || p_shipment_id || ' not found.');
    END IF;

    UPDATE orders SET order_status = p_new_status WHERE order_id = v_order_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_shipment_status;
/
