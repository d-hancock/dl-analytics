-- =================================================================================
-- 9. Party View
-- Name: party
-- Source Tables: OLTP_DB.Common.Party
-- Purpose: Core party entity for customers, payers, and vendors.
-- Key Transformations:
--   • Rename primary key to `party_id`.
--   • Expose status flag for active/inactive parties.
-- Usage:
--   • Join to invoices, payments, and carrier tables for master data.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.party AS
SELECT
  PartyKey              AS party_id,
  Status                AS status_flag
FROM OLTP_DB.Common.Party;