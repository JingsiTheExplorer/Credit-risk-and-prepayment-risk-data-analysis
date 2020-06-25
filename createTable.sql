-- create acquisition table
CREATE TABLE public.fannie_acquisition
( loan_identifier varchar,
 origination_channel varchar,
 seller_name varchar,
 original_interest_rate float8,
 original_upb int,
 original_loan_term int,
 origination_date date,
 first_payment_date date,
 original_LTV int,
 original_CLTV int,
 number_of_borrowers int,
 original_dti int,
 borrower_credit_score_orig int,
 first_time_home_buyer varchar,
 loan_purpose varchar,
 property_type varchar,
 number_of_units varchar,
 occupancy_type varchar,
 property_state varchar,
 zip_code_short varchar,
 primary_mortgage_insurance_percent int,
 product_type varchar,
 coborrower_credit_score_orig int,
 mortgage_insurance_type int,
 relocation_mortgage varchar, primary key(loan_identifier);
 
 -- upload acquisition data
 copy public.fannie_acquisition
 (loan_identifier, origination_channel, seller_name, original_interest_rate, original_upb, original_loan_term, 
  origination_date, first_payment_date, original_LTV, original_CLTV, number_of_borrowers, original_dti,
  borrower_credit_score_orig, first_time_home_buyer, loan_purpose, property_type, number_of_units, occupancy_type,
  property_state, zip_code_short, primary_mortgage_insurance_percent, product_type, coborrower_credit_score_orig,
 mortgage_insurance_type, relocation_mortgage)
 FROM '/Users/jingsixu/OneDrive-umd/OneDrive - umd.edu/Weicepts intern/2018Q1/Acquisition_2018Q1.txt' 
 (DELIMITER '|', NULL '');
 
 -- create performance table
 CREATE TABLE public.fannie_performance
( loan_identifier varchar not null,
 monthly_reporting_period date,
 servicer_name varchar,
 current_interest_rate float8,
 current_actual_upb float8,
 loan_age int,
 remaining_months_to_legal_maturity int,
  adjusted_months_to_maturity int,
 maturity_date varchar,
  msa varchar,
  current_loan_delinquency_status varchar,
  modification_flag varchar,
  zero_balance_code varchar,
  zero_balance_effective_date varchar,
  last_paid_installment_date varchar,
  foreclosure_date varchar,
  disposition_date varchar,
  foreclosure_costs int,
  property_preservation_and_repair_costs int,
  asset_recovery_costs int,
  miscellaneous_holding_expenses_and_credits int,
  associated_taxes_for_holding_property int,
  net_sale_proceeds int,
  credit_enhancement_proceeds int,
  repurchase_make_whole_proceeds int,
  other_foreclosure_proceeds int,
  non_interest_bearing_upb int,
  principal_forgiveness_amount int,
  repurchase_make_whole_proceeds_flag varchar,
  foreclosure_principal_writeoff_amount int,
  servicing_activity_indicator varchar)
 )
 
 -- upload performance data
 copy public.fannie_performance 
(loan_identifier, monthly_reporting_period, servicer_name, current_interest_rate, 
 current_actual_upb, loan_age, remaining_months_to_legal_maturity, adjusted_months_to_maturity, 
 maturity_date, msa, current_loan_delinquency_status, modification_flag, zero_balance_code, 
 zero_balance_effective_date, last_paid_installment_date, foreclosure_date, disposition_date, 
 foreclosure_costs, property_preservation_and_repair_costs, asset_recovery_costs, 
 miscellaneous_holding_expenses_and_credits, associated_taxes_for_holding_property, 
 net_sale_proceeds, credit_enhancement_proceeds, repurchase_make_whole_proceeds, 
 other_foreclosure_proceeds, non_interest_bearing_upb, principal_forgiveness_amount, 
 repurchase_make_whole_proceeds_flag, foreclosure_principal_writeoff_amount, 
 servicing_activity_indicator) 
 FROM '/Users/jingsixu/OneDrive-umd/OneDrive - umd.edu/Weicepts intern/2018Q1/Performance_2018Q1.txt' 
 (DELIMITER '|', NULL '');