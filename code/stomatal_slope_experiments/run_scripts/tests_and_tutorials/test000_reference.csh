#! /bin/csh -fe

# Modified from run_e3sm.DECKv1b_piControl.ne30_oEC.cori-knl.csh (downloaded on 30Nov2021)
# Last edited by Claire Zarakas 22Dec2021

#============================================
# RUN SETTINGS
#============================================

### BASIC INFO ABOUT RUN
set job_name       = test000_ref_06                               # only used to name the job in the batch system 
set compset        = 1850_CAM5%CMIP6_CLM45%CNPRDCTCBC_MPASCICE_DOCN%SOM_MOSART_SGLC_SWAV_TEST #BGC%BCRC_TEST 
set resolution     = ne30_oECv3 #ne30_g16 #ne30_oECv3                                        # model resolution to use
set machine        = cori-knl                                            # machine to run simulation on (note this should be lowercase)
setenv project       m3782                                               # what project code to charge for your run time
set case_name      = ${job_name}.${resolution}.${machine}                        # case name used for archiving etc.

### DIRECTORIES
set code_root_dir               = ~/E3SM_source/E3SM_v1.1                        #directory for sources E3SM code
set case_dir                    = ~/model_cases/e3sm_cases
set scratch_dir                 = /global/cscratch1/sd/czarakas
set e3sm_simulations_dir        = ${scratch_dir}/E3SM_simulations
set case_build_dir              = ${e3sm_simulations_dir}/${case_name}/build
set case_run_dir                = ${e3sm_simulations_dir}/${case_name}/run
set short_term_archive_root_dir = ${e3sm_simulations_dir}/${case_name}/archive
set dir_run_to_branch_from = /global/cfs/cdirs/e3sm/inputdata/e3sm_init/20181130_BCRC_1850SPINUP_OIBGC.ne30_oECv3.edison/0324-01-01-00000
set dir_runscript = /global/homes/c/czarakas/TREE2H2O/code/stomatal_slope_experiments/run_scripts/tests_and_tutorials

#============================================
# CREATE NEW CASE
#============================================
# rm -rf ${case_dir}/${case_name}

set std_proc_configuration = 'S' #Indicates what processor configuration to use.
# 1=single processor, S=small, M=medium, L=large, X1=very large, X2=very very large

cd ${code_root_dir}/cime/scripts

set configure_options = "--case ${case_dir}/${case_name} --compset ${compset} --res ${resolution} --pecount ${std_proc_configuration} --handle-preexisting-dirs u"
set configure_options = "${configure_options} --mach ${machine} --project ${project}"

./create_newcase ${configure_options}

cd ${case_dir}/${case_name}

./case.setup
#============================================
# COPY RUN SCRIPT TO FOLDER
#============================================
set iscript_name=`basename $0`

cp $dir_runscript/$iscript_name .

#============================================
# CHANGE XML SETTINGS
#============================================
cd ${case_dir}/${case_name}

# MACHINE
./xmlchange MACH=$machine

# SLAB OCEAN
./xmlchange DOCN_SOM_FILENAME=pop_frc.1x1d.090130.nc #this is the default slab ocean

#============================================
# SET UP CASE
#============================================
#./case.setup --reset

# RUNTIME AND SIMULATION LENGTH
./xmlchange JOB_WALLCLOCK_TIME=00:30 --subgroup case.run
./xmlchange --id STOP_OPTION --val ndays
./xmlchange --id STOP_N      --val 3

#RESTART FREQUENCY
./xmlchange --id REST_OPTION --val ndays
./xmlchange --id REST_N      --val 3
./xmlchange --id RESUBMIT --val 0

#COUPLER BUDGETS / HISTORY FILES
./xmlchange --id BUDGETS     --val TRUE
./xmlchange --id HIST_OPTION --val nyears
./xmlchange --id HIST_N      --val 1

# SETUP SHORT TERM ARCHIVING
./xmlchange --id DOUT_S --val TRUE
./xmlchange --id DOUT_S_ROOT --val $short_term_archive_root_dir 

#============================================
# SETUP SIMULATION INITIALIZATION
#============================================
# If initial
#./xmlchange RUN_TYPE=startup
#./xmlchange RUN_STARTDATE=0001-01-01

# If branching 
./xmlchange RUN_TYPE=hybrid
./xmlchange GET_REFCASE=FALSE
./xmlchange RUN_STARTDATE=0324-01-01 #0001-01-01
./xmlchange START_TOD=0
./xmlchange RUN_REFCASE=20181130_BCRC_1850SPINUP_OIBGC.ne30_oECv3.edison #'20181130_BCRC_1850SPINUP_OIBGC.ne30_oECv3.edison'
./xmlchange RUN_REFDATE=0324-01-01 #0370-01-01
./xmlchange RUN_REFDIR=$dir_run_to_branch_from

./xmlchange CONTINUE_RUN=FALSE

#============================================
# SET UP CASE
#============================================
#./case.setup

# COPY IN RESUBMIT FILES
cd /global/cscratch1/sd/czarakas/e3sm_scratch/cori-knl/$case_name/run
cp ${dir_run_to_branch_from}/* .
cd ${case_dir}/${case_name}

#============================================
# BUILD MODEL
#============================================
./case.build

#============================================
# MODIFY NAMELISTS
#============================================

#--------------- Atmosphere -----------------
cat <<EOF >> user_nl_cam
 !----------------------------------------------------------------------------------
 !------------------------------HISTORY FILES--------------------------------------
 !----History files (h2): daily output
 fincl2 = 'TS'
 nhtfrq(2)=-24
 mfilt(2)=365

EOF

#--------------- Land -----------------------
cat <<EOF >> user_nl_clm
 ! finidat
 ! use_init_interp
 ! paramfile
 check_finidat_year_consistency = .false.

 !----------------------------------------------------------------------------------
 !------------------------------HISTORY FILES--------------------------------------

 !----History files (h0): monthly output
 hist_fincl1 += 'EFLX_LH_TOT'

 !----History files (h1): monthly output for driving SP mode
 hist_fincl2 = 'TLAI'
 hist_type1d_pertape(2) = 'PFTS'
 hist_dov2xy(2)= .false.

 !----History files (h2): daily output
 hist_fincl3 = 'EFLX_LH_TOT'

 !----History files (h3): daily output at local noon
 
 hist_nhtfrq = 0,0,-24
 hist_mfilt=120,120,365
 !----------------------------------------------------------------------------------

EOF

#--------------- Coupler --------------------


#============================================
# BATCH JOB OPTIONS
#============================================
set batch_options = ''

#=================================================
# SUBMIT SIMULATION
#=================================================
./xmlchange --id JOB_QUEUE --val 'debug'
./case.submit --batch-args " ${batch_options} "
