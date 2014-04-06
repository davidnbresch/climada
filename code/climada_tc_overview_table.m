function climada_tc_overview_table(tc_track,csv_filename)
% climada
% NAME:
%   climada_tc_overview_table
% PURPOSE:
%   write key information of tracks into .csv file
% CALLING SEQUENCE:
%   climada_tc_overview_table(tc_track)
% EXAMPLE:
%   climada_tc_overview_table
% INPUTS:
%   tc_track: a tc_track structure, as returned eg by climada_tc_read_unisys_database
%       > promted for if not given
%   csv_filename: the name of the file to write to
%       > promted for if not given (well, prompted for a binary file that
%       contains a tc_track structure)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20110307
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('tc_track','var'),tc_track=[];end
if ~exist('csv_filename','var'),csv_filename='';end

% prompt for a binary file which contains a tc_track if not given
if isempty(tc_track) % local GUI
    tc_track_filename=[climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    [filename, pathname] = uigetfile(tc_track_filename, 'Load binary with tc_track:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track_filename=fullfile(pathname,filename);
    end
    load(tc_track_filename); % now, we have a tc_track loaded
end

% prompt for csv_filename if not given
if isempty(csv_filename) % local GUI
    csv_filename=[climada_global.data_dir filesep 'results' filesep 'tc_track_info.csv'];
    [filename, pathname] = uiputfile(csv_filename, 'Save as:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        csv_filename=fullfile(pathname,filename);
    end
end

fid=fopen(csv_filename,'w');

n_tracks=length(tc_track);

print_fmt='%i;%4.4i;%2.2i;%2.2i;%s;%f\r\n';
print_fmt=strrep(print_fmt,';',climada_global.csv_delimiter);

print_hdr=sprintf('ID;year;month;day;name;max_windspeed [%s]',tc_track(1).MaxSustainedWindUnit);
print_hdr=strrep(print_hdr,';',climada_global.csv_delimiter);

fprintf(fid,'%s\r\n',print_hdr);

for track_i=1:n_tracks
    fprintf(fid,print_fmt,...
        tc_track(track_i).ID_no,...
        tc_track(track_i).yyyy(1),...
        tc_track(track_i).mm(1),...
        tc_track(track_i).dd(1),...
        strtrim(tc_track(track_i).name),...
        max(tc_track(track_i).MaxSustainedWind));
end % track_i

fclose(fid);

fprintf('tc_track data written to %s\n',csv_filename);
