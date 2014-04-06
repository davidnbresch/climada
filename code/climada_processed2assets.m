function assets=climada_processed2assets(processed_file)
% climada
% NAME:
%   climada_processed2assets
% PURPOSE:
%   converts a processed (encoded) file into the essential information as
%   needed by climada
% CALLING SEQUENCE:
%   assets=climada_processed2assets(processed_file)
% EXAMPLE:
%   assets=climada_processed2assets(processed_file)
% INPUTS:
%   processed_file: filename of a processed (encoded) file
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   assets: a climada asset structure, but more important, a .csv file (to
%   be converted into xls) with the same information is generated
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091229
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('processed_file','var'),processed_file=[];end

% PARAMETERS
%

% prompt for processed_file if not given
if isempty(processed_file) % local GUI
    processed_file=[climada_global.data_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(processed_file, 'Open processed file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        processed_file=fullfile(pathname,filename);
    end
end

load(processed_file) % load the processed and encoded file

[fP,fN,fE]=fileparts(processed_file);

% write raw data to .csv
% ----------------------
raw_out_file=[fP filesep fN '_raw.csv'];
raw_out_fid=fopen(raw_out_file,'w');

% write header
out_format='CalculationUnitID;lon;lat;RiskType;OccupancyClass;VulnCurveID;Value;Deductible;LIMIT\r\n';
out_format=strrep(out_format,';',climada_global.csv_delimiter);
fprintf(raw_out_fid,out_format);

% write data
out_format='%i;%f;%f;%s;%s;%i;%f;%f;%f\r\n';
out_format=strrep(out_format,';',climada_global.csv_delimiter);
for record_i=1:length(entity.ptf.CalculationUnitID)
    fprintf(raw_out_fid,out_format,...
        entity.ptf.CalculationUnitID(record_i),...
        entity.ptf.lon(record_i),...
        entity.ptf.lat(record_i),...
        entity.ptf.RiskType(record_i,:),...
        entity.ptf.OccupancyClass(record_i,:),...
        entity.ptf.VulnCurveID(record_i),...
        entity.ptf.VALUE(record_i),...
        entity.ptf.DEDUCTIBLE(record_i),...
        entity.ptf.LIMIT(record_i));
end % record_i
fclose(raw_out_fid);
fprintf('raw data written to %s\n',raw_out_file);


% write aggregated data to .csv
% -----------------------------
fprintf('aggregating data ... ');
agg_out_file=[fP filesep fN '_agg.csv'];
agg_out_fid=fopen(agg_out_file,'w');

% first, get rid of records with zero VALUE
% we only treat the fields we need, means entity is kind of inconsistent afterwards
pos=find(entity.ptf.VALUE);
entity.ptf.CalculationUnitID=entity.ptf.CalculationUnitID(pos);
entity.ptf.lon=entity.ptf.lon(pos);
entity.ptf.lat=entity.ptf.lat(pos);
entity.ptf.RiskType=entity.ptf.RiskType(pos,:);
entity.ptf.OccupancyClass=entity.ptf.OccupancyClass(pos,:);
entity.ptf.VulnCurveID=entity.ptf.VulnCurveID(pos);
entity.ptf.VALUE=entity.ptf.VALUE(pos);

% generate a filter which consists of CalculationUnitID, RiskType and OccupancyClass
for record_i=1:length(entity.ptf.CalculationUnitID)
    agg_filter(record_i,:)=sprintf('%i%s%s',entity.ptf.CalculationUnitID(record_i),entity.ptf.RiskType(record_i,:),entity.ptf.OccupancyClass(record_i,:));
end

[unique_agg_filter,unique_pos]=unique(agg_filter,'rows');

% write header
out_format='CalculationUnitID;lon;lat;RiskType;OccupancyClass;VulnCurveID;Value\r\n';
out_format=strrep(out_format,';',climada_global.csv_delimiter);
fprintf(agg_out_fid,out_format);

% write data
out_format='%i;%f;%f;%s;%s;%i;%f\r\n';
out_format=strrep(out_format,';',climada_global.csv_delimiter);
for frecord_i=1:length(unique_agg_filter)
    pos=strmatch(unique_agg_filter(frecord_i,:),agg_filter);
    VALUE=sum(entity.ptf.VALUE(pos));
    fprintf(agg_out_fid,out_format,...
        entity.ptf.CalculationUnitID(unique_pos(frecord_i)),...
        entity.ptf.lon(unique_pos(frecord_i)),...
        entity.ptf.lat(unique_pos(frecord_i)),...
        entity.ptf.RiskType(unique_pos(frecord_i),:),...
        entity.ptf.OccupancyClass(unique_pos(frecord_i),:),...
        entity.ptf.VulnCurveID(unique_pos(frecord_i)),...
        VALUE);
end % record_i
fclose(agg_out_fid);
fprintf('written to %s\n',agg_out_file);


% get the unique CalculationUnits
[unique_CUs,unique_index]=unique(entity.ptf.CalculationUnitID);

% write only unique centroids
% ---------------------------
centroids_out_file=[fP filesep fN '_centroids.csv'];
centroids_out_fid=fopen(centroids_out_file,'w');

% write header
out_format='CalculationUnitID;Longitude;Latitude;Value\r\n';
out_format=strrep(out_format,';',climada_global.csv_delimiter);
fprintf(centroids_out_fid,out_format);

% write data
out_format='%i;%f;%f;%f\r\n';
out_format=strrep(out_format,';',climada_global.csv_delimiter);
for record_i=1:length(unique_CUs)
    pos=find(entity.ptf.CalculationUnitID==entity.ptf.CalculationUnitID(unique_index(record_i)));
    VALUE_SUM=sum(entity.ptf.VALUE(pos)); % sum of all VALUES at same CU
    fprintf(centroids_out_fid,out_format,...
        entity.ptf.CalculationUnitID(unique_index(record_i)),...
        entity.ptf.lon(unique_index(record_i)),...
        entity.ptf.lat(unique_index(record_i)),VALUE_SUM);
end % record_i
fclose(centroids_out_fid);
fprintf('centroids written to %s\n',centroids_out_file);

return
