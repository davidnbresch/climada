function climada_plot_tc_track_season(tc_track, season, markersize, check_printplot, invisible)
% plot historical tc tracks for one specific season (year) in colors 
% according to saffir-simpson hurricane scale
% NAME:
%   climada_plot_tc_track_season
% PURPOSE:
%   plot tc tracks for one specific season in colors according to saffir-simpson
%   hurricane scale
%   provide handle of tc_track
% CALLING SEQUENCE:
%   [h] = climada_plot_tc_track_season(tc_track,season,markersize,check_printplot,invisible)
% EXAMPLE:
%   [h] = climada_plot_tc_track_season(tc_track,1980,10,1,1)
% INPUTS:
%	tc_track:       one or more tc_tracks (structure)
%   season:         specific season (scalar or vector) for tc tracks to be plotted,
%                   e.g. 2012, or 2000:2012
% OPTIONAL INPUT PARAMETERS:
%   markersize:     markersize of tc_track nodes, default 7   
%   check_printplot:if set to 1 figure is saved in folder
%                   \results\mozambique\tc_tracks\tracks_1978.pdf
%   invisible:      if set to 1 figure is not visible on screen
% OUTPUTS:
%   h:               handle of tc_track nodes
% Lea Mueller, 20110606
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables
if ~exist('tc_track'       ,'var'), tc_track        = []; end
if ~exist('markersize'     ,'var'), markersize      = []; end
if ~exist('check_printplot','var'), check_printplot = []; end
if ~exist('invisible'      ,'var'), invisible       = 0 ; end
if isempty(markersize)            , markersize      = 8 ; end

%% prompt for tc_track if not given
if isempty(tc_track)
    tc_track             = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    tc_track_default     = [climada_global.data_dir filesep 'tc_tracks' filesep 'Select tc track .mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select tc track set:',tc_track_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track = fullfile(pathname,filename);
    end
end
% load the tc track set, if a filename has been passed
if ~isstruct(tc_track)
    tc_track_file = tc_track;
    tc_track      = [];
    vars = whos('-file', tc_track_file);
    load(tc_track_file);
    if ~strcmp(vars.name,'tc_track')
        tc_track = eval(vars.name);
        clear (vars.name)
    end
    prompt   ='Type specific season you want to be displayed [e.g. 1994, 2009]:';
    name     ='Requested season';
    defaultanswer = {'1994'};
    answer = inputdlg(prompt,name,1,defaultanswer);
    season = str2double(answer{1});
end


%% add season for each track
if ~isfield(tc_track, 'season')
    tc_track = climada_tc_season(tc_track);
    fprintf('field SEASON added \n')
end

% season_storms  = [tc_track(:).yyyy];
season_storms  = [tc_track(:).season];
seasons        = unique(season_storms);
season_index   = find(ismember(season_storms, season));

if ~any(season_index)
    fprintf('No track with given season found.\n Unable to proceed.\n')
    return
end


%-------------------
% Figure
%-------------------
lon    = [tc_track(:).lon];
lat    = [tc_track(:).lat];

lon = [];
lat = [];
for track_i = season_index
    len                = length(tc_track(track_i).lon);
    lon(end+1:end+len) = tc_track(track_i).lon;
    lat(end+1:end+len) = tc_track(track_i).lat;
end

scale  =  max(lon)-min(lon);
scale2 = (max(lon)-min(lon))/(max(lat)-min(lat));

height = 0.5;
if height*scale2 > 1.2; height = 1.2/scale2; end
% fig = climada_figuresize(0.4,0.74);
fig = climada_figuresize(height,height*scale2);
% climada_plot_world_borders(0.7,{'India' 'Bangladesh' 'Myanmar (Burma)' 'Thailand' 'Nepal' 'Bhutan' 'Sri Lanka' 'China' 'Malaysia' 'Indonesia' 'Viet nam' 'Cambodia' 'Lao People''s Democratic Republic' 'Pakistan' 'Kashmir and Jammu (claimed by India and Pakistan)'})
climada_plot_world_borders(0.7,{'United States (USA)'})
hold on
axis([min(lon)-scale/30  max(lon)+scale/30 ...
      min(lat)-scale/30  max(lat)+scale/30])

xlabel('Longitude')
ylabel('Latitude')
if invisible; set(gcf,'Visible','off');end
for index_i = season_index %every track in specific season
    climada_plot_tc_track_stormcategory(tc_track(index_i),markersize);
end
%add legend
climada_plot_tc_track_stormcategory(0,markersize,1);
title({[int2str(season) ','];[int2str(length(season_index)) ' storms ']})
set(gca,'layer','top')
  
% axis([72 112 4 31])
% axis equal

if isempty(check_printplot)
    choice = questdlg('print?','print');
        switch choice
        case 'Yes'
            check_printplot = 1;
        case 'No'
            check_printplot = 0;
        case 'Cancel'
            return
        end
end   
if check_printplot
    foldername = ['\results\tc_tracks_' int2str(season) '.pdf'];
    print(fig,'-dpdf',[climada_global.data_dir foldername])    
    fprintf('FIGURE saved in folder %s \n', foldername); 
end

return