function update_flag=climada_data_check(TEST_mode)
% climada git data check
% MODULE:
%   core
% NAME:
%   climada_data_check
% PURPOSE:
%   check content of climada_data folder for consistency with core
%   climada's climada/data folder content.
%
%   Files which are older in the local data folder should be replaced by the
%   newer ones from the core data folder. Currently, the code ONLY takes
%   action if TEST_mode=-1 (to avoid automatic overwrite).
%
%   previous call: climada_git_clone and/or climada_git_pull 
%   (both invoke climada_data_check)
%   next call: e.g. climada_demo_step_by_step
% CALLING SEQUENCE:
%   climada_data_check
% EXAMPLE:
%   climada_data_check(1)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   TEST_mode: =1 show also files that are newer on local (user to decide what to do)
%       =2 show also files that are identical (no action, just to
%       show complete information)
%       =0 (default), run as stated above, list only files that need
%       attention
%       =-1: do replace files which are older on local with newer ones from
%       core data folder. BE CAREFUL, this options overwrites files in your
%       local data folder
% OUTPUTS:
%   update_flag: =0 if no need to update
%       =1 if at least one file on local is older than in core
%   all messaging to stdout
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20170106, initial
%-

update_flag=0;

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('TEST_mode','var'),TEST_mode=[];end

% PARAMETERS
%
if isempty(TEST_mode),TEST_mode=0;end % default=0

% check for climada_data folder
% -----------------------------

core_data_dir=[climada_global.root_dir filesep 'data'];

if ~strcmpi(deblank(climada_global.data_dir),deblank(core_data_dir))
    
    fprintf('\nsource:      %s \n',core_data_dir);
    fprintf('destination: %s \n\n',climada_global.data_dir);
    
    core_data_content=dir(core_data_dir);
    
    for folder_i=1:length(core_data_content)
        folder_name=core_data_content(folder_i).name;
        if core_data_content(folder_i).isdir && length(folder_name)>2 % we have a data folder, check content
            core_data_subcontent=dir([core_data_dir filesep folder_name]);
            for file_i=1:length(core_data_subcontent)
                file_name=core_data_subcontent(file_i).name;
                if ~core_data_subcontent(file_i).isdir && length(file_name)>2 % we have a data file
                    
                    % be sure we compare the correct file
                    file_src=[core_data_dir           filesep folder_name filesep file_name];
                    file_dst=[climada_global.data_dir filesep folder_name filesep file_name];
                    
                    % locate same file in user's data
                    if exist(file_dst,'file') % destination exists, compare date
                        
                        src_dir=dir(file_src);
                        dst_dir=dir(file_dst);
                        src_datenum=src_dir(1).datenum;
                        dst_datenum=dst_dir(1).datenum;
                        d_datenum=dst_datenum-src_datenum;
                        
                        if d_datenum > eps
                            if TEST_mode==1,fprintf('    %s%s%s - destination file newer\n',folder_name,filesep,file_name);end
                        elseif d_datenum < -eps
                            fprintf('--> %s%s%s --> destination file older, consider to replace\n',folder_name,filesep,file_name);
                            update_flag=1;
                            if TEST_mode==-1 % TAKE ACTION
                                fprintf('COPY %s -> %s\n',file_src,file_dst);
                                [SUCCESS,MESSAGE] = copyfile(file_src,file_dst);
                                if ~SUCCESS
                                    fprintf('\nERROR: %s\n',MESSAGE)
                                    fprintf('aborted\n')
                                    return
                                end
                            end % TAKE ACTION
                        else
                            if TEST_mode==2,fprintf('    (%s%s%s - destination file identical)\n',folder_name,filesep,file_name);end
                        end
                        
                    else % destination does not exist
                        fprintf('--> %s%s%s --> not in destination, consider to copy\n',folder_name,filesep,file_name);
                        update_flag=1;
                        if TEST_mode==-1 % TAKE ACTION
                            fprintf('COPY %s -> %s\n',file_src,file_dst);
                            [SUCCESS,MESSAGE] = copyfile(file_src,file_dst);
                            if ~SUCCESS
                                fprintf('\nERROR: %s\n',MESSAGE)
                                fprintf('aborted\n')
                                return
                            end
                        end % TAKE ACTION
                    end
                    
                end % data file
            end % file_i
        end % isdir
    end % folder_i
else
    fprintf('using default data folder (%s), no check required, all fine\n',climada_global.data_dir);
end

end % climada_data_check