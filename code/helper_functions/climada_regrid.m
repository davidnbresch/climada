function [arr_target,arr_source]=climada_regrid(arr_source,arr_target,check_plot,verbose,use_parfor)
% climada array regrid
% NAME:
%   climada_regrid
% PURPOSE:
%   given an array, regrid to another resolution
%
% CALLING SEQUENCE:
%   [arr_target,arr_source]=climada_regrid(arr_source,arr_target,check_plot,verbose)
% EXAMPLE:
%   [x,y]=meshgrid(40:0.1:43,4:0.1:7);
%   arr_source.lon=reshape(x,1,numel(x));arr_source.lat=reshape(y,1,numel(y));
%   arr_source.val=1:numel(arr_source.lon);
%   [x,y]=meshgrid(41:0.5:42,5:0.5:6);
%   arr_target.lon=reshape(x,1,numel(x));arr_target.lat=reshape(y,1,numel(y));
%   arr_target.max_dist=.5;
%   [arr_target,arr_source]=climada_regrid(arr_source,arr_target,1,1);
% INPUTS:
%   arr_source: a structure with fields
%       lon(i): longitude of point i, if a grid (i,j), it will be
%           reformatted to a vector 1xN
%       lat(i): latitude of point i, if a grid (i,j), it will be
%           reformatted to a vector 1xN
%       val(i): value at point i, if a grid (i,j), it will be
%           reformatted to a vector 1xN
%   arr_target: a structure with fields
%       lon(i): longitude of point i, must be a vector
%       lat(i): latitude of point i, must be a vector
% OPTIONAL INPUT PARAMETERS:
%   arr_target.max_dist: maximum distance in degree for points to consider
%       default = 1e10 (infinite)
%   check_plot: =1, do show check plots, =0: no plots (default)
%   verbose: =1, verbose mode (default), =0: almost silent
%   use_parfor: whether we sue parfor if climada_global.parfor==1 (default)
%       with use_parfor=0, we avoid parallizatiuon in here (if e.g. called
%       from a code which itself runs parallel)
% OUTPUTS:
%   arr_target: same as on input, with additional field
%       val(i): value at point i, based on nearest neighbours of arr_source
%   arr_source: same as on input, with additional field
%       target_i(i): the index in the target array for each point in the
%           source array
%       map_time: the time in seconds for mapping
%       val_time: the time in seconds to calculate values
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20171104, initial
% david.bresch@gmail.com, 20171105, checpl_plot improved
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('arr_source','var'),return;end
if ~exist('arr_target','var'),return;end
if ~exist('check_plot','var'),check_plot = 0;end
if ~exist('verbose','var'),   verbose    = 1;end
if ~exist('use_parfor','var'),use_parfor = 1;end

% PARAMETERS
%
% define after how many points we update the progress info
verbose_n_points=10000;

if length(arr_source.lon)<numel(arr_source.lon),arr_source.lon=reshape(arr_source.lon,1,numel(arr_source.lon));end
if length(arr_source.lat)<numel(arr_source.lat),arr_source.lat=reshape(arr_source.lat,1,numel(arr_source.lat));end
if length(arr_source.val)<numel(arr_source.val),arr_source.val=reshape(arr_source.val,1,numel(arr_source.val));end

if ~isfield(arr_target,'max_dist'),arr_target.max_dist=1e10;end % infinite distance
max_dist=arr_target.max_dist^2;
target_i=arr_source.lon*0; % init
cos_lat = cos(arr_target.lat/180*pi); % calculate once for speedup

n_source_points=length(arr_source.lon);
t0=clock;
if climada_global.parfor && use_parfor
    % all to direct data for parallelization
    arr_source_lon=arr_source.lon;
    arr_source_lat=arr_source.lat;
    arr_target_lon=arr_target.lon;
    arr_target_lat=arr_target.lat;
    fprintf('mapping %i points to %i points, will take time (parallel) ...',n_source_points,length(arr_target.lon));
    parfor source_i=1:n_source_points
        % find closest centroid
        dd=((arr_source_lon(source_i)-arr_target_lon).*cos_lat).^2+(arr_source_lat(source_i)-arr_target_lat).^2; % in deg^2
        [min_dd,pos] = min(dd);
        if min_dd<max_dist
            target_i(source_i)=pos(1); % take first and closest point
        end
    end % source_i    
    fprintf(' done\n');
else
    fprintf('mapping %i points to %i points, will take time ...\n',n_source_points,length(arr_target.lon));
    if verbose,climada_progress2stdout;end % init, see terminate below
    for source_i=1:n_source_points
        % find closest centroid
        dd=((arr_source.lon(source_i)-arr_target.lon).*cos_lat).^2+(arr_source.lat(source_i)-arr_target.lat).^2; % in deg^2
        [min_dd,pos] = min(dd);
        if min_dd<max_dist
            target_i(source_i)=pos(1); % take first and closest point
        end
        if verbose,climada_progress2stdout(source_i,n_source_points,verbose_n_points,'points');end % update
    end % source_i
    if verbose,climada_progress2stdout(0);end % terminate
end

arr_source.map_time=etime(clock,t0);
arr_source.target_i=target_i;
fprintf('mapping grids took %f sec.\n',arr_source.map_time);

unique_i=unique(arr_source.target_i);
unique_i=unique_i(unique_i>0); % remove zero or neg
arr_target_val=unique_i*0+NaN;
t0=clock;
if climada_global.parfor && use_parfor
    arr_source_val=arr_source.val; % to direct data for parallelizatioon
    if verbose,fprintf('calculating values at %i centroids (parallel)',length(arr_target.lon));end
    parfor point_ii=1:length(unique_i) % loop over non-zero surge points
        arr_target_val(point_ii)=mean(arr_source_val(target_i==unique_i(point_ii))); % average height
    end % centroid_i
    fprintf(' done\n');
else
    if verbose,fprintf('calculating values at %i centroids\n',length(arr_target.lon));end
    if verbose,climada_progress2stdout;end % init, see terminate below
    for point_ii=1:length(unique_i) % loop over non-zero surge points
        % source_pos = arr_source.target_i==unique_i(point_ii); % pointing to ...
        % arr_target_val(point_ii)=mean(arr_source.val(source_pos)); % average height
        arr_target_val(point_ii)=mean(arr_source.val(arr_source.target_i==unique_i(point_ii))); % average height
        if verbose,climada_progress2stdout(point_ii,n_source_points,1000,'centroids');end % update
    end % centroid_i
    if verbose,climada_progress2stdout(0);end % terminate
end
arr_target.val=arr_target.lon*0+NaN; % init
arr_target.val(unique_i)=arr_target_val; % copy subset into destination
arr_source.val_time=etime(clock,t0);

fprintf('calculating values took %f sec.\n',arr_source.val_time);

if check_plot>0
    fprintf('plot mapping, might take some time ...');
    figure('Name',mfilename);
    plot(arr_source.lon,arr_source.lat,'.g');hold on;plot(arr_target.lon,arr_target.lat,'xb');legend({'source','target'});
    for source_ii=1:n_source_points
        if arr_source.target_i(source_ii)>0
            plot([arr_source.lon(source_ii),arr_target.lon(arr_source.target_i(source_ii))],...
                [arr_source.lat(source_ii),arr_target.lat(arr_source.target_i(source_ii))],'-g');
        end
    end % source_ii
    plot(arr_target.lon,arr_target.lat,'xb'); % to show again on top
    set(gcf,'Color',[1 1 1]),title(strrep(mfilename,'_','\_'));
    fprintf(' done\n');
end % check_plot

end % climada_regrid