function ok=climada_check_matfile(source_filename,mat_filename)
% climada
% NAME:
%   climada_check_matfile
% PURPOSE:
%   check for existence of the .mat file (binary) version of the source
%   file (source_filename, usually a .xls) and check for the .mat file
%   being more recent than the source
%
%   The code does NOT re-read the source_file, as this is context specific
%   and the .mat file might contain more than the raw content of the source
%   file
% CALLING SEQUENCE:
%   ok=climada_check_matfile(source_filename,mat_filename)
% EXAMPLE:
%   ok=climada_check_matfile
% INPUTS:
%   source_filename: the source filename, most likely a .xls file that gets
%       imported into climada and saved as .mat (binary)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   mat_filename: check for the given filename of the binary file
%       if empty, use the source_filename with its extension replaced by
%       .mat to check against
% OUTPUTS:
%   ok: =1 if .mat file exists and is more recent than source file
%       =0 if .mat file does not exist or if source file is more recent
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141104
% David N. Bresch, david.bresch@gmail.com, 20141208, datenum_mat-datenum_source>=0
% Lea Mueller, muellele@gmail.com, 20150305, datenum taken automatically
% from file (for source and mat_file), due to problems with German version
%-

ok=0; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('source_filename','var'),source_filename=[];end
if ~exist('mat_filename','var'),mat_filename=[];end

% PARAMETERS
%

% prompt for source_filename if not given
if isempty(source_filename) % local GUI
    source_filename=[climada_global.data_dir filesep '*.xls'];
    [filename, pathname] = uigetfile(source_filename, 'Check:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        source_filename=fullfile(pathname,filename);
    end
end


if exist(source_filename,'file')
    
    D_source = dir(char(source_filename));
    %datenum_source=datenum(D_source.date); % date of source
    % lea, 20150305, take datenum directly, the above line does not 
    % work with date spelled out in german
    datenum_source = D_source.datenum;
    
    [fP,fN]=fileparts(char(source_filename));
    
    if isempty(mat_filename),mat_filename=[fP filesep fN '.mat'];end
    
    if exist(mat_filename,'file')
        
        D_mat = dir(mat_filename);
        %datenum_mat=datenum(D_mat.date); % date of .mat
        % lea, 20150305, see above
        datenum_mat = D_mat.datenum;
        
        if datenum_mat-datenum_source >=0
            ok=1; % only if .mat exists and is newer
        end
    end
end

return
