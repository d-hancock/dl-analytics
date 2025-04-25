CREATE OR REPLACE VIEW stg_billing_claim AS
SELECT
    Id                             AS claim_id,
    Patient_Id                     AS patient_id,
    Carrier_Id                     AS carrier_id,
    BillingProvider_Id             AS provider_id,
    ServiceFromDate                AS claim_start_date,
    ServiceToDate                  AS claim_end_date,
    ClaimType_Id                   AS claim_type_id,
    Record_Status_Id               AS record_status
FROM OLTP_DB.Billing.Claim
WHERE Record_Status_Id = 1;

CREATE OR REPLACE VIEW stg_billing_claim_item AS
SELECT
    Id                             AS claim_item_id,
    Claim_Id                       AS claim_id,
    InventoryItem_Id               AS inventory_item_id,
    Quantity,
    ExpectedPrice                  AS unit_price,
    TotalExpectedPrice             AS total_expected_price,
    ServiceFromDate                AS service_from_date,
    ServiceToDate                  AS service_to_date,
    RecStatus                      AS record_status
FROM OLTP_DB.Billing.ClaimItem
WHERE RecStatus = 1;

CREATE OR REPLACE VIEW stg_date_dimension AS
SELECT
    Id                         AS date_id,
    DayDate                    AS calendar_date,
    DayNameLong                AS day_of_week_name,
    DayOfCalendarMonth         AS day_of_month,
    DayOfCalendarYear          AS day_of_year,
    CalendarMonthId            AS month_id,
    CalendarQuarterId          AS quarter_id,
    CalendarYearId             AS year_id
FROM OLTP_DB.Utilities.Date;

CREATE OR REPLACE VIEW stg_encounter_discharge_summary AS
SELECT
    Id                        AS discharge_id,
    PatientEncounter_Id       AS patient_encounter_id,
    DischargeDate             AS discharge_date,
    DischargeStatus_Id        AS discharge_status_id,
    PatientStatus_Id          AS patient_status_id,
    DischargeReason_Id        AS discharge_reason_id,
    DischargeAcuity_Id        AS discharge_acuity_id,
    RecStatus                 AS record_status
FROM OLTP_DB.Encounter.DischargeSummary
WHERE RecStatus = 1;

CREATE OR REPLACE VIEW stg_patient_referrals AS
SELECT
    Id                        AS referral_id,
    Patient_Id                AS patient_id,
    ReferralSource_Id         AS referral_source_id,
    ReferralRequest           AS referral_request,
    ReferralDate              AS referral_date,
    ReferralResponseDate      AS response_date,
    ResponseStatus_Id         AS response_status_id,
    RecStatus                 AS record_status
FROM OLTP_DB.Patient.PatientReferrals
WHERE RecStatus = 1;

CREATE OR REPLACE VIEW stg_patient_order AS
SELECT
    Id                        AS order_id,
    Patient_Id                AS patient_id,
    TherapyType_Id            AS therapy_type_id,
    PatientOrderStatus_Id     AS order_status_id,
    OrderedDate               AS ordered_date,
    StartDate                 AS start_date,
    StopDate                  AS stop_date,
    DiscontinuedDate          AS discontinued_date,
    InventoryItem_Id          AS inventory_item_id,
    InventoryItemType_Id      AS inventory_item_type_id,
    Provider_Id               AS provider_id,
    Record_Status_Id          AS record_status
FROM OLTP_DB.Prescription.PatientOrder
WHERE Record_Status_Id = 1;