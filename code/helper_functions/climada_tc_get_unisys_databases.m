function climada_tc_get_unisys_databases(tc_tracks_folder,read_it)
% climada
% NAME:
%   climada_tc_get_unisys_databases
% PURPOSE:
%   get UNISYS databases from www, i.e. all the ocean basin files from 
%   http://weather.unisys.com/hurricane/index.html
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
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

if ~exist('tc_tracks_folder','var')
    tc_tracks_folder = [climada_global.data_dir filesep 'tc_tracks'];
end
if ~exist('read_it','var'),read_it=0;end

% PARAMETERS
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
    if STATUS==1
        txt_filename=[tc_tracks_folder filesep fN fE '.txt'];
        fprintf(' save as %s%s.txt ...',fN,fE);
        fid=fopen(txt_filename,'w');
        fprintf(fid,'%s',S);
        fclose(fid);
        fprintf(' done\n')

        if read_it,climada_tc_read_unisys_database(txt_filename);end 
    else
        fprintf(' FAILED\n')
        
    end
end % file_i

return
