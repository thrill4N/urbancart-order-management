-- =====================================================================
-- UrbanCart Database Project — run_all.sql
-- Run this from SQL Developer (or sqlplus) while positioned in the
-- /database folder, connected AS urbancart (except 00, which is run
-- separately as SYSTEM — see README.md).
-- =====================================================================

@ddl/01_sequences.sql
@ddl/02_tables.sql
@ddl/03_indexes.sql
@types/04_types.sql
@triggers/05_triggers.sql
@procedures/06_procedures.sql
@views/07_views.sql
@seed-data/08_seed_data.sql
@test-queries/09_test_queries.sql
