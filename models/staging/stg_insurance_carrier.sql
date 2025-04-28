-- =================================================================================
-- Staging Layer: Insurance Carrier
-- Name: stg_insurance_carrier
-- Source Tables: OLTP_DB.Insurance.Carrier
-- Purpose: 
--   Extract insurance carrier/payer details for financial analysis.
-- Key Transformations:
--   • Rename primary key to `carrier_id`
--   • Extract relevant carrier attributes
-- Usage:
--   • Source for payer dimension
--   • Enables analysis by payer category
--   • Supports the dimensional requirements in the dashboard
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.insurance_carrier AS
SELECT
  Id                                    AS carrier_id,
  CarrierType_Id                        AS carrier_type_id,
  PayorType_Id                          AS payor_type_id,
  Identifier                            AS carrier_identifier,
  AutomaticBillingMethod_Id             AS automatic_billing_method_id,
  AutomaticBillingMethodPerDiemType_Id  AS automatic_billing_method_per_diem_type_id,
  PrescriptionBillingMethod_Id          AS prescription_billing_method_id,
  Collector_Id                          AS collector_id,
  Biller_Id                             AS biller_id,
  BatchBillingMethod_Id                 AS batch_billing_method_id,
  NumberOfDaysAfterForBillingFollowupNote AS days_for_billing_followup,
  NumberOfDaysOutForTimelyFiling        AS days_for_timely_filing,
  UseMedicareModifiersForRecurringRentals AS use_medicare_modifiers_for_recurring_rentals,
  DefaultTypeOfService                  AS default_type_of_service,
  AutoSplitPerDiemsForDailyBilling      AS auto_split_per_diems_for_daily_billing,
  DefaultPercentageOfCoverage           AS default_percentage_of_coverage,
  IsSupplementary                       AS is_supplementary,
  IsIncludedIn340BExport                AS is_included_in_340b_export,
  OptionalOrganizationName              AS optional_organization_name,
  BillingOrganizationName               AS billing_organization_name,
  ProviderNumberQualifier_Id            AS provider_number_qualifier_id,
  AuthorizationRequirement_Id           AS authorization_requirement_id,
  UseMedicareRules                      AS use_medicare_rules,
  ClaimInsuranceType_Id                 AS claim_insurance_type_id,
  ElectronicClaimType_Id                AS electronic_claim_type_id,
  UseICD9DiagnosisCodes                 AS use_icd9_diagnosis_codes,
  HoldClaimFromRRForInitialPayment      AS hold_claim_from_rr_for_initial_payment,
  IsBilledInHcpcUnits                   AS is_billed_in_hcpc_units,
  LegacyId                              AS legacy_id,
  IsAlwaysBilledForDenial               AS is_always_billed_for_denial,
  IsMedicareCBAProvider                 AS is_medicare_cba_provider,
  UseMedicareCPAPBiPAPCoverageRules     AS use_medicare_cpap_bipap_coverage_rules,
  TaxAssessment_Id                      AS tax_assessment_id,
  TaxClaimOption_Id                     AS tax_claim_option_id,
  TaxHcpc_Id                            AS tax_hcpc_id,
  UseBenefitsVerification               AS use_benefits_verification,
  IsCoPayAssistanceFunder               AS is_copay_assistance_funder,
  IsTrackGrantFunds                     AS is_track_grant_funds,
  CreatedBy                             AS created_by,
  CreatedDate                           AS created_date,
  ModifiedBy                            AS modified_by,
  ModifiedDate                          AS modified_date,
  RecStatus                             AS record_status
FROM OLTP_DB.Insurance.Carrier
WHERE RecStatus = 1;  -- Only include active records