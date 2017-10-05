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


exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN01',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,38 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN02',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',38 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN03',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN01',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN02',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN03',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN01',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN02',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN03',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN01',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,28 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN02',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',37 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN03',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',56 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN01',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN02',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN03',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',58 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN01',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN02',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN03',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN01',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,38 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN02',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',38 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN03',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN01',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN02',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN03',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN01',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN02',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN03',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN01',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,28 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN02',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',37 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN03',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',56 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN01',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN02',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN03',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',58 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN01',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN02',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN03',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN04',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,38 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN05',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',38 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN06',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN04',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN05',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN06',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN04',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN05',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN06',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN04',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,28 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN05',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',37 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN06',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',56 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN04',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN05',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN06',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',58 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN04',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN05',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN06',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN04',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,38 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN05',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',38 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN06',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN04',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN05',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN06',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN04',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN05',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN06',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN04',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,28 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN05',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',37 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN06',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',56 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN04',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN05',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN06',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',58 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN04',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN05',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN06',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN07',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,38 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN08',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',38 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN09',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN07',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN08',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN09',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN07',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN08',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN09',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN07',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,28 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN08',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',37 );
exec pkg_secval.add_loan_schedule ( 'ACCT04_LOAN09',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',56 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN07',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN08',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT05_LOAN09',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',58 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN07',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN08',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT06_LOAN09',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN07',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,38 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN08',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',38 );
exec pkg_secval.add_loan_schedule ( 'ACCT07_LOAN09',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN07',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN08',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT08_LOAN09',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN07',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN08',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT09_LOAN09',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN07',424.89, 14,'8/3/2015',1.7,4.108 ,'7/31/2015' ,28 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN08',428.89, 14,'8/3/2015',101.75, 4.25 ,'7/31/2015',37 );
exec pkg_secval.add_loan_schedule ( 'ACCT10_LOAN09',265.75, 14,'8/3/2015',null,5.00 ,'7/31/2015',56 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN07',530.25, 14,'8/01/2015',25.89,3.3110,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN08',590.25, 14,'8/05/2015',5.89,2.89,'7/31/2015',60 );
exec pkg_secval.add_loan_schedule ( 'ACCT11_LOAN09',628.47, 14,'8/24/2015',null,4.375,'7/31/2015',58 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN07',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN08',290.25, 14,'8/15/2015',5.89,2.89,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT12_LOAN09',128.47, 14,'8/28/2015',null,4.375,'7/31/2015',48 );
exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN10',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN10',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );
exec pkg_secval.add_loan_schedule ( 'ACCT03_LOAN10',830.25, 14,'8/17/2015',25.89,3.3110,'7/31/2015',21 );


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
  