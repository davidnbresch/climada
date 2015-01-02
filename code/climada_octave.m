function ok=climada_octave
% climada octave
% MODULE:
%   core
% NAME:
%   climada_octave
% PURPOSE:
%   Sourced at the end of climada_init_vars if the system we're running on
%   is Octave instead of MATLAB
%
%   This way, we can handle any specifics at startup
%
%   Currently, Octave specifc are:
%   - admin0.mat contains non-ASCII characters, remedied for Octave
%   - climada_global.map_border_file is set to
%     climada_global.coastline_file, since Octave takes about 6 sec to plot
%     borders based on admin0.mat, compared to only 0.1 sec if based on
%     coastline.mat. WARNING: it could be somebody uses map_border_file in
%     a specific sense, in which case this shortcut might trigger problems.
%
% CALLING SEQUENCE:
%   ok=climada_octave
% EXAMPLE:
%   ok=climada_octave
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok: =1, if running on Octave
%       =0, if MATLAB (the default)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141231, initial
%-

ok=0; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%

if ~isempty(which('OCTAVE_VERSION'))
    
    % AHA, we're running on Octave
    
    map_border_file_oct=climada_global.map_border_file;
    [fP,fN,fE]=fileparts(climada_global.map_border_file);
    if isempty(strfind(fN,'_oct')),map_border_file_oct=[fP filesep fN '_oct' fE];end
    if ~exist(map_border_file_oct,'file')
        % save an Octave-compliant version of the admin0 file (with non-ASCII
        % portions of UTF characters replaced by '?')
        load(climada_global.map_border_file,'shapes'); % load shapes
        fprintf('Octave: saving clean Octave version as %s\n',map_border_file_oct)
        save(map_border_file_oct,'shapes')
    end
    climada_global.map_border_file=map_border_file_oct;
    
    % plus, for speedup, set the coastline file as map border file
    %fprintf('Octave: map_boder_file set to coastline_file for speedup\n');
    %climada_global.map_border_file=climada_global.coastline_file;
    
    % Octave's io package works properly with .xlsx (on Mac), therefore, we
    % set the default spreadsheet extension accordingly:
    climada_global.spreadsheet_ext='.xlsx';
    % One better converts other Excel files (.xls) into .xlsx then to try
    % fix such Excel-related backward compatibility issues

    ok=1; % yes, we're running on Octave
    
end

return
