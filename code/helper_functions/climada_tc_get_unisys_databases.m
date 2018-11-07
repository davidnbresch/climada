function climada_tc_get_unisys_databases(tc_tracks_folder,read_it)
% climada
% NAME:
%   climada_tc_get_unisys_databases
% PURPOSE:
%   get UNISYS databases from www, i.e. all the ocean basin files from 
%   http://www.aoml.noaa.gov/hrd/hurdat/Data_Storm.html
%
%   In the past, we used http://weather.unisys.com/hurricane/index.html,
%   but the page got revamped and does not provide the database any more.
%
%   next step: see climada_tc_read_unisys_database (see also read_it here)
% CALLING SEQUENCE:
%   climada_tc_get_unisys_databases
% EXAMPLE:
%   climada_tc_get_unisys_databases
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   tc_tracks_folder: the place to store the data files to
%       default the climada core /data/tc_tracks folder
%   read_it: if =1, do read the database and save as .mat file
% OUTPUTS:
%   into .../tc_tracks folder
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20140715
% David N. Bresch, david.bresch@gmail.com, 20161023, read_it added
% David N. Bresch, david.bresch@gmail.com, 20181107, weather.unisys.com does not provide the dtaa any more - manual, see remark in code
% David N. Bresch, david.bresch@gmail.com, 20181107, tc track .txt files stored in repositroy
%-

fprintf('\n--> get HURDAT database manually from http://www.aoml.noaa.gov/hrd/hurdat/Data_Storm.html\n')
fprintf('    (in the past, we used http://weather.unisys.com/hurricane/index.html\n')
fprintf('     but the page got revamped and does not provide the database any more)\n\n')

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

if ~exist('tc_tracks_folder','var'),tc_tracks_folder='';end
if ~exist('read_it','var'),read_it=0;end

% PARAMETERS
%
if isempty(tc_tracks_folder),tc_tracks_folder = [climada_global.data_dir filesep 'tc_tracks'];end
%
% hard-wired www-locations of the latest best track datasets:
unisys_files={...
    'http://weather.unisys.com/hurricane/atlantic/tracks.atl',...
    'http://weather.unisys.com/hurricane/e_pacific/tracks.epa',...
    'http://weather.unisys.com/hurricane/w_pacific/tracks.wpa',...
    'http://weather.unisys.com/hurricane/s_indian/tracks.she',...
    'http://weather.unisys.com/hurricane/n_indian/tracks.nio',...
    };

for file_i=1:length(unisys_files)
    www_filename=unisys_files{file_i};
    [~,fN,fE]=fileparts(www_filename);
    fprintf('reading %s ... ',fE);
    [S,STATUS] = urlread(www_filename);
    txt_filename=[tc_tracks_folder filesep fN fE '.txt'];
    if STATUS==1
        fprintf(' save as %s%s.txt ...',fN,fE);
        fid=fopen(txt_filename,'w');
        fprintf(fid,'%s',S);
        fclose(fid);
        fprintf(' done\n')

        if read_it,climada_tc_read_unisys_database(txt_filename);end 
    else
        if exist(txt_filename,'file')
            fprintf(' already exists (but new download failed)\n')
        else
            fprintf(' FAILED\n')
        end
    end
end % file_i

return
