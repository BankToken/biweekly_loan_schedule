CREATE OR REPLACE PACKAGE BODY  pkg_secval
AS


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

procedure calclate_secval ( pi_calc_period in varchar2 )
is
v_sp_name varchar2(100) := 'calclate_secval' ;
v_log_status varchar2(4000);
v_cnt number(10) := 0;


cursor c1 is
select distinct loanacctnumber  from pmt_schedule where calcperiod = to_date (pi_calc_period, 'MM/DD/YYYY');

type loanaccounts_typ is table of pmt_schedule.loanacctnumber%type index by binary_integer;

tbl1 loanaccounts_typ ;

begin

  delete from gtt_LoanPmt_cash_flow where calc_period = to_date (pi_calc_period, 'MM/DD/YYYY');

  open c1 ;


  
  loop
  fetch c1 bulk collect into tbl1 limit gv_loan_commit_interval;
  
  EXIT WHEN tbl1.COUNT = 0;
  
    v_cnt := v_cnt + tbl1.count;
    v_log_status  := null;
        
   dbms_output.put_line(' Loaded :'||tbl1.count||'  loans ');
  
    --Calculate PV for each loan and save into LOANSECVAL table.
    --1000 loans at a time.
    -- select * from loan_secvalue  
          
    begin
    
    forall i in tbl1.first..tbl1.last
    insert into gtt_loanpmt_cash_flow ( calc_period , loanacctnumber , nbr_mos , calendar_month , cash_flow, discountrate, pv )
    select  p.calcperiod,
            p.loanacctnumber,  
            row_number() over ( partition by p.loanacctnumber order by p.pcd_act_d ) as mth_nbr, -- Addl Info, not required
            p.pcd_act_d as calendar_month,                                                       -- Addl Info, not required
            sum (mopmt),                                                                         -- Addl Info, not required
            d.discountrate, 
            sum (mopmt)/power((1+(discountrate/1200)),row_number() over ( partition by p.loanacctnumber order by p.pcd_act_d ))   as pv
        from pmt_schedule p , loan_discrate d
        where p.calcperiod = to_date (pi_calc_period, 'MM/DD/YYYY')
        and p.loanacctnumber = d.loanacctnumber
        and  d.calcperiod = p.calcperiod
        and p.loanacctnumber =  tbl1(i) 
        group by  p.calcperiod, p.loanacctnumber,  d.discountrate, p.pcd_act_d ;
            
        v_log_status := ' Loaded '||v_cnt||' loan schedules into gtt';
        
        --add_log( ' Loaded '||tbl1.count||' loan schedules into gtt', null);    
        
    exception
    when others then
        add_log( ' Error while Loading '||v_cnt||' loan schedules into gtt', sqlerrm);
    
    end;
    
    begin
    
    MERGE INTO loan_secvalue D
    USING (select loanacctnumber, round(sum(pv),2) as secval from gtt_loanpmt_cash_flow  group by loanacctnumber ) S
    ON ( D.loanacctnumber = S.loanacctnumber and D.CALCPERIOD = to_date (pi_calc_period, 'MM/DD/YYYY')  )
    WHEN MATCHED THEN UPDATE SET D.secval = S.secval , D.record_modified_by = v_sp_name
     DELETE WHERE (S.secval <= 0 )
    WHEN NOT MATCHED THEN INSERT ( D.loanacctnumber, D.secval, D.calcperiod , D.record_modified_by )
     VALUES ( S.loanacctnumber, S.secval , to_date (pi_calc_period, 'MM/DD/YYYY'), v_sp_name );
 
        v_log_status :=  v_log_status|| '; Merged '||v_cnt||' loan schedules into loan_secvalue';

    exception
    when others then
        add_log( ' Error while Loading '||v_cnt||' loans schedules into loan_secvalue', sqlerrm);
       
    end;    
   
       add_log( v_log_status, null);

  end loop;
  
   close c1; 

end;


procedure add_log ( pi_msg in varchar2, pi_error in varchar2  default null)
is
PRAGMA AUTONOMOUS_TRANSACTION;
begin

insert into process_log (log,error_msg ) values ( pi_msg, pi_error ) ;

commit;

end;
procedure calclate_secval_gtt ( pi_calc_period in varchar2 )
is
v_disc_rate loan_discrate.discountrate%type;
v_sp_name varchar2(100) := 'calclate_secval_gtt' ;
v_status varchar2(4000) := null;
begin


--using temp table

add_log (' start loading');
    
delete from LoanPmt_cash_flow where calcperiod =  to_date (pi_calc_period, 'MM/DD/YYYY') ;
 
add_log (' deleted '||sql%rowcount||' rows from temp table');

insert into loanpmt_cash_flow (loanacctnumber,
                                discountrate,
                                calcperiod,
                               nbr_mos,
                               cash_flow
                               )
   select p.loanacctnumber,  d.discountrate, p.pcd_act_d,
             row_number() over ( partition by p.loanacctnumber order by p.pcd_act_d ) as pmt_nbr,
            sum (mopmt) as cash_flow
      from PMT_SCHEDULE p , loan_discrate d
      where p.calcperiod = to_date (pi_calc_period, 'MM/DD/YYYY')
      and p.loanacctnumber = d.loanacctnumber
      and  d.calcperiod = p.calcperiod
   group by  p.loanacctnumber,  d.discountrate, p.pcd_act_d
   order by 1, 5;

   add_log ( ' added '||sql%rowcount||' rows into loanpmt_cash_flow');

   update LoanPmt_cash_flow set pv = cash_flow/power((1+(discountrate/1200)),nbr_mos) where discountrate is not null ;

   add_log ( ' updated PV');

   --Merge temp table  with loan_sevalue , by lanaccountnumber
   
      
MERGE INTO loan_secvalue D
   USING (select loanacctnumber, round(sum(pv),2) as secval from LoanPmt_cash_flow  group by loanacctnumber ) S
   ON (D.loanacctnumber = S.loanacctnumber and D.CALCPERIOD = to_date (pi_calc_period, 'MM/DD/YYYY'))
   WHEN MATCHED THEN UPDATE SET D.secval = S.secval , D.record_modified_by = v_sp_name
     DELETE WHERE (S.secval <=0 )
   WHEN NOT MATCHED THEN INSERT (D.loanacctnumber, D.secval, D.calcperiod , D.record_modified_by)
     VALUES (S.loanacctnumber, S.secval , to_date (pi_calc_period, 'MM/DD/YYYY'), v_sp_name)
     ;

   add_log ( ' Merged into loan_secvalue');
end ;

procedure add_loan_schedule  (
pi_loan_acctnumber in varchar2 ,
pi_monthly_pmt in number,
pi_interval in number, --days
pi_first_date in varchar2, --MM/DD/YYYY
pi_last_pmt in number,
pi_discount_rate in number,
pi_calcperiod in varchar2 --MM/DD/YYYY
,pi_remaining_payments in number
)
is

   
    v_first_pmt_date date :=  to_date(pi_first_date,'MM/DD/YYYY') ;
    v_pmt_interval_days number(5) := pi_interval; 
    v_loan_acct_number  varchar2(200):= pi_loan_acctnumber ;
    v_mthly_pmt number(10,2) := pi_monthly_pmt ;
    v_last_pmt number(10,2) := pi_last_pmt;
    v_discount_rate LOAN_DISCRATE.discountrate%type :=  pi_discount_rate;   
    v_cut_pmt_due_date date;
    v_last_day_of_pmt_month date;
    v_calcperiod date :=  to_date(pi_calcperiod,'MM/DD/YYYY') ;
    begin
    
    
        for i in 1..pi_remaining_payments loop
    
            v_cut_pmt_due_date := v_first_pmt_date+ v_pmt_interval_days*(i-1) ;
            v_last_day_of_pmt_month := last_day(v_cut_pmt_due_date);
        
            insert into PMT_SCHEDULE ( loanacctnumber, pmtnbr , current_pmt_due_dt , mopmt , calcperiod , pcd_act_d ) 
            values (v_loan_acct_number ,i, v_first_pmt_date+ v_pmt_interval_days*(i-1) , v_mthly_pmt ,v_calcperiod,v_last_day_of_pmt_month);
        end loop;

        if ( v_last_pmt is not null ) then
        --update last payment , if differnet
        update PMT_SCHEDULE a 
        set mopmt = v_last_pmt 
        where loanacctnumber = v_loan_acct_number 
        and pmtnbr = ( select max(pmtnbr) from PMT_SCHEDULE b where b.loanacctnumber = a.loanacctnumber );
        
        end if;
            
        
        --populate loan discount rate
        insert into LOAN_DISCRATE  ( loanacctnumber, calcperiod,discountrate)
        values ( v_loan_acct_number, v_calcperiod, v_discount_rate );
        
    end;
    
end pkg_secval;
/

show err
/