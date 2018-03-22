% batch job for cluster: bsub -W 4:00 -R "rusage[mem=1000]" -n 24 matlab -nodisplay -singleCompThread -r batch_job_template
% MODULE:
%   climada
% NAME:
%   batch_job_template
% PURPOSE:
%   a template batch job for (any) cluster
%
%   See climada_global.parfor, as this speeds up many functions, as
%   mentioned in the purpose section of the header of each function (if
%   applicable).
%
%   The job can be tested on a desktop, see run_on_desktop below and the
%   example.
%
%   some hints to work with the cluster (explicit paths, edit this ;-)
%
%   copy job to cluster:       scp -r Documents/_GIT/climada_modules/isimip/code/batch/batch_job_template.m dbresch@euler.ethz.ch:/cluster/home/dbresch/euler_jobs/.
%   check progress:            ls -la /cluster/work/climate/dbresch/climada_data/hazards/*.mat
%
%   copy data to cluster:      scp -r Documents/_GIT/climada_data/hazards/*.mat dbresch@euler.ethz.ch:/cluster/work/climate/dbresch/climada_data/hazards/.
%   run on cluster:            bsub -R "rusage[mem=1000]" -n 24 matlab -nodisplay -singleCompThread -r batch_job_template
%
%   copy results back local:   scp -r dbresch@euler.ethz.ch:/cluster/work/climate/dbresch/climada_data/hazards/*.mat Documents/_GIT/climada_data/hazards/.
%   copy results back polybox: scp -r dbresch@euler.ethz.ch:/cluster/work/climate/dbresch/climada_data/hazards/*.mat /Users/bresch/polybox/isimip/hazards_v04/.
%   copy results to dkrz:      scp -r /cluster/work/climate/dbresch/climada_data/hazards/*.mat b380587@mistralpp.dkrz.de:/work/bb0820/scratch/b380587/.
%
%   other option, a LSF pool, see http://www.clusterwiki.ethz.ch/brutus/Parallel_MATLAB_and_Brutus
% CALLING SEQUENCE:
%   bsub -R "rusage[mem=5000]" -n 24 matlab -nodisplay -singleCompThread -r batch_job_template
% EXAMPLE:
%   bsub -W 4:00 -R "rusage[mem=1000]" -n 24 matlab -nodisplay -singleCompThread -r batch_job_template
%   -W: time, here 4 hours
%   mem: memory, for large jobs, request e.g. 9000
%   .n: number of cluster workers, here 24
%
%   run_on_desktop=1; % to test the job on a desktop
%   batch_job_template
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   run_on_desktop: if you set =1 before calling batch_job_template (all in
%       MATLAB command window), it sets the number of parallel pool workers
%       to two, does not delete the pool after execution and does not quit
%       MATLAB and hence allows to TEST a job on a local desktop. This
%       allows to TEST a job without editing it.
%       Default=0 for cluster.
% OUTPUTS:
%   to disk, see PARAMETERS and climada folders
% MODIFICATION HISTORY:
% David N. Bresch, dbresch@ethz.ch, 20180322, initial
%-


% PARAMETERS
%
FAST_TEST=0; % default=0, if =1, set -R "rusage[mem=500]"
%
cluster_climada_root_dir='/cluster/home/dbresch/climada'; % to make sure the cluster finds climada
cluster_N_pool_workers=24; % number of parpool workers on pool (same as argument in bsub -n ..)
desktop_N_pool_workers= 2; % number of parpool workers on desktop

% aaa: some admin to start with (up to % eee standard code)
if ~exist('run_on_desktop','var'),run_on_desktop=[];end
if isempty(run_on_desktop),run_on_desktop=0;end % default=0, =1 to run job on mac
if run_on_desktop % for parpool on desktop
    N_pool_workers=desktop_N_pool_workers;
    pool_active=gcp('nocreate');
    if isempty(pool_active),pool=parpool(N_pool_workers);end
else
    cd(cluster_climada_root_dir)
    N_pool_workers=cluster_N_pool_workers;
    pool=parpool(N_pool_workers);
end
startup % climada_global exists afterwards
if exist('startupp','file'),startupp;end
fprintf('executing in %s\n',pwd) % just to check where the job is running from
climada_global.parfor=1; % for parpool, see e.g. climada_tc_hazard_set
t0=clock;
% eee: end of admin (do not edit until here)


parfor i=1:100
    
    ;
    
end % parfor


if ~run_on_desktop,delete(pool);exit;end % no need to delete the pool on mac, the cluster appreciates exit