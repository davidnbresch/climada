function climada_EDS_ED_at_centroid_report(EDS,Percentage_Of_Value_Flag,report_file)
% climada
% NAME:
%   climada_EDS_ED_at_centroid_report
% PURPOSE:
%   Write out ED at centroids for one or multiple EDS structures into .csv
%   file
%   previous call: climada_EDS_calc
% CALLING SEQUENCE:
%   climada_EDS_ED_at_centroid_report(EDS,Percentage_Of_Value_Flag,report_file)
% EXAMPLE:
%   climada_EDS_ED_at_centroid_report(climada_EDS_calc(climada_entity_read))
% INPUTS:
%   EDS: either an event damage set, as e.g. returned by climada_EDS_calc or
%       a file containing such a structure
%       SPECIAL: we also accept a structure which contains an EDS, like
%       measures_impact.EDS
%       if EDS has the field annotation_name, the legend will show this
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   Percentage_Of_Value_Flag: if =1, scale vertical axis with Value, such
%       that damage as percentage of value is shown, instead of damage amount,
%       default=0 (damage amount shown). Very useful to compare DFCs of
%       different portfolios to see relative differences in risk
%   report_file: filename (and path) to save the report to (as .csv), if
%       empty, prompted for
% OUTPUTS:
%   none, report file written as .csv
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150430, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),EDS=[];end
if ~exist('Percentage_Of_Value_Flag','var'),Percentage_Of_Value_Flag=0;end
if ~exist('report_file','var'),report_file='';end

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

if isempty(report_file)
    report_file=[climada_global.data_dir filesep 'results' filesep 'DFC_report.csv'];
    [filename, pathname] = uiputfile(report_file, 'Save DFC report as:');
    if isequal(filename,0) || isequal(pathname,0)
        report_file='';
    else
        report_file=fullfile(pathname,filename);
    end
end

if ~isempty(report_file)
    % write .csv file
    header_str=['EDS name' climada_global.csv_delimiter 'Reference year' climada_global.csv_delimiter 'Total value'];
    if Percentage_Of_Value_Flag
        header_str=[header_str climada_global.csv_delimiter 'Damage percentage of Value'];
        pct_mult=1/100;
    else
        header_str=[header_str climada_global.csv_delimiter 'Damage absolute'];
        pct_mult=1;
    end
    header_str=[header_str climada_global.csv_delimiter 'Total ED'];
    for c_i=1:length(EDS(1).ED_at_centroid)
        header_str=[header_str climada_global.csv_delimiter sprintf('%d',c_i)];
    end   
    header_str=[header_str '\n'];
    fid=fopen(report_file,'w');
    fprintf(fid,strrep(strrep(header_str,'EDS name','Centroid variable'),'Total ED','')); % print header with ED at each centroid
    
    EDS_i=1; %first time print also lat, lon and values per centroid
    fprintf(fid,'Longitude');
    fprintf(fid,'%s%d',climada_global.csv_delimiter,EDS(EDS_i).reference_year);
    fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(EDS_i).Value);
    fprintf(fid,'%s%i%s',climada_global.csv_delimiter,1,climada_global.csv_delimiter); % always as stated in header
    for c_i=1:length(EDS(EDS_i).ED_at_centroid)
        fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(EDS_i).assets.lon(c_i));
    end % c_i
    fprintf(fid,'\n');
    fprintf(fid,'Latitude');
    fprintf(fid,'%s%d',climada_global.csv_delimiter,EDS(EDS_i).reference_year);
    fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(EDS_i).Value);
    fprintf(fid,'%s%i%s',climada_global.csv_delimiter,1,climada_global.csv_delimiter); % always as stated in header
    for c_i=1:length(EDS(EDS_i).ED_at_centroid)
        fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(EDS_i).assets.lat(c_i));
    end % c_i
    fprintf(fid,'\n');
    
    Values_all = [EDS.Value];
    [Values_unique indx] = unique(Values_all); 
    indx = sort(indx);
    for EDS_i = 1:length(indx)
        name_ = EDS(indx(EDS_i)).annotation_name;
        indx2 = strfind(name_,',');
        fprintf(fid,'Value at centroid (%d), %s', EDS(indx(EDS_i)).reference_year, name_(1:indx2-1));
        fprintf(fid,'%s%d',climada_global.csv_delimiter,EDS(indx(EDS_i)).reference_year);
        fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(indx(EDS_i)).Value);
        fprintf(fid,'%s%i%s',climada_global.csv_delimiter,1,climada_global.csv_delimiter); % always as stated in header
        for c_i=1:length(EDS(indx(EDS_i)).ED_at_centroid)
            fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(indx(EDS_i)).assets.Value(c_i));
        end % c_i
        fprintf(fid,'\n');
    end
    fprintf(fid,'\n');

    fprintf(fid,header_str); % print header with ED at each centroid
    for EDS_i=1:length(EDS)
        fprintf(fid,'%s',EDS(EDS_i).annotation_name);
        fprintf(fid,'%s%d',climada_global.csv_delimiter,EDS(EDS_i).reference_year);
        fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(EDS_i).Value);
        fprintf(fid,'%s%i',climada_global.csv_delimiter,1); % always as stated in header
        fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(EDS_i).ED);
        for c_i=1:length(EDS(EDS_i).ED_at_centroid)
            fprintf(fid,'%s%f',climada_global.csv_delimiter,EDS(EDS_i).ED_at_centroid(c_i)*pct_mult);
        end % c_i
        fprintf(fid,'\n');
    end % EDS_i
    fclose(fid);
    fprintf('ED at centroid report written to %s\n',report_file);
    
end % ~isempty(report_file)


return
