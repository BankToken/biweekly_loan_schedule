/* Formatted on 10/6/2017 3:56:33 PM (QP5 v5.252.13127.32847) */
CREATE OR REPLACE PACKAGE pkg_secval
AS
   /******************************************************************************
      NAME:       asdas
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        10/6/2017      jahir       1. Created this package.

                                               PROCEDURE  calclate_secval
                                               --This SP will calculate SECVAL of all loans at a time
                                               --Use this SP if number of loans are less than 10000
                                               --This is resubale procedure. Can be re-run for same calcperiod again


                                               PROCEDURE  calc_secval_commit_inteval
                                               --This SP will calculate SECVAL, processes X number of loans at a time
                                               --Use this SP if number of loans  are >10000
                                               --This is resubale procedure. Can be re-run for same calcperiod again


                                               PROCEDURE  add_log
                                               --This SP will insert log entry at each step of the load/calculation
                                               --

                                               PROCEDURE  add_loan_schedule
                                               -- This SP will add loan schedule in pmt_schedule
                                               --Created for inserting test data

   ******************************************************************************/



   PROCEDURE calclate_secval (pi_calc_period IN VARCHAR2);

   PROCEDURE calc_secval_commit_inteval (pi_calc_period       IN VARCHAR2,
                                         pi_commit_interval   IN NUMBER);

   PROCEDURE add_log (pi_msg IN VARCHAR2, pi_error IN VARCHAR2 DEFAULT NULL);


   PROCEDURE add_loan_schedule (pi_loan_acctnumber      IN VARCHAR2,
                                pi_monthly_pmt          IN NUMBER,
                                pi_interval             IN NUMBER,      --days
                                pi_first_date           IN VARCHAR2, --MM/DD/YYYY
                                pi_last_pmt             IN NUMBER,
                                pi_discount_rate        IN NUMBER,
                                pi_calcperiod           IN VARCHAR2 --MM/DD/YYYY
                                                                   ,
                                pi_remaining_payments   IN NUMBER);
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_secval
AS
   PROCEDURE add_log (pi_msg IN VARCHAR2, pi_error IN VARCHAR2 DEFAULT NULL)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO process_log (LOG, error_msg)
           VALUES (pi_msg, pi_error);

      COMMIT;
   END;

   --Assumption/
   --Each month, You get loan payment schedules for remaining paments only, Hence Secval will be calculated today,for future cash flows only
   --Secvalue will not be calculated for entire payment schedule ( from first payment, which was paid in the past,  to last payment )
   --for example, for a Loan with payment terms of 60 monthly payments,  from Jan 2015 to  Dec 2020,  you get new loan schedule today (i.e. 9/30/2017 ), SecVal will be calculated for payments from Sept 2017 to Dec 2020
   --

   --Logic
   -- Take given parameter pi_calc_period
   -- and find all loan schedules having that calcPeriod ( This is assumption )
   -- and calculate Secval for each of those loans ( FOR ENTIRE SCHEDULE , not only upto current date )
   --

   PROCEDURE calc_secval_commit_inteval (pi_calc_period       IN VARCHAR2,
                                         pi_commit_interval   IN NUMBER)
   IS
      v_sp_name           VARCHAR2 (100) := 'calc_secval_commit_inteval';
      v_log_status        VARCHAR2 (4000);
      v_cnt               NUMBER (10) := 0;
      v_commit_interval   NUMBER (10) := NVL (pi_commit_interval, 10); -- defaulted to 10.
      v_calc_period       DATE := TO_DATE (pi_calc_period, 'MM/DD/YYYY');
      v_start_time        NUMBER (10) := DBMS_UTILITY.get_time;
      v_end_time          NUMBER;


      CURSOR c1
      IS
         SELECT DISTINCT loanacctnumber
           FROM pmt_schedule
          WHERE calcperiod = v_calc_period;

      TYPE loanaccounts_typ IS TABLE OF pmt_schedule.loanacctnumber%TYPE
         INDEX BY BINARY_INTEGER;

      tbl1                loanaccounts_typ;
   BEGIN
      add_log ('== Start SP : calc_secval_commit_inteval ==');

      DELETE FROM gtt_loanpmt_cash_flow
            WHERE calc_period = v_calc_period;

      OPEN c1;
      LOOP
         FETCH c1 BULK COLLECT INTO tbl1 LIMIT v_commit_interval; --1000 loans at a time.

         EXIT WHEN tbl1.COUNT = 0;

         v_cnt := v_cnt + tbl1.COUNT;
         v_log_status := NULL;

         DBMS_OUTPUT.put_line (' Loaded :' || tbl1.COUNT || '  loans ');



         BEGIN
            FORALL i IN tbl1.FIRST .. tbl1.LAST
               INSERT INTO gtt_loanpmt_cash_flow (calc_period,
                                                  loanacctnumber,
                                                  nbr_mos,
                                                  calendar_month,
                                                  cash_flow,
                                                  discountrate,
                                                  pv)
                    SELECT p.calcperiod,
                           p.loanacctnumber,
                           ROW_NUMBER () OVER (PARTITION BY p.loanacctnumber  ORDER BY p.pcd_act_d)  AS mth_nbr,           -- Addl Info, not required , Added for storing into global temp table only
                           p.pcd_act_d AS calendar_month,                                                                  -- Addl Info, not required , Added for storing into global temp table only
                           SUM (mopmt),                                                                                    -- Addl Info, not required , Added for storing into global temp table only
                           d.discountrate,
                            SUM (mopmt)/ POWER ((1 + (discountrate / 1200)),ROW_NUMBER () OVER (PARTITION BY p.loanacctnumber ORDER BY p.pcd_act_d)) AS pv
                      FROM pmt_schedule p, loan_discrate d
                     WHERE     p.calcperiod = v_calc_period
                           AND p.loanacctnumber = d.loanacctnumber
                           AND d.calcperiod = p.calcperiod
                           AND p.loanacctnumber = tbl1 (i)
                  GROUP BY p.calcperiod,
                           p.loanacctnumber,
                           d.discountrate,
                           p.pcd_act_d;

            v_log_status := ' Loaded ' || tbl1.COUNT || ' loan schedules into gtt';

         EXCEPTION
            WHEN OTHERS
            THEN
               add_log (' Error while Loading ' || tbl1.COUNT || ' loan schedules into gtt',SQLERRM);
         END;

         BEGIN
            MERGE INTO loan_secvalue d
                 USING (  SELECT loanacctnumber, ROUND (SUM (pv), 2) AS secval FROM gtt_loanpmt_cash_flow WHERE merge_flag = 'P' GROUP BY loanacctnumber) s
                    ON (    d.loanacctnumber = s.loanacctnumber
                        AND d.calcperiod = v_calc_period)
            WHEN MATCHED
            THEN
               UPDATE SET
                  d.secval = s.secval, d.record_modified_by = v_sp_name
               DELETE
                       WHERE (s.secval <= 0)
            WHEN NOT MATCHED
            THEN
               INSERT     (d.loanacctnumber,
                           d.secval,
                           d.calcperiod,
                           d.record_modified_by)
                   VALUES (s.loanacctnumber,
                           s.secval,
                           v_calc_period,
                           v_sp_name);

            v_log_status := v_log_status || '; Merged total ' || v_cnt || ' loan schedules into loan_secvalue';

            UPDATE gtt_loanpmt_cash_flow
               SET merge_flag = 'C'
             WHERE merge_flag = 'P';
         EXCEPTION
            WHEN OTHERS
            THEN
               add_log (' Error while Loading '|| v_cnt || ' loans schedules into loan_secvalue',SQLERRM);
         END;

         add_log (v_log_status, NULL);
         COMMIT;
      END LOOP;

      CLOSE c1;

      v_end_time := DBMS_UTILITY.get_time;

      add_log ('== Complete SP : calc_secval_commit_inteval == time Taken:'|| ROUND ( (v_end_time - v_start_time) / 100, 2)|| ' seconds');

   EXCEPTION
            WHEN OTHERS
            THEN
               add_log (' Error in SP calc_secval_commit_inteval.',SQLERRM);
           
   END;

   PROCEDURE calclate_secval (pi_calc_period IN VARCHAR2)
   IS
      v_disc_rate     loan_discrate.discountrate%TYPE;
      v_sp_name       VARCHAR2 (100) := 'calclate_secval';
      v_status        VARCHAR2 (4000) := NULL;
      v_calc_period   DATE := TO_DATE (pi_calc_period, 'MM/DD/YYYY');
      v_start_time    NUMBER (10) := DBMS_UTILITY.get_time;
      v_end_time      NUMBER (10);
   BEGIN
      add_log ('== Start SP :calculate_secval ==');

      DELETE FROM gtt_loanpmt_cash_flow
            WHERE calc_period = v_calc_period;

      add_log (' deleted ' || SQL%ROWCOUNT || ' rows from temp table');

      INSERT INTO gtt_loanpmt_cash_flow (calc_period,
                                         loanacctnumber,
                                         discountrate,
                                         calendar_month,
                                         nbr_mos,
                                         cash_flow)
           SELECT TO_DATE (pi_calc_period, 'MM/DD/YYYY'),
                  p.loanacctnumber,
                  d.discountrate,
                  p.pcd_act_d,
                  ROW_NUMBER () OVER (PARTITION BY p.loanacctnumber ORDER BY p.pcd_act_d) AS pmt_nbr,
                  SUM (mopmt) AS cash_flow
             FROM pmt_schedule p, loan_discrate d
            WHERE     p.calcperiod = v_calc_period
                  AND p.loanacctnumber = d.loanacctnumber
                  AND d.calcperiod = p.calcperiod
         GROUP BY p.loanacctnumber, d.discountrate, p.pcd_act_d
         ORDER BY 1, 5;

      add_log (' Caclulated monthly cashflow. Added '|| SQL%ROWCOUNT || ' rows into loanpmt_cash_flow');

      UPDATE gtt_loanpmt_cash_flow
         SET pv = cash_flow / POWER ( (1 + (discountrate / 1200)), nbr_mos)
       WHERE discountrate IS NOT NULL;

      add_log (' Calculated PV for all cash flows');

      MERGE INTO loan_secvalue d
           USING (  SELECT loanacctnumber,
                           v_calc_period AS calc_period,
                           ROUND (SUM (pv), 2) AS secval
                      FROM gtt_loanpmt_cash_flow
                     WHERE merge_flag = 'P'
                  GROUP BY loanacctnumber, v_calc_period) s
              ON (    d.loanacctnumber = s.loanacctnumber
                  AND d.calcperiod = s.calc_period)
      WHEN MATCHED
      THEN
         UPDATE SET
            d.secval = s.secval,
            d.record_modified_by = v_sp_name || ' update'
      WHEN NOT MATCHED
      THEN
         INSERT     (d.loanacctnumber,
                     d.secval,
                     d.calcperiod,
                     d.record_modified_by)
             VALUES (s.loanacctnumber,
                     s.secval,
                     v_calc_period,
                     v_sp_name || ' insert');

      add_log (' Merged into loan_secvalue');

      UPDATE gtt_loanpmt_cash_flow
         SET merge_flag = 'C'
       WHERE merge_flag = 'P';

      v_end_time := DBMS_UTILITY.get_time;

      add_log ('== Complete SP : calc_secval == time Taken:' || ROUND ( (v_end_time - v_start_time) / 100, 2) || ' seconds');

      COMMIT;
   END;

   PROCEDURE add_loan_schedule (pi_loan_acctnumber      IN VARCHAR2,
                                pi_monthly_pmt          IN NUMBER,
                                pi_interval             IN NUMBER,      --days
                                pi_first_date           IN VARCHAR2, --MM/DD/YYYY
                                pi_last_pmt             IN NUMBER,
                                pi_discount_rate        IN NUMBER,
                                pi_calcperiod           IN VARCHAR2 --MM/DD/YYYY
                                                                   ,
                                pi_remaining_payments   IN NUMBER)
   IS
      v_first_pmt_date          DATE := TO_DATE (pi_first_date, 'MM/DD/YYYY');
      v_pmt_interval_days       NUMBER (5) := pi_interval;
      v_loan_acct_number        VARCHAR2 (200) := pi_loan_acctnumber;
      v_mthly_pmt               NUMBER (10, 2) := pi_monthly_pmt;
      v_last_pmt                NUMBER (10, 2) := pi_last_pmt;
      v_discount_rate           loan_discrate.discountrate%TYPE
                                   := pi_discount_rate;
      v_cut_pmt_due_date        DATE;
      v_last_day_of_pmt_month   DATE;
      v_calcperiod              DATE := TO_DATE (pi_calcperiod, 'MM/DD/YYYY');
      v_id_loan_disc_rate       NUMBER (10);
   BEGIN
      --populate loan discount rate
      INSERT INTO loan_discrate (loanacctnumber, calcperiod, discountrate)
           VALUES (v_loan_acct_number, v_calcperiod, v_discount_rate);

      FOR i IN 1 .. pi_remaining_payments
      LOOP
         v_cut_pmt_due_date :=
         v_first_pmt_date + v_pmt_interval_days * (i - 1);
         v_last_day_of_pmt_month := LAST_DAY (v_cut_pmt_due_date);

         INSERT INTO pmt_schedule (loanacctnumber,
                                   pmtnbr,
                                   current_pmt_due_dt,
                                   mopmt,
                                   calcperiod,
                                   pcd_act_d)
              VALUES (v_loan_acct_number,
                      i,
                      v_first_pmt_date + v_pmt_interval_days * (i - 1),
                      v_mthly_pmt,
                      v_calcperiod,
                      v_last_day_of_pmt_month);
      END LOOP;

      IF (v_last_pmt IS NOT NULL)
      THEN
         --update last payment , if differnet
         UPDATE pmt_schedule a
            SET mopmt = v_last_pmt
          WHERE     loanacctnumber = v_loan_acct_number
                AND pmtnbr = (SELECT MAX (pmtnbr)
                                FROM pmt_schedule b
                               WHERE b.loanacctnumber = a.loanacctnumber);
      END IF;
   END;
END pkg_secval;
/

SHOW ERR
/