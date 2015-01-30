function entity_adjusted=climada_entity_value_GDP_adjust(entity_file_regexp,verbose_mode)
% scale up asset values
% MODULE:
%   country_risk
% NAME:
%   climada_entity_value_GDP_adjust
% PURPOSE:
%   Scale up asset values based on a country's estimated total asset value.
%   The total asset value is derived as follows:
%       - normalize the asset values
%       - multiply with the country's GDP
%       - multiply with a factor that depends on a country's income
%         group, i.e., its GDP per capita. This last factor is the KEY
%         ASSUMPTION here, see income_group_factors in PARAMETERS in code
%
%   If an entity has a field entity.assets.Value_today, the code calculates
%   the factor to entity.assets.Value and applies this factor after GDP
%   adjustment (this way, the code does not scale _future entities back to
%   today).
%
%   The entities' asset values are first normalized and then
%   multiplied by a factor that depends on a country's income group (low,
%   lower middle, upper middle, or high). The choice of this factor is
%   based on a comparison of climada entities to estimates for total asset
%   values in countries where such data are available. This comparison
%   showed that in general, adjusting the Climada asset values requires a
%   higher multiplication factor the wealthier a country is. Thus, as a
%   rule of thumb, the value of all assets in a country can be estimated by
%       Total_asset_value = GDP * (1+income_group_factor) 
%   where GDP is the country's gross domestic product, and
%   income_group_factor ranges from 2 for low income countries to 5 for
%   high income countries.             
%
%   Caution: as soon as the entity has a field entity.assets.admin0_ISO3 or
%   entity.assets.admin0_name, it is adjusted, unless there are non-empty
%   fields entity.assets.admin1_name or entity.assets.admin1_code, in which
%   case it skips adjustment. 
%
%   Prior calls: e.g. climada_nightlight_entity, country_risk_calc
%   Next calls: e.g. country_risk_calc
% CALLING SEQUENCE:
%   entity_adjusted=climada_entity_value_GDP_adjust(entity_file_regexp,verbose_mode)
% EXAMPLE:
%   entity_adjusted=climada_entity_value_GDP_adjust('../data/*.mat') % put .. in
%   entity_adjusted=climada_entity_value_GDP_adjust('BEL_Belgium_entity.mat')
% INPUT:
%   entity_file_regexp: the full filename of the entity to be scaled up
%       or a regexp expression, e.g. for all entities:
%       entity_file_regexp=[climada_global.data_dir filesep 'entities' filesep '*.mat']
% OPTIONAL INPUT PARAMETERS:
%   verbose_mode: =1, print step-by-step to stdout, =0, not (default)
%       If =2, do not care for Value_today, just adjust to GDP*income_group_factors
% OUTPUTS:
%   entity_adjusted: entity with adjusted asset values, also stored as .mat
%       file (only last netity if entity_file_regexp covers more than one)
% MODIFICATION HISTORY:
% Melanie Bieli, melanie.bieli@bluewin.ch, 20150121, initial
% David N. Bresch, david.bresch@gmail.com, 20150121, cleanup
% David N. Bresch, david.bresch@gmail.com, 20150122, verbose_mode
%-

% initialize output
entity_adjusted = [];

% set global variables and directories
global climada_global
if ~climada_init_vars,return;end % init/import global variables

% check input
if ~exist('entity_file_regexp','var'),entity_file_regexp='';end
if ~exist('verbose_mode','var'),      verbose_mode      =0;end


% PARAMETERS
%
% the table with global GDP etc info (per country) 
economic_data_file=[climada_global.data_dir filesep 'system' filesep 'economic_indicators_mastertable.xls'];
%
% missing data indicator (any missing in Excel has this entry)
misdat_value=-999;
%
% income group depending scale-up factors
% we take the income group number (1..4) from the
% economic_indicators_mastertable and use it as index to the
% income_group_factors:
income_group_factors = [2 3 4 5];


% template to prompt for filename if not given
if isempty(entity_file_regexp) % local GUI
    entity_file_regexp=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file_regexp, 'Select entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file_regexp=fullfile(pathname,filename);
    end
end

% find the desired entity / entities
D_entity_mat = dir(entity_file_regexp);

% Check if economic data file is available
if ~exist(economic_data_file,'file')
    fprintf('Error: economic_indicators_mastertable.xls is missing.\n')
    fprintf('Please download it from the <a href="https://github.com/davidnbresch/climada_module_country_risk/tree/master/data">Climada country risk repository on Github\n</a>');
    return;
end

% Read economic data
[fP,fN]=fileparts(economic_data_file);
economic_data_file_mat=[fP filesep fN '.mat'];
if ~climada_check_matfile(economic_data_file,economic_data_file_mat)
    econ_master_data = climada_xlsread('no',economic_data_file,[],1,misdat_value);
    fprintf('saving economic master data as %s\n',economic_data_file_mat);
    save(economic_data_file_mat,'econ_master_data');
else
    load(economic_data_file_mat);
end

% loop over entities and adjust asset values
fP = fileparts(entity_file_regexp);
for file_i = 1:length(D_entity_mat)
    
    entity_file_i = [fP, filesep D_entity_mat(file_i).name];
    
    try
        load(entity_file_i)
    catch
        fprintf('skipped (invalid entity): %s\n',D_entity_mat(file_i).name);
        entity.assets=[]; % dummy
    end
    
    if isfield(entity.assets,'admin0_ISO3')
        country_index = find(strcmp(econ_master_data.ISO3,char(entity.assets.admin0_ISO3)));
        if isempty(country_index),fprintf('skipped (no admin0_ISO3 match): %s\n',D_entity_mat(file_i).name);end
    elseif isfield(entity.assets,'admin0_name')
        country_index = find(strcmp(econ_master_data.Country,char(entity.assets.admin0_name)));
        if isempty(country_index),fprintf('skipped (no admin0_name match): %s\n',D_entity_mat(file_i).name);end
    else
        fprintf('skipped (no admin0_ISO3 nor admin0_name): %s\n',D_entity_mat(file_i).name);
        country_index=[];
    end
    
    if ~isempty(country_index)
        % avoid treating entities on admin1 level
        admin1_message=1; % to suppress 2nd message in case both admin1_name and admin1_code are non-empty
        if isfield(entity.assets,'admin1_name')
            if ~isempty(entity.assets.admin1_name)
                country_index=[];
                fprintf('skipped (admin1_name not empty): %s\n',D_entity_mat(file_i).name);
                admin1_message=0;
            end
        end
        if isfield(entity.assets,'admin1_code')
            if ~isempty(entity.assets.admin1_code)
                country_index=[];
                if admin1_message,fprintf('skipped (admin1_code not empty): %s\n',D_entity_mat(file_i).name);end
            end
        end
    end % ~isempty(country_index)
    
    if ~isempty(country_index)
        
        if ~isnan(econ_master_data.income_group(country_index))
            
            if isfield(entity.assets,'Value_today')
                % aha, it's a _future entity
                sum_Value_today =sum(entity.assets.Value_today);
                sum_Value_future=sum(entity.assets.Value);
                future_factor=sum_Value_future/sum_Value_today;
                
                if verbose_mode==2,future_factor=1.0;end

                if abs(future_factor-1)>0.051; % 5 percent tolerance
                    % if factor equals one, do it silenty
                    if isempty(strfind(D_entity_mat(file_i).name,'_future'))
                        fprintf('HINT: you might append _future to the entity filename (%s) - or it has high annual growth\n',...
                            D_entity_mat(file_i).name);
                    end
                    fprintf('%s: future values scaled up by %f*today (it has Value_today)\n',...
                        strrep(D_entity_mat(file_i).name,'.mat',''),future_factor);
                else
                    future_factor=1.0; % force the same, as we ignore up to 5% difference
                end
                
                if verbose_mode,fprintf('future_factor: %f (likely a future entity or substantial annual growth)\n',future_factor);end

            else
                future_factor=1;
            end
                        
            scale_up_factor = income_group_factors(econ_master_data.income_group(country_index));
            
            if verbose_mode,fprintf('sum(value) as on file: %g\n',sum(entity.assets.Value));end
            
            % normalize assets
            entity.assets.Value = entity.assets.Value/sum(entity.assets.Value);
            
            GDP_today=econ_master_data.GDP_today(country_index);
            if isnan(GDP_today)
                GDP_today=1.0;
                scale_up_factor=1.0; % in this case makes also no sense
                fprintf('Warning: GDP=NaN, not applied\n');
            else
                if verbose_mode,fprintf('GDP: %g, scale_up_factor: %f\n',GDP_today,scale_up_factor);end
            end
            
            % multiply with GDP
            entity.assets.Value = entity.assets.Value*GDP_today;
            
            % multiply with scale-up factor
            entity.assets.Value = entity.assets.Value*scale_up_factor;
            
            % special treatment for future entities
            if isfield(entity.assets,'Value_today'),entity.assets.Value_today=entity.assets.Value;end
            
            % and finally apply future factor (in case it's a _future entity)
            entity.assets.Value = entity.assets.Value*future_factor;
            
            if verbose_mode,fprintf('sum(value) after scaling: %g\n',sum(entity.assets.Value));end

            % for consistency, update Cover
            if isfield(entity.assets,'Cover')
                entity.assets.Cover=entity.assets.Cover*GDP_today*scale_up_factor*future_factor;
                Cover_pct=entity.assets.Cover./entity.assets.Value;
                if max(Cover_pct)<0.01
                    fprintf('Warning: max Cover less than 1%% of Value -> consider to adjust Cover\n');
                end
            end

            % save entity
            entity_adjusted = entity;
            fprintf('saved %s in %s (by %s)\n',D_entity_mat(file_i).name,fP,mfilename)
            save(entity_file_i,'entity')
            
        else
            fprintf('skipped (no income group info): %s\n',D_entity_mat(file_i).name);
        end
        
    end % ~isempty(country_index)
    
end