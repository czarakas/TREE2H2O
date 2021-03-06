#! /bin/csh -fe

# Modified from run_e3sm.DECKv1b_piControl.ne30_oEC.cori-knl.csh (downloaded on 30Nov2021)
# Last edited by Claire Zarakas 20Dec2021

#============================================
# RUN SETTINGS
#============================================

### BASIC INFO ABOUT RUN
set job_name       = test_E3SMv1.1BGC_1850_DOM_002                               # only used to name the job in the batch system 
set compset        = 1850_CAM5_CLM45%CNPRDCTCBC_MPASCICE_DOCN%DOM_MOSART_SGLC_SWAV_BGC%BDRD
# TARGET COMPSET: 1850_CAM5_CLM45%BGC_CICE_DOCN%SOM_MOSART_SGLC_SWAV
# Differences from compset that worked
# CICE vs. MPASCICE%SPUNUP
# DOCN%SOM vs. MPASO%SPUNUP
set resolution     = ne30_oECv3 #ne30_g16 #ne30_oECv3                                        # model resolution to use
set machine        = cori-knl                                            # machine to run simulation on (note this should be lowercase)
setenv project       m3782                                               # what project code to charge for your run time
set case_name      = ${job_name}.ne30_oECv3.cori-kn                        # case name used for archiving etc.

### DIRECTORIES
set code_root_dir               = ~/E3SM_source/E3SM_v1.1                        #directory for sources E3SM code
set case_dir                    = ~/model_cases/e3sm_cases
set scratch_dir                 = /global/cscratch1/sd/czarakas
set e3sm_simulations_dir        = ${scratch_dir}/E3SM_simulations
set case_build_dir              = ${e3sm_simulations_dir}/${case_name}/build
set case_run_dir                = ${e3sm_simulations_dir}/${case_name}/run
set short_term_archive_root_dir = ${e3sm_simulations_dir}/${case_name}/archive

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

#============================================
# CHANGE XML SETTINGS
#============================================
cd ${case_dir}/${case_name}

# MACHINE
./xmlchange MACH=$machine

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

# SETUP SIMULATION INITIALIZATION
./xmlchange RUN_STARTDATE=0001-01-01

./xmlchange --id RUN_TYPE --val "startup"
./xmlchange --id CONTINUE_RUN --val "FALSE"

# CONTINUE
#./xmlchange --id CONTINUE_RUN --val "TRUE"

# HYBRID
#  ./xmlchange  --id RUN_TYPE --val "hybrid"
#  ./xmlchange  --id RUN_REFCASE --val 20171228.beta3rc13_1850.ne30_oECv3_ICG.edison
#  ./xmlchange  --id RUN_REFDATE --val 0331-01-01
#  ./xmlchange  --id GET_REFCASE  --val "TRUE"
#  ./xmlchange  --id RUN_REFDIR  --val e3sm_init
#  ./xmlchange  --id CONTINUE_RUN --val "FALSE"


#============================================
# SET UP CASE
#============================================
./case.setup #--reset

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
 fincl2 = 'TSMN','TSMX','PRECT'
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
