CREATE OR REPLACE PACKAGE   pkg_secval
AS

--this paramter will control how many loans to process at a time
gv_loan_commit_interval number(10) := 10; 

procedure calclate_secval_gtt ( pi_calc_period in varchar2 );

procedure calclate_secval ( pi_calc_period in varchar2 );

procedure add_log ( pi_msg in varchar2, pi_error in varchar2  default null);


procedure add_loan_schedule  (
pi_loan_acctnumber in varchar2 ,
pi_monthly_pmt in number,
pi_interval in number, --days
pi_first_date in varchar2, --MM/DD/YYYY
pi_last_pmt in number,
pi_discount_rate in number,
pi_calcperiod in varchar2 --MM/DD/YYYY
,pi_remaining_payments in number

);
end;
/
