function [is_selected,peril_criterum,unit_criterium,category_criterium] = climada_assets_select(entity,peril_criterum,unit_criterium,category_criterium,silent_mode)
%  Create a selection array to select a subset of asset locations
% MODULE:
%   climada core
% NAME:
%   climada_assets_select
% PURPOSE:
%   Create a selection array to select a subset of asset locations, that
%   match a peril, a unit and a category (e.g. FL, USD, Category 7). Selected assets must fullfil ALL
%   criterias. However empty criterium will select all assets.
% CALLING SEQUENCE:
%   is_selected = climada_assets_select(entity,peril_criterum,unit_criterium, category_criterium)
% EXAMPLE:
%   is_selected = climada_assets_select(entity,'FL','USD',6)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   entity:  climada entity structure, with fields entity.assets.Value_unit
%            and entity.damagefunctions.peril_ID
%   peril_criterum: a string, e.g. 'FL' or 'TC'
%   unit_criterium: a string, e.g. 'USD' or 'people'
%   category_criterium: a string or a number, e.g. 7
%   silent_mode: set to 1 if no fprintf output
% OUTPUTS:
%   is_selected   : a logical array that points to the selected asset locations
%   peril_criterum: a string or a cell, e.g. 'FL' or 'TC'
%   unit_criterium: a string or a cell, e.g. 'USD' or 'people'
%   category_criterium: a string, cell or a number, e.g. 7

% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150730, init
% Lea Mueller, muellele@gmail.com, 20150731, add outputs for criteria, e.g. if select only
%                'TC', unit_criterium will return all corresponding units, e.g. USD and people
% Lea Mueller, muellele@gmail.com, 20150831, rename to climada_assets_select
% Lea Mueller, muellele@gmail.com, 20150910, reshape selection vectors so that dimensions match
% Lea Mueller, muellele@gmail.com, 20150910, enhance to cope with Category names (cell) instead of numbers
% Lea Mueller, muellele@gmail.com, 20150924, add silent_mode option
% Lea Mueller, muellele@gmail.com, 20151106, move to core
% Lea Mueller, muellele@gmail.com, 20151120, make sure that category_criterium is a cell and not a char
% Lea Mueller, muellele@gmail.com, 20151202, replace strcmp with ismember for multiple category_criterium as a cell
% Lea Mueller, muellele@gmail.com, 20151203, set print_cat to 0 if category-criterium is a cell (and not numeric)
% -


% poor man's version to check arguments
if ~exist('entity'            ,'var'), entity             = []; end
if ~exist('peril_criterum'    ,'var'), peril_criterum     = []; end
if ~exist('unit_criterium'    ,'var'), unit_criterium     = []; end
if ~exist('category_criterium','var'), category_criterium = []; end
if ~exist('silent_mode','var'), silent_mode = ''; end

% prompt for entity if not given
if isempty(entity            ), entity             = climada_entity_load; end
if isempty(peril_criterum    ), peril_criterum     = ''; end    
if isempty(unit_criterium    ), unit_criterium     = ''; end 
if isempty(category_criterium), category_criterium = ''; end 
if isempty(silent_mode), silent_mode = 0; end 

entity.assets.lon(isnan(entity.assets.lon)) = 0;
is_selected = logical(entity.assets.lon); %init
is_unit     = logical(entity.assets.lon);
is_category = logical(entity.assets.lon);


% find peril in entity.damagefunctions.peril_ID
if ~isempty(peril_criterum)
    if isfield(entity, 'damagefunctions')
        if isfield(entity.damagefunctions, 'peril_ID')
            is_peril    = strcmp(entity.damagefunctions.peril_ID,peril_criterum);
            selected_damagefunctionID = unique(entity.damagefunctions.DamageFunID(is_peril));
            is_selected = ismember(entity.assets.DamageFunID,selected_damagefunctionID);
        end
    end
end

% find unit in entity.assets.Value_unit
if ~isempty(unit_criterium)
    if isfield(entity.assets, 'Value_unit')
        is_unit = strcmp(entity.assets.Value_unit, unit_criterium);
    end
end

% find category in entity.assets.Category
if ~isempty(category_criterium)
    % make sure that category_criterium is a cell and not a char
    if ischar(category_criterium), category_criterium = {category_criterium}; end
    if isfield(entity.assets, 'Category')
        if iscell(category_criterium)
            if numel(category_criterium)>1
                is_category  = ismember(entity.assets.Category, category_criterium);
            else
                is_category  = strcmp(entity.assets.Category, category_criterium);
            end
        elseif isnumeric(category_criterium)
            is_category  = ismember(entity.assets.Category, category_criterium);
        end
    end
end


% combine the three logical arrays, selected assets must fullfil ALL
% criterias
% reshape selection vectors, so that dimensions match
n = numel(entity.assets.lon);
is_selected = reshape(is_selected,n,1);
is_unit = reshape(is_unit,n,1);
is_category = reshape(is_category,n,1);
is_selected = logical(is_selected .* is_unit .* is_category);


% set empty peril criterium if not given, that goes together with selected
% assets
if isempty(peril_criterum)
    if isfield(entity, 'damagefunctions')
        if isfield(entity.damagefunctions, 'peril_ID')
            DamageFunID_selected = unique(entity.assets.DamageFunID(is_selected));
            has_DamageFunID      = ismember(entity.damagefunctions.DamageFunID,DamageFunID_selected);
            peril_criterum       = unique(entity.damagefunctions.peril_ID(has_DamageFunID));
        end
    end    
end

% set empty unit or category criterium if not given, that goes together
% with the selected unit/category criterium
print_cat = 1;
if isfield(entity.assets, 'Category') && isfield(entity.assets, 'Value_unit')
    unit_criterium = unique(entity.assets.Value_unit(is_selected));
    category_criterium = unique(entity.assets.Category(is_selected));
elseif isfield(entity.assets, 'Category') && ~isfield(entity.assets, 'Value_unit')
    category_criterium = unique(entity.assets.Category(is_selected));
    print_cat = 0;
end


% create strings for fprintf
if iscell(peril_criterum)
    peril_criterum_str = sprintf('%s, ',peril_criterum{:});
    if numel(peril_criterum)>1
        peril_criterum_str(end-1:end) = [];
    end
else
    peril_criterum_str = peril_criterum;
end

if iscell(unit_criterium)
    unit_criterium_str = sprintf('%s, ',unit_criterium{:});
    if numel(unit_criterium)>1
        unit_criterium_str(end-1:end) = [];
    end
else
    unit_criterium_str = unit_criterium;
end

% transform num to string
if isnumeric(category_criterium)
    category_criterium_str = sprintf('%d, ',category_criterium);
    category_criterium_str(end-1:end) = [];
else
    %category_criterium_str = category_criterium;
    %category_criterium_str = char(category_criterium);
    category_criterium_str = category_criterium{1};
    %print_cat = 0;
end
        
if ~silent_mode
    if print_cat
        fprintf('%d locations selected (%s, %s, %s)\n',sum(is_selected),peril_criterum_str, unit_criterium_str, category_criterium_str)
    else
        fprintf('%d locations selected (%s, %s)\n',sum(is_selected),peril_criterum_str, unit_criterium_str)
    end
end


