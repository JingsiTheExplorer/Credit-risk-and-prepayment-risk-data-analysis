-- calculate prepaid and scheduled_remain, SMM
create table schedule as
select sch.*,
		(sch.actual_Prin-sch.scheduled_Prin) as prepaid,	
		(sch.pre_month_upb-sch.scheduled_Prin) as scheduled_remain,
		((sch.actual_Prin-sch.scheduled_Prin)/(sch.pre_month_upb-sch.scheduled_Prin))as SMM
from(select pf.loan_identifier,  pf.monthly_reporting_period,
			ac.original_upb, ac.original_interest_rate,
			(ac.original_upb*ac.original_interest_rate/1200*(1+ac.original_interest_rate/1200)^ac.original_loan_term/((1+ac.original_interest_rate/1200)^ac.original_loan_term-1)) as amortization,
			(pf.pre_month_upb*ac.original_interest_rate/1200) as interest,
			((ac.original_upb*ac.original_interest_rate/1200*(1+ac.original_interest_rate/1200)^ac.original_loan_term/((1+ac.original_interest_rate/1200)^ac.original_loan_term-1))- (pf.pre_month_upb*ac.original_interest_rate/1200)) as scheduled_Prin,
			pf.current_actual_upb,
	 		pf.pre_month_upb,
	 		(pf.pre_month_upb - pf.current_actual_upb) as actual_Prin
	from (select *, 
			lag(p.current_actual_upb) over (partition by p.loan_identifier order by p.monthly_reporting_period) as pre_month_upb
		   from fannie_performance p) as pf
	left join fannie_acquisition ac
	on pf.loan_identifier = ac.loan_identifier) as sch;	

-- method1:1.SMM for each loan each month, 2.then aggregate
create table cpr1 as
select monthly_reporting_period,
		(sum(smm)/count(smm))as smm_month,
		(1-(1-(sum(smm)/count(smm)))^12) as CPR
from schedule
group by monthly_reporting_period;

-- method2:1.sum 2.calculate ratio
create table cpr2 as
select monthly_reporting_period,
		(sum(prepaid)/sum(scheduled_remain))as smm_month,
		(1-(1-(sum(prepaid)/sum(scheduled_remain)))^12) as CPR
from schedule
group by monthly_reporting_period;

--CPR calculation methods compare
create table cpr_compare as
select monthly_reporting_period,
		(1-(1-(sum(smm)/count(smm)))^12) as CPR1,
		(1-(1-(sum(prepaid)/sum(scheduled_remain)))^12) as CPR2
from schedule
group by monthly_reporting_period;

------------------------------------------------------------------------------
-- check paid off prepayment
select loan_identifier,monthly_reporting_period, current_actual_upb,
		zero_balance_code, zero_balance_effective_date
from fannie_performance
limit 500;

--- check '01' if the last row upb is the same with the the last second row upb
select loan_identifier,monthly_reporting_period, current_actual_upb, pre_upb,
		(pre_upb - current_actual_upb) as diff,
		zero_balance_code, zero_balance_effective_date			
from(select loan_identifier,monthly_reporting_period, current_actual_upb,
	 		lag(current_actual_upb) over (partition by loan_identifier order by monthly_reporting_period asc) pre_upb,
			zero_balance_code, zero_balance_effective_date,
			row_number() over (partition by loan_identifier order by monthly_reporting_period desc) as rn
	 from fannie_performance) as with_rn
where rn = 1
	  and (pre_upb - current_actual_upb) != 0 
	  and loan_identifier in (select distinct loan_identifier
								from fannie_performance
								where zero_balance_code = '01');

create table fannie_performance2 as table fannie_performance;

update fannie_performance2
set current_actual_upb = 0::float8
where zero_balance_code = '01';
----------------------------------the following is useless for now-------------------------------------
-- insert another row for the following month when zero_balance_code equals zero
-- step1:Extract the last row of prepaid loan (67775 loans includes 2 zero upb and 1 null upb)	
create temp table extract_prepay as
select distinct on (loan_identifier) loan_identifier, monthly_reporting_period, current_actual_upb, zero_balance_code
from fannie_performance
where zero_balance_code = '01' and current_actual_upb != 0
order by loan_identifier, monthly_reporting_period desc;

-- check 2 loan with current upb = 0 and null and zero balance code = 01, turns out they are also prepaid
--- find out the three loans with current upb is not !=0
select distinct loan_identifier
from fannie_performance
where zero_balance_code = '01'
except
	select distinct loan_identifier
	from fannie_performance
	where zero_balance_code = '01' and current_actual_upb != 0;
-- '516363262016','857448576731' upb=0, '931558953451' upb is null
select loan_identifier, monthly_reporting_period, current_actual_upb, zero_balance_code, zero_balance_effective_date
from fannie_performance
where loan_identifier = '163319714766';

update fannie_performance
set current_actual_upb = 0::float8
where loan_identifier = '931558953451' and monthly_reporting_period = to_date('10/01/2019','mm/dd/yyyy')

-- step2:update step1 table, delay one month
create table paidoffRow as
select loan_identifier, (monthly_reporting_period+interval '1 month')::date as monthly_reporting_period , 
		0::float8 as current_actual_upb, zero_balance_code
from extract_prepay

-- step3:add paid of row to performance data
select count(*) from extract_prepay  --67772
select count(*) from fannie_performance --9332050

create table curtail_paidoff_pf as
select * from paidoffRow
union all
select loan_identifier, monthly_reporting_period, current_actual_upb, zero_balance_code from fannie_performance
order by loan_identifier, monthly_reporting_period;

-- calculate cpr for both curtailment and paid-off prepayment
-- calculate prepaid and scheduled_remain, SMM
create table schedule_curtail_paidoff as
select sch.*,
		(sch.actual_Prin-sch.scheduled_Prin) as prepaid,	
		(sch.pre_month_upb-sch.scheduled_Prin) as scheduled_remain,
		((sch.actual_Prin-sch.scheduled_Prin)/(sch.pre_month_upb-sch.scheduled_Prin))as SMM
from(select pf.loan_identifier,  pf.monthly_reporting_period,
			ac.original_upb, ac.original_interest_rate,
			(ac.original_upb*ac.original_interest_rate/1200*(1+ac.original_interest_rate/1200)^ac.original_loan_term/((1+ac.original_interest_rate/1200)^ac.original_loan_term-1)) as amortization,
			(pf.pre_month_upb*ac.original_interest_rate/1200) as interest,
			((ac.original_upb*ac.original_interest_rate/1200*(1+ac.original_interest_rate/1200)^ac.original_loan_term/((1+ac.original_interest_rate/1200)^ac.original_loan_term-1))- (pf.pre_month_upb*ac.original_interest_rate/1200)) as scheduled_Prin,
			pf.current_actual_upb,
	 		pf.pre_month_upb,
	 		(pf.pre_month_upb - pf.current_actual_upb) as actual_Prin
	from (select *, 
			lag(p.current_actual_upb) over (partition by p.loan_identifier order by p.monthly_reporting_period) as pre_month_upb
		   from curtail_paidoff_pf p) as pf
	left join fannie_acquisition ac
	on pf.loan_identifier = ac.loan_identifier) as sch;	

--CPR(for both curtailment and paidoff) calculation methods compare
create table cpr_compare_cp as
select monthly_reporting_period,
		(1-(1-(sum(smm)/count(smm)))^12) as CPR1,
		(1-(1-(sum(prepaid)/sum(scheduled_remain)))^12) as CPR2
from schedule_curtail_paidoff
group by monthly_reporting_period;
------------------------------------------ingnore the part above-------------------------------------------
-- calculate cpr for both curtailment and paid-off prepayment
-- calculate prepaid and scheduled_remain, SMM
create table schedule_curtail_paidoff as
select sch.*,
		(sch.actual_Prin-sch.scheduled_Prin) as prepaid,	
		(sch.pre_month_upb-sch.scheduled_Prin) as scheduled_remain,
		((sch.actual_Prin-sch.scheduled_Prin)/(sch.pre_month_upb-sch.scheduled_Prin))as SMM
from(select pf.loan_identifier,  pf.monthly_reporting_period,
			ac.original_upb, ac.original_interest_rate,
			(ac.original_upb*ac.original_interest_rate/1200*(1+ac.original_interest_rate/1200)^ac.original_loan_term/((1+ac.original_interest_rate/1200)^ac.original_loan_term-1)) as amortization,
			(pf.pre_month_upb*ac.original_interest_rate/1200) as interest,
			((ac.original_upb*ac.original_interest_rate/1200*(1+ac.original_interest_rate/1200)^ac.original_loan_term/((1+ac.original_interest_rate/1200)^ac.original_loan_term-1))- (pf.pre_month_upb*ac.original_interest_rate/1200)) as scheduled_Prin,
			pf.current_actual_upb,
	 		pf.pre_month_upb,
	 		(pf.pre_month_upb - pf.current_actual_upb) as actual_Prin
	from (select *, 
			lag(p.current_actual_upb) over (partition by p.loan_identifier order by p.monthly_reporting_period) as pre_month_upb
		   from fannie_performance2 p) as pf
	left join fannie_acquisition ac
	on pf.loan_identifier = ac.loan_identifier) as sch;	

--CPR(for both curtailment and paidoff) calculation methods compare
create table cpr_compare_cp as
select monthly_reporting_period,
		(1-(1-(sum(smm)/count(smm)))^12) as CPR1,
		(1-(1-(sum(prepaid)/sum(scheduled_remain)))^12) as CPR2
from schedule_curtail_paidoff
group by monthly_reporting_period;
----------------------------------------------------------------------
-- consider only paid-off prepayment and treat as a classification problem
create temp table all_zero_bc as
select distinct on (loan_identifier) loan_identifier, monthly_reporting_period, current_actual_upb, zero_balance_code
from fannie_performance2
order by loan_identifier, monthly_reporting_period desc;

create table paidoff_rate as
select zbc.monthly_reporting_period, zbc.zero_balance_code, zbc.count_zbc, loan.count_loan, 
		(zbc.count_zbc::float8/loan.count_loan::float8) as paidoff_ratio
from(
	select monthly_reporting_period, zero_balance_code, count(zero_balance_code) as count_zbc
	from all_zero_bc
	group by monthly_reporting_period, zero_balance_code) as zbc
	left join (
	select monthly_reporting_period, count(loan_identifier) as count_loan
	from fannie_performance2
	group by monthly_reporting_period) as loan
	on zbc.monthly_reporting_period = loan.monthly_reporting_period
where zbc.zero_balance_code = '01'
order by monthly_reporting_period, zero_balance_code;

--for check why '01' happend at 2018-02-01
select loan_identifier, monthly_reporting_period, current_actual_upb, zero_balance_code
from fannie_performance
where loan_identifier = '112526324106';







