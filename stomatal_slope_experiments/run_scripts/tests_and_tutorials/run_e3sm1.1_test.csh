#! /bin/csh -fe

# Modified from run_e3sm.DECKv1b_piControl.ne30_oEC.cori-knl.csh (downloaded on 30Nov2021)
# Last edited by Claire Zarakas 30Nov2021

#============================================
# RUN SETTINGS
#============================================

### BASIC INFO ABOUT RUN
# only used to name the job in the batch system
set job_name       = test_e3sm1.1         
set compset        = A_WCYCL1850S_CMIP6    # indicates which model components and forcings to use. List choices by typing 'create_newcase -list compsets'
set resolution     = ne30_oECv3_ICG        # model resolution to use. Type `create_newcase -list grids` for a list of options
set machine        = cori-knl              # machine to run simulation on (note this should be lowercase). Valid machine names can also be listed via 'create_newcase -list machines'
setenv project       m3782                 # what project code to charge for your run time

### CASE_NAME
set case_name      = e3smv1.1_${job_name}.ne30_oEC.cori-kn

### STARTUP TYPE
set model_start_type = initial             #how to initialize model. options are:  initial, continue, branch, 'hybrid','restart'
set run_refdir = e3sm_init
set run_refcase = 20171228.beta3rc13_1850.ne30_oECv3_ICG.edison
set run_refdate = 0331-01-01

### DIRECTORIES
set code_root_dir               = ~/E3SM_source/E3SM_v1.0                        #directory for sources E3SM code
set case_dir                    = ~/model_cases/e3sm_cases
set scratch_dir                 = /global/cscratch1/sd/czarakas
set e3sm_simulations_dir        = ${scratch_dir}/E3SM_simulations
set case_build_dir              = ${e3sm_simulations_dir}/${case_name}/build
set case_run_dir                = ${e3sm_simulations_dir}/${case_name}/run
set short_term_archive_root_dir = ${e3sm_simulations_dir}/${case_name}/archive

### PROCESSOR CONFIGURATION
set processor_config = S           
#Indicates what processor configuration to use.
# 1=single processor, S=small, M=medium, L=large, X1=very large, X2=very very large

#=============================================================
# HANDLE STANDARD PROCESSOR CONFIGURATIONS
#=============================================================
# NOTE: Some standard PE configurations are available (S,M,L,X1,X2).
#       If the requested configuration is 1 or CUSTOM, then set to M here, and handle later.

alias lowercase "echo \!:1 | tr '[A-Z]' '[a-z]'"  #make function which lowercases any strings passed to it.
set lower_case = `lowercase $processor_config`
switch ( $lower_case )
  case 's':
    set std_proc_configuration = 'S'
    breaksw
  case 'm':
    set std_proc_configuration = 'M'
    breaksw
  case 'l':
    set std_proc_configuration = 'L'
    breaksw
  case 'x1':
    set std_proc_configuration = 'X1'
    breaksw
  case 'x2':
    set std_proc_configuration = 'X2'
    breaksw
  case '1':
    set std_proc_configuration = 'M'
    breaksw
  case 'custom*':
    # Note: this is just a placeholder so create_newcase will work.
    #       The actual configuration should be set under 'CUSTOMIZE PROCESSOR CONFIGURATION'
    set std_proc_configuration = 'M'
    breaksw
  default:
    e3sm_print 'ERROR: $processor_config='$processor_config' is not recognized'
    exit 40
    breaksw
endsw

#============================================
# CREATE NEW CASE
#============================================
cd ${code_root_dir}/cime/scripts

set configure_options = "--case ${case_dir}/${case_name} --compset ${compset} --res ${resolution} --pecount ${std_proc_configuration} --handle-preexisting-dirs u"
set configure_options = "${configure_options} --mach ${machine} --project ${project}"

./create_newcase ${configure_options}

# --script-root ${case_scripts_dir} 
# --handle-preexisting-dirs u
# --output-root ${build_root}

#============================================
# CHANGE XML SETTINGS
#============================================
cd ${case_dir}/${case_name}

# MACHINE
./xmlchange MACH=$machine

# 
./xmlchange JOB_WALLCLOCK_TIME=00:30
./xmlchange RUN_STARTDATE=0001-01-01

#SIMULATION LENGTH
./xmlchange --id STOP_OPTION --val ndays
./xmlchange --id STOP_N      --val 2

#RESTART FREQUENCY
./xmlchange --id REST_OPTION --val ndays
./xmlchange --id REST_N      --val 2
./xmlchange --id RESUBMIT --val 0

#COUPLER BUDGETS
./xmlchange --id BUDGETS     --val TRUE

#COUPLER HISTORY FILES
./xmlchange --id HIST_OPTION --val nyears
./xmlchange --id HIST_N      --val 1

# SETUP SHORT TERM ARCHIVING
./xmlchange --id DOUT_S --val FALSE
./xmlchange --id DOUT_S_ROOT --val $short_term_archive_root_dir 

# SETUP SIMULATION INITIALIZATION
set model_start_type = $model_start_type
if ( $model_start_type == 'initial' ) then
  ./xmlchange --id RUN_TYPE --val "startup"
  ./xmlchange --id CONTINUE_RUN --val "FALSE"
else if ( $model_start_type == 'continue' ) then
  ./xmlchange --id CONTINUE_RUN --val "TRUE"
else if ( $model_start_type == 'hybrid' ) then
  ./xmlchange  --id RUN_TYPE --val "hybrid"
  ./xmlchange  --id RUN_REFCASE --val $run_refcase
  ./xmlchange  --id RUN_REFDATE --val $run_refdate
  ./xmlchange  --id GET_REFCASE  --val "TRUE"
  ./xmlchange  --id RUN_REFDIR  --val $run_refdir
  ./xmlchange  --id CONTINUE_RUN --val "FALSE"
endif


#============================================
# SET UP CASE
#============================================
./case.setup #--reset

#============================================
# BUILD MODEL
#============================================
# ./xmlchange --id DEBUG --val TRUE
./case.build

#============================================
# MODIFY NAMELISTS
#============================================
cat <<EOF >> user_nl_cam
 !----------------------------------------------------------------------------------
 !------------------------------HISTORY FILES--------------------------------------
 !----History files (h2): daily output
 fincl2 = 'TSMN','TSMX','PRECT'
 nhtfrq(2)=-24
 mfilt(2)=365

EOF

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
 
 hist_nhtfrq = 0,0,-24,-24
 hist_mfilt=120,120,365,365
 !----------------------------------------------------------------------------------

EOF

#============================================
# BATCH JOB OPTIONS
#============================================

mkdir -p batch_output      ### Make directory that stdout and stderr will go into.

set batch_options = ''

if ( $machine =~ 'cori*' || $machine == edison ) then
    echo CORI
    set batch_options = "--job-name=${job_name} --output=batch_output/${case_name}.o%j"

    sed -i /"#SBATCH \( \)*--job-name"/c"#SBATCH  --job-name=ST+${job_name}"                  $shortterm_archive_script
    sed -i /"#SBATCH \( \)*--job-name"/a"#SBATCH  --account=${project}"                       $shortterm_archive_script
    sed -i /"#SBATCH \( \)*--output"/c'#SBATCH  --output=batch_output/ST+'${case_name}'.o%j'  $shortterm_archive_script

endif


#=================================================
# SUBMIT SIMULATION
#=================================================
#./xmlchange --id JOB_QUEUE --val 'debug' #if machine is cab or sierra, this should be 'pdebug'
./case.submit --batch-args " ${batch_options} "
