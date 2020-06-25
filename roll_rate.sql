-- check foreclosure. 
--- found only 126 loans was forclosured; and they have zero_balance_code in (2,3,9); and delinquency_status is null
select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date,foreclosure_flag
from (select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date,
			case when foreclosure_date is not null then 'F'
			else null
			end as foreclosure_flag
	from fannie_performance) as flag
where foreclosure_flag = 'F';

--132obs
select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date
from fannie_performance
where zero_balance_code in ('02','03','09');

select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date,foreclosure_flag
from (select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date,
			case when foreclosure_date is not null then 'F'
			else null
			end as foreclosure_flag
	from fannie_performance) as flag
where loan_identifier = '173174036604'

-- check when zero_balance_code is '01' --found all delinquency_status is X
select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date
from fannie_performance
where zero_balance_code = '01';

select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date
from fannie_performance
where loan_identifier = '100012691523';

-- check if all delinquency_status with X also has zero_balance_code of '01'
--- found 326obs with '06', 12obs with '16', the rest 67775obs with '01', and X only shows in the last row of each loan
select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date
from fannie_performance
where current_loan_delinquency_status = 'X' and zero_balance_code not in ('01','06');

-- check when zero_balance_code is not null, how is delinquency_status
--- all ('02','03','09') zb_code has null delinquency_status with X except six, all ('01','06','16')has null delinquency_status
--- "669177782287" '03'code but foreclosure_date is null
--- "110207265310" '15'code and foreclosure_date is null
select loan_identifier,monthly_reporting_period, current_actual_upb, current_loan_delinquency_status,
			zero_balance_code,foreclosure_date
from fannie_performance
where zero_balance_code is not null and zero_balance_code != '01';

-- check the first 7 month in 2018 of delinquency, since 6 months upb were hiden on purpose
--- found delinquency_status still shows properly
select monthly_reporting_period, count(loan_identifier), count(nullif(current_loan_delinquency_status, '0')),
			count(zero_balance_code),count(foreclosure_date)
from fannie_performance
group by monthly_reporting_period 

select loan_identifier, monthly_reporting_period, current_loan_delinquency_status, zero_balance_code,
		foreclosure_date
from fannie_performance
where monthly_reporting_period = to_date('01/01/2018','mm/dd/yyyy') and current_loan_delinquency_status !='0';
-----------------------------------------------------------------------------------------------------------
-- Generate a column for roll rate
create table cb_performance as
select loan_identifier, monthly_reporting_period, current_loan_delinquency_status, zero_balance_code,
		case when current_loan_delinquency_status in ('0','1','2','3') then current_loan_delinquency_status
		when current_loan_delinquency_status is not null and current_loan_delinquency_status not in ('0','1','2','3','X')then '4+'
		when zero_balance_code = '01' then 'P'
		when foreclosure_date is not null then 'F'
		when zero_balance_code in ('02','03','06','09','15','16') then 'O'
		end as performance
from fannie_performance;

-- check performance column
select performance, count(performance)
from cb_performance
group by performance;
		
-- roll rate
create temp table count_performance2 as
select monthly_reporting_period, performance, count(loan_identifier) as counts
from cb_performance
group by monthly_reporting_period, performance;

CREATE EXTENSION tablefunc;
create table roll_rate as
select *
from crosstab(
	 'select performance, monthly_reporting_period, coalesce(counts, 0) 
	  from count_performance2
	  order by 1,2',
 	 'select distinct monthly_reporting_period from count_performance2 order by 1')
as cp(performance varchar, Jan18 int, Feb18 int, Mar18 int,
					Apr18 int, May18 int, Jun18 int, July18 int,
					Aug18 int, Sep18 int, Oct18 int, Nov18 int,
					Dec18 int, Jan19 int, Feb19 int, Mar19 int,
					Apr19 int, May19 int, June19 int, July19 int,
					Aug19 int, Sep19 int, Oct19 int, Nov19 int,
					Dec19 int);

-- check performance is null case
--- '106744050927', "2019-04-01"
select *
from cb_performance
where performance is null;

select loan_identifier, monthly_reporting_period, current_loan_delinquency_status, zero_balance_code,foreclosure_date
from fannie_performance
where loan_identifier = '106744050927'
order by monthly_reporting_period;



