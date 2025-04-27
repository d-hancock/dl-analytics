CREATE OR REPLACE PROCEDURE sp_build_analytics_views()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    build_message STRING;
    error_message STRING;
    affected_rows INTEGER;
BEGIN
    build_message := 'CareTend Analytics View Builder\n';
    build_message := build_message || '--------------------------\n';
    build_message := build_message || 'Started: ' || CURRENT_TIMESTAMP() || '\n\n';
    
    -- Track successful builds
    LET staging_views_built INTEGER := 0;
    LET intermediate_views_built INTEGER := 0;
    LET marts_views_built INTEGER := 0;
    LET presentation_views_built INTEGER := 0;

    -- Catch any errors during execution
    BEGIN
        
        build_message := build_message || '1. Building Staging Layer Views\n';
        build_message := build_message || '----------------------------\n';
        
        -- Drop and rebuild stg_date_dimension
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_date_dimension';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_date_dimension AS
            SELECT 
                CalendarDate           AS calendar_date,
                FiscalPeriodId         AS fiscal_period_key,
                FiscalYear             AS fiscal_year,
                FiscalQuarter          AS fiscal_quarter,
                FiscalMonth            AS fiscal_month,
                CalendarYear           AS calendar_year,
                CalendarQuarter        AS calendar_quarter,
                CalendarMonth          AS calendar_month,
                DayOfWeek              AS day_of_week,
                IsWeekend              AS is_weekend,
                IsHoliday              AS is_holiday,
                CalendarMonthStartDate AS month_start_date,
                CalendarMonthEndDate   AS month_end_date,
                CalendarQuarterStartDate AS quarter_start_date
            FROM OLTP_DB.Utilities.Date;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_date_dimension\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_date_dimension - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_facility_dimension
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_facility_dimension';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_facility_dimension AS
            SELECT 
                facility_id,
                facility_name,
                facility_type,
                address_id,
                state_id,
                region_id,
                is_active
            FROM OLTP_DB.Facility.Facility
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_facility_dimension\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_facility_dimension - ' || error_message || '\n';
        END;
            
        -- Drop and rebuild stg_patient_dimension 
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_patient_dimension';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_patient_dimension AS
            SELECT
                p.patient_id,
                p.first_name,
                p.last_name,
                p.birth_date,
                p.gender_id,
                p.admission_date,
                p.assigned_team_id,
                p.patient_status_id,
                p.record_status
            FROM OLTP_DB.Patient.Patient p
            WHERE p.record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_patient_dimension\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_patient_dimension - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_payer_dimension
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_payer_dimension';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_payer_dimension AS
            SELECT
                p.payer_id,
                p.payer_name,
                p.payer_code,
                p.payer_type_id,
                p.record_status
            FROM OLTP_DB.Billing.Payer p
            WHERE p.record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_payer_dimension\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_payer_dimension - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_provider_dimension
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_provider_dimension';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_provider_dimension AS
            SELECT
                provider_id,
                provider_name,
                npi,
                provider_type_id,
                specialty_id,
                is_active
            FROM OLTP_DB.Provider.Provider
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_provider_dimension\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_provider_dimension - ' || error_message || '\n';
        END;
            
        -- Drop and rebuild stg_patient_policy
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_patient_policy';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_patient_policy AS
            SELECT
                policy_id,
                patient_id,
                payer_id,
                effective_date,
                termination_date,
                policy_number,
                is_primary,
                record_status
            FROM OLTP_DB.Patient.PatientPolicy
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_patient_policy\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_patient_policy - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_patient_referrals
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_patient_referrals';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_patient_referrals AS
            SELECT
                referral_id,
                patient_id,
                referral_date,
                referral_status_id,
                provider_id,
                team_id,
                record_status
            FROM OLTP_DB.Patient.PatientReferrals
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_patient_referrals\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_patient_referrals - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_encounter_patient_encounter
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_encounter_patient_encounter';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_encounter_patient_encounter AS
            SELECT
                patient_encounter_id,
                patient_id,
                encounter_date,
                encounter_type_id,
                provider_id,
                record_status
            FROM OLTP_DB.Encounter.PatientEncounter
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_encounter_patient_encounter\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_encounter_patient_encounter - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_encounter_discharge_summary
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_encounter_discharge_summary';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_encounter_discharge_summary AS
            SELECT 
                Id as discharge_id, 
                PatientEncounter_Id as patient_encounter_id,
                DischargeDate as discharge_date,
                DischargeStatus_Id as discharge_status_id,
                PatientStatus_Id as patient_status_id,
                DischargeReason_Id as discharge_reason_id,
                DischargeAcuity_Id as discharge_acuity_id,
                CreatedDate as created_date,
                ModifiedDate as modified_date,
                RecStatus as record_status
            FROM OLTP_DB.Encounter.DischargeSummary
            WHERE RecStatus = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_encounter_discharge_summary\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_encounter_discharge_summary - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_encounter_patient_order
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_encounter_patient_order';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_encounter_patient_order AS
            SELECT
                order_id,
                patient_id,
                order_date,
                provider_id,
                therapy_type_id,
                order_status_id,
                record_status
            FROM OLTP_DB.Prescription.PatientOrder
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_encounter_patient_order\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_encounter_patient_order - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_billing_claim
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_billing_claim';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_billing_claim AS
            SELECT
                claim_id,
                patient_id,
                facility_id,
                payer_id,
                provider_id,
                service_date,
                claim_status_id,
                total_claim_amount,
                record_status
            FROM OLTP_DB.Billing.Claim
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_billing_claim\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_billing_claim - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild stg_billing_claim_item
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.stg.stg_billing_claim_item';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.stg.stg_billing_claim_item AS
            SELECT
                claim_item_id,
                claim_id,
                product_id,
                quantity,
                unit_price,
                discount_percentage,
                expected_reimbursement,
                record_status
            FROM OLTP_DB.Billing.ClaimItem
            WHERE record_status = 1;
            ';
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: stg_billing_claim_item\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: stg_billing_claim_item - ' || error_message || '\n';
        END;
        
        build_message := build_message || '\n2. Building Intermediate Layer Views\n';
        build_message := build_message || '--------------------------------\n';
        
        -- Drop and rebuild int_dim_date
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.dim_date';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.dim_date AS
            SELECT
                calendar_date,
                fiscal_period_key,
                fiscal_year,
                fiscal_quarter,
                fiscal_month,
                calendar_year,
                calendar_quarter,
                calendar_month,
                day_of_week,
                is_weekend,
                is_holiday,
                month_start_date,
                month_end_date,
                quarter_start_date,
                LAST_DAY(calendar_date) = calendar_date AS is_month_end,
                DAY(calendar_date) AS day_of_month
            FROM DEV_DB.stg.stg_date_dimension;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_dim_date\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_dim_date - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_dim_location
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.dim_location';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.dim_location AS
            SELECT
                facility_id AS location_id,
                facility_name AS location_name,
                facility_type,
                region_id,
                state_id,
                is_active
            FROM DEV_DB.stg.stg_facility_dimension;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_dim_location\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_dim_location - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_dim_payer
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.dim_payer';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.dim_payer AS
            SELECT
                payer_id,
                payer_name,
                payer_code,
                payer_type_id,
                CASE 
                    WHEN payer_type_id = 1 THEN ''Medicare'' 
                    WHEN payer_type_id = 2 THEN ''Medicaid''
                    WHEN payer_type_id = 3 THEN ''Commercial''
                    WHEN payer_type_id = 4 THEN ''Self-Pay''
                    ELSE ''Other''
                END AS payer_type_name
            FROM DEV_DB.stg.stg_payer_dimension;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_dim_payer\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_dim_payer - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_dim_product
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.dim_product';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.dim_product AS
            SELECT
                p.product_id,
                p.product_name,
                p.product_code,
                p.product_category_id,
                pc.category_name,
                CASE 
                    WHEN pc.category_type = ''Drug'' THEN TRUE
                    ELSE FALSE
                END AS is_drug
            FROM OLTP_DB.Catalog.Product p
            JOIN OLTP_DB.Catalog.ProductCategory pc ON p.product_category_id = pc.category_id
            WHERE p.record_status = 1;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_dim_product\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_dim_product - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_dim_therapy
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.dim_therapy';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.dim_therapy AS
            SELECT
                therapy_type_id,
                therapy_name,
                therapy_description,
                therapy_class_id,
                is_active
            FROM OLTP_DB.Therapy.TherapyType
            WHERE record_status = 1;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_dim_therapy\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_dim_therapy - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_patient_dimension
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.patient_dimension';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.patient_dimension AS
            SELECT
                p.patient_id,
                p.first_name,
                p.last_name,
                p.first_name || '' '' || p.last_name AS patient_name,
                p.birth_date,
                FLOOR(DATEDIFF(DAY, p.birth_date, CURRENT_DATE()) / 365.25) AS age,
                p.gender_id,
                g.gender_name,
                p.admission_date,
                p.assigned_team_id,
                p.patient_status_id,
                ps.status_name AS patient_status_name,
                pp.payer_id AS primary_payer_id,
                py.payer_name AS primary_payer_name
            FROM DEV_DB.stg.stg_patient_dimension p
            LEFT JOIN OLTP_DB.Lookups.Gender g ON p.gender_id = g.gender_id
            LEFT JOIN OLTP_DB.Patient.PatientStatus ps ON p.patient_status_id = ps.status_id
            LEFT JOIN DEV_DB.stg.stg_patient_policy pp 
                ON p.patient_id = pp.patient_id 
                AND pp.is_primary = TRUE 
                AND CURRENT_DATE() BETWEEN pp.effective_date AND COALESCE(pp.termination_date, ''9999-12-31'')
            LEFT JOIN DEV_DB.stg.stg_payer_dimension py ON pp.payer_id = py.payer_id;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_patient_dimension\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_patient_dimension - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_fct_referrals
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.fct_referrals';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.fct_referrals AS
            SELECT
                r.referral_id,
                r.patient_id,
                r.referral_date,
                r.referral_status_id,
                r.provider_id,
                r.team_id,
                po.therapy_type_id,
                po.order_id
            FROM DEV_DB.stg.stg_patient_referrals r
            JOIN DEV_DB.stg.stg_encounter_patient_order po ON r.patient_id = po.patient_id
            WHERE r.record_status = 1;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_fct_referrals\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_fct_referrals - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_fct_new_starts
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.fct_new_starts';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.fct_new_starts AS
            SELECT
                p.patient_id,
                p.admission_date AS start_date,
                p.assigned_team_id AS team_id,
                po.therapy_type_id,
                po.order_id
            FROM DEV_DB.stg.stg_patient_dimension p
            JOIN DEV_DB.stg.stg_encounter_patient_order po ON p.patient_id = po.patient_id
            WHERE NOT EXISTS (
                -- Looking back 365 days to ensure this is truly a new start
                SELECT 1 FROM OLTP_DB.Patient.PatientStatusHistory psh
                WHERE psh.patient_id = p.patient_id
                AND psh.status_date < p.admission_date
                AND psh.status_date >= DATEADD(day, -365, p.admission_date)
            );
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_fct_new_starts\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_fct_new_starts - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_fct_discharges
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.fct_discharges';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.fct_discharges AS
            SELECT
                ds.discharge_id,
                ds.patient_encounter_id,
                pe.patient_id,
                ds.discharge_date,
                ds.discharge_status_id,
                ds.patient_status_id,
                ds.discharge_reason_id,
                p.assigned_team_id AS team_id,
                po.therapy_type_id
            FROM DEV_DB.stg.stg_encounter_discharge_summary ds
            JOIN DEV_DB.stg.stg_encounter_patient_encounter pe ON ds.patient_encounter_id = pe.patient_encounter_id
            JOIN DEV_DB.stg.stg_patient_dimension p ON pe.patient_id = p.patient_id
            JOIN DEV_DB.stg.stg_encounter_patient_order po ON p.patient_id = po.patient_id;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_fct_discharges\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_fct_discharges - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_fct_drug_revenue
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.fct_drug_revenue';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.fct_drug_revenue AS
            SELECT
                c.claim_id,
                ci.claim_item_id,
                c.service_date AS transaction_date,
                c.facility_id AS location_id,
                ci.product_id,
                c.payer_id,
                ci.quantity,
                ci.unit_price,
                ci.discount_percentage,
                ci.quantity * ci.unit_price * (1 - ci.discount_percentage/100) AS total_price
            FROM DEV_DB.stg.stg_billing_claim c
            JOIN DEV_DB.stg.stg_billing_claim_item ci ON c.claim_id = ci.claim_id
            JOIN DEV_DB.int.dim_product p ON ci.product_id = p.product_id
            WHERE p.is_drug = TRUE;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_fct_drug_revenue\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_fct_drug_revenue - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild int_fct_expected_revenue
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.int.fct_expected_revenue';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.int.fct_expected_revenue AS
            SELECT
                c.claim_id,
                ci.claim_item_id,
                c.service_date AS revenue_date,
                c.facility_id AS location_id,
                ci.product_id,
                c.payer_id,
                ci.expected_reimbursement
            FROM DEV_DB.stg.stg_billing_claim c
            JOIN DEV_DB.stg.stg_billing_claim_item ci ON c.claim_id = ci.claim_id;
            ';
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: int_fct_expected_revenue\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: int_fct_expected_revenue - ' || error_message || '\n';
        END;
        
        build_message := build_message || '\n3. Building Marts Layer Views\n';
        build_message := build_message || '----------------------------\n';
        
        -- Drop and rebuild mart layer finance.fct_revenue
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.finance.fct_revenue';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.finance.fct_revenue AS
            SELECT
                COALESCE(dr.transaction_date, er.revenue_date) AS calendar_date,
                COALESCE(dr.location_id, er.location_id) AS location_id,
                COALESCE(dr.product_id, er.product_id) AS product_id,
                p.product_category_id AS therapy_type_id,
                COALESCE(dr.payer_id, er.payer_id) AS payer_id,
                COALESCE(dr.total_price, 0) AS drug_revenue,
                COALESCE(er.expected_reimbursement, 0) AS expected_revenue,
                COALESCE(dr.total_price, 0) + COALESCE(er.expected_reimbursement, 0) AS total_revenue
            FROM DEV_DB.int.fct_drug_revenue dr
            FULL OUTER JOIN DEV_DB.int.fct_expected_revenue er 
                ON dr.claim_id = er.claim_id 
                AND dr.claim_item_id = er.claim_item_id
            JOIN DEV_DB.int.dim_product p 
                ON COALESCE(dr.product_id, er.product_id) = p.product_id;
            ';
            marts_views_built := marts_views_built + 1;
            build_message := build_message || '✓ Built: finance.fct_revenue\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: finance.fct_revenue - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild mart layer finance.fct_patient_activity
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.finance.fct_patient_activity';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.finance.fct_patient_activity AS
            SELECT
                COALESCE(r.referral_date, ns.start_date, d.discharge_date) AS calendar_date,
                COALESCE(r.team_id, ns.team_id, d.team_id) AS location_id,
                COALESCE(r.therapy_type_id, ns.therapy_type_id, d.therapy_type_id) AS therapy_type_id,
                COALESCE(r.referral_id, 0) AS referral_id,
                COALESCE(ns.patient_id, 0) AS new_start_patient_id,
                COALESCE(d.discharge_id, 0) AS discharge_id,
                CASE WHEN r.referral_id IS NOT NULL THEN 1 ELSE 0 END AS referrals,
                CASE WHEN ns.patient_id IS NOT NULL THEN 1 ELSE 0 END AS new_starts,
                CASE WHEN d.discharge_id IS NOT NULL THEN 1 ELSE 0 END AS discharged_patients,
                CASE WHEN ns.patient_id IS NOT NULL THEN 1 ELSE 0 END - 
                    CASE WHEN d.discharge_id IS NOT NULL THEN 1 ELSE 0 END AS net_patient_change
            FROM DEV_DB.int.fct_referrals r
            FULL OUTER JOIN DEV_DB.int.fct_new_starts ns 
                ON r.patient_id = ns.patient_id 
                AND r.referral_date = ns.start_date
            FULL OUTER JOIN DEV_DB.int.fct_discharges d 
                ON COALESCE(r.patient_id, ns.patient_id) = d.patient_id 
                AND COALESCE(r.referral_date, ns.start_date) = d.discharge_date;
            ';
            marts_views_built := marts_views_built + 1;
            build_message := build_message || '✓ Built: finance.fct_patient_activity\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: finance.fct_patient_activity - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild mart layer finance.kpi_revenue_metrics
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.finance.kpi_revenue_metrics';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.finance.kpi_revenue_metrics AS
            SELECT
                d.fiscal_period_key,
                d.fiscal_year,
                d.fiscal_quarter,
                d.fiscal_month,
                r.location_id,
                r.product_id,
                r.therapy_type_id,
                r.payer_id,
                SUM(r.drug_revenue) AS period_drug_revenue,
                SUM(r.total_revenue) AS period_total_expected_revenue,
                COUNT(DISTINCT d.calendar_date) AS days_in_period,
                SUM(r.total_revenue) / COUNT(DISTINCT d.calendar_date) AS period_expected_revenue_per_day,
                AVG(r.drug_revenue) AS avg_daily_drug_revenue
            FROM DEV_DB.finance.fct_revenue r
            JOIN DEV_DB.int.dim_date d ON r.calendar_date = d.calendar_date
            GROUP BY 
                d.fiscal_period_key,
                d.fiscal_year,
                d.fiscal_quarter,
                d.fiscal_month,
                r.location_id,
                r.product_id,
                r.therapy_type_id,
                r.payer_id;
            ';
            marts_views_built := marts_views_built + 1;
            build_message := build_message || '✓ Built: finance.kpi_revenue_metrics\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: finance.kpi_revenue_metrics - ' || error_message || '\n';
        END;
        
        -- Drop and rebuild mart layer finance.kpi_patient_metrics
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.finance.kpi_patient_metrics';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.finance.kpi_patient_metrics AS
            SELECT
                d.fiscal_period_key,
                d.fiscal_year,
                d.fiscal_quarter,
                d.fiscal_month,
                pa.location_id,
                pa.therapy_type_id,
                SUM(pa.referrals) AS period_referrals,
                SUM(pa.new_starts) AS period_new_starts,
                SUM(pa.discharged_patients) AS period_discharged_patients,
                SUM(pa.net_patient_change) AS period_net_patient_change,
                CASE 
                    WHEN SUM(pa.referrals) > 0 THEN SUM(pa.new_starts) / SUM(pa.referrals) 
                    ELSE 0 
                END AS referral_conversion_rate
            FROM DEV_DB.finance.fct_patient_activity pa
            JOIN DEV_DB.int.dim_date d ON pa.calendar_date = d.calendar_date
            GROUP BY 
                d.fiscal_period_key,
                d.fiscal_year,
                d.fiscal_quarter,
                d.fiscal_month,
                pa.location_id,
                pa.therapy_type_id;
            ';
            marts_views_built := marts_views_built + 1;
            build_message := build_message || '✓ Built: finance.kpi_patient_metrics\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: finance.kpi_patient_metrics - ' || error_message || '\n';
        END;
        
        build_message := build_message || '\n4. Building Presentation Layer Views\n';
        build_message := build_message || '----------------------------------\n';
        
        -- Drop and rebuild presentation layer dashboard_financial_executive
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS DEV_DB.presentation.dashboard_financial_executive';
            EXECUTE IMMEDIATE '
            CREATE VIEW DEV_DB.presentation.dashboard_financial_executive AS
            WITH date_dim AS (
                SELECT
                    d.calendar_date,
                    d.fiscal_period_key,
                    d.fiscal_year,
                    d.fiscal_quarter,
                    d.fiscal_month,
                    MIN(d.calendar_date) OVER (PARTITION BY d.fiscal_period_key) AS period_start_date,
                    MAX(d.calendar_date) OVER (PARTITION BY d.fiscal_period_key) AS period_end_date,
                    COUNT(*) OVER (PARTITION BY d.fiscal_period_key) AS days_in_period
                FROM DEV_DB.int.dim_date d
            ),
            
            patient_activity AS (
                SELECT
                    calendar_date,
                    location_id,
                    therapy_type_id,
                    referrals,
                    new_starts,
                    discharged_patients
                FROM DEV_DB.finance.fct_patient_activity
            ),
            
            revenue_metrics AS (
                SELECT
                    calendar_date,
                    location_id,
                    product_id,
                    therapy_type_id,
                    payer_id,
                    drug_revenue,
                    expected_revenue,
                    total_revenue
                FROM DEV_DB.finance.fct_revenue
            ),
            
            period_metrics AS (
                SELECT
                    fiscal_period_key,
                    location_id,
                    product_id,
                    therapy_type_id,
                    payer_id,
                    period_drug_revenue,
                    period_total_expected_revenue,
                    period_expected_revenue_per_day
                FROM DEV_DB.finance.kpi_revenue_metrics
            )
            
            SELECT 
                dd.calendar_date,
                dd.fiscal_period_key,
                dd.fiscal_year,
                dd.fiscal_quarter,
                dd.fiscal_month,
                
                -- Entity dimensions
                COALESCE(pa.location_id, rm.location_id) AS location_id,
                l.location_name,
                rm.product_id,
                p.product_name,
                COALESCE(pa.therapy_type_id, rm.therapy_type_id) AS therapy_id,
                t.therapy_name,
                rm.payer_id,
                py.payer_name,
                
                -- Patient metrics
                COALESCE(pa.discharged_patients, 0) AS discharged_patients,    
                COALESCE(pa.new_starts, 0) AS new_starts,             
                COALESCE(pa.referrals, 0) AS referrals,          
                
                -- Revenue metrics
                COALESCE(rm.drug_revenue, 0) AS drug_revenue,
                COALESCE(rm.total_revenue, 0) AS total_expected_revenue,
                COALESCE(rm.total_revenue / dd.days_in_period, 0) AS expected_revenue_per_day,
                
                -- Period metrics
                COALESCE(pm.period_total_expected_revenue, 0) AS period_total_expected_revenue,
                COALESCE(pm.period_drug_revenue, 0) AS period_drug_revenue,
                COALESCE(pm.period_expected_revenue_per_day, 0) AS period_expected_revenue_per_day
                
            FROM date_dim dd
            LEFT JOIN patient_activity pa ON dd.calendar_date = pa.calendar_date
            LEFT JOIN revenue_metrics rm 
                ON dd.calendar_date = rm.calendar_date
                AND (pa.location_id = rm.location_id OR pa.location_id IS NULL OR rm.location_id IS NULL)
                AND (pa.therapy_type_id = rm.therapy_type_id OR pa.therapy_type_id IS NULL OR rm.therapy_type_id IS NULL)
            LEFT JOIN period_metrics pm
                ON dd.fiscal_period_key = pm.fiscal_period_key
                AND COALESCE(pa.location_id, rm.location_id) = pm.location_id
                AND rm.product_id = pm.product_id
                AND COALESCE(pa.therapy_type_id, rm.therapy_type_id) = pm.therapy_type_id
                AND rm.payer_id = pm.payer_id
            LEFT JOIN DEV_DB.int.dim_location l ON COALESCE(pa.location_id, rm.location_id) = l.location_id
            LEFT JOIN DEV_DB.int.dim_product p ON rm.product_id = p.product_id
            LEFT JOIN DEV_DB.int.dim_therapy t ON COALESCE(pa.therapy_type_id, rm.therapy_type_id) = t.therapy_type_id
            LEFT JOIN DEV_DB.int.dim_payer py ON rm.payer_id = py.payer_id
            ORDER BY dd.calendar_date, location_id, rm.product_id;
            ';
            presentation_views_built := presentation_views_built + 1;
            build_message := build_message || '✓ Built: presentation.dashboard_financial_executive\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: presentation.dashboard_financial_executive - ' || error_message || '\n';
        END;
        
    EXCEPTION
        WHEN OTHER THEN
            error_message := SQLSTATE || ': ' || SQLERRM;
            build_message := build_message || '\nERROR: ' || error_message;
    END;
    
    build_message := build_message || '\n\nBuild Summary\n';
    build_message := build_message || '------------\n';
    build_message := build_message || 'Staging Views Built: ' || staging_views_built || '\n';
    build_message := build_message || 'Intermediate Views Built: ' || intermediate_views_built || '\n';
    build_message := build_message || 'Marts Views Built: ' || marts_views_built || '\n';
    build_message := build_message || 'Presentation Views Built: ' || presentation_views_built || '\n';
    build_message := build_message || 'Total Views Built: ' || (staging_views_built + intermediate_views_built + marts_views_built + presentation_views_built) || '\n';
    build_message := build_message || '\nCompleted: ' || CURRENT_TIMESTAMP();
    
    RETURN build_message;
END;
$$;