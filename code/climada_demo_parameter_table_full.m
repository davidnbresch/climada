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
%   This code might need several hours to run:
%   for each line of output, it simulates 15*13'000 events (takes a few sec)
%   number of lines in the output file: 3*6*6*(parameter_resolution^n_measures)
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
if ~exist('csv_filename'),'var'),csv_filename=[];end

% PARAMETERS
%
% set default value for parameter_resolution if not given
% be careful: we will have 3*6*6*(parameter_resolution^n_measures) output lines
parameter_resolution=3; % the number of points we take (plus one for zero)

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

print_fmt='%i;%f;%f;%f;%f;%f;%f;%f,%f;%f;%f';
print_fmt=strrep(print_fmt,';',climada_global.csv_delimiter);

print_hdr='scenario;growth;discount_rate;beachnourish;mangroves;seawall;quality;insurance_deductible';
print_hdr=[print_hdr ';risk_today;risk_econ_growth;risk_climate_change'];
print_hdr=[print_hdr ';beachnourish_C,'beachnourish_B;mangroves_C;mangroves_B;seawall_C;seawall_B'];
print_hdr=[print_hdr ';quality_C;quality_B;insurance_deductible_C;insurance_deductible_B'];
print_hdr=[print_hdr ';Total_adaptation_C;Total_adaptation_B'];
print_hdr=strrep(print_hdr,';',climada_global.csv_delimiter);

fprintf(fid,'%s\r\n',print_hdr); % write header

for scenario_i=0:2

 for growth_i=0:2:10 % up to 10% of growth
  for discount_rate_i=0:2:10 % up to 10% of growth

    for beachnourish_i=0:parameter_resolution
     for mangroves_i=0:parameter_resolution
      for seawall_i=0:parameter_resolution
       for quality_i=0:parameter_resolution
        for insurance_deductible_i=0:parameter_resolution

         climada_demo_params.scenario=scenario_i;
         climada_demo_params.growth=growth_i/100;
         climada_demo_params.discount_rate=discount_rate_i/100;

         climada_demo_params.measures.beachnourish=beachnourish_i/parameter_resolution;
         climada_demo_params.measures.mangroves=mangroves_i/parameter_resolution;
         climada_demo_params.measures.seawall=seawall_i/parameter_resolution;
         climada_demo_params.measures.quality=quality_i/parameter_resolution;
         climada_demo_params.measures.insurance_deductible=insurance_deductible_i/parameter_resolution;

         [risk_today,risk_econ_growth,risk_climate_change]=climada_demo_waterfall_graph(climada_demo_params)
         [impact_present,impact_future]=climada_demo_adapt_cost_curve(climada_demo_params,1);

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
       for measure_i=1:5 % curently HARD-WIRED
           fprintf(fid,';%f;%f',...
              impact_future.measures.cost(measure_i)+impact_future.risk_transfer(measure_i),... % Cost
              impact_future.benefit(measure_i)); % Benefit
        end % measure_i

        % write the total cost and benefit
        total_adaptation_costs=sum(impact_future.measures.cost)+sum(impact_future.risk_transfer);
        total_adaptation_benefits=sum(impact_future.benefit);
        fprintf(fid,';%f;%f',total_adaptation_costs,total_adaptation_benefits);

        fprintf(fid,'\r\n'); % line feed

       end % insurance_deductible
      end % quality
     end % seawall
    end % mangroves
   end % beachnourish

  end % discount_rate
 end % growth

end % scenario

fclose(fid);

fprintf('parameter table written to %s\n',csv_filename);

return
