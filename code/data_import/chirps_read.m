function res=chirps_read(nc_files,lonlatrect,check_animation,verbose)
% read CHIRPS netCDF file
% MODULE:
%   _LOCAL
% NAME:
%   chirps_read
% PURPOSE:
%   read CHIRPS netCDF file, see  http://chg.geog.ucsb.edu/data/chirps/#_Data
%
%   currently reading global daily data, i.e. from files obtained from 
%   ftp://ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0//global_daily/netcdf/p05/by_month/
%
%   currently VERY innefficient memory use, as we store all (70%) of ocean
%   points as zeros
%
% CALLING SEQUENCE:
%   res=chirps_read(nc_files,lonlatrect,check_animation,verbose)
% EXAMPLE:
%   res=chirps_read(nc_files)
% INPUTS:
%   nc_files: netCDF filename(s) with path. If more than one file, pass as
%       struct, i.e. nc_files{i} a single filename with path
% OPTIONAL INPUT PARAMETERS:
%   lonlatrect: [minlon maxlon minlat maxlat] to read a rectangular region
%       instead of the wholw world, default=[].
%   check_animation: =0 (default): no animation, =1: animation to screen
%       =2: to screen and saved as MP4 file (CHIRPS_animation.mp4 in pwd)
%       =3: only saved to mp4, figure not visible
%   verbose: =1 print some info to stdout, =0 not (silent, default)
% OUTPUTS:
%   res: a structure with
%       lat: [2000x1 single] the latitude
%       lon: [7200x1 single] the longitude
%       time: [31x1 double] the time (here rather the date),
%           as a MATLAB datenum
%       time_str: [31x11 char] date string (=datestr(res.time))
%   precip: [7200x2000x31 double] the precipitation
%   precip_units: the units of res.precip
%   > check output e.g. with
%       image(res.lon,res.lat,res.precip(:,end:-1:1,1)');axis equal
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160103, initial
%-

res=[]; % init

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('nc_files','var'),nc_files=[];end
if ~exist('lonlatrect','var'),lonlatrect=[];end
if ~exist('check_animation','var'),check_animation=0;end
if ~exist('verbose','var'),verbose=0;end

% locate the module's (or this code's) data folder (usually a folder
% 'parallel' to the code folder, i.e. in the same level as code folder)
%module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
chirps_time0 = datenum('1-Jan-1980'); % start date of the CHIRPS time stamp
chirps_misdat=-9999;
%
animation_mp4_file='CHIRPS_animation';
%
% TEST filename(s)
nc_files{ 1}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.01.days_p05.nc'; % Jan 2015
nc_files{ 2}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.02.days_p05.nc'; % Feb 2015
nc_files{ 3}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.03.days_p05.nc'; % Mar 2015
nc_files{ 4}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.04.days_p05.nc'; % Apr 2015
nc_files{ 5}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.05.days_p05.nc'; % Mai 2015
nc_files{ 6}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.06.days_p05.nc'; % Jun 2015
nc_files{ 7}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.07.days_p05.nc'; % Jul 2015
nc_files{ 8}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.08.days_p05.nc'; % Aug 2015
nc_files{ 9}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.09.days_p05.nc'; % Sep 2015
nc_files{10}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.10.days_p05.nc'; % Oct 2015
nc_files{11}='/Users/bresch/Desktop/CHIRPS/chirps-v2.0.2015.11.days_p05.nc'; % Nov 2015

if ~iscell(nc_files)
    nc_file=nc_files;clear nc_files
    nc_files{1}=nc_file;
end

res.time=[]; % init
n_files=length(nc_files);

% loop 1 to establish dimensions and 1-d variables
ntimes=zeros(1,n_files);
if verbose,fprintf('preparation (dimensioning) loop (%i files) ...\n',n_files);end
for file_i=1:n_files
    nc_file=nc_files{file_i};
    %FINFO = ncinfo(nc_files); % to inquire content
    if ~isfield(res,'lon'),res.lon = ncread(nc_file,'longitude');end % degrees_east
    if ~isfield(res,'lat'),res.lat = ncread(nc_file,'latitude');end % degrees_north
    if ~isfield(res,'precip_units'),res.precip_units='mm/day';end
    time = ncread(nc_file,'time'); % days since 1980-1-1 0:0:0
    time=double(time+chirps_time0);
    res.time=[res.time time']; % concat
    ntimes(file_i)=length(res.time);
end % file_i (loop 1)

if ~isempty(lonlatrect)
    x=res.lon;y=res.lat; % copy into x and y for convenience (same proceudre as in etopo_get)
    % figure which subset of the etopometry to obtain
    Lon1=lonlatrect(1); Lon2=lonlatrect(2);
    Lat1=lonlatrect(3); Lat2=lonlatrect(4);
    inds=1:numel(x); inds=inds(:);
    if Lon1<0
        startx = floor(interp1(x,inds,Lon1)); % x(startx)
    else
        startx = ceil(interp1(x,inds,Lon1)); % x(startx)
    end
    if Lon2<0
        endx   = ceil (interp1(x,inds,Lon2)); % x(endx)
    else
        endx   = floor (interp1(x,inds,Lon2)); % x(endx)
    end
    inds=1:numel(y);
    if Lat1>0
        starty = floor(interp1(y,inds,Lat1)); % y(starty)
    else
        starty = ceil(interp1(y,inds,Lat1)); % y(starty)
    end
    if Lat2>0
        endy   = ceil (interp1(y,inds,Lat2)); % y(endy)
    else
        endy   = floor (interp1(y,inds,Lat2)); % y(endy)
    end
    countx=endx-startx-1; % x(startx+countx)
    county=endy-starty+1; % y(starty+county)
    if isnan(startx),startx=1;end
    if isnan(countx),countx=1;end
    res.lon=res.lon(startx:endx);
    res.lat=res.lat(starty:endy);
else
    startx=[];
    countx=length(res.lon)-1;
    county=length(res.lat)-1;
end

res.precip=zeros(countx+1,county+1,length(res.time),'single'); % allocate

% loop 2 to read precip data
time1=1; % init
for file_i=1:n_files
    nc_file=nc_files{file_i};
    if verbose,fprintf('reading (%i/%i) %s\n',file_i,n_files,nc_file);end
    
    if isempty(startx)
        % read whole world (all times)
        precip = ncread(nc_file,'precip'); % mm/day, (lon x lat x time)
    else
        % read rectabgular region (all times)
        precip = ncread(nc_file,'precip',[startx starty 1],[countx+1 county+1 (ntimes(file_i)-time1)+1]);
    end
    
    precip(precip==chirps_misdat)=NaN;
    res.precip(:,:,time1:ntimes(file_i))=precip; % fill into large array
    time1=ntimes(file_i)+1;
end % file_i (loop 2)

res.time_str=datestr(res.time); % convert to user-readable date/time
% all reading done

if check_animation
    
    fig_visible='on';if check_animation==3,fig_visible='off';end
    fig_handle = figure('Name','CHIRPS animation','visible',fig_visible,'Color',[1 1 1],'Position',[2 274 1365 399]);
    
    if check_animation>1
        vidObj = VideoWriter(animation_mp4_file,'MPEG-4');
        open(vidObj);
    end
    
    for time_i=1:size(res.precip,3)
        
        hold off;clf % start with blank plot each time
        
        image(res.lon,res.lat,res.precip(:,:,time_i)');
        set(gca,'YDir','normal');axis tight;axis equal
        hold on;climada_plot_world_borders
        if ~isempty(lonlatrect)
            set(gca,'XLim',lonlatrect(1:2));
            set(gca,'YLim',lonlatrect(3:4));
        end
        title(['CHIRPS precip mm/day ' res.time_str(time_i,:)])
        hold off
        
        if check_animation>1
            currFrame   = getframe(fig_handle);
            writeVideo(vidObj,currFrame);
        end % check_animation
        
    end % time_i
    
    if check_animation>1
        close(vidObj);
        fprintf('movie saved in %s\n', animation_mp4_file)
    end % check_animation>0
    
end % check_animation

end % chirps_read