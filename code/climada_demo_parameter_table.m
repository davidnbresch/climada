function climada_demo_parameter_table(csv_filename)
% climada
% NAME:
%   climada_demo_parameter_table
% PURPOSE:
%   based on climada_demo_gui, create a (extensive) parameter table
%   for use by applications which cannot truly simulate the risk
%   such applications will have to interpolate (linearly) between
%   lookup points.
%
%   NOTE: This code takes more than 10 hours to run:
%   for each line of output, it simulates 15*13'000 events (takes a few sec)
%   number of lines in the output file: 3*11*11*n_measures*parameter_resolution
%
%   measure names etc. are currently hard-wired, could be made dynamic
% CALLING SEQUENCE:
%   climada_demo_parameter_table(csv_filename)
% EXAMPLE:
%   climada_demo_parameter_table
% INPUTS:
%   csv_filename:
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%	parameters written to file csv_filename
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20110628, sur TGV Paris-Mulhouse
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('csv_filename','var'),csv_filename=[];end

% PARAMETERS
%
% set default value for parameter_resolution if not given
% be careful: we will have 3*11*11*n_measures*parameter_resolution output lines
parameter_resolution=10; % the number of points we take (plus one for zero)
%
climada_global.waitbar=0; % supress waitbars

% prompt for csv_filename if not given
if isempty(csv_filename) % local GUI
    csv_filename=[climada_global.data_dir filesep 'results' filesep 'parameter_table.csv'];
    [filename, pathname] = uiputfile(csv_filename, 'Save as:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        csv_filename=fullfile(pathname,filename);
    end
end

fid=fopen(csv_filename,'w');

print_fmt='%i;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f';
print_fmt=strrep(print_fmt,';',climada_global.csv_delimiter);

print_hdr='scenario;growth;discount_rate;beachnourish;mangroves;seawall;quality;insurance_deductible';
print_hdr=[print_hdr ';risk_today;risk_econ_growth;risk_climate_change'];
print_hdr=[print_hdr ';beachnourish_C;beachnourish_B;mangroves_C;mangroves_B;seawall_C;seawall_B'];
print_hdr=[print_hdr ';quality_C;quality_B;insurance_deductible_C;insurance_deductible_B'];
print_hdr=[print_hdr ';Total_adaptation_C;Total_adaptation_B'];
print_hdr=strrep(print_hdr,';',climada_global.csv_delimiter);

fprintf(fid,'%s\r\n',print_hdr); % write header

t0 = clock;

for scenario_i=0:2
    
    for growth_i=0:1:10 % up to 10% of growth
        for discount_rate_i=0:1:10 % up to 10% of growth
            
            climada_demo_params.scenario=scenario_i;
            climada_demo_params.growth=growth_i/100;
            climada_demo_params.discount_rate=discount_rate_i/100;
            
            for measure_i=1:5 % loop over measures
                
                climada_demo_params.measures.beachnourish=0;
                climada_demo_params.measures.mangroves=0;
                climada_demo_params.measures.seawall=0;
                climada_demo_params.measures.quality=0;
                climada_demo_params.measures.insurance_deductible=1;
                
                for parameter_i=0:parameter_resolution
                    
                    if measure_i==1
                        climada_demo_params.measures.beachnourish=parameter_i/parameter_resolution;
                    elseif measure_i==2
                        climada_demo_params.measures.mangroves=parameter_i/parameter_resolution;
                    elseif measure_i==3
                        climada_demo_params.measures.seawall=parameter_i/parameter_resolution;
                    elseif measure_i==4
                        climada_demo_params.measures.quality=parameter_i/parameter_resolution;
                    else
                        climada_demo_params.measures.insurance_deductible=parameter_i/parameter_resolution;
                    end % measure_i
                    
                    [risk_today,risk_econ_growth,risk_climate_change]=climada_demo_waterfall_graph(climada_demo_params,1); %  1 to omit plot
                    [impact_present,impact_future]=climada_demo_adapt_cost_curve(climada_demo_params,1); %  1 to omit plot
                    
                    % write all parameters and the climate risk components
                    fprintf(fid,print_fmt,...
                        climada_demo_params.scenario,...
                        climada_demo_params.growth,...
                        climada_demo_params.discount_rate,...
                        climada_demo_params.measures.beachnourish,...
                        climada_demo_params.measures.mangroves,...
                        climada_demo_params.measures.seawall,...
                        climada_demo_params.measures.quality,...
                        climada_demo_params.measures.insurance_deductible,...
                        risk_today,risk_econ_growth,risk_climate_change);
                    
                    % write the costs and benefits for all measures
                    for measure_ii=1:5 % curently HARD-WIRED
                        fprintf(fid,';%f;%f',...
                            impact_future.measures.cost(measure_ii)+impact_future.risk_transfer(measure_ii),... % Cost
                            impact_future.benefit(measure_ii)); % Benefit
                    end % measure_i
                    
                    % write the total cost and benefit
                    total_adaptation_costs=sum(impact_future.measures.cost)+sum(impact_future.risk_transfer);
                    total_adaptation_benefits=sum(impact_future.benefit);
                    fprintf(fid,';%f;%f',total_adaptation_costs,total_adaptation_benefits);
                    
                    fprintf(fid,'\r\n'); % line feed
                    
                end % parameter_i
            end % measure_i
            
        end % discount_rate
    end % growth
    
end % scenario

fprintf('total calculation took %i seconds ',etime(clock,t0));

fclose(fid);

fprintf('parameter table written to %s\n',csv_filename);

return
