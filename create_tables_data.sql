drop package pkg_secval
/
drop table pmt_schedule
/
drop table loan_discrate
/
drop table loan_secvalue
/
drop table loan_secvalue_log 
/
drop sequence id_pmt_seq;
/
drop sequence id_loan_disc_rate_seq ;
/
drop sequence id_loan_sec_val_seq ;
/
drop sequence id_loan_sec_val_seq_log ;
/

create table pmt_schedule 
(id_pmt number(10)  primary key , 
 loanacctnumber varchar(20) not null,
 calcperiod date not null, 
 pmtnbr number(10) not null, 
 current_pmt_due_dt  date, 
 mopmt  number(18,4) not null, 
 pcd_act_d date not null,
 record_create_date date  default sysdate,
 record_modified_date date  default sysdate 
)
/

alter table pmt_schedule add constraint pmt_schedule_uk#acct#pmtnmr unique ( loanacctnumber, pmtnbr )
/


create table loan_discrate 
(
id_loan_disc_rate number(10) primary key,
loanacctnumber varchar(20) not null, 
calcperiod date not null, 
discountrate number(18, 15) not null,
record_create_date date  default sysdate,
record_modified_date date  default sysdate
)
/

create table loan_secvalue 
(
id_loan_sec_val number(10) primary key,
loanacctnumber varchar(20) not null, 
calcperiod date not null, 
secval number(18, 4) ,
record_create_date date  default sysdate,
record_modified_date date  default sysdate,
record_modified_by varchar2(200) default user
)
/

create table loan_secvalue_log 
(
id_loan_sec_val_log number(10) primary key ,
log_timestamp timestamp default systimestamp ,
record_modified_by varchar2(200) ,
operation_type varchar2(1) constraint chk_op_typ  check  (operation_type in ('I','U','D')),
id_loan_sec_val number(10) not null,
loanacctnumber varchar(20) not null, 
calcperiod date not null, 
secval number(18, 4)
)
/

create table process_log
(
log_timestamp timestamp default systimestamp ,
log varchar2(1000),
error_msg varchar2(4000)
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

--CREATE A NON UNINUE, NON CLUSTERED INDEX ON CALCPERIOD
create index idx_pmtsched_calcprd on pmt_schedule ( calcperiod );

create index idx_pmtsched_acctnbr on pmt_schedule ( loanacctnumber );



--log triggers
create or replace trigger trg_loan_discrate_log_upd_date
before insert or update
on loan_discrate
referencing new as new old as old
for each row
begin

  :new.id_loan_disc_rate := id_loan_disc_rate_seq.nextval;
 :new.record_modified_date := sysdate;
end;
/


create or replace trigger trg_pmtsched_log_upd_date
before insert or update
on pmt_schedule
referencing new as new old as old
for each row
begin
:new.id_pmt := id_pmt_seq.nextval;
 :new.record_modified_date := sysdate;
end;
/

create or replace trigger trg_secval_defaults
before insert or update
on loan_secvalue    
referencing new as new old as old
for each row
begin

:new.id_loan_sec_val := id_loan_sec_val_seq.nextval ;
:new.record_modified_date := sysdate;

end;
/

create or replace trigger trg_log_secval_changes
after insert or update or delete
on loan_secvalue    
referencing new as new old as old
for each row
declare
v_op_type varchar2(1);
begin

    if ( inserting ) then  v_op_type := 'I';
    elsif ( updating ) then v_op_type := 'U';
    elsif deleting then  v_op_type := 'D';
    end if;
    
    
    if  ( v_op_type = 'D' ) then
       
       insert into loan_secvalue_log  ( id_loan_sec_val_log, operation_type, id_loan_sec_val, loanacctnumber,  calcperiod, secval ,record_modified_by) values
        ( id_loan_sec_val_seq_log.nextval,  v_op_type, :old.id_loan_sec_val,:old.loanacctnumber, :old.calcperiod, :old.secval ,:old.record_modified_by);
            
    elsif ( v_op_type = 'I' or v_op_type = 'U' ) then
       
        insert into loan_secvalue_log (id_loan_sec_val_log, operation_type, id_loan_sec_val, loanacctnumber, calcperiod, secval ,record_modified_by) values
        ( id_loan_sec_val_seq_log.nextval, v_op_type, :new.id_loan_sec_val, :new.loanacctnumber,:new.calcperiod,:new.secval ,:new.record_modified_by);
            
    end if;

end;
/


----TEMP TABLE---

DROP TABLE LOANPMT_CASH_FLOW CASCADE CONSTRAINTS;

CREATE GLOBAL TEMPORARY TABLE LOANPMT_CASH_FLOW
(
  LOANACCTNUMBER  VARCHAR2(20 BYTE)                 NULL,
  NBR_MOS         NUMBER(10)                        NULL,
  calcperiod      DATE                              NULL,
  CASH_FLOW       NUMBER(18,4)                      NULL,
  DISCOUNTRATE    NUMBER(18,4)                      NULL,
  PV              NUMBER(18,4)                      NULL
)
ON COMMIT PRESERVE ROWS;



DROP TABLE GTT_LOANPMT_CASH_FLOW CASCADE CONSTRAINTS;

CREATE GLOBAL TEMPORARY TABLE GTT_LOANPMT_CASH_FLOW
(
  calc_period     date,
  LOANACCTNUMBER  VARCHAR2(20 BYTE)                 NULL,
  NBR_MOS         NUMBER(10)                        NULL,
  calendar_month  DATE                              NULL,
  CASH_FLOW       NUMBER(18,4)                      NULL,
  DISCOUNTRATE    NUMBER(18,4)                      NULL,
  PV              NUMBER(18,4)                      NULL
)
ON COMMIT PRESERVE ROWS;


--select * from LOANPMT_CASH_FLOW

