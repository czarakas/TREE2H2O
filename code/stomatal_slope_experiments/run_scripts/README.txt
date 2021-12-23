
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
Other machine options:
  stampede2 : Stampede2. Intel skylake nodes at TACC.  48 cores per node, batch system is SLURM 
  mac : Mac OS/X workstation or laptop 
  linux-generic : Linux workstation or laptop 
  melvin : Linux workstation for Jenkins testing 
  snl-white : IBM Power 8 Testbed machine 
  snl-blake : Skylake Testbed machine 
  anlworkstation : Linux workstation for ANL 
  sandiatoss3 : SNL clust 
  ghost : SNL clust 
  blues : ANL/LCRC Linux Cluster 
  anvil : ANL/LCRC Linux Cluster 
  bebop : ANL/LCRC Cluster, Cray CS400, 352-nodes Xeon Phi 7230 KNLs 64C/1.3GHz + 672-nodes Xeon E5-2695v4 Broadwells 36C/2.10GHz, Intel Omni-Path network, SLURM batch system, Lmod module environment. 
  cetus : ANL IBM BG/Q, os is BGQ, 16 cores/node, batch system is cobalt 
  cab : LLNL Linux Cluster, Linux (pgi), 16 pes/node, batch system is Slurm 
  syrah : LLNL Linux Cluster, Linux (pgi), 16 pes/node, batch system is Slurm 
  quartz : LLNL Linux Cluster, Linux (pgi), 36 pes/node, batch system is Slurm 
  mira : ANL IBM BG/Q, os is BGQ, 16 cores/node, batch system is cobalt 
  theta : ALCF Cray XC40 KNL, os is CNL, 64 pes/node, batch system is cobalt 
  sooty : PNL cluster, OS is Linux, batch system is SLURM 
  cascade : PNNL Intel KNC cluster, OS is Linux, batch system is SLURM 
  constance : PNL Haswell cluster, OS is Linux, batch system is SLURM 
  compy : PNL E3SM Intel Xeon Gold 6148(Skylake) nodes, OS is Linux, SLURM 
  oic5 : ORNL XK6, os is Linux, 32 pes/node, batch system is PBS 
  cades :  OR-CONDO, CADES-CCSI, os is Linux, 16 pes/nodes, batch system is PBS 
  titan : ORNL XK6, os is CNL, 16 pes/node, batch system is PBS 
  eos : ORNL XC30, os is CNL, 16 pes/node, batch system is PBS 
  grizzly : LANL Linux Cluster, 36 pes/node, batch system slurm 
  wolf : LANL Linux Cluster, 16 pes/node, batch system slurm 
  mesabi : Mesabi batch queue 
  itasca : Itasca batch queue 
  lawrencium-lr3 : Lawrencium LR3 cluster at LBL, OS is Linux (intel), batch system is SLURM 
  lawrencium-lr2 : Lawrencium LR2 cluster at LBL, OS is Linux (intel), batch system is SLURM 
  eddi : small developer workhorse at lbl climate sciences 
  summitdev : ORNL pre-Summit testbed. Node: 2x POWER8 + 4x Tesla P100, 20 cores/node, 8 HW threads/core. 
  summit : ORNL Summit. Node: 2x POWER9 + 6x Volta V100, 22 cores/socket, 4 HW threads/core. 


