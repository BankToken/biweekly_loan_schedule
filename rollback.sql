--
--
---rollback Script
-- 
--
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
drop table process_log
/

drop sequence id_pmt_seq;
/
drop sequence id_loan_disc_rate_seq ;
/
drop sequence id_loan_sec_val_seq ;
/
drop sequence id_loan_sec_val_seq_log ;
/
drop table gtt_loanpmt_cash_flow cascade constraints;
/ 