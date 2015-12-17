function assets = climada_assets_category_ID(assets)
% climada_assets_category_ID
% MODULE:
%   core/helper_functions
% NAME:
%   climada_assets_category_ID
% PURPOSE:
%   Create category IDs (assets.Category_name, assets.Category_ID) and
%   overwrite assets.Category with IDs. This is saves memory space.
% CALLING SEQUENCE:
%   assets = climada_assets_category_ID(assets)
% EXAMPLE:
%   assets = climada_assets_category_ID
%   assets = climada_assets_category_ID('entity_template.xlsx')
%   assets = climada_assets_category_ID(assets)
% INPUTS:
%   assets: a climada assets structure (included in entity), contains
%   fields .lon, .lat, .Value, .Category. If .Category is not given, this
%   function does nothing. 
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151207, init
% Lea Mueller, muellele@gmail.com, 20151208, add Category_name and Category_ID also if field Category does not exist (.Category_name = 'All categories'; .Category_ID = ''; .Category = '';)
% Lea Mueller, muellele@gmail.com, 20151217, make sure assets.Category_name is a cell
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('assets','var'), assets = ''; end

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below

% assets check: do nothing if we already have an assets structure, read assets if assets are empty
assets = climada_assets_read(assets);
if isempty(assets), return, end % no spreadsheet assets selected
% if ~isfield(assets,'Category'), return, end

% category_IDs are already assigned
if isfield(assets,'Category_name') && isfield(assets,'Category_ID'), return, end 

if ~isfield(assets,'Category')
    assets.Category = '';
    assets.Category_name = 'All categories';
    assets.Category_ID = '';
    return
end
        
     
% get unique category values
[Category_list,~,is_located] = unique(assets.Category);

% make sure Category_list is a cell
if isnumeric(Category_list)
    Category_list_num = Category_list; clear Category_list
    for i = 1:numel(Category_list_num)
        Category_list{i,1} = sprintf('Cat. %d',Category_list_num(i));
    end
    %Category_list = num2cell(Category_list); 
end

% create table for category names
n_Category = numel(Category_list);
assets.Category_name(1:n_Category,1) = Category_list;
assets.Category_ID(1:n_Category,1) = 1:n_Category;

% convert to uint8 (maximum 255 categories)
Category = uint8(zeros(size(assets.lon)));
for c_i = 1:n_Category
    Category(is_located == c_i) = c_i;
end

% overwrite category names with category int32 ID
assets.Category = Category;

return
