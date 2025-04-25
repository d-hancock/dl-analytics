create or replace procedure FIN_DB.proc.refresh_analytics()
returns string
language sql
as
$$
declare
  result string;
begin
  -- Create or refresh views by copying from dev schema to production
  
  -- Refresh base views
  execute immediate 'create or replace view staging.stg_discharge_summary as select * from dev_schema.stg_discharge_summary';
  execute immediate 'create or replace view staging.stg_patient_referrals as select * from dev_schema.stg_patient_referrals';
  execute immediate 'create or replace view staging.stg_patient_status_history as select * from dev_schema.stg_patient_status_history';
  execute immediate 'create or replace view staging.stg_drug_claim_items as select * from dev_schema.stg_drug_claim_items';

  -- Refresh intermediate views
  execute immediate 'create or replace view intermediate.int_fct_new_starts as select * from dev_schema.int_fct_new_starts';
  execute immediate 'create or replace view intermediate.int_fct_referrals as select * from dev_schema.int_fct_referrals';
  execute immediate 'create or replace view intermediate.int_fct_drug_revenue as select * from dev_schema.int_fct_drug_revenue';
  execute immediate 'create or replace view intermediate.int_fct_discharged_patients as select * from dev_schema.int_fct_discharged_patients';

  -- Refresh KPI layer
  execute immediate 'create or replace view marts.finance.kpi_new_starts as select * from dev_schema.kpi_new_starts';
  execute immediate 'create or replace view marts.finance.kpi_drug_revenue as select * from dev_schema.kpi_drug_revenue';
  execute immediate 'create or replace view marts.finance.kpi_referrals as select * from dev_schema.kpi_referrals';
  execute immediate 'create or replace view marts.finance.kpi_discharged_patients as select * from dev_schema.kpi_discharged_patients';

  -- Refresh final summary
  execute immediate 'create or replace view marts.finance.kpi_finance_summary as select * from dev_schema.kpi_finance_summary';
  
  result := 'Financial KPI dataset refresh completed successfully.';
  return result;

exception
  when other then
    result := 'Error: ' || SQLCODE || ' - ' || SQLERRM;
    return result;
end;
$$;