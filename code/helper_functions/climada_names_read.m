function names = climada_names_read(names_filename)
% climada names read import
% NAME:
%   climada_names_read
% PURPOSE:
%   read names sheet with .item, .ID, .name
%   usually called from climada_entity_read, see climada_entity_read for
%   more information. Not a mandatory tab, hence very tolerant (i.e. it
%   just returns empty in case of troubles).
%
%   The names tab can alos contain definitions for climada_global
%   parameters, see ADVANCED use in code (and manual).
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls and .ods files
%   For .xls, the sheet names are dynamically checked, for .ods, the sheet
%   names are hard-wired (see code), means for .ods, the sheet 'names'
%   needs to exist (if not, no problem, it returns with []).
% CALLING SEQUENCE:
%   names = climada_names_read(names_filename)
% EXAMPLE:
%   names = climada_names_read;
% INPUTS:
%   names_filename: the filename of the Excel (or .ods) file with the
%       names information
%       If no path provided, default path ../data/entities is used
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%    names: a structure, with fields
%       Item: the name of the item to assign a speaking name, default
%           ={'Category_ID' 'Region_ID'}'
%       ID: the ID, default=[1 1]'
%       name: the speaking name, default={'Category 1' 'Region 1'}'
% MODIFICATION HISTORY:
% David Bresch, david.bresch@gmail.com, 20160919, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% simple default setting
names.Item={'Category_ID' 'Region_ID'}';
names.ID=[1 1]';
names.name={'Category 1' 'Region 1'}';

% poor man's version to check arguments
if ~exist('names_filename','var'),names_filename = [];end

% PARAMETERS
%

% prompt for names_filename if not given
if isempty(names_filename) % local GUI
    names_filename      = [climada_global.entities_dir filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(names_filename, 'Select entity file (with tab names):');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        names_filename = fullfile(pathname,filename);
    end
end

[fP,fN,fE] = fileparts(names_filename);
if isempty(fE),fE=climada_global.spreadsheet_ext;end
if isempty(fP) % complete path, if missing
    names_filename=[climada_global.entities_dir filesep fN fE];
end

if strcmp(fE,'.ods')
    % hard-wired sheet names for files of type .ods
    sheet_names = {'names'};
else
    try
        % inquire sheet names from .xls
        [~,sheet_names] = xlsfinfo(names_filename);
    catch
        sheet_names = {'names'};
    end
end

try
    % read names
    % --------------------
    for sheet_i = 1:length(sheet_names) % loop over tab (sheet) names
        if strcmp(sheet_names{sheet_i},'names')
            names = climada_spreadsheet_read('no',names_filename,'names',1);
        end
    end % sheet_i
    if isempty(names),return;end
    
catch ME
    fprintf('NOTE (no problem): no names data read: %s\n',ME.message)
end

% delete NaNs if there are invalid entries
names = climada_entity_check(names,'Item');

% for debugging:
% names.Item
% names.ID
% names.name

% check whether we do have a value for reference_year
pos=find(strcmp(names.Item,'reference_year')>0);
if ~isempty(pos),names.reference_year=names.name{pos};end

% ADVANCED USE ONLY (we print these parameter definitions to stdout):
% an elegant way to define some climada_global parameters via entity
% (not part of the standard template, but documented in the manual, use
% entity_template_ADVANCED.xlsx to test it)
global_fieldnames=fieldnames(climada_global);
% loop over all Items and assign climada_global if Item name matches a
% field in climada_global
for item_i=1:length(names.Item)
    for check_i=1:length(global_fieldnames)
        if strcmp(names.Item{item_i},global_fieldnames{check_i})
            %global_fieldnames{check_i} % debugging
            climada_global.(global_fieldnames{check_i})=names.name{item_i};
            if ischar(climada_global.(global_fieldnames{check_i}))
                fprintf('Note: climada_global.%s = %s\n',global_fieldnames{check_i},climada_global.(global_fieldnames{check_i}));
            else
                fprintf('Note: climada_global.%s = %i\n',global_fieldnames{check_i},climada_global.(global_fieldnames{check_i}));
            end
        end
    end % check_i
end % item_i

end % climada_names_read