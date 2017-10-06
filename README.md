# biweekly_loan_schedule : Project for calculating securitization value for given loan payment schedule ( hypothetical).
#
############################################### How to execute/Test ##############################################
#																				#							
# 1) Run script @rollback.sql ( Remove, If db objects already created )											
# 2) @create_tables_data.sql																	#				
# 3) @pkg_secval.sql																		#					
# 4) @test.sql																			#								
#																				#								
#################################################################################################################
#
# INFO:  The project contains four scripts.
#
#
#
##########(1) @create_tables_data.sql ########### 
#
# This script will create tables / indexes/triggers /temp table needed to serupt data model
#
#
##########(2) @pkg_secval.sql########### 
#
# This script will create package pkg_secval with four procedures. 
# Assumption :
# Each month, You get loan payment schedules for remaining paments only, Hence Secval will be calculated today,for future cash flows only
# Secvalue will not be calculated for entire payment schedule ( from first payment, which was paid in the past,  to last payment )
# for example, for a Loan with payment terms of 60 monthly payments,  from Jan 2015 to  Dec 2020,  you get new loan schedule today (i.e. 9/30/2017 ), 
# and SecVal will be calculated for payments from Sept # # 2017 to Dec 2020
#
# There are Two primary Procedures to process loan schedules :
# (1) procedure calclate_secval ( pi_calc_period in varchar2 );
#     This SP will calculate SECVAL of all loans at a time
#     Use this SP if number of loans are less than 10000
#     This is resubale procedure. Can be re-run for same calcperiod again 
#
# (2) procedure calc_secval_commit_inteval ( pi_calc_period in varchar2 , pi_commit_interval in number);
#    This SP will calculate SECVAL, processes X number of loans at a time
#    Use this SP if number of loans  are >10000
#    This is resubale procedure. Can be re-run for same calcperiod again
#
#
######### (3) @rollback.sql ##########
#
# This script will remove all datamodels , package(s). 
#
#
##########(4) @test.sql###########
#  
#  This script will execute test .Modify Accordingly for testing needs 
#
#  Test has 4 steps:
#   STEP1:Truncate tables
#   STEP2:Load loan schedules into pm_schedules table
#   
#   STEP3: Run this : exec pkg_secval.calc_secval_commit_inteval('7/31/2015',15);
#    -- OR 
#    --exec pkg_secval.calclate_secval('7/31/2015');
#
#   STEP 4: Check Tables.
#
#################################################################################################################



