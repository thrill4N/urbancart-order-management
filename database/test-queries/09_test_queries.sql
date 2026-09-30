-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 09: Test Queries
-- Run connected AS urbancart, AFTER 08_seed_data.sql.
-- Part A exercises the reporting views against the seed data.
-- Part B deliberately triggers the two negative-path business rules
-- (BR7 and BR13) and catches the error, to prove the guards actually
-- fire rather than just existing unused in the source.
-- SET SERVEROUTPUT ON is needed to see the DBMS_OUTPUT lines in
-- SQL Developer's Script Output pane.
-- =====================================================================

SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------
-- Part A: reporting views
-- ---------------------------------------------------------------------

-- LFR-7.1: every order, with customer, payment, and delivery status
SELECT * FROM v_order_status ORDER BY order_id;

-- LFR-7.2: products at or below their reorder level
-- (seed data intentionally leaves product 5 and product 10 low)
SELECT * FROM v_low_stock ORDER BY stock_quantity;

-- LFR-7.3: confirmed revenue and units sold, by category
SELECT * FROM v_sales_by_category ORDER BY total_revenue DESC;

-- ---------------------------------------------------------------------
-- Part B: negative-path proofs
-- ---------------------------------------------------------------------

-- BR7: ordering more than available stock must fail.
-- Product 5 (Stainless Steel Kettle) has 3 in stock — this requests 999.
DECLARE
    v_items    order_item_tab := order_item_tab(order_item_type(5, 999));
    v_order_id NUMBER;
BEGIN
    place_order(p_customer_id => 5, p_payment_method => 'Card', p_items => v_items, p_order_id => v_order_id);
    DBMS_OUTPUT.PUT_LINE('UNEXPECTED: order succeeded, BR7 did not fire.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('BR7 correctly rejected the order: ' || SQLERRM);
END;
/

-- BR13: moving an order to Shipped while payment is still Pending
-- must fail. Demo order 2 (placed in seed data, never confirmed) is
-- used here — look up its order_id from v_order_status if it isn't 2.
DECLARE
    v_unpaid_order_id orders.order_id%TYPE;
BEGIN
    SELECT order_id INTO v_unpaid_order_id
      FROM v_order_status
     WHERE payment_status = 'Pending'
       AND ROWNUM = 1;

    UPDATE orders SET order_status = 'Shipped' WHERE order_id = v_unpaid_order_id;
    DBMS_OUTPUT.PUT_LINE('UNEXPECTED: status update succeeded, BR13 did not fire.');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('BR13 correctly rejected the status change: ' || SQLERRM);
        ROLLBACK;
END;
/

-- BR12 (procedural half): creating a shipment for an unconfirmed
-- payment must fail.
DECLARE
    v_unpaid_order_id orders.order_id%TYPE;
    v_shipment_id      NUMBER;
BEGIN
    SELECT order_id INTO v_unpaid_order_id
      FROM v_order_status
     WHERE payment_status = 'Pending'
       AND ROWNUM = 1;

    create_shipment(
        p_order_id => v_unpaid_order_id, p_courier_name => 'CourierGuy',
        p_tracking_number => 'SHOULD-FAIL', p_shipment_id => v_shipment_id
    );
    DBMS_OUTPUT.PUT_LINE('UNEXPECTED: shipment created, BR12 did not fire.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('BR12 correctly rejected the shipment: ' || SQLERRM);
END;
/
