--create d90 by extracting first row of each loan has d value >=3
create table d90 as
select delin.loan_identifier, ac.original_upb, delin.current_actual_upb,
	delin.loan_age, delin.current_loan_delinquency_status,
	(delin.current_actual_upb/ac.original_upb)as upb_percent
from fannie_acquisition ac 
left join (select loan_identifier, current_actual_upb, loan_age, 
                            current_loan_delinquency_status,
                           row_number() OVER(PARTITION BY loan_identifier ORDER BY    monthly_reporting_period) AS rn
               from fannie_performance 
               where current_loan_delinquency_status not in ('0', '1', '2', 'X')) as delin
on ac.loan_identifier = delin.loan_identifier
where delin.rn = 1

-- create d90 by extracting first row of each loan has d value >=2
create table d60 as
select delin.loan_identifier, ac.original_upb, delin.current_actual_upb,
	delin.loan_age, delin.current_loan_delinquency_status,
	(delin.current_actual_upb/ac.original_upb)as upb_percent
from fannie_acquisition ac 
left join (select loan_identifier, current_actual_upb, loan_age, 
                            current_loan_delinquency_status,
                           row_number() OVER(PARTITION BY loan_identifier ORDER BY    monthly_reporting_period) AS rn
               from fannie_performance 
               where current_loan_delinquency_status not in ('0', '1', 'X')) as delin
on ac.loan_identifier = delin.loan_identifier
where delin.rn = 1

--combine d60 and d90 flag column with fannie_acquisition table
create table d60_90_flag as
select ac.*,
	case when ac.loan_identifier in (select d90.loan_identifier from d90) then 1
	else 0 end as d90_flag,
	case when ac.loan_identifier in (select d60.loan_identifier from d60) then 1
	else 0 end as d60_flag
from fannie_acquisition ac