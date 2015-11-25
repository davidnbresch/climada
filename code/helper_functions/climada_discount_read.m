function discount = climada_discount_read(discount_filename)
% climada discount read import
% NAME:
%   climada_discount_read
% PURPOSE:
%   read discount sheet with .yield_ID, .year, .discount_rate. 
%   usually called from climada_entity_read, see climada_entity_read for
%   more information. The field "discount_rate" is
%   mandatory otherwise discount is not read.
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls and .ods files
%   For .xls, the sheet names are dynamically checked, for .ods, the sheet
%   names are hard-wired (see code), means for .ods, the sheet 'discount' 
%   needs to exist.
% CALLING SEQUENCE:
%   [discount,discount_save_file] = climada_discount_read(discount_filename)
% EXAMPLE:
%   discount = climada_discount_read;
% INPUTS:
%   discount_filename: the filename of the Excel (or .ods) file with the
%   discount information
%       If no path provided, default path ../data/entities is used
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%    discount: a structure, with
%           .yield_ID: yield ID
%           .year: year
%           .discount_rate: discount_rate per year
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151117, init from climada_entity_read to read only discount
% David Bresch, david.bresch@gmail.com, 20151119, bugfix for Octave to try/catch xlsinfo
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

discount = [];

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('discount_filename','var'),discount_filename = [];end

% PARAMETERS
%

% prompt for discount_filename if not given
if isempty(discount_filename) % local GUI
    discount_filename      = [climada_global.data_dir filesep 'entities' filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(discount_filename, 'Select discount file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        discount_filename = fullfile(pathname,filename);
    end
end

% figure out the file type
[fP,fN,fE] = fileparts(discount_filename);

if isempty(fP) % complete path, if missing
    discount_filename=[climada_global.data_dir filesep 'entities' filesep fN fE];
    [fP,fN,fE] = fileparts(discount_filename);
end

if strcmp(fE,'.ods')
    % hard-wired sheet names for files of type .ods
    sheet_names = {'discount'};
else
    try
        % inquire sheet names from .xls
        [~,sheet_names] = xlsfinfo(discount_filename);
    catch
        sheet_names = {'discount'};
    end
end

try
    % read discount
    % --------------------
    for sheet_i = 1:length(sheet_names) % loop over tab (sheet) names
        if strcmp(sheet_names{sheet_i},'discount')
            discount = climada_spreadsheet_read('no',discount_filename,'discount',1);
        end
    end % sheet_i
    if isempty(discount)
        fprintf('No sheet "discount" found, just reading the first sheet.\n')
        discount = climada_spreadsheet_read('no',discount_filename,1);
    end
    
catch ME
    fprintf('WARN: no discount data read, %s\n',ME.message)
end

% .discount_rate is mandatory
if ~isfield(discount,'discount_rate')
    fprintf('Error: no discount_rate column in discount tab, aborted\n')
    discount = [];
    if strcmp(fE,'.ods') && climada_global.octave_mode
        fprintf('> make sure there are no cell comments in the .ods file, as they trouble odsread\n');
    end
    return
end
    
% delete nans if there are invalid entries
discount = climada_entity_check(discount,'year');

    
return


