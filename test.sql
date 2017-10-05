 -- TEST ---
  


/*
 

truncate table pmt_schedule
/
truncate table loan_discrate
/
truncate table LOAN_SECVALUE_log
/
truncate table LoanPmt_cash_flow
/
truncate table gtt_LoanPmt_cash_flow
/
truncate table process_log
/
--adding 110 schedulees



exec pkg_secval.calclate_secval_gtt('7/31/2015');

exec pkg_secval.calclate_secval('7/31/2015');


 select p.loanacctnumber, p.pcd_act_d,
           --  row_number() over ( partition by p.loanacctnumber order by p.pcd_act_d ) as pmt_nbr,
            sum (mopmt) as cash_flow
      from PMT_SCHEDULE p , loan_discrate d
      where p.calcperiod = to_date ('7/31/2015', 'MM/DD/YYYY')
      and p.loanacctnumber = d.loanacctnumber
      and  d.calcperiod = p.calcperiod
   group by  p.loanacctnumber,  p.pcd_act_d
   order by 1,4;
   


select * from process_log
  
  select * from PMT_SCHEDULE ORDER BY 2,4;

select * from loan_discrate ORDER BY 2,3;

select * from  gtt_LoanPmt_cash_flow order by loanacctnumber, nbr_mos

select * from LOAN_SECVALUE  order by loanacctnumber

select * from LOAN_SECVALUE_log order by loanacctnumber , 2 desc


  
  */
  