function tc_track = climada_plot_ACE(tc_track, name_tag, check_printplot)
% ---------------------------------------------
%% ACCUMULATED CYCLONE ENERGY ACE
% % The ACE of a season is calculated by 
% % summing the squares of the estimated maximum sustained velocity of
% % - every active tropical storm (wind speed 35 knots (65 km/h) or higher),
% % - at six-hour intervals. 
% ---------------------------------------------
%
% plot histograms of Accumulated Cyclone Energy ACE, No. of storms per
% seasons, No. of hurricanes and No. of major hurricanes per season of
% probabilistic tracks, with historical tracks indicated with dotted black
% lines
% NAME:
%   climada_plot_ACE
% PURPOSE:
%   given a probabilistic tc_track structure, histograms of ACE, No. storms,
%   hurricanes and major hurricanes per season and compare with historical
%   histograms (black dotted lines), check distributions
%   ACE of a season is calculated by summing the squares of the estimated 
%   maximum sustained velocity of
%   - every active tropical storm (wind speed 35 knots (65 km/h) or higher),
%   - at six-hour intervals. 
% 
%   previous step:  generation of probabilistic tracks, 
%   tc_track_prob = climada_tc_random_walk_position_windspeed;
%   next step:      
% CALLING SEQUENCE:
%   climada_plot_ACE(tc_track, name_tag, check_printplot)
% EXAMPLE:
%   climada_plot_ACE(tc_track_prob, '4480', 1)
% INPUTS:
%   tc_track: probabilistic tc track set (random walk of wind speed, 
%   longitude and latitude), wind speed in knots, nodes every six hours
% OPTIONAL INPUT PARAMETERS:
%   name_tag:        string that will be used for name of printed pdf
%   check_printplot: if set to 1 will print (save) figure
% OUTPUTS:
%   figure, printout of figure if requested
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Lea Mueller, 20110621
% davids.bresch@gmail.com, 20120407
%-



global climada_global
if ~climada_init_vars, return; end % init/import global variables
if ~exist('tc_track'       , 'var'), tc_track        = []   ; end
if ~exist('name_tag'       , 'var'), name_tag        = ''   ; end
if ~exist('check_printplot', 'var'), check_printplot = []   ; end


% prompt for probabilistic tc_track if not given
if isempty(tc_track)
    tc_track         = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    tc_track_default = [climada_global.data_dir filesep 'tc_tracks' filesep 'select PROBABILISTIC track .mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select PROBABILISTIC tc track set:',tc_track_default);
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





%% check 6 hours records interval
unequal_timestep = 0;
for track_i = 1:length(tc_track)
    time_step_max = max(tc_track(track_i).TimeStep);
    time_step_min = min(tc_track(track_i).TimeStep);
    if time_step_max ~= 6
        fprintf('time steps are not equal to 6 h, \n check track no %i \n',track_i)
        tc_track(track_i) = climada_tc_equal_timestep(tc_track(track_i),6);
        %return
    end
    if time_step_min ~= 6
        fprintf('time steps are not equal to 6 h, \n check track no %i \n',track_i)
        tc_track(track_i) = climada_tc_equal_timestep(tc_track(track_i),6);
        %return
    end
end

    
%% check wind speed record in knots
for track_i = 1:length(tc_track)
    if strcmp(tc_track(track_i).MaxSustainedWindUnit,'kn') ~= 1
        fprintf('Wind not recorded in kn, conversion to kn needed')
        return
    end
end


%% add category for each track
if ~isfield(tc_track, 'category')
    tc_track = climada_tc_stormcategory(tc_track);
    fprintf('field tc_track.category added \n')
end

%% add season for each track
if ~isfield(tc_track, 'season')
    [tc_track, seasons] = climada_tc_season(tc_track);
    fprintf('field tc_track.season added \n')
end

%% allocate tracks to cyclone season
% %  cyclone season: 1 July     to 30 June
% [a seasons] = climada_tc_season(tc_track);
% seasons = [tc_track(:).yyyy];


%% create vector with season, category and max_wind
for track_i = 1:length(tc_track)
    season_storm(track_i) = tc_track(track_i).season;
    cat_storms  (track_i) = tc_track(track_i).category;
    max_wind              = max(tc_track(track_i).MaxSustainedWind);
end

season_storm = [tc_track(:).season];
seasons      = unique(season_storm); 
seasons_plot = seasons;
seasons_plot(seasons_plot>2012) = seasons_plot(seasons_plot>2012) - 17768;



%% counts and ACE
season_count = length(seasons);
ACE          = zeros(season_count,1);
TS_count     = zeros(season_count,1);
Hur_count    = zeros(season_count,1);
Hur3_count   = zeros(season_count,1);

for season_i = 1:season_count
    season_index = find( season_storm == seasons(season_i));
    TS_count(season_i) = length(season_index);
    
    for index_i = 1:length(season_index)
        % find max sustained wind greater or equal 35 kn
        v_35kn        = tc_track(season_index(index_i)).MaxSustainedWind(tc_track(season_index(index_i)).MaxSustainedWind >= 35);
        ACE_track_i   = sum(v_35kn.^2)*10^-4;
        ACE(season_i) = ACE(season_i) + ACE_track_i;
        if tc_track(season_index(index_i)).category>=1
            Hur_count(season_i)  =  Hur_count(season_i) +1;
        end
        if tc_track(season_index(index_i)).category>=3
            Hur3_count(season_i) =  Hur3_count(season_i) +1;
        end
    end
end

counts        = [ACE TS_count Hur_count Hur3_count];
counts_sorted = sort(counts,'descend');
counts_max    = max(counts);
if counts_max(1) > 500; counts_max(1) = 500; end

%counts_ori        = counts(1:34,:); % hard-wired, seems incorrect, LEA TO CHECK
% I guess the first part of counts contains the orig ones, second part the
% probab. But in this case, one needs to dynamically figure out up to wich
% index the orig counts are stored...
counts_ori        = counts(:,:);


%----------------------
%% figure distribution histogram 
%----------------------

% fig = climada_figuresize(0.7,0.5);
fig = climada_figuresize(0.6,0.75);
subaxis(2,2,1,'sv',0.1)
    % probabilistic set
    [ACE_count, ACE_bin] = hist(counts(:,1),[0:20:counts_max(1)+20]);
    p = bar(ACE_bin, ACE_count/sum(ACE_count),'FaceColor',[139 131 134 ]/255,'EdgeColor','w');
    hold on
    
    % historical
    [ACE_count, ACE_bin] = hist(counts_ori(:,1),[0:20:counts_max(1)+20]);
    h = plot([0 ACE_bin], [0 ACE_count/sum(ACE_count)],':xk');
    
    legend([h p],'historical','probabilistic','location','ne')
    legend('boxoff')
    xlabel('ACE (10^4 kn^2)')
    ylabel(['Relative count in ' int2str(season_count) ' seasons'])
    ymax = max(ACE_count/sum(ACE_count))*1.4; % to allow for legend to be visible
    ylim([0 ymax])
    %ylim([0 0.32])
    xlim([-20 counts_max(1)+20])
    set(subaxis(1),'layer','top','xtick',0:80:counts_max(1)+20)

subaxis(2)
    % probabilistic set
    [No_count, No_bin] = hist(counts(:,2),[0:2:counts_max(2)+2]);
    bar(No_bin, No_count/sum(No_count),'FaceColor','b','EdgeColor','w')
    hold on
    
    % historical
    [No_count, No_bin] = hist(counts_ori(:,2),[0:2:counts_max(2)+2]);
    plot([0 No_bin], [0 No_count/sum(No_count)],':xk')
    
    xlabel('No. trop. storms')
    %%ylim([0 ymax])
    %ylim([0 0.32])
    xlim([-2 counts_max(2)+2])
    set(subaxis(2),'layer','top')
    
subaxis(3)
    % probabilistic set
    [No_count, No_bin] = hist(counts(:,3),[0:2:counts_max(2)+1]);
    bar(No_bin, No_count/sum(No_count),'FaceColor',[255 165 0]/255,'EdgeColor','w')
    hold on

    % historical
    [No_count, No_bin] = hist(counts_ori(:,3),[0:2:counts_max(2)+1]);
    plot([0 No_bin], [0 No_count/sum(No_count)],':xk')

    xlabel('No. hurricanes')
    ylabel(['Relative count in ' int2str(season_count) ' seasons'])
    %ylim([0 0.32])
    %%ylim([0 ymax])
    xlim([-2 counts_max(2)+2])
    set(subaxis(3),'layer','top','xtick',[0:4:counts_max(2)+1])
    
subaxis(4)
    % probabilistic set
    [No_count, No_bin] = hist(counts(:,4),[0:1:counts_max(2)+1]);
    bar(No_bin, No_count/sum(No_count),'FaceColor','r','EdgeColor','w')
    hold on

    % historical
    [No_count, No_bin] = hist(counts_ori(:,4),[0:1:counts_max(2)+1]);
    plot([0 No_bin], [0 No_count/sum(No_count)],':xk')

    xlabel('No. major hurricanes')
    %ylim([0 0.32])
    %ylim([0 ymax])
    xlim([-2 counts_max(2)+2])
    set(subaxis(4),'layer','top')
    
%overall title
ha = axes('Position',[0 0.93 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off', 'Visible','off', 'Units','normalized', 'clipping','off');    
text(0.5, 0,name_tag,'fontsize',12,'fontweight','bold','HorizontalAlignment','center','VerticalAlignment', 'bottom')

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
    %foldername  = ['\results\mozambique\tc_tracks\histogram_tracks_prob_' name_tag '.pdf'];
    foldername  = ['\results\histogram_tracks_prob_' name_tag '.pdf'];
    print(fig,'-dpdf',[climada_global.data_dir foldername])
    fprintf('FIGURE saved in folder %s \n', foldername);    
end



%%


%----------------------
%% figure counts per season
%----------------------
% fig = mozambique_figuresize(0.5,0.6);
% subaxis(3,1,1,1,1,1)
%     %plot(seasons,ACE,'.-k')
%     bar(seasons_plot,ACE,0.5,'facecolor',[139 131 134 ]/255,'edgecolor','none');
%     hold on
%     plot([seasons_plot(1)-1 seasons_plot(end)+1],mean(ACE)*ones(2,1),'-k')
%     plot([seasons_plot(1)-1 seasons_plot(end)+1],(mean(ACE)+std(ACE))*ones(2,1),':k')
%     plot([seasons_plot(1)-1 seasons_plot(end)+1],(mean(ACE)-std(ACE))*ones(2,1),':k')
%     ylabel('ACE  (10^4 kn^2)')
%     xlim([seasons_plot(1)-1 seasons_plot(end)+1])
%     set(subaxis(3,1,1,1,1,1),'layer','top')    
% subaxis(3,1,1,2,1,2)
%     area(seasons,TS_count,'facecolor','b','edgecolor','none')
%     hold on
%     area(seasons,Hur_count,'facecolor',[255 165 0]/255,'edgecolor','none')
%     area(seasons,Hur3_count,'facecolor','r','edgecolor','none')
%     ylabel('No. storms incl. generated')
%     %ylabel('No. trop. storms, hurricanes and major hurricanes')
%     xlim([seasons(1)-1 seasons(end)+1])
%     ylim([0 230])
%     %ylim([0 10])
%     legend('No. trop. storms','No. hurricanes','No. major hurricanes','location','ne')
%     legend('boxoff')
%     set(subaxis(3,1,1,2,1,2),'layer','top')    
% 
% if check_printplot
%     % foldername  = ['\results\mozambique\tc_tracks\count_tracks_60.pdf'];
%     foldername  = ['\results\mozambique\tc_tracks\count_tracks_gen_' name_tag '.pdf'];
%     print(fig,'-dpdf',[climada_global.data_dir foldername])
%     fprintf('FIGURE saved in folder %s \n', foldername);    
% end


%%





