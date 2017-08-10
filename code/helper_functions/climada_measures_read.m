function [measures, measures_impact] = climada_measures_read(measures_filename,entity_damagefunctions_filename)
% climada measures read import
% NAME:
%   climada_measures_read
% PURPOSE:
%   read the Excel file with the list of measures, usually called from
%   climada_entity_read. The field "cost" is mandatory otherwise measures are not read.
%   See climada_entity_read for a comprehensive description of output fields.
%
%   This code allows single Excel files with measures
%   (and, if a tab damagefunctions exists, damage functions, and if a tab 
%   assets exists, regional_scope of measures) to be read
%   The user will then have to 'switch' measures in an already read and
%   encoded entity with the measures read here.
% CALLING SEQUENCE:
%   measures = climada_measures_read(measures_filename)
% EXAMPLE:
%   measures = climada_measures_read;
% INPUTS:
%   measures_filename: the filename of the Excel file with the measures
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   entity_damagefunctions_filename: the filename (if possible with path) of damagefunctions
%       already in entity, if the same as the filename for measures, do NOT
%       read damagefunctions again. If not passed, measures do read
%       damagefunctions tab (if it exists) of the file.
% OUTPUTS:
%   measures: a structure, with the measures, including .regional_scope if
%   assets tab found wich specifies the regional_scope of a measure
% MODIFICATION HISTORY:
% David N. Bresch,  david.bresch@gmail.com, 20091228
% David N. Bresch,  david.bresch@gmail.com, 20130316, vulnerability->damagefunctions...
% Jacob Anz, j.anz@gmx.net, 20150819, use try statement to check for damagefunctions in excel sheet
% Lea Mueller, muellele@gmail.com, 20150907, add measures sanity check
% Lea Mueller, muellele@gmail.com, 20150915, add read the "assets" tab which defines the regional scope of one or more measures
% Lea Mueller, muellele@gmail.com, 20150916, omit nans in regional_scope 
% Lea Mueller, muellele@gmail.com, 20151016, delete nans in measures.name if there are invalid entries
% Lea Mueller, muellele@gmail.com, 20151119, use climada_assets_read, use spreadsheet_read instead of xls_read
% David Bresch, david.bresch@gmail.com, 20151119, bugfix for Octave to try/catch xlsinfo
% Jacob Anz, j.anz@gmx.net, 20151204, remove measures.damagefunctions if empty
% Lea Mueller, muellele@gmail.com, 20160523, complete extension, if missing
% Lea Mueller, muellele@gmail.com, 20160523, add measures_impact, invoke climada_measures_impact_read
% David Bresch, david.bresch@gmail.com, 20160917, re-calling encode disabled
% David Bresch, david.bresch@gmail.com, 20170810, entity_damagefunctions_filename added
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

measures = []; %init
assets = [];
measures_impact = [];

% poor man's version to check arguments
if ~exist('measures_filename','var'),measures_filename=[];end
if ~exist('entity_damagefunctions_filename','var'),entity_damagefunctions_filename='';end

% PARAMETERS
%

% prompt for measures_filename if not given
if isempty(measures_filename) % local GUI
    measures_filename=[climada_global.data_dir filesep 'entities' filesep '*.xls'];
    [filename, pathname] = uigetfile(measures_filename, 'Select measures:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        measures_filename = fullfile(pathname,filename);
    end
end

% figure out the file type
[fP,fN,fE] = fileparts(measures_filename);

if isempty(fP) % complete path, if missing
    measures_filename = [climada_global.data_dir filesep 'entities' filesep fN fE];
    [fP,fN,fE] = fileparts(measures_filename);
    if isempty(fE) % complete extension, if missing
        fE = '.xlsx'; 
        if ~exist([measures_filename fE],'file'), fE = '.xls'; end
        measures_filename = [measures_filename fE];
    end
end

if strcmp(fE,'.ods')
    % hard-wired sheet names for files of type .ods
    sheet_names = {'measures'};
else
    try
        % inquire sheet names from .xls
        [~,sheet_names] = xlsfinfo(measures_filename);
    catch
        sheet_names = {'measures'};
    end
end

try
    % read measures
    % --------------------
    for sheet_i = 1:length(sheet_names) % loop over tab (sheet) names
        if strcmp(sheet_names{sheet_i},'measures')
            measures = climada_spreadsheet_read('no',measures_filename,'measures',1);
            % measures = climada_xlsread('no',measures_filename,'measures',1);
        end
    end % sheet_i
    if isempty(measures)
        fprintf('No sheet "measures" found, just reading the first sheet.\n')
        measures = climada_spreadsheet_read('no',measures_filename,1);
    end 
    
catch ME
    fprintf('WARN: no measures data read, %s\n',ME.message)
end

% .cost is mandatory
if ~isfield(measures,'cost')
    fprintf('Error: no cost column in measures tab, aborted\n')
    measures= [];
    if strcmp(fE,'.ods') && climada_global.octave_mode
        fprintf('> make sure there are no cell comments in the .ods file, as they trouble odsread\n');
    end
    return
end
    
if ~strcmp(entity_damagefunctions_filename,measures.filename)
    measures.damagefunctions = climada_damagefunctions_read(measures_filename);
    fprintf('Special damagefunctions for measures found (measures.damagefunctions filled in)\n')
    if isempty(measures.damagefunctions)
        measures = rmfield(measures, 'damagefunctions');
    else
        measures.damagefunctions = climada_entity_check(measures.damagefunctions,'DamageFunID'); % delete NaNs if there are
    end
end

% rename vuln_map, since otherwise climada_measures_encode does not treat it
if isfield(measures,'vuln_map'),measures.damagefunctions_map=measures.vuln_map;measures=rmfield(measures,'vuln_map');end

% check for OLD naming convention, vuln_MDD_impact_a -> MDD_impact_a
if isfield(measures,'vuln_MDD_impact_a'),measures.MDD_impact_a=measures.vuln_MDD_impact_a;measures=rmfield(measures,'vuln_MDD_impact_a');end
if isfield(measures,'vuln_MDD_impact_b'),measures.MDD_impact_b=measures.vuln_MDD_impact_b;measures=rmfield(measures,'vuln_MDD_impact_b');end
if isfield(measures,'vuln_PAA_impact_a'),measures.PAA_impact_a=measures.vuln_PAA_impact_a;measures=rmfield(measures,'vuln_PAA_impact_a');end
if isfield(measures,'vuln_PAA_impact_b'),measures.PAA_impact_b=measures.vuln_PAA_impact_b;measures=rmfield(measures,'vuln_PAA_impact_b');end     

% delete NaNs if there are invalid entries
measures = climada_entity_check(measures,'name',0,'measures');

% make sure we have all fields and they are 'correct'
measures = climada_measures_complete(measures);

% encode measures
measures = climada_measures_encode(measures);

% % sanity check for measures
% measures = climada_measures_check(measures); % 20160917, return value added
% 'checked'

% create measures_impact struct directly if "benefit" per measure is given. 
% shortcut instead of calculating measures_impact with climada_measures_impact
measures_impact = climada_measures_impact_read(measures);

end % climada_measures_read