function output_report = climada_measures_impact_report(measures_impact,xls_file,sheet)
% MODULE:
%   climada core
% NAME:
%   climada_measures_impact_report
% PURPOSE:
%   Write out measures_impact report (discounted benefits over time horizon, costs, benefit/cost ratio)
% CALLING SEQUENCE:
%   output_report = climada_measures_impact_report(measures_impact,xls_file,sheet)
% EXAMPLE:
%   output_report = climada_measures_impact_report
% INPUTS:
%   measures_impact: climada measures_impact structure, with fields 
%       .benefit, .cb_ratio, measures.cost, .measures.name 
%       can hold multiple measures_impact files
% OPTIONAL INPUT PARAMETERS:
%   xls_file: filename (and path) to save the report to (as .xls), if
%       empty, prompted for.Can be set to 'NO_xls_file' to omit creation of
%       xls file instead only creates the cell "output_report"
%   sheet: sheet name for xls file, if empty, default excel name is "Sheet1"
% OUTPUTS:
%   output_report: cell including header and ED values
%   report file written as .xls
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150907, init
% Lea Mueller, muellele@gmail.com, 20150909, add NPV total climate risk
% Lea Mueller, muellele@gmail.com, 20150924, enhance to cope with multiple measures_impact's
% Lea Mueller, muellele@gmail.com, 20151106, move to core
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures_impact','var'), measures_impact = []; end
if ~exist('xls_file','var'),    xls_file='';    end
if ~exist('sheet'   ,'var'),    sheet   ='';    end


% PARAMETERS

% prompt for entity if not given
if isempty(measures_impact),return;end


% do not save in an xls_file
if ~strcmp(xls_file,'NO_xls_file')
    if isempty(xls_file)
        xls_file=[climada_global.data_dir filesep 'results' filesep 'ED_report.xls'];
        [filename, pathname] = uiputfile(xls_file, 'Save ED at centroid report as:');
        if isequal(filename,0) || isequal(pathname,0)
            xls_file='';
        else
            xls_file=fullfile(pathname,filename);
        end
    end
end

header_row    = 1;
static_column_no = 2;
variable_column_no = 2;
n_measures = numel(measures_impact(1).measures.cost);
n_impacts = numel(measures_impact);
n_years = climada_global.future_reference_year - climada_global.present_reference_year+1;
output_report = cell(n_measures+header_row+1,static_column_no);
% output_report = cell(numel(category_criterium)+numel(unit_list)+header_row,static_column_no);

% % additional information below the table
% row_no = numel(category_criterium)+numel(unit_list)+6;
% output_report{row_no+1,1} = 'Further information';
% output_report{row_no+2,1} = 'AED';
% output_report{row_no+2,2} = ' = Annual expected damage';
% output_report{row_no+3,1} = 'Benefit';
% output_report{row_no+3,2} = ' = Averted damage = AED control - AED with a specific measure';
% output_report{row_no+4,1} = 'Benefit in percentage ';
% output_report{row_no+4,2} = 'in relation to AED control, this is to describe the efficiency of a measure';


% set header names
output_report{1,1} = 'Measure name';
output_report{1,2} = sprintf('Costs (USD)');



% loop over n_impacts
for impact_i = 1:n_impacts
    column_position = static_column_no + (impact_i-1)*variable_column_no;
    % special case for people
    if strcmp(measures_impact(1).Value_unit,'people')
        output_report{1,column_position+1} = sprintf('Benefit over %d years (%s, peril %s), %s',...
                             n_years,sprintf('%s ',measures_impact(impact_i).Value_unit), measures_impact(impact_i).peril_ID,...
                             measures_impact(impact_i).title_str);
        output_report{1,column_position+2} = sprintf('Benefit-cost ratio (%s/10''000USD, peril %s)',...
                             measures_impact(impact_i).Value_unit, measures_impact(impact_i).peril_ID);
        measures_impact(impact_i).cb_ratio = measures_impact(impact_i).cb_ratio/10000;
        output_report{end,1} = sprintf('Control (Not discounted damage over %d years)',n_years);  
        
    else
        output_report{1,column_position+1} = sprintf('Discounted benefit over %d years (%s, peril %s), %s',...
                             n_years,sprintf('%s ',measures_impact(impact_i).Value_unit), measures_impact(impact_i).peril_ID,...
                             measures_impact(impact_i).title_str);
        output_report{1,column_position+2} = sprintf('Benefit-cost ratio (%s/USD, peril %s)',...
                             measures_impact(impact_i).Value_unit, measures_impact(impact_i).peril_ID);
        output_report{end,1} = sprintf('Control (Discounted damage over %d years)',n_years);               
    end
end %impact_i

output_report(2:end-1,1) = measures_impact(1).measures.name;
output_report(2:end-1,2) = num2cell(measures_impact(1).measures.cost);

% loop over n_impacts
for impact_i = 1:n_impacts
    column_position = static_column_no + (impact_i-1)*variable_column_no;
    output_report(2:end-1,column_position+1) = num2cell(measures_impact(impact_i).benefit);
    output_report(2:end-1,column_position+2) = num2cell(1./measures_impact(impact_i).cb_ratio);
    output_report(end,column_position+1) = num2cell(measures_impact(impact_i).NPV_total_climate_risk);
end %impact_i


% do not save in an xls_file
if ~strcmp(xls_file,'NO_xls_file')
  
    warning('off','MATLAB:xlswrite:AddSheet'); % suppress warning message
    try
        xlswrite(xls_file,output_report,sheet)
    catch
        % probably too large for old excel, try writing to .xlsx instead
        try
            xlsx_file = [xls_file 'x'];
            xlswrite(xlsx_file,output_report,sheet)
        catch
            % probably too large for new excel, write to textfile instead
            cprintf([1 0 0],'FAILED\n')
            fprintf('attempting to write to text file instead... ')
            txt_file = strrep(xlsx_file,'.xlsx','.txt');
            writetable(cell2table(output_report),txt_file)
            fclose all;
        end
    end

    fprintf('done\n')
    fprintf('report written to sheet %s of %s\n',sheet,xls_file);
    
end

return
