EXPERIMENTAL DESIGN

* 1xCO2 spin up:
* 2xCO2 spin up:
* 1xCO2 default parameters
* 1xCO2 high medlynslope
* 1xCO2 low medlynslope
* 2xCO2 default parameters
* 2xCO2 high medlynslope
* 2xCO2 low medlynslope

----------------------------------------------------------------------------
Things to change between simulations
*   ./xmlchange CCSM_CO2_PPMV=569.4 or 284.7
*   stomatal slope - change via parameterfile in CLM namelists
*   atmospheric CO2 concentration - change via parameterfile in CAM namelists (co2vmr=569.4e-6)

################################################################################
################################################################################
################################################################################

Check simulation status with
>> squeue -u czarakas

Cancel job with
>> scancel JOBID
----------------------------------------------------------------------------
Look at model output in
/global/cscratch1/sd/czarakas/

----------------------------------------------------------------------------
where to find slab ocean options:
/global/cfs/cdirs/e3sm/inputdata/ocn/docn7/SOM/

----------------------------------------------------------------------------
List machine options with
>> ./query_config -machines

Options for machine (on NERSC):
  cori-haswell : Cori. XC40 Cray system at NERSC. Haswell partition. os is CNL, 32 pes/node, batch system is SLURM 
  cori-knl (current) : Cori. XC40 Cray system at NERSC. KNL partition. os is CNL, 68 pes/node (for now only use 64), batch system is SLURM 


