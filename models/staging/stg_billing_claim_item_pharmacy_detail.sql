-- =================================================================================
-- Staging Layer: Billing Claim Item Pharmacy Detail
-- Name: stg_billing_claim_item_pharmacy_detail
-- Source Tables: OLTP_DB.Billing.ClaimItemPharmacyDetail
-- Purpose: 
--   Extract pharmacy claim details for revenue analysis, particularly for 
--   drug revenue metrics required in the analytics requirements.
-- Key Transformations:
--   • Rename columns for consistency
--   • Extract relevant pharmacy attributes
-- Usage:
--   • Source for drug-specific revenue metrics
--   • Feeds into finance.fct_revenue fact table
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim_item_pharmacy_detail AS
SELECT
  Id                            AS claim_item_pharmacy_detail_id,
  -- ClaimItem_Id is not directly listed but implied by FK_ClaimItemPharmacyDetail_ClaimItem
  -- Assuming ClaimItem_Id exists based on FK, needs verification if join is required.
  -- The following columns are NOT found in Billing.ClaimItemPharmacyDetail documentation
  -- and likely belong to a different source table (e.g., Pharmacy.PrescriptionFillItem).
  -- Commenting them out until the correct source is identified.
  -- DrugUnit_Id                   AS drug_unit_id,
  -- PrescriptionFill_Id          AS prescription_fill_id,
  -- NDC                          AS ndc_code,
  -- LabelName                    AS label_name,
  -- DrugCost                     AS drug_cost,
  -- Quantity                     AS quantity,
  -- DaysSupply                   AS days_supply,
  -- RefillNumber                 AS refill_number,
  -- RefillsAuthorized            AS refills_authorized,
  -- DispensedAsWritten          AS dispensed_as_written,
  -- PriorAuth                    AS prior_auth,
  -- CompoundCode                 AS compound_code,
  -- UnitDoseIndicator            AS unit_dose_indicator,
  -- DEASchedule                  AS dea_schedule,

  -- Columns actually present in Billing.ClaimItemPharmacyDetail:
  IsPrimaryDrug                 AS is_primary_drug,
  CoAgentNDC                    AS co_agent_ndc,
  CompoundProductIDQualifier_Id AS compound_product_id_qualifier_id,
  Cost                          AS cost,
  SalesTax                      AS sales_tax,
  IncentiveAmountSubmitted      AS incentive_amount_submitted,
  IngredientGrossAmountDue      AS ingredient_gross_amount_due,
  PatientPaidAmount             AS patient_paid_amount,
  BasisOfCostDetermination_Id   AS basis_of_cost_determination_id,
  RevenueCode_Id                AS revenue_code_id,
  LevelOfEffort_Id              AS level_of_effort_id,
  LevelOfService_Id             AS level_of_service_id,
  ProcedureModifier1            AS procedure_modifier_1,
  ProcedureModifier2            AS procedure_modifier_2,
  ProcedureModifier3            AS procedure_modifier_3,
  ProcedureModifier4            AS procedure_modifier_4,

  -- Standard audit columns (assuming they exist, not explicitly listed but common)
  -- CreatedBy                    AS created_by,
  -- CreatedDate                  AS created_date,
  -- ModifiedBy                   AS modified_by,
  -- ModifiedDate                 AS modified_date,
  RecStatus                     AS record_status -- Assuming RecStatus exists based on WHERE clause
FROM OLTP_DB.Billing.ClaimItemPharmacyDetail
WHERE RecStatus = 1; -- Assuming RecStatus exists, needs verification from docs if not standard.