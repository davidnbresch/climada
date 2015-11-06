function climada_distribution_lon_lat(tc_track, check_printplot, check_printplot_2)
% distribution of start point longitude and latitude and difference in
% longitude and latitude
% NAME:
%   climada_distribution_lon_lat
% PURPOSE:
%   plot to visually control distribution of probabilistic to historical
%   track data
% CALLING SEQUENCE:
%   climada_distribution_lon_lat(tc_track_prob, check_printplot, check_printplot_2)
% EXAMPLE:
%   climada_distribution_lon_lat
%   climada_distribution_lon_lat([],1,1)
% INPUTS:
%   none
% OPTIONAL INPUT PARAMETERS:
%   tc_track_prob  :  probabilistic track set, if not given prompted for
%   check_printplot:  if set to 1 will print (save) figure, default 0
% OUTPUTS:
%   plot
% MODIFICATION HISTORY:
% Lea Mueller, 20110715
% david.bresch@gmail.com, 20120407, load(colormap) fixed, but still some Q.
%-

global climada_global
if ~climada_init_vars, return; end % init/import global variables
if ~exist('tc_track'         ,'var'), tc_track          = []   ; end
if ~exist('check_printplot'  ,'var'), check_printplot   = []   ; end
if ~exist('check_printplot_2','var'), check_printplot_2 = []   ; end


%% load interpolated and probabilistic data (6h timestep)
% %  historical tracks in the south western indian ocean, 448 tracks
% %  probabilistic tracks, 4480 tracks
% if isempty(tc_track_prob)
%     load([climada_global.data_dir '\tc_tracks\tc_tracks_mozambique_1978_2011_southwestindian_prob_V_4480'])
% end;

% prompt for probabilistic tc_track if not given
if isempty(tc_track)
    %load ([climada_global.data_dir
    %'\tc_tracks\tc_tracks_mozambique_1978_2011_southwestindian_cleaned_6h'])
    tc_track = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select PROBABILISTIC tc track set:');
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
end


no_hist      = sum([tc_track.orig_event_flag]);
no_generated = length(tc_track)/no_hist;


%% initial lon, lat for every track,
%  difference in lon, lat for every track node and track
x0 = [];
y0 = [];
xi = [];
yi = [];
for track_i = 1:no_generated:length(tc_track)
    x0(end+1) = tc_track(track_i).lon(1);
    y0(end+1) = tc_track(track_i).lat(1);
    
    xi_         = diff(tc_track(track_i).lon);
    xi(end+1:end+length(xi_)) = xi_;
    
    yi_         = diff(tc_track(track_i).lat);
    yi(end+1:end+length(yi_)) = yi_;  
end
clear xi_
clear yi_
clear track_i



x0_prob = [];
y0_prob = [];
xi_prob = [];
yi_prob = [];
for track_i = 1:length(tc_track)
    x0_prob(track_i) = tc_track(track_i).lon(1);
    y0_prob(track_i) = tc_track(track_i).lat(1);
    
    xi_         = diff(tc_track(track_i).lon);
    xi_prob(end+1:end+length(xi_)) = xi_;
    
    yi_         = diff(tc_track(track_i).lat);
    yi_prob(end+1:end+length(yi_)) = yi_;  
end
clear xi_
clear yi_
clear track_i




% define range of longitude and latitude
if min(x0)>0;    x_min = ceil(min(x0)/10)*10;  else    x_min = floor(min(x0)/10)*10;end
if max(x0)>0;    x_max = ceil(max(x0)/10)*10;  else    x_max = floor(max(x0)/10)*10;end

if min(y0)>0;    y_min = ceil(min(y0)/10)*10;  else    y_min = floor(min(y0)/10)*10;end
if max(y0)>0;    y_max = ceil(max(y0)/10)*10;  else    y_max = floor(max(y0)/10)*10;end

x_range = [x_min-30 x_max+30];
y_range = [y_min-10 y_max+10];



%---------------
%% FIGURE HISTOGRAMS
%---------------        
fprintf('preparing histogram of starting points and difference in longitude and latitude \n')

fig = climada_figuresize(0.6,0.75);
subaxis(2,2,1,'sv',0.1)
    % probabilistic set
    %[x0_count, x0_bin] = hist(x0_prob,[20:10:150]);
    [x0_count, x0_bin] = hist(x0_prob,[x_min:10:200]);
    bar(x0_bin, x0_count/sum(x0_count),'FaceColor',[139 131 134 ]/255,'EdgeColor','w')
    hold on
    
    % historical
    [x0_count, x0_bin] = hist(x0,[x_min:10:200]);
    plot(x0_bin, x0_count/sum(x0_count),':k')
    
    xlabel('Startpoint Longitude (?)')
    ylabel({['Relative count in'] ; [int2str(length(tc_track)) ' tc tracks']})
    ylim([0 0.31])
    xlim(x_range)
    set(subaxis(1),'layer','top','xtick',x_min:50:200,'ytick',0:0.1:0.4)
 
subaxis(2)
    % probabilistic set
    [xi_count, xi_bin] = hist(xi_prob,[-4:0.25:4]);
    h(2) = bar(xi_bin, xi_count/sum(xi_count),'FaceColor',[139 131 134 ]/255,'EdgeColor','w');
    hold on
    
    % historical
    [xi_count, xi_bin] = hist(xi,[-4:0.25:4]);
    h(1) = plot(xi_bin, xi_count/sum(xi_count),':k');
    
    xlabel('Difference in Longitude (?)')
    ylim([0 0.31])
    xlim([-4 4])
    legend(h,'Hist. data','Prob. data','location','ne')
    legend('boxoff')
    set(subaxis(2),'layer','top','xtick',-4:2:4,'ytick',0:0.1:0.4)


subaxis(3)
    % probabilistic set
    [y0_count, y0_bin] = hist(y0_prob,[y_min:2.5:100]);
    bar(y0_bin, y0_count/sum(y0_count),'FaceColor',[139 131 134 ]/255,'EdgeColor','w')
    hold on
    
    % historical
    %[y0_count, y0_bin] = hist(y0,[-40:2.5:0]);
    [y0_count, y0_bin] = hist(y0,[y_min:2.5:100]);
    plot(y0_bin, y0_count/sum(y0_count),':k')
    
    xlabel('Startpoint Latitude (?)')
    ylabel({['Relative count in'] ; [int2str(length(tc_track)) ' tc tracks']})
    ylim([0 0.31])
    %xlim([-35 5])
    xlim([y_range])
    set(subaxis(3),'layer','top','xtick',y_min:10:100,'ytick',0:0.1:0.4)
    
subaxis(4)
    % probabilistic set
    [yi_count, yi_bin] = hist(yi_prob,[-4:0.25:4]);
    bar(yi_bin, yi_count/sum(yi_count),'FaceColor',[139 131 134 ]/255,'EdgeColor','w')
    hold on
    
    % historical
    [yi_count, yi_bin] = hist(yi,[-4:0.25:4]);
    plot(yi_bin, yi_count/sum(yi_count),':k')
    
    xlabel('Difference in Latitude (?)')
    ylim([0 0.31])
    xlim([-4 4])
    set(subaxis(4),'layer','top','xtick',-4:2:4,'ytick',0:0.1:0.4)
    
if isempty(check_printplot)
    choice = questdlg('print?','print');
    switch choice
    case 'Yes'
        check_printplot = 1;
    case 'No'
        check_printplot = 0;
    case 'Cancel'
        check_printplot = 0;
    end
end   
if check_printplot
    %foldername  = ['\results\mozambique\tc_tracks\histogram_tracks_prob_lon_lat.pdf'];
    foldername  = [filesep 'results' filesep 'tc_tracks_histogram_tracks_prob_lon_lat.pdf'];
    print(fig, '-dpdf',[climada_global.data_dir foldername])
    fprintf('FIGURE saved in folder %s \n', foldername); 
end




%---------------
%% FIGURE MAP
%---------------

fprintf('preparing map of starting points \n')

% load colormap
colormap_file=[climada_global.system_dir filesep 'colormap_track_count'];
if exist(colormap_file,'file'),load(colormap_file);end

lon    = [tc_track(:).lon];
lat    = [tc_track(:).lat];

scale  = max(lon)-min(lon);
scale2 =(max(lon)-min(lon))/(min(max(lat),60)-max(min(lat),-50));

height = 0.4;
if height*scale2 > 1.2; height = 1.2/scale2; end
fig = climada_figuresize(height*2,height*scale2+0.1);
subaxis(2,1,1,'sv',0.1)
    [X, Y, H] = hist2d([x0; y0],20,10);
    %H(H==0) = nan;
    contourf(X,Y,H/sum(H(:))*100,0.1:0.5:10,'LineStyle','none')
    hold on
    climada_plot_world_borders

    if exist('track_count','var'),colormap(track_count);end
    
    axis([min(lon)-scale/30  max(lon)+scale/30 ...
          max(min(lat),-50)-scale/30  min(max(lat),60)+scale/30])
    caxis([0 6])
    
    title('Historical tracks')
    t = colorbar;
    set(get(t,'ylabel'),'String', 'Starting points in %');
    
subaxis(2)
    X = []; Y = []; H = [];
    [X, Y, H] = hist2d([x0_prob; y0_prob],20,10);
    %H(H==0) = nan;
    contourf(X,Y,H/sum(H(:))*100,0.1:0.5:10,'LineStyle','none')
    hold on
    climada_plot_world_borders

    if exist('track_count','var'),colormap(track_count);end

    axis([min(lon)-scale/30  max(lon)+scale/30 ...
          max(min(lat),-50)-scale/30  min(max(lat),60)+scale/30])
    caxis([0 6])
    
    title('Probabilistic tracks')
    t = colorbar;
    set(get(t,'ylabel'),'String', 'Starting points in %');
    
if isempty(check_printplot_2)
    choice = questdlg('print?','print');
    switch choice
    case 'Yes'
        check_printplot_2 = 1;
    case 'No'
        check_printplot_2 = 0;
    case 'Cancel'
        return
    end
end       
if check_printplot_2
    foldername  = [filesep 'results' filesep 'tc_tracks_map_starting_points.pdf'];
    print(fig, '-dpdf',[climada_global.data_dir foldername])
    fprintf('FIGURE saved in folder %s \n', foldername); 
end    

% colormapeditor
% track_count = get(fig,'colormap');
% save([climada_global.data_dir '\results\mozambique\tc_tracks\colormap_track_count'],'track_count')







%%
