-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 05: Triggers
-- Run connected AS urbancart, AFTER 04_types.sql.
-- Every trigger here maps directly to a numbered business rule (BRx)
-- from the Phase 2 design document — see the comment above each one.
-- None of these exist just to populate primary keys; PK generation is
-- handled by explicit sequence.NEXTVAL calls inside the stored
-- procedures (06_procedures.sql), so every trigger below is doing
-- genuine business-rule enforcement, not boilerplate.
-- =====================================================================

-- ---------------------------------------------------------------------
-- BR7: A product cannot be ordered if the requested quantity exceeds
-- available stock. Runs BEFORE the row is inserted, so a bad order
-- line never reaches the table at all.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_orderitem_before_insert
BEFORE INSERT ON order_item
FOR EACH ROW
DECLARE
    v_stock NUMBER;
BEGIN
    SELECT stock_quantity INTO v_stock
      FROM product
     WHERE product_id = :NEW.product_id;

    IF :NEW.quantity > v_stock THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Insufficient stock for product ' || :NEW.product_id ||
            ': requested ' || :NEW.quantity || ', available ' || v_stock
        );
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- BR8: Inserting an order item automatically decrements the product's
-- stock by the ordered quantity.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_orderitem_stock_decrement
AFTER INSERT ON order_item
FOR EACH ROW
BEGIN
    UPDATE product
       SET stock_quantity = stock_quantity - :NEW.quantity
     WHERE product_id = :NEW.product_id;
END;
/

-- ---------------------------------------------------------------------
-- Extra functionality (not a numbered BR, but keeps stock consistent):
-- if an order item is later changed or removed, give the stock back.
-- Without this, editing/cancelling an order before payment would leave
-- stock permanently understated.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_orderitem_stock_adjust
AFTER UPDATE OR DELETE ON order_item
FOR EACH ROW
BEGIN
    IF UPDATING THEN
        UPDATE product
           SET stock_quantity = stock_quantity + :OLD.quantity - :NEW.quantity
         WHERE product_id = :NEW.product_id;
    ELSIF DELETING THEN
        UPDATE product
           SET stock_quantity = stock_quantity + :OLD.quantity
         WHERE product_id = :OLD.product_id;
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- BR9: orders.total_amount always equals the sum of (quantity ×
-- unit_price) across its order items. Implemented as an incremental
-- adjustment (+/- the changed row's value) rather than re-summing the
-- whole order_item table on every change — re-summing from inside a
-- row-level trigger on order_item would try to SELECT from the same
-- table that fired the trigger mid-statement, which Oracle blocks as
-- a "mutating table" error (ORA-04091). Adjusting the running total
-- incrementally avoids that entirely and is cheaper besides.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_orderitem_total_amount
AFTER INSERT OR UPDATE OR DELETE ON order_item
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE orders
           SET total_amount = total_amount + (:NEW.quantity * :NEW.unit_price)
         WHERE order_id = :NEW.order_id;
    ELSIF UPDATING THEN
        UPDATE orders
           SET total_amount = total_amount
                               - (:OLD.quantity * :OLD.unit_price)
                               + (:NEW.quantity * :NEW.unit_price)
         WHERE order_id = :NEW.order_id;
    ELSIF DELETING THEN
        UPDATE orders
           SET total_amount = total_amount - (:OLD.quantity * :OLD.unit_price)
         WHERE order_id = :OLD.order_id;
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- BR13: An order's status cannot move to Shipped or Delivered while
-- its payment is not Confirmed. This is the DB-level half of "defence
-- in depth" — the Spring Boot layer will check this too before calling
-- the database, but the database never trusts the caller to have
-- checked correctly.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_orders_status_guard
BEFORE UPDATE OF order_status ON orders
FOR EACH ROW
DECLARE
    v_payment_status VARCHAR2(20);
BEGIN
    IF :NEW.order_status IN ('Shipped', 'Delivered') THEN
        SELECT payment_status INTO v_payment_status
          FROM payment
         WHERE order_id = :NEW.order_id;

        IF v_payment_status IS NULL OR v_payment_status != 'Confirmed' THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'Cannot move order ' || :NEW.order_id || ' to ' || :NEW.order_status ||
                ' before its payment is Confirmed.'
            );
        END IF;
    END IF;
END;
/
