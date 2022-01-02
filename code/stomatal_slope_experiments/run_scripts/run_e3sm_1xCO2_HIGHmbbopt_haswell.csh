#! /bin/csh -fe

#============================================
# RUN SETTINGS
#============================================

### BASIC INFO ABOUT RUN
set job_name       = mbbopt_high_1xCO2_003                               # only used to name the job in the batch system 
set compset        = 1850_CAM5%CMIP6_CLM45%CNPRDCTCBC_MPASCICE_DOCN%SOM_MOSART_SGLC_SWAV_TEST
set resolution     = ne30_oECv3                                          # model resolution to use
set machine        = cori-haswell                                        # machine to run simulation on (note this should be lowercase)
setenv project       m3782                                               # what project code to charge for your run time
set case_name      = ${job_name}.${resolution}.${machine}                # case name used for archiving etc.

### DIRECTORIES
set dir_code_root               = ~/E3SM_source/E3SM_v1.1_haswell                        #directory for sources E3SM code
set dir_case                    = ~/model_cases/e3sm_cases
set dir_scratch                 = /global/cscratch1/sd/czarakas
set dir_e3sm_simulations        = ${dir_scratch}/E3SM_simulations
set dir_short_term_archive_root = ${dir_e3sm_simulations}/${case_name}/archive
set dir_run_to_branch_from      = /global/cscratch1/sd/czarakas/restart_files/20181130_BCRC_1850SPINUP_OIBGC/0370-01-01-00000
set dir_runscript               = /global/homes/c/czarakas/TREE2H2O/code/stomatal_slope_experiments/run_scripts

#============================================
# CREATE NEW CASE
#============================================
# rm -rf ${dir_case}/${case_name}

set std_proc_configuration = 'M' #Indicates what processor configuration to use.
# 1=single processor, S=small, M=medium, L=large, X1=very large, X2=very very large

cd ${dir_code_root}/cime/scripts

set configure_options = "--case ${dir_case}/${case_name} --compset ${compset} --res ${resolution} --pecount ${std_proc_configuration} --handle-preexisting-dirs u"
set configure_options = "${configure_options} --mach ${machine} --project ${project}"

./create_newcase ${configure_options}

cd ${dir_case}/${case_name}

./xmlquery NTASKS_CPL
./xmlquery NTASKS_ATM
./xmlquery NTASKS_LND
./xmlquery NTASKS_ICE
./xmlquery NTASKS_OCN
./xmlquery NTASKS_ROF
./xmlquery NTASKS_GLC
./xmlquery NTASKS_WAV

set ntasks=1200
./xmlchange NTASKS_CPL=$ntasks
./xmlchange NTASKS_ATM=$ntasks
./xmlchange NTASKS_LND=$ntasks
./xmlchange NTASKS_ICE=$ntasks
./xmlchange NTASKS_OCN=$ntasks
./xmlchange NTASKS_ROF=$ntasks
./xmlchange NTASKS_GLC=$ntasks
./xmlchange NTASKS_WAV=$ntasks

./case.setup
#============================================
# COPY RUN SCRIPT TO FOLDER
#============================================
set iscript_name=`basename $0`

cp $dir_runscript/$iscript_name .

#============================================
# CHANGE XML SETTINGS
#============================================
cd ${dir_case}/${case_name}

# MACHINE
./xmlchange MACH=$machine

# SLAB OCEAN
./xmlchange DOCN_SOM_FILENAME=pop_frc.1x1d.090130.nc #this is the default slab ocean

# CO2 CONCENTRATION
./xmlchange CCSM_CO2_PPMV=284.7
./xmlchange CLM_CO2_TYPE=constant
#./xmlchange CCSM_BGC=CO2A

#============================================
# SET UP CASE
#============================================

# RUNTIME AND SIMULATION LENGTH
./xmlchange JOB_WALLCLOCK_TIME=21:10 --subgroup case.run
./xmlchange --id STOP_OPTION --val nyears
./xmlchange --id STOP_N      --val 3

#RESTART FREQUENCY
./xmlchange --id REST_OPTION --val nyears
./xmlchange --id REST_N      --val 3
./xmlchange --id RESUBMIT --val 20

#COUPLER BUDGETS / HISTORY FILES
./xmlchange --id BUDGETS     --val TRUE
./xmlchange --id HIST_OPTION --val nyears
./xmlchange --id HIST_N      --val 1

# SETUP SHORT TERM ARCHIVING
./xmlchange --id DOUT_S --val TRUE
./xmlchange --id DOUT_S_ROOT --val $dir_short_term_archive_root

#============================================
# SETUP SIMULATION INITIALIZATION
#============================================
# If initial
#./xmlchange RUN_TYPE=startup
#./xmlchange RUN_STARTDATE=0001-01-01

# If branching 
./xmlchange RUN_TYPE=hybrid
./xmlchange GET_REFCASE=FALSE
./xmlchange RUN_STARTDATE=0370-01-01 #0001-01-01
./xmlchange START_TOD=0
./xmlchange RUN_REFCASE=20181130_BCRC_1850SPINUP_OIBGC.ne30_oECv3.edison
./xmlchange RUN_REFDATE=0370-01-01
./xmlchange RUN_REFDIR=$dir_run_to_branch_from

./xmlchange CONTINUE_RUN=FALSE

#============================================
# SET UP CASE
#============================================
#./case.setup

# COPY IN RESUBMIT FILES
cd /global/cscratch1/sd/czarakas/e3sm_scratch/cori-haswell/$case_name/run
cp ${dir_run_to_branch_from}/* .
cd ${dir_case}/${case_name}

#============================================
# BUILD MODEL
#============================================
./case.build

#============================================
# MODIFY NAMELISTS
#============================================

#--------------- Atmosphere -----------------
cat <<EOF >> user_nl_cam
 co2vmr=284.7e-6
 co2vmr_rad=284.7e-6

 !----------------------------------------------------------------------------------
 !------------------------------HISTORY FILES--------------------------------------
 !----History files (h1): daily output
 fincl2 = 'TS','TREFHT','ICEFRAC','FLNT','FSNT'
 nhtfrq(2)=0
 mfilt(2)=12

 fincl3 = 'TSMN','TSMX','PRECT'
 nhtfrq(3)=-24
 mfilt(3)=365

EOF

#--------------- Land -----------------------
cat <<EOF >> user_nl_clm
 ! finidat
 ! use_init_interp
 paramfile = '/global/homes/c/czarakas/TREE2H2O/code/stomatal_slope_experiments/model_inputs/parameter_files/clm_params_high.nc'
 check_finidat_year_consistency = .false.

 !----------------------------------------------------------------------------------
 !------------------------------HISTORY FILES--------------------------------------
 !----History files (h0): default monthly output
 hist_fincl1 += 'GPP','QVEGT','QRUNOFF','RH2M','TV'!,'C13_GPP','C13_TOTVEGC'
 hist_nhtfrq(1)=0
 hist_mfilt(1)=12

 !----History files (h1): output to save for spin up
 hist_fincl2 += 'TBOT','TSA','TLAI','TSAI','HTOP','GPP','ER','AR','NPP','NEE','NBP','TWS','FSNO','TOTVEGC','TOTVEGN','TOTECOSYSC','TOTECOSYSN'
 hist_nhtfrq(2)=0
 hist_mfilt(2)=12

 !----History files (h2): monthly output for driving SP mode
 hist_fincl3 = 'TLAI','TSAI','HBOT','HTOP'
 hist_type1d_pertape(3) = 'PFTS'
 hist_dov2xy(3)= .false.
 hist_nhtfrq(3)=0
 hist_mfilt(3)=12

 !----History files (h3): daily output
 hist_fincl4 = 'GPP','LAISUN','LAISHA','PCO2','PBOT','THBOT','QSOIL','QVEGE','QVEGT','QRUNOFF','RH2M','FLDS','FSDS','FSR','FIRE','FSH','EFLX_LH_TOT','TSA','FPSN','PSNSHA','PSNSUN','BTRAN','SMP'
 !- other variables I would like to include, for which there is no history variable in E3SM
 !- 'VPD_CAN','GBMOL','GSSHALN','GSSUNLN','ANSHA_LN','ANSUN_LN','VPD_CAN_LN','GBMOL_LN','QVEGT_LN','GSSHA','GSSUN','VEGWP','TSKIN'
 hist_nhtfrq(4)=-24
 hist_mfilt(4)=365

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
#./xmlchange --id JOB_QUEUE --val 'premium'
./case.submit --batch-args " ${batch_options} "
