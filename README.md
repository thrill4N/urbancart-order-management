# UrbanCart Order Management Database

Solo project by Nkululeko. An Oracle relational database for a fictional South African online retailer (UrbanCart), built through the three phases of the database life cycle, plus a Spring Boot API layer as a personal portfolio extension.

## Project status

| Phase | Contents | Status |
|---|---|---|
| Phase 1 — Database Initial Study | Company scenario, problems/constraints, DB system specification | ✅ Complete |
| Phase 2 — Database Design | Business rules, ER diagram, logical data model | ✅ Complete |
| Phase 3 — Physical Design | Schema, sequences, indexes, triggers, procedures, views, seed data, tests | ✅ Complete |
| Spring Boot API (portfolio extension, not part of the graded assignment) | OOP service layer over this schema | ⏳ Not yet started |

## Folder structure

```
docs/
  UrbanCart_Phase1_Database_Initial_Study.docx
  UrbanCart_Phase2_Database_Design.docx
  UrbanCart_Engineering_Brief.md        # requirements spec for the whole project
database/
  00_create_schema_user.sql              # run as SYSTEM, once
  run_all.sql                            # runs everything below, in order
  ddl/
    01_sequences.sql
    02_tables.sql
    03_indexes.sql
  types/
    04_types.sql                         # order_item_type / order_item_tab
  triggers/
    05_triggers.sql
  procedures/
    06_procedures.sql                    # place_order, confirm_payment, create_shipment, update_shipment_status
  views/
    07_views.sql                         # v_order_status, v_low_stock, v_sales_by_category
  seed-data/
    08_seed_data.sql                     # reference data + demo orders run through the procedures
  test-queries/
    09_test_queries.sql                  # view checks + deliberate negative-path tests
```

## How to run this

1. Install Oracle Database Free (23ai) and Oracle SQL Developer locally.
2. Connect to `localhost:1521/FREEPDB1` as `system`, and run `00_create_schema_user.sql`.
3. Open a new connection as `urbancart` (the user that script just created).
4. From that connection, run `run_all.sql` (or each numbered script individually, in order — the numbering is the dependency order).
5. Check the Script Output pane for the test-query results — Part A should show populated views, and Part B should show three "correctly rejected" messages, proving the business rules actually hold.

## Design decisions worth knowing before reading the code

- **The database owns its business logic.** Constraints, triggers, and stored procedures enforce every rule from the Phase 2 business-rules table — not an application layer. Any future client (including the planned Spring Boot API) is a thin caller, not a second source of truth.
- **Primary keys are populated by explicit `sequence.NEXTVAL` calls inside the stored procedures**, not by BEFORE INSERT triggers, so every trigger in the project is doing real business-rule work — see the header comments in `05_triggers.sql` for the reasoning.
- **`total_amount` is maintained incrementally**, not by re-summing `order_item` on every change, to avoid Oracle's mutating-table restriction and because it's cheaper. See the comment above `trg_orderitem_total_amount`.
- Full requirement traceability (which rule is enforced where, and why) is in `docs/UrbanCart_Engineering_Brief.md`, §4.

## What's next

The Spring Boot API layer described in the engineering brief (§6–§7): OOP domain model with a real inheritance hierarchy, layered architecture, and 2–3 well-justified data-structure choices, calling the four procedures above rather than duplicating their logic in Java.
