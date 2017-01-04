function res=trmm_read(nc_files,lonlatrect,check_animation,verbose)
% read TRMM netCDF file
% MODULE:
%   core
% NAME:
%   trmm_read
% PURPOSE:
%   read TRMM netCDF file, see  and 
%   https://disc2.gesdisc.eosdis.nasa.gov/data/TRMM_RT/TRMM_3B42RT.7/doc/TRMM_Readme_v3.pdf
%
%   for the hard-wired test filens below:
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010500.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010421.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010418.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010415.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010412.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010409.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010406.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/004/3B42RT.2015010403.7.nc4
%   http://disc2.gesdisc.eosdis.nasa.gov/data//TRMM_RT/TRMM_3B42RT.7/2015/003/3B42RT.2015010400.7.nc4
%
%   currently VERY innefficient memory use, as we store all (70%) of ocean
%   points as zeros
%
% CALLING SEQUENCE:
%   res=trmm_read(nc_files,lonlatrect,check_animation,verbose)
% EXAMPLE:
%   res=trmm_read(nc_files)
%   res=trmm_read('',[40 60 -20 0],3,1) % TEST, small area
% INPUTS:
%   nc_files: netCDF filename(s) with path. If more than one file, pass as
%       struct, i.e. nc_files{i} a single filename with path
% OPTIONAL INPUT PARAMETERS:
%   lonlatrect: [minlon maxlon minlat maxlat] to read a rectangular region
%       instead of the wholw world, default=[].
%   check_animation: =0 (default): no animation, =1: animation to screen
%       =2: to screen and saved as MP4 file (TRMM_animation.mp4 in pwd)
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
% David N. Bresch, david.bresch@gmail.com, 20161228, initial, based on chirps_read
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
trmm_misdat=-9999;
%
animation_mp4_file='TRMM_animation';
%
% TEST filename(s)
data_folder='/Users/bresch/Documents/software_data/TRMM';
nc_files{ 1}=[ data_folder filesep '3B42RT.2015010400.7.nc4'];
nc_files{ 2}=[ data_folder filesep '3B42RT.2015010403.7.nc4'];
nc_files{ 3}=[ data_folder filesep '3B42RT.2015010406.7.nc4'];
nc_files{ 4}=[ data_folder filesep '3B42RT.2015010409.7.nc4'];
nc_files{ 5}=[ data_folder filesep '3B42RT.2015010412.7.nc4'];
nc_files{ 6}=[ data_folder filesep '3B42RT.2015010415.7.nc4'];
nc_files{ 7}=[ data_folder filesep '3B42RT.2015010418.7.nc4'];
nc_files{ 8}=[ data_folder filesep '3B42RT.2015010421.7.nc4'];
nc_files{ 9}=[ data_folder filesep '3B42RT.2015010500.7.nc4'];

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
    if ~isfield(res,'lon'),res.lon = ncread(nc_file,'lon');end % degrees_east
    if ~isfield(res,'lat'),res.lat = ncread(nc_file,'lat');end % degrees_north
    if ~isfield(res,'precip_units'),res.precip_units='mm/day';end
    %time = ncread(nc_file,'time'); % days since 1980-1-1 0:0:0
    % get time/date
    [~,fN]=fileparts(nc_file);
    [~,time_str]=strtok(fN,'.');time_str=strtok(time_str,'.');
    res.time=[res.time datenum(time_str,'yyyymmddhh')]; % concat
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
        precip = ncread(nc_file,'precipitation'); % mm/day, (lon x lat x time)
    else
        % read rectabgular region (all times)
        precip = ncread(nc_file,'precipitation',[startx starty],[countx+1 county+1]);
    end
    
    precip(precip==trmm_misdat)=NaN;
    res.precip(:,:,time1:ntimes(file_i))=precip; % fill into large array
    time1=ntimes(file_i)+1;
end % file_i (loop 2)

res.time_str=datestr(res.time); % convert to user-readable date/time
% all reading done

if check_animation
    
    if verbose,fprintf('animation (%i frames) ...\n',size(res.precip,3));end

    fig_visible='on';if check_animation==3,fig_visible='off';end
    fig_handle = figure('Name','TRMM animation','visible',fig_visible,'Color',[1 1 1],'Position',[2 274 1365 399]);
    
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
        title(['TRMM precip mm/day ' res.time_str(time_i,:)])
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

end % trmm_read