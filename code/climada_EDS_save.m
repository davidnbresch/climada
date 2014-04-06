function climada_EDS_save(EDS,EDS_save_file,EDS_default)
% climada
% NAME:
%   climada_EDS_save
% PURPOSE:
%   save an EDS to a .mat file (just to avoid typing long paths and
%   filenames in the cmd window)
% CALLING SEQUENCE:
%   climada_EDS_save(EDS,EDS_save_file)
% EXAMPLE:
%   climada_EDS_save(EDS,EDS_save_file)
% INPUTS:
%   EDS: the event damage set (EDS), see e.g. climada_EDS_calc
%   EDS_save_file: the filename to save the EDS in
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   EDS saved to a .mat file
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091230
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),return;end
if ~exist('EDS_save_file','var'), EDS_save_file = []; end
if ~exist('EDS_default'  ,'var'), EDS_default   = []; end
if isempty(EDS_default)
    EDS_default = [climada_global.data_dir filesep 'results' filesep 'save event damage set as EDS_2010...2030...clim... .mat'];
else
    EDS_default = [climada_global.data_dir filesep 'results' filesep EDS_default];
end

% PARAMETERS

% prompt for EDS_save_file if not given
if isempty(EDS_save_file) % local GUI
    EDS_save_file        = [climada_global.data_dir filesep 'results' filesep 'EDS_XXXX.mat'];
    [filename, pathname] = uiputfile(EDS_save_file, 'Save EDS set as:',EDS_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        EDS_save_file = fullfile(pathname,filename);
    end
else
    [token remain]= strtok(EDS_save_file,'\');
    if isempty(remain)
        EDS_save_file = [climada_global.data_dir filesep 'results' filesep EDS_save_file];
    end        
end

if EDS_save_file
    fprintf('saving EDS as %s\n',EDS_save_file);
    save(EDS_save_file,'EDS')
end



return
