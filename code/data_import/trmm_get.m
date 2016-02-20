function TRMM = trmm_get(yyyy,mm,dd,hh,check_plot,verbose)
% climada TRMM precipitation
% MODULE:
%   helper functions
% NAME:
%   trmm_get
% PURPOSE:
%   Read the TRMM precipitation data, GIS-reformatted version of TRMM 3B42
%   files (spatial resolution is 0.25 degrees)
%   See ftp://trmmopen.gsfc.nasa.gov/pub/trmmdata/GIS/README.GIS.pdf
%
%   The code tries to automatically get the files from
%   ftp://trmmopen.gsfc.nasa.gov/pub/trmmdata/GIS/ (see TRMM_URL in
%   PARAMETERS in code). If this fails, the required TRMM file
%   is printed to stdout for the user to manually retrieve. Once locally
%   stored (to TRMM_data_dir, i.e. ../data/trmm), call trmm_get
%   again to process the file.
%
%   calls climada functions climada_plot_world_borders and
%   climada_figure_scale_add only if they exists. Hence can easily be run
%   stand-alone
% CALLING SEQUENCE:
%   TRMM = trmm_get(yyyy,mm,dd,hh,check_plot,verbose)
% EXAMPLE:
%   TRMM = trmm_get(2014,10,21,15,1,0);
%   trmm_get(2014,10,21,[],1,0) % animate all hours of one day
%   trmm_get(2014,10,1:31,[],1,0) % animate a full month
% INPUTS:
%   yyyy,mm,dd: year month and day (integers)
%   hh: the hour UTC, allowed are every 3 hours, i.e. 0,3,6,9,12,15,18,21
%       Special: if empty, we get ALL 3-hourly data and produce an
%           animation (to e.g. check data consistenccy)
%           In this special case, dd can also be a vector, to loop over
%           more than one day, e.g. dd=1:30 
%           Note that in this special case TRMM is empty on output
% OPTIONAL INPUT PARAMETERS:
%   check_plot: show a check plot, if =1, (default=0)
%       if >1, do not open a new figure
%       if >2, do only show precic <400 mm
%   verbose: =1 print info, =0 not (default)
% OUTPUTS:
%   TRMM: a structure, with
%       yyyy,mm,dd,hh: as on input
%       datenum: the MATLAB datenum(yyyy,mm,dd,hh,0,0)
%       source_filename: the original (ftp) filename with web path
%       filename: the local .mat filename (with path)
%       tif_filename: the local .tif filename (with path)
%       data(i,j): the data
%       lon(i,j): the longitude of the pixels
%       lat(i,j): the latitude of the pixels
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20160220, initial
%-

TRMM.data=[];TRMM.lon=[];TRMM.lat=[]; % init output

global climada_global
if exist('climada_init_vars','file') % check for climada
    if ~climada_init_vars,return;end % init/import global variables
else
    % special, to allow for stand-alone usage
    climada_global.data_dir=pwd; % just use local
end
    
if ~exist('yyyy','var'),yyyy = []; end
if ~exist('mm','var'),mm = []; end
if ~exist('dd','var'),dd = []; end
if ~exist('hh','var'),hh = []; end
if ~exist('check_plot','var'),check_plot = 0; end
if ~exist('verbose','var'),verbose = 0; end

% check for TRMM folder in climada_data/TRMM (we can not store to the
% elevation_models module, as this creates troubles when updating code via github)
TRMM_data_dir= [climada_global.data_dir filesep 'trmm'];
if ~isdir(TRMM_data_dir),mkdir(fileparts(TRMM_data_dir),'trmm');end % create, should it not exist (no further checking)

% PARAMETERS
%
% the URL where to find the single tiles of the TRMM
TRMM_URL='ftp://trmmopen.gsfc.nasa.gov/pub/trmmdata/GIS';
URL_filesep='/';
%
% TEST
%yyyy=2014;mm=10;dd=21;hh=15;

if isempty(hh)
    
    % Special: we get ALL 3-hourly data and produce an animation (to e.g. check
    % data consistency). If dd is also be a vector, we loop over days, too.
    fprintf('SPECIAL: create animation ...\n')

    hh=[0,3,6,9,12,15,18,21]; % set all hours
    
    % prepare figure and init animation
    fig_handle = figure('Name','TRMM animation','visible','off','Color',[1 1 1],'Position',[2 274 1365 399]);
    animation_mp4_file=[TRMM_data_dir filesep num2str(yyyy,'%4.4i') num2str(mm,'%2.2i') num2str(dd(1),'%2.2i')];
    vidObj = VideoWriter(animation_mp4_file,'MPEG-4');
    open(vidObj);
    
    for dd_i=1:length(dd)
        for hh_i=1:length(hh)
            trmm_get(yyyy,mm,dd(dd_i),hh(hh_i),3,1);
            title(['TRMM 3h precip [mm] ' num2str(yyyy,'%4.4i') ...
                num2str(mm,'%2.2i') num2str(dd(dd_i),'%2.2i') ' ' num2str(hh(hh_i),'%2.2i')]);
            currFrame = getframe(fig_handle);
            writeVideo(vidObj,currFrame); % add frame to animation
        end % hh_i
    end % dd_i
    
     close(vidObj);
     fprintf('movie saved in %s\n', animation_mp4_file)
     return
end % isempty(hh)


% construct the ftp filename
TRMM.yyyy=yyyy;TRMM.mm=mm;TRMM.dd=dd;TRMM.hh=hh;
TRMM.datenum=datenum(yyyy,mm,dd,hh,0,0);
TRMM_filename_only=['3B42.' num2str(yyyy,'%4.4i') num2str(mm,'%2.2i') num2str(dd,'%2.2i') '.' num2str(hh,'%2.2i') '.7.tif'];
TRMM.source_filename=[TRMM_URL URL_filesep num2str(yyyy,'%4.4i') URL_filesep num2str(mm,'%2.2i') ...
    URL_filesep num2str(dd,'%2.2i') URL_filesep TRMM_filename_only];
TRMM.tif_filename=[TRMM_data_dir filesep TRMM_filename_only];
[fP,fN]=fileparts(TRMM.tif_filename);
TRMM.filename=[fP filesep fN '.mat'];

if exist(TRMM.filename,'file')
    % load from previously saved .mat (binary) file
    if verbose,fprintf('restoring %s\n',TRMM.filename);end
    load(TRMM.filename)
else
    
    if ~exist(TRMM.tif_filename,'file') % file
        try
            % get the original file from ftp server
            % -------------------------------------
            fprintf('retrieving %s (be patient) ... ',TRMM.source_filename);
            gunzip(TRMM.source_filename,TRMM_data_dir);
            fprintf('done\n');
        catch
            fprintf('ERROR: retrieving %s failed\n',TRMM.source_filename)
            fprintf('get the .tif file manually, then call %s again\n',mfilename);
            return
        end % try
    else
        if verbose,fprintf('reading local %s\n',TRMM.tif_filename);end
    end % ~exist(TRMM.tif_filename,'file') % file
    
    % read the TRMM data
    % ------------------
    TRMM.data = flipud(imread(TRMM.tif_filename));
    
    % create coordinate meshgrid
    [TRMM.lon,TRMM.lat] = meshgrid(linspace(-180,180,size(TRMM.data,2)),linspace(-50,50,size(TRMM.data,1)));
    
    % single precision to save space
    TRMM.lon=single(TRMM.lon);
    TRMM.lat=single(TRMM.lat);
    TRMM.data=single(TRMM.data);
    
    if verbose,fprintf('saving %s\n',TRMM.filename);end
    save(TRMM.filename,'TRMM'); % save as .mat (binary) file
    
end % exist(TRMM.filename,'file')

if check_plot    
    if check_plot==1,figure('Name','TRMM (3h precipitation)','Color',[1 1 1]);end
    if check_plot>2,TRMM.data(TRMM.data>400)=NaN;end % safeguard
    imagesc([min(TRMM.lon(:)) max(TRMM.lon(:))],[min(TRMM.lat(:)) max(TRMM.lat(:))],TRMM.data)
    set(gca,'YDir','normal')
    hold on
    colorbar;
    caxis;
    axis equal
    if exist('climada_plot_world_borders','file'),climada_plot_world_borders;end
    axis([min(TRMM.lon(:)) max(TRMM.lon(:)) min(TRMM.lat(:)) max(TRMM.lat(:))]);
    if exist('climada_figure_scale_add','file'),climada_figure_scale_add;end
end

end % trmm_get