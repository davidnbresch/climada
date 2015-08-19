function ok=climada_centroids_cleanup
% climada cleanup centroids
% MODULE:
%   core
% NAME:
%   climada_centroids_cleanup
% PURPOSE:
%   moves all centroid files into centroid folder
%   (in the past, they were stored in system folder)
%
%   Note: this code is currently invoked ONCE by climada_init_vars. There,
%   a small file ../system/climada_centroids_cleanup_done.txt is written to
%   indicate successful execution. We will remove this cleanup in winter
%   2015 latest.
% CALLING SEQUENCE:
%   ok=climada_centroids_cleanup
% EXAMPLE:
%   ok=climada_centroids_cleanup
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok: =1 if all done, see error messages else
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150819
%-

ok=0; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below

% check for centroids folder, create if not existing
climada_global.centroids_dir=[climada_global.data_dir filesep 'centroids'];
if ~exist(climada_global.centroids_dir,'dir')
    if ~mkdir(climada_global.data_dir,'centroids')
        fprintf('ERROR: unable to create folder %s\n',climada_global.centroids_dir);
        fprintf('WORK AROUND: please create %s manually\n',climada_global.centroids_dir);
        fprintf('quit MATLAB and start again\n');
        climada_global.centroids_dir=climada_global.system_dir;
        fprintf('--> ad interim: centroids in system folder (backward compatibility, too)\n');
        return
    end
end

% move all centroids files from ../data/system to ../data/centroids

system_files=dir([climada_global.system_dir filesep '*.*']);

issue_count=0;

for file_i=1:length(system_files)
    if ~system_files(file_i).isdir
        if ~isempty(strfind(system_files(file_i).name,'centroids'))
            src_file=[climada_global.system_dir filesep deblank(system_files(file_i).name)];
            dst_file=[climada_global.centroids_dir filesep deblank(system_files(file_i).name)];
            if movefile(src_file,dst_file)
                fprintf('moved %s from system to centroids\n',deblank(system_files(file_i).name))
            else
                fprintf('ERROR: %s NOT moved from system to centroids\n',deblank(system_files(file_i).name))
                issue_count=issue_count+1;
            end
        end
    end
end % file_i

if issue_count>0,fprintf('WARNING: %i (likely) centroids files not moved\n',issue_count);end

ok=1; % if we got here, must be ok ;-)

end % climada_centroids_cleanup
