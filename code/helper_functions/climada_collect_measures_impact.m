function impact_collected=climada_collect_measures_impact(impact1,impact2)
%climada
% NAME:
%   climada_collect_measures_impact
% PURPOSE:
%   collect impact files for two hazards created by climada_measures_impact
%   next step: climada_adaptation_cost_curve
%
%   1. sum up benefit (loss averted) for shared measures
%   2. cost of shared measures - take higher costs if costs not the same --> WARNING
%   3. It is assumed that the two hazards are insured separately, therefore
%       make sure to not use the same name for both hazards e.g. risk_transfer_rain
%       and risk_transfer_wind. If one insurance covers both hazards sum up the losses
%       of both hazards, apply the risk transfer and calculate the NPV of
%       the benefits and the premium
%
% CALLING SEQUENCE:
%   impact_collected=climada_collect_measures_impact(impact1,impact2))
% INPUTS:
%   impact: 2 struct files with impact on ELS of differnet adaptation measures
%   see climada_measures_impact
%       > promted for if not given
% OUTPUTS:
%   impact_collected: struct file which includes the impact of both shared
%   and unique measures.
%
%   -   new cost benefit ratios: for shared measures the benefits
%       were summed up and the costs taken only once (if costs are not the
%       same the higher ones are taken ->warning)
%
%   -   Risk transfer was not changed asuming that the two hazards are
%       insured separately.
%
%   EL(measure_i): the annual expected loss to the assets under measure_i
%   benefit(measure_i):NPV of the benefit of measure_i
%   cb_ratio(measure_i):initial cost or NPV of insurance premium (for risk transfer only)
%                       divided by NPV of benefit (averted loss) of measure_i
%   measures: just a copy of measures, so we have all we need together
%   risk_transfer: NPV of insurance rate (risk transfer costs)
%   NPV_total_climate_risk: NPV of loss without measures
%   EL: annual unmitigated loss (no measures)
%   title_str: a meaningful title stating the two collected impacts
%
% MODIFICATION HISTORY:
% Martin Heynen, 20120313
% david.bresch@gmail.com, 20140804, GIT update
% david.bresch@gmail.com, 20141020, moved from tc_rain to core climada
%-


global climada_global
if ~climada_init_vars,return;end


% check arguments
if ~exist('impact1','var'),impact1=[];end
if ~exist('impact2','var'),impact2=[];end


% prompt for impacts if none is given
if isempty(impact1) && isempty(impact2) % local GUI
    impact=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    impact_default  = [climada_global.data_dir filesep 'results' filesep 'Select EXACTLY 2 impact files (m_... .mat)'];
    
    [filename, pathname] = uigetfile(impact, 'Select EXACTLY 2 impact files (m_... .mat)',impact_default,'MultiSelect','on');
    if isequal(filename,0) || isequal(pathname,0)
        warning('function stopped: please choose as function input 2 impact files')
        return;
    end
    
    %load the impact files, if a filename has been passed
    if iscell(filename)
        vars = whos('-file', fullfile(pathname,filename{1}));
        load(fullfile(pathname,filename{1}))
        impact1 = eval(vars.name);
        
        vars = whos('-file', fullfile(pathname,filename{2}));
        load(fullfile(pathname,filename{2}))
        impact2 = eval(vars.name);
    end
end


%check peril_ID to dinstinguish between rain and wind impact
if strcmp(impact1.peril_ID,'TC_rain')
    impact_rain=impact1;
    impact_wind=impact2;
else
    impact_rain=impact2;
    impact_wind=impact1;
end


n_years=climada_global.future_reference_year-climada_global.present_reference_year+1;


%shared measures and their index
[collector.shared_measures.names,collector.shared_measures.index_wind,collector.shared_measures.index_rain]=...
    intersect(impact_wind.measures.name,impact_rain.measures.name);

%unique measures and their index
[c,collector.unique_measures.wind.index] = setdiff(impact_wind.measures.name,collector.shared_measures.names);
[c,collector.unique_measures.rain.index] = setdiff(impact_rain.measures.name,collector.shared_measures.names);

%names of unique measures
collector.unique_measures.wind.name = impact_wind.measures.name(collector.unique_measures.wind.index);
collector.unique_measures.rain.name = impact_rain.measures.name(collector.unique_measures.rain.index);

%nr of measures total shared
collector.nr_measures.shared=length((collector.shared_measures.names));
%nr of measures total unique
collector.nr_measures.unique.wind=length((collector.unique_measures.wind.index));
collector.nr_measures.unique.rain=length((collector.unique_measures.rain.index));

% sum up benefit (loss averted) for shared measures
collector.shared_measures.benefits_sum=impact_wind.benefit(collector.shared_measures.index_wind)...
    +impact_rain.benefit(collector.shared_measures.index_rain);

% cost of shared measures - take higher costs if costs not the same
collector.shared_measures.cost(:,1)=impact_wind.measures.cost(collector.shared_measures.index_wind);
collector.shared_measures.cost(:,2)=impact_rain.measures.cost(collector.shared_measures.index_rain);
% check if costs for shared measures are the same
% (number shared measures == number of shared costs ?)
if collector.nr_measures.shared ~= length(intersect(collector.shared_measures.cost(:,1),collector.shared_measures.cost(:,2)));
    warning('costs for at least one shared mesure are not the same - higher costs were taken!')
end

collector.shared_measures.cost=max(collector.shared_measures.cost,[],2)';

%cb (risk transfer not shared therefor premium neglected) if shared sum up
%losses aply risk transfer and calculate NPV of premium
collector.shared_measures.cb=collector.shared_measures.cost./collector.shared_measures.benefits_sum;





% create output in the needed format
impact_collected  = struct();
%create output impact_wind 1. shared measures / 2. unique wind / 3. unique rain
for i=1:collector.nr_measures.shared+collector.nr_measures.unique.wind+collector.nr_measures.unique.rain
    
    %1. shared measures
    if i<=collector.nr_measures.shared
        impact_collected.measures.name(i)      =collector.shared_measures.names(i);
        impact_collected.measures.cost(i)      =collector.shared_measures.cost(i);
        
        impact_collected.risk_transfer(i)      =impact_wind.risk_transfer(collector.shared_measures.index_wind(i));
        impact_collected.risk_transfer(i)      =impact_rain.risk_transfer(collector.shared_measures.index_rain(i));
        impact_collected.measures.color_RGB(i,:)      =impact_wind.measures.color_RGB(collector.shared_measures.index_wind(i),:);
        %impact_collected.measures.color_RGB(i,:)      =impact_rain.measures.color_RGB(collector.shared_measures.index_rain(i),:);
        
        
        impact_collected.benefit(i)   =collector.shared_measures.benefits_sum(i);
        impact_collected.cb_ratio(i)  =collector.shared_measures.cb(i);
        %         impact_collected.EL(i)        =collector.shared_measures.EL_sum(i);
        
    end
    %2. wind measures
    if i>collector.nr_measures.shared && i<= collector.nr_measures.shared+collector.nr_measures.unique.wind
        impact_collected.measures.name(i)            =impact_wind.measures.name(collector.unique_measures.wind.index(i-collector.nr_measures.shared));
        impact_collected.measures.cost(i)            =impact_wind.measures.cost(collector.unique_measures.wind.index(i-collector.nr_measures.shared));
        
        impact_collected.risk_transfer(i)           =impact_wind.risk_transfer(collector.unique_measures.wind.index(i-collector.nr_measures.shared));
        impact_collected.measures.color_RGB(i,:)    =impact_wind.measures.color_RGB(collector.unique_measures.wind.index(i-collector.nr_measures.shared),:);
        
        impact_collected.benefit(i)                  =impact_wind.benefit(collector.unique_measures.wind.index(i-collector.nr_measures.shared));
        impact_collected.cb_ratio(i)                 =impact_wind.cb_ratio(collector.unique_measures.wind.index(i-collector.nr_measures.shared));
        %         impact_collected.EL(i)                       =impact_wind.EL(collector.unique_measures.wind.index(i-collector.nr_measures.shared));
    end
    
    %3. rain measures
    if i>collector.nr_measures.shared+collector.nr_measures.unique.wind
        impact_collected.measures.name(i)          =impact_rain.measures.name(collector.unique_measures.rain.index(i-collector.nr_measures.shared-collector.nr_measures.unique.wind));
        impact_collected.measures.cost(i)          =impact_rain.measures.cost(collector.unique_measures.rain.index(i-collector.nr_measures.shared-collector.nr_measures.unique.wind));
        
        impact_collected.risk_transfer(i)          =impact_rain.risk_transfer(collector.unique_measures.rain.index(i-collector.nr_measures.shared-collector.nr_measures.unique.wind));
        impact_collected.measures.color_RGB(i,:)   =impact_rain.measures.color_RGB(collector.unique_measures.rain.index(i-collector.nr_measures.shared-collector.nr_measures.unique.wind),:);
        
        impact_collected.benefit(i)   =impact_rain.benefit(collector.unique_measures.rain.index(i-collector.nr_measures.shared-collector.nr_measures.unique.wind));
        impact_collected.cb_ratio(i)  =impact_rain.cb_ratio(collector.unique_measures.rain.index(i-collector.nr_measures.shared-collector.nr_measures.unique.wind));
    end
    
end


% sum up EL (unmitigated loss)
impact_collected.EL=impact_wind.EL(end)+impact_rain.EL(end);


% calculate the NPV of the full unaverted losses
% TCR stands for total climate risk (last entry "end" is EL with no
% measures)
impact_collected.NPV_total_climate_risk=climada_NPV(ones(1,n_years)*(impact_wind.EL(end)+impact_rain.EL(end)));

%title string
impact_collected.title_str=['COLLECTED IMPACTS:' char(10) impact_wind.title_str char(10) impact_rain.title_str];

% ['line 1' char(10) 'line 2']
return

