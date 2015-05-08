function climada_EDS_ED_at_centroid_report_xls(EDS,entity,xls_file)
% climada
% NAME:
%   climada_EDS_ED_at_centroid_report
% PURPOSE:
%   Write out ED at centroids for one or multiple EDS structures into .csv
%   file
%   previous call: climada_EDS_calc
% CALLING SEQUENCE:
%   climada_EDS_ED_at_centroid_report(EDS,entity,xls_file)
% EXAMPLE:
%   climada_EDS_ED_at_centroid_report(climada_EDS_calc(climada_entity_read), climada_entity_read)
% INPUTS:
%   EDS: either an event damage set, as e.g. returned by climada_EDS_calc or
%       a file containing such a structure
%       SPECIAL: we also accept a structure which contains an EDS, like
%       measures_impact.EDS
%       if EDS has the field annotation_name, the legend will show this
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   xls_file: filename (and path) to save the report to (as .xls), if
%       empty, prompted for
% OUTPUTS:
%   none, report file written as .xls
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150430, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),EDS=[];end
if ~exist('xls_file','var'),xls_file='';end

% PARAMETERS
% prompt for EDS if not given
if isempty(EDS) % local GUI
    EDS=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(EDS, 'Select EDS:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        EDS=fullfile(pathname,filename);
    end
end

% load the entity, if a filename has been passed
if ~isstruct(EDS)
    EDS_file=EDS;EDS=[];
    load(EDS_file);
end

if exist('measures_impact','var') % if a results file is loaded
    EDS=measures_impact.EDS;
end

if isfield(EDS,'EDS')
    EDS_temp = EDS;
    EDS      = EDS_temp.EDS;
    EDS_temp = [];
end

% check if field 'ED_at_centroid' exists
if ~isfield(EDS,'ED_at_centroid')
    fprintf('Field ''ED at centroid'' not provided in EDS structure.\n')
    return
end

if isempty(xls_file)
    xls_file=[climada_global.data_dir filesep 'results' filesep 'ED_report.xls'];
    [filename, pathname] = uiputfile(xls_file, 'Save ED at centroid report as:');
    if isequal(filename,0) || isequal(pathname,0)
        xls_file='';
    else
        xls_file=fullfile(pathname,filename);
    end
end


% write data into matrix, which will be outputted to xls
fprintf('\t - Results into xls: Write annual damages to xls \n')

matr          = cell(length(EDS(1).ED_at_centroid)+3,numel(EDS)*2+2);
matr{3,1}     = 'Longitude';
matr{3,2}     = 'Latitude';
matr(4:end,1) = num2cell(EDS(1).assets.lon);
matr(4:end,2) = num2cell(EDS(1).assets.lat);
matr{3,3}     = 'Ward no';
matr{3,4}     = 'Category';
% special case for Barisal where we have two additional variables to
% describe the centroids
if isfield(entity(1).assets,'Ward_Nr')
    matr(4:end,3) = num2cell(entity(1).assets.Ward_Nr);
end
if isfield(entity(1).assets,'Category')
    matr(4:end,4) = entity(1).assets.Category;
end

static_row_no = 4;

for e_i = 1:numel(EDS)
    hazard_name_indx = strfind(EDS(e_i).annotation_name,',');
    hazard_name = EDS(e_i).annotation_name(1:hazard_name_indx-1);
    matr{3,(e_i-1)*2+1 +static_row_no} = sprintf('Value %d (%s)', EDS(e_i).reference_year, strrep(hazard_name,'_',' '));
    matr{3,(e_i-1)*2+2 +static_row_no} = sprintf('Annual damage from %s, %d, %s', strrep(hazard_name,'_',' '), EDS(e_i).reference_year, EDS(e_i).annotation_name);

    matr(4:end,(e_i-1)*2+1 +static_row_no) = num2cell(EDS(e_i).assets.Value);
    matr(4:end,(e_i-1)*2+2 +static_row_no) = num2cell(EDS(e_i).ED_at_centroid);

    matr{1,(e_i-1)*2+1 +static_row_no} = sprintf('Total Value');
    matr{2,(e_i-1)*2+1 +static_row_no} = sum(EDS(e_i).assets.Value);

    matr{1,(e_i-1)*2+2 +static_row_no} = sprintf('Total damage');
    matr{2,(e_i-1)*2+2 +static_row_no} = sum(EDS(e_i).ED_at_centroid);
end
xlswrite(xls_file,matr)
%xlswrite(xls_file,matr(1:10,:))

fprintf('ED at centroid report written to %s\n',xls_file);
    


return
