create or replace package   pkg_secval
as

--This SP will calculate SECVAL of all loans at a time
--Use this SP if number of loans are less than 10000
--This is resubale procedure. Can be re-run for same calcperiod again 
procedure calclate_secval ( pi_calc_period in varchar2 );


--This SP will calculate SECVAL, processes X number of loans at a time
--Use this SP if number of loans  are >10000
--This is resubale procedure. Can be re-run for same calcperiod again

procedure calc_secval_commit_inteval ( pi_calc_period in varchar2 , pi_commit_interval in number);


--This SP will insert log entry at each step of the load/calculation
--
procedure add_log ( pi_msg in varchar2, pi_error in varchar2  default null);


-- This SP will add loan schedule in pmt_schedule
--Created for inserting test data
 
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

create or replace package body  pkg_secval
as

procedure add_log ( pi_msg in varchar2, pi_error in varchar2  default null)
is
pragma autonomous_transaction;
begin

insert into process_log (log,error_msg ) values ( pi_msg, pi_error ) ;

commit;

end;

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

procedure calc_secval_commit_inteval ( pi_calc_period in varchar2 , pi_commit_interval in number)
is
v_sp_name varchar2(100) := 'calc_secval_commit_inteval' ;
v_log_status varchar2(4000);
v_cnt number(10) := 0;
v_commit_interval number(10) := nvl(pi_commit_interval, 10); -- defaulted to 10.
v_calc_period date := to_date (pi_calc_period, 'MM/DD/YYYY');
v_start_time  number(10) :=  dbms_utility.get_time;
v_end_time number;


cursor c1 is
select distinct loanacctnumber  from pmt_schedule where calcperiod =v_calc_period;

type loanaccounts_typ is table of pmt_schedule.loanacctnumber%type index by binary_integer;

tbl1 loanaccounts_typ ;

begin

 add_log( '== Start SP : calc_secval_commit_inteval ==');
 
  delete from gtt_loanpmt_cash_flow where calc_period = v_calc_period;

  open c1 ;


  
  loop
  fetch c1 bulk collect into tbl1 limit v_commit_interval;
  
  exit when tbl1.count = 0;
  
    v_cnt := v_cnt + tbl1.count;
    v_log_status  := null;
        
   dbms_output.put_line(' Loaded :'||tbl1.count||'  loans ');
  
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
        where p.calcperiod = v_calc_period
        and p.loanacctnumber = d.loanacctnumber
        and  d.calcperiod = p.calcperiod
        and p.loanacctnumber =  tbl1(i) 
        group by  p.calcperiod, p.loanacctnumber,  d.discountrate, p.pcd_act_d ;
            
        v_log_status := ' Loaded '||tbl1.count||' loan schedules into gtt';
        
        --add_log( ' Loaded '||tbl1.count||' loan schedules into gtt', null);    
        
    exception
    when others then
        add_log( ' Error while Loading '||tbl1.count||' loan schedules into gtt', sqlerrm);
    
    end;
    
    begin
    
    merge into loan_secvalue d
    using (select loanacctnumber, round(sum(pv),2) as secval from gtt_loanpmt_cash_flow  where merge_flag = 'P' group by loanacctnumber ) s
    on ( d.loanacctnumber = s.loanacctnumber and d.calcperiod = v_calc_period  )
    when matched then update set d.secval = s.secval , d.record_modified_by = v_sp_name
     delete where (s.secval <= 0 )
    when not matched then insert ( d.loanacctnumber, d.secval, d.calcperiod , d.record_modified_by )
     values ( s.loanacctnumber, s.secval , v_calc_period, v_sp_name );
 
        v_log_status :=  v_log_status|| '; Merged total'||v_cnt||' loan schedules into loan_secvalue';
        
        update gtt_loanpmt_cash_flow set merge_flag = 'C'  where merge_flag = 'P';

    exception
    when others then
        add_log( ' Error while Loading '||v_cnt||' loans schedules into loan_secvalue', sqlerrm);
       
    end;    
   
       add_log( v_log_status, null);
     commit;
  end loop;
  
   close c1; 
   
   v_end_time := dbms_utility.get_time;
   
  add_log( '== Complete SP : calc_secval_commit_inteval == time Taken:'|| round((v_end_time - v_start_time)/100,2) ||' seconds');

end;

procedure calclate_secval ( pi_calc_period in varchar2 )
is
v_disc_rate loan_discrate.discountrate%type;
v_sp_name varchar2(100) := 'calclate_secval' ;
v_status varchar2(4000) := null;
v_calc_period date := to_date (pi_calc_period, 'MM/DD/YYYY');
v_start_time  number(10) := dbms_utility.get_time; 
v_end_time number(10);

begin


--using temp table

 add_log( '== Start SP :calclate_secval ==');

    
delete from gtt_loanpmt_cash_flow where calc_period =  v_calc_period ;
 
add_log (' deleted '||sql%rowcount||' rows from temp table');

insert into gtt_loanpmt_cash_flow (calc_period,
                                 loanacctnumber,
                                discountrate,
                                calendar_month,
                               nbr_mos,
                               cash_flow
                               )
   select to_date (pi_calc_period, 'MM/DD/YYYY') , 
   p.loanacctnumber,  
   d.discountrate, 
   p.pcd_act_d,
   row_number() over ( partition by p.loanacctnumber order by p.pcd_act_d ) as pmt_nbr,
   sum (mopmt) as cash_flow
      from pmt_schedule p , loan_discrate d
      where p.calcperiod = v_calc_period
      and p.loanacctnumber = d.loanacctnumber
      and  d.calcperiod = p.calcperiod
   group by  p.loanacctnumber,  d.discountrate, p.pcd_act_d
   order by 1, 5;

   add_log ( ' Caclulated monthly cashflow. Added '||sql%rowcount||' rows into loanpmt_cash_flow');

   update gtt_loanpmt_cash_flow set pv = cash_flow/power((1+(discountrate/1200)),nbr_mos) where discountrate is not null ;

   add_log ( ' Calculated PV for all cash flows');

   --Merge temp table  with loan_sevalue , by lanaccountnumber
   
      
merge into loan_secvalue d
   using (select loanacctnumber, round(sum(pv),2) as secval from gtt_loanpmt_cash_flow  group by loanacctnumber ) s
   on (d.loanacctnumber = s.loanacctnumber and d.calcperiod = v_calc_period)
   when matched then update set d.secval = s.secval , d.record_modified_by = v_sp_name
     delete where (s.secval <=0 )
   when not matched then insert (d.loanacctnumber, d.secval, d.calcperiod , d.record_modified_by)
     values (s.loanacctnumber, s.secval , v_calc_period, v_sp_name)
     ;

   add_log ( ' Merged into loan_secvalue');

  
   v_end_time := dbms_utility.get_time;
   
  add_log( '== Complete SP : calc_secval == time Taken:'|| round((v_end_time - v_start_time)/100,2) ||' seconds');
  
  commit;

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
    v_discount_rate loan_discrate.discountrate%type :=  pi_discount_rate;   
    v_cut_pmt_due_date date;
    v_last_day_of_pmt_month date;
    v_calcperiod date :=  to_date(pi_calcperiod,'MM/DD/YYYY') ;
    v_id_loan_disc_rate number(10);
    begin
    
    
        --populate loan discount rate
        insert into loan_discrate  ( loanacctnumber, calcperiod,discountrate)
        values ( v_loan_acct_number, v_calcperiod, v_discount_rate );
            
        for i in 1..pi_remaining_payments loop
    
            v_cut_pmt_due_date := v_first_pmt_date+ v_pmt_interval_days*(i-1) ;
            v_last_day_of_pmt_month := last_day(v_cut_pmt_due_date);
        
            insert into pmt_schedule ( loanacctnumber, pmtnbr , current_pmt_due_dt , mopmt , calcperiod , pcd_act_d  ) 
            values (v_loan_acct_number ,i, v_first_pmt_date+ v_pmt_interval_days*(i-1) , v_mthly_pmt ,v_calcperiod,v_last_day_of_pmt_month  );
        end loop;

        if ( v_last_pmt is not null ) then
        --update last payment , if differnet
        update pmt_schedule a 
        set mopmt = v_last_pmt 
        where loanacctnumber = v_loan_acct_number 
        and pmtnbr = ( select max(pmtnbr) from pmt_schedule b where b.loanacctnumber = a.loanacctnumber );
        
        end if;
   
    end;
  
end pkg_secval;
/

show err
/