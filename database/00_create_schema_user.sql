-- =====================================================================
-- UrbanCart Database Project — Solo project (Nkululeko)
-- Script 00: Create the dedicated schema user
-- Run this ONCE, connected as SYSTEM (or SYS) on the FREEPDB1 service.
-- Purpose: keep all UrbanCart objects in their own schema instead of
-- building under SYSTEM, matching how a real Oracle deployment is set up.
-- =====================================================================

-- Change the password below before running. Keep it somewhere safe —
-- you will use it every time you connect SQL Developer to this project.
CREATE USER urbancart IDENTIFIED BY "UrbanCart_2026!"
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users;

-- CONNECT  -> lets the user log in (CREATE SESSION)
-- RESOURCE -> lets the user create tables, sequences, triggers, procedures
-- CREATE VIEW -> not included in RESOURCE, so granted separately
GRANT CONNECT, RESOURCE TO urbancart;
GRANT CREATE VIEW TO urbancart;

-- After running this script, open a NEW connection in SQL Developer:
--   Username: urbancart
--   Password: (whatever you set above)
--   Hostname: localhost   Port: 1521   Service name: FREEPDB1
-- All remaining scripts (tables, sequences, triggers, procedures, views,
-- seed data) are run while connected AS urbancart, not as SYSTEM.
