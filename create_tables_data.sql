

CREATE TABLE pmt_schedule
(
   id_pmt                 NUMBER (10) PRIMARY KEY,
   loanacctnumber         VARCHAR (20) NOT NULL,
   calcperiod             DATE NOT NULL,
   pmtnbr                 NUMBER (10) NOT NULL,
   current_pmt_due_dt     DATE,
   mopmt                  NUMBER (18, 4) NOT NULL,
   pcd_act_d              DATE NOT NULL,
   id_loan_disc_rate      NUMBER (10),
   record_create_date     DATE DEFAULT SYSDATE,
   record_modified_date   DATE DEFAULT SYSDATE
)
/

ALTER TABLE pmt_schedule ADD CONSTRAINT pmt_schedule_uk#acct#pmtnmr UNIQUE ( loanacctnumber, pmtnbr )
/

--sequences

CREATE SEQUENCE id_pmt_seq START WITH 1 INCREMENT BY 1
/

--CREATE A NON UNINUE, NON CLUSTERED INDEX ON CALCPERIOD

CREATE INDEX idx_pmtsched_calcprd
   ON pmt_schedule (calcperiod);

CREATE INDEX idx_pmtsched_acctnbr
   ON pmt_schedule (loanacctnumber);

CREATE OR REPLACE TRIGGER trg_pmtsched_log_upd_date
   BEFORE INSERT OR UPDATE
   ON pmt_schedule
   REFERENCING NEW AS new OLD AS old
   FOR EACH ROW
BEGIN
   :new.id_pmt := id_pmt_seq.NEXTVAL;
   :new.record_modified_date := SYSDATE;
END;
/

------***************************loan_discrate********************************-----------------

CREATE TABLE loan_discrate
(
   id_loan_disc_rate      NUMBER (10) PRIMARY KEY,
   loanacctnumber         VARCHAR (20) NOT NULL,
   calcperiod             DATE NOT NULL,
   discountrate           NUMBER (18, 15) NOT NULL,
   record_create_date     DATE DEFAULT SYSDATE,
   record_modified_date   DATE DEFAULT SYSDATE
)
/



CREATE SEQUENCE id_loan_disc_rate_seq START WITH 1 INCREMENT BY 1
/

--log triggers

CREATE OR REPLACE TRIGGER trg_loan_discrate_log_upd_date
   BEFORE INSERT OR UPDATE
   ON loan_discrate
   REFERENCING NEW AS new OLD AS old
   FOR EACH ROW
BEGIN
   :new.id_loan_disc_rate := id_loan_disc_rate_seq.NEXTVAL;
   :new.record_modified_date := SYSDATE;
END;
/



------**************************loan_secvalue*********************************-----------------


CREATE TABLE loan_secvalue
(
   id_loan_sec_val        NUMBER (10) PRIMARY KEY,
   loanacctnumber         VARCHAR (20) NOT NULL,
   calcperiod             DATE NOT NULL,
   secval                 NUMBER (18, 4),
   record_create_date     DATE DEFAULT SYSDATE,
   record_modified_date   DATE DEFAULT SYSDATE,
   record_modified_by     VARCHAR2 (200) DEFAULT USER
)
/

CREATE UNIQUE INDEX idx_secval#acct#calc
   ON loan_secvalue (loanacctnumber, calcperiod)
/

CREATE SEQUENCE id_loan_sec_val_seq START WITH 1 INCREMENT BY 1
/


CREATE OR REPLACE TRIGGER trg_secval_defaults
   BEFORE INSERT OR UPDATE
   ON loan_secvalue
   REFERENCING NEW AS new OLD AS old
   FOR EACH ROW
BEGIN
   IF (INSERTING)
   THEN
      :new.id_loan_sec_val := id_loan_sec_val_seq.NEXTVAL;
   END IF;


   :new.record_modified_date := SYSDATE;
END;
/



------***************************loan_secvalue_log********************************-----------------
-- This table will hold any changes to the loan_secvalue.,
-- This will serve as history table for loan_secvalue
--

CREATE TABLE loan_secvalue_log
(
   id_loan_sec_val_log   NUMBER (10) PRIMARY KEY,
   log_timestamp         TIMESTAMP DEFAULT SYSTIMESTAMP,
   record_modified_by    VARCHAR2 (200),
   operation_type        VARCHAR2 (1)
                            CONSTRAINT chk_op_typ CHECK
                               (operation_type IN ('I', 'U', 'D')),
   id_loan_sec_val       NUMBER (10) NOT NULL,
   loanacctnumber        VARCHAR (20) NOT NULL,
   calcperiod            DATE NOT NULL,
   secval                NUMBER (18, 4)
)
/


CREATE SEQUENCE id_loan_sec_val_seq_log START WITH 1 INCREMENT BY 1
/



CREATE OR REPLACE TRIGGER trg_log_secval_changes
   AFTER INSERT OR UPDATE OR DELETE
   ON loan_secvalue
   REFERENCING NEW AS new OLD AS old
   FOR EACH ROW
DECLARE
   v_op_type   VARCHAR2 (1);
BEGIN
   IF (INSERTING)
   THEN
      v_op_type := 'I';
   ELSIF (UPDATING)
   THEN
      v_op_type := 'U';
   ELSIF DELETING
   THEN
      v_op_type := 'D';
   END IF;


   IF (v_op_type = 'D' OR v_op_type = 'U')
   THEN
      INSERT INTO loan_secvalue_log (id_loan_sec_val_log,
                                     operation_type,
                                     id_loan_sec_val,
                                     loanacctnumber,
                                     calcperiod,
                                     secval,
                                     record_modified_by)
           VALUES (id_loan_sec_val_seq_log.NEXTVAL,
                   v_op_type,
                   :old.id_loan_sec_val,
                   :old.loanacctnumber,
                   :old.calcperiod,
                   :old.secval,
                   :old.record_modified_by);
   ELSIF (v_op_type = 'I')
   THEN
      INSERT INTO loan_secvalue_log (id_loan_sec_val_log,
                                     operation_type,
                                     id_loan_sec_val,
                                     loanacctnumber,
                                     calcperiod,
                                     secval,
                                     record_modified_by)
           VALUES (id_loan_sec_val_seq_log.NEXTVAL,
                   v_op_type,
                   :new.id_loan_sec_val,
                   :new.loanacctnumber,
                   :new.calcperiod,
                   :new.secval,
                   :new.record_modified_by);
   END IF;
END;
/


------********************************GTT_LOANPMT_CASH_FLOW***************************-----------------

--This table holds temp data, for monthly cash flows/PVs
--used ON COMMIT PRESERVE ROWS clause For test/validation purposes
--can be changed to ON COMMIT DELETE ROWS


CREATE GLOBAL TEMPORARY TABLE GTT_LOANPMT_CASH_FLOW
(
   calc_period      DATE,
   LOANACCTNUMBER   VARCHAR2 (20 BYTE) NULL,
   NBR_MOS          NUMBER (10) NULL,
   calendar_month   DATE NULL,
   CASH_FLOW        NUMBER (18, 4) NULL,
   DISCOUNTRATE     NUMBER (18, 4) NULL,
   PV               NUMBER (18, 4) NULL,
   MERGE_FLAG       VARCHAR2 (1) DEFAULT 'P'            --P:Pending/C:Complete
) ON COMMIT PRESERVE ROWS
/



------***********************************************************-----------------
--This table holds process log.
--Will log each step, after merging X loans into loansecvalue table
--Will log any errors

CREATE TABLE process_log
(
   log_timestamp   TIMESTAMP DEFAULT SYSTIMESTAMP,
   LOG             VARCHAR2 (1000),
   error_msg       VARCHAR2 (4000)
)
/