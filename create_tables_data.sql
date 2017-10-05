drop package pkg_secval
/

DROP TABLE PMTSCHEDULE
/
DROP TABLE LOANDISCRATE
/
DROP TABLE LOAN_SECVALUE
/
DROP TABLE LOAN_SECVALUE_LOG 
/
DROP sequence id_pmt_seq;
/
DROP sequence id_loan_disc_rate_seq ;
/
DROP sequence id_loan_sec_val_seq ;
/
DROP sequence id_loan_sec_val_seq_log ;
/

CREATE TABLE PMTSCHEDULE 
(ID_PMT NUMBER(10)  PRIMARY KEY , 
 LOANACCTNUMBER VARCHAR(20),
 CALCPERIOD DATE, 
 PMTNBR NUMBER(10), 
 CURRENT_PMT_DUE_DT  DATE, 
 MOPMT  NUMBER(18,4), 
 PCD_ACT_D DATE ,
 DTM_CREATED DATE  DEFAULT SYSDATE,
 DTM_MODIFIED DATE  DEFAULT SYSDATE 
)
/



CREATE TABLE LOANDISCRATE 
(
ID_LOAN_DISC_RATE NUMBER(10),
LOANACCTNUMBER VARCHAR(20), 
CALCPERIOD DATE, 
DISCOUNTRATE NUMBER(18, 15),
 DTM_CREATED DATE  DEFAULT SYSDATE,
 DTM_MODIFIED DATE  DEFAULT SYSDATE
)
/

CREATE TABLE LOAN_SECVALUE 
(
id_loan_sec_val number(10),
loanacctnumber varchar(20), 
calcperiod date, 
secval number(18, 4),
dtm_created date  default sysdate,
dtm_modified date  default sysdate
)
/

CREATE TABLE LOAN_SECVALUE_LOG 
(
id_loan_sec_val_LOG number(10) primary key ,
log_timestamp timestamp default systimestamp ,
operation_type varchar2(1) constraint chk_op_typ  CHECK  (operation_type in ('I','U','D')),
id_loan_sec_val number(10),
LOANACCTNUMBER VARCHAR(20), 
CALCPERIOD DATE, 
SECVAL NUMBER(18, 4)
)
/


--sequences
create sequence id_pmt_seq start with 1 increment by 1
/
create sequence id_loan_disc_rate_seq start with 1 increment by 1
/
create sequence id_loan_sec_val_seq start with 1 increment by 1
/
create sequence id_loan_sec_val_seq_log start with 1 increment by 1
/

--log triggers
CREATE OR REPLACE TRIGGER trg_loandiscrate_log_upd_date
BEFORE INSERT OR UPDATE
ON LOANDISCRATE
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
begin

  :new.ID_LOAN_DISC_RATE := ID_LOAN_DISC_RATE_SEQ.nextval;
 :new.dtm_modified := sysdate;
end;
/
CREATE OR REPLACE TRIGGER trg_pmtsched_log_upd_date
BEFORE INSERT OR UPDATE
ON PMTSCHEDULE
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
begin
:new.ID_PMT := id_pmt_seq.nextval;
 :new.dtm_modified := sysdate;
end;
/

CREATE OR REPLACE TRIGGER trg_secval_defaults
BEFORE INSERT OR UPDATE
ON LOAN_SECVALUE    
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
begin

:new.id_loan_sec_val := id_loan_sec_val_seq.nextval ;
:new.dtm_modified := sysdate;

end;
/

CREATE OR REPLACE TRIGGER trg_log_secval_changes
AFTER INSERT OR UPDATE OR DELETE
ON LOAN_SECVALUE    
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE
v_op_type varchar2(1);
begin

    if ( inserting ) then
        v_op_type := 'I';
    elsif ( updating ) then 
        v_op_type := 'U';
    elsif deleting then
        v_op_type := 'D';
    end if;
    
    
    If  ( v_op_type = 'D' ) then
    insert into loan_secvalue_log 
    (
    id_loan_sec_val_log,
    operation_type,
    id_loan_sec_val,
    loanacctnumber,
    calcperiod,
    secval
    ) values
    ( id_loan_sec_val_seq_log.nextval,
       v_op_type,
       :old.id_loan_sec_val,
       :old.loanacctnumber,
       :old.calcperiod,
       :old.secval
    );
    
    elsif ( v_op_type = 'I' or v_op_type = 'U' ) then
    insert into loan_secvalue_log 
    (
    id_loan_sec_val_log,
    operation_type,
    id_loan_sec_val,
    loanacctnumber,
    calcperiod,
    secval
    ) values
    ( id_loan_sec_val_seq_log.nextval,
       v_op_type,
       :new.id_loan_sec_val,
       :new.loanacctnumber,
       :new.calcperiod,
       :new.secval
    );
    
    end if;

end;
/



--Load Data into PMTSCHEDULE , first loan

truncate table pmtschedule
/
truncate table loandiscrate
/

exec pkg_secval.add_loan_schedule ( 'ACCT01_LOAN01',424.89, 14,'8/3/2015',1.7,4.108 );

exec pkg_secval.add_loan_schedule ( 'ACCT02_LOAN02',530.25, 14,'8/3/2015',25.89,3.3110 );



exec calclate_secval('8/1/2015');



--CREATE A NON UNINUE, NON CLUSTERED INDEX ON CALCPERIOD
CREATE INDEX IDX_PMTSCHED_CALCPRD ON PMTSCHEDULE ( CALCPERIOD );




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
 

  
  /*
  
  select * from PMTSCHEDULE ORDER BY 2,4;

select * from loandiscrate ORDER BY 2,3;

select * from  LoanPmt_cash_flow order by 1,2

select * from LOAN_SECVALUE

select * from LOAN_SECVALUE_log order by loanacctnumber , 2 desc


  
  */