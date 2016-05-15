function info=climada_tc_track_info(tc_track,check_plot,boundary_rect)
% climada tc track info
% MODULE:
%   core
% NAME:
%   climada_tc_track_info
% PURPOSE:
%   Prints information of tracks to stdout (name, date....) and shows
%   (nice) plots of historic (and probabilistic) tracks
%
%   Prior call: climada_tc_read_unisys_tc_track
%   Possible subsequent call: hold on;climada_entity_plot
% CALLING SEQUENCE:
%   info=climada_tc_track_info(tc_track)
% EXAMPLE:
%   info=climada_tc_track_info('tracks.she_hist.mat',-2,[140 180 -40 -10]); % historic
%   info=climada_tc_track_info('tracks.she_prob.mat',-1,[140 180 -40 -10]); % also probabilistic
% INPUTS:
%   tc_track: a tc_track structure, as returned by
%       climada_tc_read_unisys_database or climada_tc_read_unisys_tc_track
%       > promted for (.mat) if not given
%       If a .mat filename is passed, the content is loaded
% OPTIONAL INPUT PARAMETERS:
%   check_plot: if =1, show checkplot, =0 not (default)
%       =-1; ONLY check plot, do not print info to stdout
%       =-2; only check plot and only historic events (to create the e.g.
%       the slide to show hist/prob, see boundary_rect also)
%   boundary_rect: the boundary to plot [minlon maxlon minlat maxlat]
%       default is whole globe
% OUTPUTS:
%   info contains some information, but to stdout is main purpose of this
%       routine
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150118, initial
% David N. Bresch, david.bresch@gmail.com, 20160515, check_plot and boundary_rect added
%-

info=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('tc_track','var'),tc_track=[];end
if ~exist('check_plot','var'),check_plot=0;end
if ~exist('boundary_rect','var'),boundary_rect=[];end

% PARAMETERS
% 
% color of land
country_color=[.7 .7 .7]; % light gray

% prompt for tc_track
tc_track_filename='';
if isempty(tc_track) % local GUI
    tc_track_filename=[climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    [filename, pathname] = uigetfile(tc_track_filename, 'Select tc_track file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track_filename=fullfile(pathname,filename);
    end
elseif ~isstruct(tc_track)
    tc_track_filename=tc_track; % assume filename passed
end

if ~isempty(tc_track_filename)
    % complete path, if missing
    [fP,fN,fE]=fileparts(tc_track_filename);
    if isempty(fP),fP=[climada_global.data_dir filesep 'tc_tracks'];end
    if isempty(fE),fE='.mat';end
    tc_track_filename=[fP filesep fN fE];
    load(tc_track_filename)
end

if isempty(tc_track),tc_track=climada_tc_read_unisys_database;end % get tc_track

if ~isfield(tc_track,'category')
    tc_track=climada_tc_stormcategory(tc_track); % add storm category
end

if check_plot>=0
    
    fprintf('iiii: name          yyyymmdd  category\n'); % header
    
    info=cell(1,length(tc_track)); % allocate
    
    for track_i=1:length(tc_track)
        info{track_i}=sprintf('%4.4i: %s (%4.4i%2.2i%2.2i) %i',track_i,...
            char(tc_track(track_i).name),...
            tc_track(track_i).yyyy(1),tc_track(track_i).mm(1),tc_track(track_i).dd(1),...
            max(tc_track(track_i).category));
        fprintf('%s\n',char(info{track_i}));
    end % track_i
    
end % check_plot>=0

min_yyyy=1e6;max_yyyy=-1e6;

if abs(check_plot)
    
    % plot land and ocean in light blue
    climada_plot_world_borders(-1,'','',1,[],country_color);
    hold on
    
    % fastest two loops, first ploting probabilsitic tracks, then historic
    fprintf('plotting %i tracks,',length(tc_track))
    if check_plot>-2
        fprintf(' probabilistic ...')
        for track_i=1:length(tc_track)
            if tc_track(track_i).orig_event_flag==0
                color_cat=min(max(tc_track(track_i).category,0),5);
                plot(tc_track(track_i).lon,tc_track(track_i).lat,'Color',[0 0 color_cat/7+2/7]);
                hold on
            end % probabilistic
        end % track_i
    end
    fprintf(' historic ...')
    for track_i=1:length(tc_track)
        min_yyyy=min(min_yyyy,min(tc_track(track_i).yyyy));
        max_yyyy=max(max_yyyy,max(tc_track(track_i).yyyy));
        if tc_track(track_i).orig_event_flag==1
            color_cat=min(max(tc_track(track_i).category,0),5);
            plot(tc_track(track_i).lon,tc_track(track_i).lat,'Color',[color_cat/7+2/7 0 0]);
            hold on
        end % historic
    end % track_i
    fprintf(' done\n')
    axis equal
    if ~isempty(boundary_rect),xlim(boundary_rect(1:2));ylim(boundary_rect(3:4));end
    %climada_plot_world_borders(2,'','',1,[],[0 .7 0]);
    hold off; drawnow
    xlabel('blue: probabilistic, red: historic');
    title(sprintf('%4.4i .. %4.4i',min_yyyy,max_yyyy));
end % check_plot

end % climada_tc_track_info