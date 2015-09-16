function measures = climada_measures_read(measures_filename)
% climada measures read import
% NAME:
%   climada_measures_read
% PURPOSE:
%   read the Excel file with the list of measures
%
%   usually, measures are read together with assets and damagefunctions in
%   climada_entity_read. This code allows single Excel files with measures
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
%
global climada_global
if ~climada_init_vars,return;end % init/import global variables

measures = []; %init

% poor man's version to check arguments
if ~exist('measures_filename','var'),measures_filename=[];end

% PARAMETERS
%

% prompt for measures_filename if not given
if isempty(measures_filename) % local GUI
    measures_filename=[climada_global.data_dir filesep 'measures' filesep '*.xls'];
    [filename, pathname] = uigetfile(measures_filename, 'Select measures:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        measures_filename=fullfile(pathname,filename);
    end
end

measures = climada_xlsread('no',measures_filename,'measures',1);
try 
    measures.damagefunctions = climada_xlsread('no',measures_filename,'damagefunctions',1);
    display('damagefunction sheet found')
catch
    display('no damagefunction sheet found')
end

try 
    % see if assets tab is provided, which defines the regional scope of
    % one or more measures
    assets = climada_xlsread('no',measures_filename,'assets',1);
    display('asset sheet found');
catch
    assets = [];
    display('no asset sheet found');
end


if ~isempty(assets)
    
    % number of measures
    n_measures = numel(measures.name);
    
    % initialize logical index to define the regional scope of measures
    measures.regional_scope = ones(length(assets.Value),n_measures);
    
    % get all fieldnames in the structure "assets"
    asset_columns = fieldnames(assets);
    
    % get measures names, without brackets and replace empty spaces with underline
    measures_names = strrep(strrep(strrep(measures.name,' ','_'),'(',''),')','');
    
    % find those names in the asset_columns
    has_scope = ismember(measures_names,asset_columns);
    
    if any(has_scope)
        has_scope = find(has_scope);
        
        % loop over measures that have a regional scope and save in matrix
        % measures.regional_scope
        for scope_i = 1:numel(has_scope)
            scope = getfield(assets, measures_names{has_scope(scope_i)});     
            scope(isnan(scope)) = 0;
            measures.regional_scope(:,has_scope(scope_i)) = scope;
        end 
    end %has_scope
    
    % create logical 
    measures.regional_scope = logical(measures.regional_scope);
end

% encode measures
measures = climada_measures_encode(measures);

% sanity check for measures
climada_measures_check(measures)

% save measures as .mat file for fast access
% but we re-read form .xls each time this code is called
[fP,fN] = fileparts(measures_filename);
save([fP filesep fN],'measures')

return
