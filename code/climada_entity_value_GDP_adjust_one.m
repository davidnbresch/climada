function entity=climada_entity_value_GDP_adjust_one(entity,mode_selector)
% scale up asset values GDP
% MODULE:
%   country_risk
% NAME:
%   climada_entity_value_GDP_adjust_one
% PURPOSE:
%   Scale up asset values based on a country's estimated total asset value.
%   The total asset value is derived as follows:
%       - normalize the asset values
%       - multiply with the country's GDP
%       - multiply with a factor that depends on a country's income
%         group, i.e., its GDP per capita. This last factor is the KEY
%         ASSUMPTION here, see income_group_factors in PARAMETERS in code
%
%   See also climada_entity_value_GDP_adjust, which allows to process a
%   series of entity .mat files
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
%   Note: to avoid any troubles, Cover is set equal to Value.
%
%   Prior calls: e.g. climada_nightlight_entity, country_risk_calc
%   Next calls: e.g. country_risk_calc
% CALLING SEQUENCE:
%   entity_adjusted=climada_entity_value_GDP_adjust_one(entity,mode_selector)
% EXAMPLE:
%   entity_adjusted=climada_entity_value_GDP_adjust_one(climada_entity_load)
% INPUT:
%   entity: an entity structure, see e.g. climada_entity_load and
%       climada_entity_read
% OPTIONAL INPUT PARAMETERS:
%   mode_selector: =1, print step-by-step to stdout, =0, not (default)
%       If =2, do not care for Value_today, just adjust to GDP*income_group_factors
%       If =3, use GDP_future instead of GDP_today (if this column is in
%       the economic_indicators_mastertable.xls, otherwise throw an error).
%       In this case, ignore Value_today, just scale with GDP_future.
% OUTPUTS:
%   entity_adjusted: entity with adjusted asset values, also stored as .mat
%       file (only last entity if entity_file_regexp covers more than one)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150204, switched to one entity, see also climada_entity_value_GDP_adjust
%-

% set global variables and directories
global climada_global
if ~climada_init_vars,return;end % init/import global variables

% check input
if ~exist('entity','var'),return;end
if ~exist('mode_selector','var'),mode_selector=0;end


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
            
            if mode_selector>1,future_factor=1.0;end
            
            if abs(future_factor-1)>0.051; % 5 percent tolerance
                % if factor equals one, do it silenty
                fprintf('future values scaled up by %f*today (it has Value_today)\n',future_factor);
            else
                future_factor=1.0; % force the same, as we ignore up to 5% difference
            end
            
            if mode_selector,fprintf('future_factor: %f\n',future_factor);end
            
        else
            future_factor=1;
        end
        
        scale_up_factor = income_group_factors(econ_master_data.income_group(country_index));
        
        if mode_selector,fprintf('sum(value) as on file: %g\n',sum(entity.assets.Value));end
        
        % normalize assets
        entity.assets.Value = entity.assets.Value/sum(entity.assets.Value);
        
        if mode_selector==3
            if ~isfield(econ_master_data,'GDP_future')
                fprintf('Error: no GDP_future in %s, aborted\n',economic_data_file);
                return
            else
                GDP_value=econ_master_data.GDP_future(country_index);
            end
        else
            GDP_value=econ_master_data.GDP_today(country_index);
        end
        
        if isnan(GDP_value)
            GDP_value=1.0;
            scale_up_factor=1.0; % in this case makes also no sense
            fprintf('Warning: GDP=NaN, not applied\n');
        else
            if mode_selector,fprintf('GDP: %g, scale_up_factor: %f\n',GDP_value,scale_up_factor);end
        end
        
        % multiply with GDP
        entity.assets.Value = entity.assets.Value*GDP_value;
        
        % multiply with scale-up factor
        entity.assets.Value = entity.assets.Value*scale_up_factor;
        
        % special treatment for future entities
        if isfield(entity.assets,'Value_today'),entity.assets.Value_today=entity.assets.Value;end
        
        % and finally apply future factor (in case it's a _future entity)
        entity.assets.Value = entity.assets.Value*future_factor;
        
        if mode_selector,fprintf('sum(value) after scaling: %g\n',sum(entity.assets.Value));end
        
        % for consistency, update Cover
        if isfield(entity.assets,'Cover'),entity.assets.Cover=entity.assets.Value;end
        %             if isfield(entity.assets,'Cover')
        %                 entity.assets.Cover=entity.assets.Cover*GDP_value*scale_up_factor*future_factor;
        %                 Cover_pct=entity.assets.Cover./entity.assets.Value;
        %                 if max(Cover_pct)<0.01
        %                     fprintf('Warning: max Cover less than 1%% of Value -> consider to adjust Cover\n');
        %                 end
        %             end
        
    else
        msg_name='';
        if isfield(entity.assets,'admin0_ISO3'),msg_name=entity.assets.admin0_ISO3;end
        if isfield(entity.assets,'admin0_name'),msg_name=entity.assets.admin0_name;end
        fprintf('skipped (no income group info): %s\n',msg_name);
    end
    
end % ~isempty(country_index)

end % climada_entity_value_GDP_adjust_one