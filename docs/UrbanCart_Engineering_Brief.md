# UrbanCart Order Management System — Engineering Brief & Requirements Specification

**Owner:** Nkululeko (solo project)
**Type:** Full-stack data-and-backend engineering project — Oracle relational database (academic deliverable) + Spring Boot service layer (portfolio extension)
**Status:** Phase 1 & 2 complete. Phase 3 (DDL, triggers, procedures, views) in progress.

---

## 1. Purpose

Most student database projects stop at "tables + a few SELECT statements." This project is scoped so that the database is a real backend — one that enforces its own business rules — and the Spring Boot layer is a thin client that proves those rules work end-to-end. The goal isn't just to pass the assignment; it's to produce an artifact a recruiter can open, understand in five minutes, and immediately see engineering judgment in: separation of concerns, data integrity by design, and code that reads like it was written by someone who has shipped something before.

**What this needs to demonstrate to a recruiter, specifically:**
- You can design a normalized relational schema from a real-world scenario, not just copy a textbook ERD.
- You understand *where* logic belongs (constraint vs. trigger vs. procedure vs. service layer) and can justify the choice.
- You can write a layered Java backend using OOP properly — not flat, procedural code wearing Spring annotations.
- You know at least one place a data structure or algorithm choice mattered, and can explain why.
- You can document and ship something, not just make it run once on your machine.

---

## 2. Scope

**In scope:**
- Oracle relational database implementing the UrbanCart order-management domain (Phases 1–3 of the DBLC assignment).
- A Spring Boot REST API that is a thin client over that database — validation and orchestration only, no duplicated business logic.
- Documentation: ERD, schema docs, API docs, README, setup instructions.

**Out of scope (state this explicitly in your README so scope creep doesn't dilute the story):**
- Real payment gateway integration (payments are recorded, not processed).
- Real courier API integration (shipment status is recorded, not tracked live).
- Authentication/authorization beyond a basic placeholder (unless you choose to add JWT as a stretch goal — see §7).
- Frontend UI (this is a backend/data portfolio piece, not a full-stack app — a UI is optional future work, not a requirement).

---

## 3. High-Level Functional Requirements

| ID | Requirement | Owned by |
|---|---|---|
| FR-1 | Manage a product catalogue organised into categories, with accurate stock levels | Database |
| FR-2 | Register and maintain customer records | Database |
| FR-3 | Place an order consisting of one or more products, validated against live stock | Database (procedure) + API (orchestration) |
| FR-4 | Record and confirm payment against an order | Database (procedure) + API |
| FR-5 | Create and update shipment/delivery status, gated by payment confirmation | Database (procedure) + API |
| FR-6 | Prevent invalid states at the data layer regardless of which client writes to it | Database (constraints + triggers) |
| FR-7 | Report on sales, stock, and order status without ad-hoc queries scattered across the app | Database (views) |
| FR-8 | Expose the above as a documented REST API | Spring Boot |

---

## 4. Low-Level Functional Requirements

Each low-level requirement below states the acceptance criteria and *where* it's enforced. This mapping is the core engineering artifact of the project — it should appear in your README as a table, because it's the single clearest signal of "this person understands layered architecture."

### FR-3: Place an order
- **LFR-3.1** An order cannot be created for a non-existent customer. → FK constraint (`orders.customer_id`).
- **LFR-3.2** An order must contain at least one item; an order header can never exist without item rows. → `place_order` stored procedure runs both inserts in a single transaction.
- **LFR-3.3** An item's quantity must be > 0. → CHECK constraint (`order_item.quantity`).
- **LFR-3.4** An order cannot be placed for more than the available stock of a product. → `BEFORE INSERT` trigger on `order_item` raises an application error (`RAISE_APPLICATION_ERROR`) if requested quantity exceeds `product.stock_quantity`.
- **LFR-3.5** Placing an order automatically decrements stock. → `AFTER INSERT` trigger on `order_item`.
- **LFR-3.6** `orders.total_amount` always reflects the sum of its line items. → Trigger recalculates on INSERT/UPDATE/DELETE of `order_item`.
- **LFR-3.7** `POST /api/orders` — API validates the request shape (customer exists, items non-empty, quantities positive) *before* calling the procedure, then surfaces a clean 4xx with a message if the procedure raises a stock error, rather than leaking a raw Oracle error to the client.

### FR-4: Payment
- **LFR-4.1** Every order gets exactly one payment record, in `Pending` status, created at order placement. → Same transaction as `place_order`.
- **LFR-4.2** A payment's amount must equal its order's total. → Validated inside `confirm_payment` procedure.
- **LFR-4.3** `POST /api/orders/{id}/payment` — confirms payment; returns 409 if amount mismatch or order already confirmed.

### FR-5: Shipment
- **LFR-5.1** A shipment can only be created once payment is `Confirmed`. → Checked inside `create_shipment` procedure.
- **LFR-5.2** An order's status cannot move to `Shipped`/`Delivered` while payment is not `Confirmed`. → CHECK constraint + trigger validation.
- **LFR-5.3** `POST /api/orders/{id}/shipment` — returns 409 with a clear message if payment isn't confirmed yet, rather than a generic 500.

### FR-6: Data integrity (cross-cutting)
- **LFR-6.1** Every FK relationship in the ERD is enforced at the DB level — not assumed by the application.
- **LFR-6.2** Every enumerated status field (`order_status`, `payment_status`, `payment_method`, `delivery_status`) is constrained by CHECK, not just validated in Java.
- **LFR-6.3** Indexes exist on every FK column and on columns used in the reporting views' WHERE/JOIN clauses.

### FR-7: Reporting
- **LFR-7.1** `v_order_status` — one row per order with customer name, item count, total, payment status, delivery status.
- **LFR-7.2** `v_low_stock` — products where `stock_quantity < reorder_level`.
- **LFR-7.3** `v_sales_by_category` — revenue and units sold, grouped by category, for a given period.
- **LFR-7.4** `GET /api/reports/*` — thin endpoints that `SELECT * FROM` these views. No business logic here — if you find yourself writing a WHERE clause in the Java service layer for a report, that logic belongs in the view instead.

---

## 5. Non-Functional Requirements

| Requirement | Why it matters here |
|---|---|
| 3NF schema, no repeating groups | Baseline correctness — the assignment marks this directly |
| Every write path enforces its own invariants regardless of caller | Proves you understand "don't trust the application layer alone" |
| API errors are meaningful (4xx + message), never a raw stack trace | Signals production-mindedness, not tutorial-mindedness |
| Code is modular: controller / service / repository / domain separated | Signals you know Spring Boot idiom, not just "it compiles" |
| Every class has a single, nameable responsibility | Directly assessable in a code review — recruiters look for this |
| README lets a stranger run the project in under 10 minutes | Most recruiter portfolio reviews are 2–5 minutes; friction kills the impression |

---

## 6. Architecture

```
urbancart/
├── database/                  # Graded deliverable — pure Oracle SQL
│   ├── 00_create_schema_user.sql
│   ├── ddl/                   # tables, sequences, indexes
│   ├── triggers/
│   ├── procedures/
│   ├── views/
│   └── seed-data/
├── api/                       # Portfolio extension — Spring Boot
│   ├── src/main/java/com/urbancart/
│   │   ├── domain/            # entities + inheritance hierarchy (see §7)
│   │   ├── repository/        # Spring Data JPA interfaces
│   │   ├── service/           # business orchestration, calls procedures
│   │   ├── controller/        # REST endpoints
│   │   ├── dto/                # request/response objects — never expose entities directly
│   │   └── exception/         # custom exceptions + a global @ControllerAdvice handler
│   └── src/test/java/...      # unit + integration tests
└── docs/
    ├── erd.png
    ├── api-spec.yaml           # OpenAPI/Swagger
    └── README.md
```

**Rule of thumb that keeps this defensible in an interview:** if you can point at any piece of logic and say "this lives here because—", you've done the job. If the honest answer is "it's here because that's where I put it," refactor it before you submit.

---

## 7. Spring Boot Layer — OOP, Modularity, Inheritance, DSA

This section is written to your stated requirements: OOP, modular code, class inheritance, DSA where it fits naturally, inline comments throughout.

**Domain model / inheritance:**
- Define an abstract base class, e.g. `AuditableEntity`, holding shared fields (`id`, `createdAt`, `updatedAt`) — `Customer`, `Product`, `Orders`, `Payment`, `Shipment` all extend it. This is a legitimate, non-forced use of inheritance (shared audit behaviour), not inheritance for its own sake.
- Consider a small interface hierarchy for status-bearing entities, e.g. `interface StatusTracked { String getStatus(); void transitionTo(String newStatus); }`, implemented by `Orders`, `Payment`, `Shipment` — gives you real polymorphism to point to, and a natural home for state-transition validation on the Java side that mirrors the DB triggers (defence in depth, and a good interview talking point: "I enforce it twice, once at each boundary, and here's why that's not redundant").

**Modularity:**
- Strict controller → service → repository separation. Controllers do not contain business logic. Services do not know about HTTP.
- DTOs at the API boundary; JPA entities never returned directly from a controller (prevents leaking internal schema, a real production concern worth having in your back pocket for interviews).
- A custom unchecked exception hierarchy (e.g. `InsufficientStockException`, `PaymentMismatchException`, `InvalidStateTransitionException` extending a common `UrbanCartException`), caught centrally by a `@ControllerAdvice` and mapped to proper HTTP status codes.

**DSA — pick 2–3 of these, done well, rather than forcing DSA everywhere:**
- **Min-heap / `PriorityQueue`** for the low-stock report: rank products by urgency (`stock_quantity / reorder_level` ratio) instead of returning the view's raw row order — a legitimate, explainable use of a heap.
- **HashMap-based in-memory cache** for category lookups (read-heavy, rarely-changing reference data) — demonstrates you understand when caching is appropriate and the eviction/staleness trade-off, without needing Redis.
- **Custom comparator-based sort** for an "orders by priority" endpoint (e.g. sort by a composite of order age + total value) — shows you can reach past `ORDER BY` when the sort logic doesn't belong in SQL.
- Document *why* each one was chosen in an inline comment and in the README — an unexplained `PriorityQueue` reads as decoration; an explained one reads as judgement.

**Inline comments:** aim for comments that explain *why*, not *what* (the code already says what). E.g. `// Using a heap here instead of sorting the full list — we only ever need the top N urgent items, not a full ordering.`

---

## 8. Stretch Goals (only after core requirements are solid)

1. JWT-based auth on the API (proves you can do more than CRUD).
2. Swagger/OpenAPI docs auto-generated and published alongside the README.
3. Dockerfile + docker-compose for the API (Oracle itself is heavier to containerise — document this trade-off rather than attempting it under time pressure).
4. A small integration test suite using Testcontainers or an in-memory profile, proving the API's error handling against real constraint violations.

---

## 9. Definition of Done

- [ ] Phase 1–3 Word documents finalised and internally consistent with the actual SQL delivered.
- [ ] All DDL, triggers, procedures, views, indexes run cleanly from a fresh schema.
- [ ] Seed data present; every reporting view returns sensible results against it.
- [ ] Spring Boot API covers FR-3 through FR-7 with meaningful error responses.
- [ ] README explains: the scenario, the architecture, the FR-to-enforcement mapping table (§4), how to run it, and what's explicitly out of scope.
- [ ] Repo pushed to GitHub with a clean commit history (not one giant commit).
