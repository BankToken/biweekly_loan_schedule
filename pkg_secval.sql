CREATE OR REPLACE PACKAGE   pkg_secval
AS

procedure calclate_secval ( pi_calc_period in varchar2 );


procedure add_loan_schedule  (
 pi_loan_acctnumber in varchar2 ,
pi_monthly_pmt in number,
pi_interval in number, --days
pi_first_date in varchar2, --MM/DD/YYYY
pi_last_pmt in number,
pi_discount_rate in number
);

end;
/


/*
CalcPeriod in both tables represents the end of each month. New Payment schedule comes in every month and 
we need to recalculate secvalue every month based on the new schedule and save results for the month.
Please create stored procedure in MS SQL or Oracle which will have one parameter: CalcPeriod (e.g. ‘07/31/2017’)

Based on that parameter stored procedure will retrieve the data from PmtSchedule table, calculate SecValue for each loan and save it to the Loan_SecValue.
User should be able to rerun SP for the same CalcPeriod many times

Please add to the tables all the required indexes and keys. You can add extra columns if you need them for the indexes and keys. The application should be able to work with millions of loans. Each loan can have up to 60 payments in the schedule.
*/



--Assumption/ 
--Each month, You get loan payment schedules for remaining paments only, Hence Secval will be calculated today, for future cash flows only
--Secvalue will not be calculated for entire payment schedule ( from first payment, which was paid in the past,  to last payment )
--for example, for a Loan with payment terms of 60 monthly payments,  from Jan 2015 to  Dec 2020,  you get new loan schedule today (i.e. 9/30/2017 ), SecVal will be calculated for payments from Sept 2017 to Dec 2020
--

--Logic
-- Take given parameter pi_calc_period
-- and find all loan schedules having that calcPeriod ( This is assumption )
-- and calculate Secval for each of those loans ( FOR ENTIRE SCHEDULE , not only upto current date )
--

CREATE OR REPLACE PACKAGE BODY  pkg_secval

AS

procedure calclate_secval ( pi_calc_period in varchar2 )
is
begin

    
delete from LoanPmt_cash_flow;
 
insert into loanpmt_cash_flow (loanacctnumber,
                               nbr_mos,
                               calcperiod,
                               cash_flow,
                               discountrate)
     select p.loanacctnumber,
            row_number () over (partition by p.loanacctnumber order by p.calcperiod) as pmt_nbr,
            p.calcperiod,
            sum (mopmt) as cash_flow,
            (select d.discountrate  from loandiscrate d  where     loanacctnumber = p.loanacctnumber   and d.calcperiod = p.calcperiod and rownum < 2)  as discountrate
       from pmtschedule p
      where p.calcperiod >= last_day (to_date (pi_calc_period, 'MM/DD/YYYY'))
   group by p.loanacctnumber, p.calcperiod
   order by 1, 2;


    update LoanPmt_cash_flow set pv = cash_flow/power((1+(discountrate/1200)),nbr_mos) where discountrate is not null ;


   --Merge with loan_sevalue
   
      
MERGE INTO loan_secvalue D
   USING (select loanacctnumber, round(sum(pv),2) as secval from LoanPmt_cash_flow  group by loanacctnumber ) S
   ON (D.loanacctnumber = S.loanacctnumber)
   WHEN MATCHED THEN UPDATE SET D.secval = S.secval
     DELETE WHERE (S.secval <=0 )
   WHEN NOT MATCHED THEN INSERT (D.loanacctnumber, D.secval)
     VALUES (S.loanacctnumber, S.secval)
     ;

end ;

procedure add_loan_schedule  (
 pi_loan_acctnumber in varchar2 ,
pi_monthly_pmt in number,
pi_interval in number, --days
pi_first_date in varchar2, --MM/DD/YYYY
pi_last_pmt in number,
pi_discount_rate in number
)
is

   
    v_first_pmt_date date :=  to_date(pi_first_date,'MM/DD/YYYY') ;
    v_pmt_interval_days number(5) := pi_interval; 
    v_loan_acct_number  varchar2(200):= pi_loan_acctnumber ;
    v_mthly_pmt number(10,2) := pi_monthly_pmt ;
    v_last_pmt number(10,2) := pi_last_pmt;
    v_discount_rate loandiscrate.discountrate%type :=  pi_discount_rate;   
    v_cut_pmt_due_date date;
    v_last_day_of_pmt_month date;
    begin
    
    
        for i in 1..38 loop
    
            v_cut_pmt_due_date := v_first_pmt_date+ v_pmt_interval_days*(i-1) ;
            v_last_day_of_pmt_month := last_day(v_cut_pmt_due_date);
        
            insert into pmtschedule ( loanacctnumber, pmtnbr , current_pmt_due_dt , mopmt , calcperiod , pcd_act_d ) 
            values (v_loan_acct_number ,i, v_first_pmt_date+ v_pmt_interval_days*(i-1) , v_mthly_pmt ,v_last_day_of_pmt_month,v_last_day_of_pmt_month);
        end loop;

        update pmtschedule a set mopmt = v_last_pmt where loanacctnumber = v_loan_acct_number 
        and pmtnbr = ( select max(pmtnbr) from pmtschedule b where b.loanacctnumber = a.loanacctnumber );    

        insert into loandiscrate  ( loanacctnumber, calcperiod,discountrate)
        select distinct  loanacctnumber,  calcperiod, v_discount_rate
        from pmtschedule  where  loanacctnumber = v_loan_acct_number ;       
        
    end;
    
end pkg_secval;
/