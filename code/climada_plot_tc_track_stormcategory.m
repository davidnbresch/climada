function  [h] = climada_plot_tc_track_stormcategory(tc_track, markersize, check_legend, linewidth)
% plot tc track in colors according to saffir-simpson hurricane scale
% NAME:
%   climada_plot_tc_track_stormcategory
% PURPOSE:
%   plot tc track in colors according to saffir-simpson hurricane scale
%   provide handle of tc_track
% CALLING SEQUENCE:
%   [h] =
%   climada_plot_tc_track_stormcategory(tc_track,markersize,check_legend)
% EXAMPLE:
%   [h] =
%   climada_plot_tc_track_stormcategory(tc_track(1),10,1)
% INPUTS:
%	tc_track:        one or more tc_tracks (structure)
% OPTIONAL INPUT PARAMETERS:
%   markersize:      markersize of tc_track nodes, default 7   
%   check_legend:    if set to 1 legend of saffir-simpson hurricane scale
%   in upper left corner
% OUTPUTS:
%   h:               handle of tc_track nodes
% Lea Mueller, 20110603
%-

global climada_global
if ~climada_init_vars, return; end

% check inputs, and set default values
if ~exist('tc_track'    ,'var'), tc_track     = []  ; end
if ~exist('markersize'  ,'var'), markersize   = 7   ; end
if ~exist('linewidth'   ,'var'), linewidth    = 0.7 ; end
if ~exist('check_legend','var'), check_legend = 0   ; end

if isempty(markersize), markersize   = 7   ; end
if isempty(linewidth) , linewidth    = 0.7 ; end


% prompt for probabilistic tc_track if not given
if isempty(tc_track)
    tc_track         = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    tc_track_default = [climada_global.data_dir filesep 'tc_tracks' filesep 'select tc track .mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select tc track set:',tc_track_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track = fullfile(pathname,filename);
    end
    if ~isstruct(tc_track)
        tc_track_file = tc_track;
        tc_track      = [];
        vars = whos('-file', tc_track_file);
        load(tc_track_file);
        if ~strcmp(vars.name,'tc_track')
            tc_track = eval(vars.name);
            clear (vars.name)
        end
        prompt   ='Type specific No. of track to print windfield [e.g. 1, 10, 34]:';
        name     =' No. of track';
        defaultanswer = {'34'};
        answer = inputdlg(prompt,name,1,defaultanswer);
        track_no = str2double(answer{1});
        tc_track = tc_track(track_no);
    end
end
% if ~isstruct(tc_track)
%     tc_track_file = tc_track;
%     tc_track      = [];
%     vars = whos('-file', tc_track_file);
%     load(tc_track_file);
%     if ~strcmp(vars.name,'tc_track')
%         tc_track = eval(vars.name);
%         clear (vars.name)
%     end
%     prompt   ='Type specific No. of track to print windfield [e.g. 1, 10, 34]:';
%     name     =' No. of track';
%     defaultanswer = {'34'};
%     answer = inputdlg(prompt,name,1,defaultanswer);
%     track_no = str2double(answer{1});
%     tc_track = tc_track(track_no);
% end


%% Figures with color coding based on storm categories
if isfield(tc_track,'MaxSustainedWindUnit')
    switch tc_track.MaxSustainedWindUnit % to convert to km/h
        case 'km/h'
            tc_track.MaxSustainedWind = tc_track.MaxSustainedWind/1.15/1.61;
        case 'kt'
            tc_track.MaxSustainedWind = tc_track.MaxSustainedWind/1.15/1.61;
        otherwise
            % already kn
    end;
    tc_track.MaxSustainedWindUnit = 'kn'; % after conversion
end


v_categories = [34 64 83 96 113 135 1000]; %(unit kn)
colors_      = [ 99 184 255 ; %light blue  28 134 238 ; %blue
                  0 139   0 ; %green
                255 215   0 ; %yellow
                238 154   0 ; %dark yellow  
                238 118   0 ; %orange
                238  64   0 ; %red
                139  37   0 ; %dark red
                ]/255;


if isstruct(tc_track)
    track_count = length(tc_track);

    for track_i = 1:track_count %every track
        hold on
        for node_i = 1:length(tc_track(track_i).MaxSustainedWind)-1 %every node for specific track
            v       = tc_track(track_i).MaxSustainedWind(node_i);
            v_color = find (v < v_categories);
            if numel(v_color)>0
                v_color = v_color(1);
                h(node_i) = plot(tc_track(track_i).lon(node_i:node_i+1), tc_track(track_i).lat(node_i:node_i+1),...
                        '.-','color',colors_(v_color,:),'markersize',markersize,'linewidth',linewidth);
                %plot(tc_track(track_i).lon(node_i), tc_track(track_i).lat(node_i),...
                %'.','color','k','markersize',markersize-5);    
            end
        end
        if markersize <=3; markersize_start = 1;else markersize_start = markersize-3;end
        h(node_i+1) = plot(tc_track(track_i).lon(1), tc_track(track_i).lat(1),'or','markersize',markersize_start,'linewidth',linewidth);

    end
end

if check_legend %(>=1)
    f = plot(700,700,'or','markersize',markersize-3,'linewidth',linewidth);
    hold on
    for cat_i = 1:length(v_categories)
        %g(cat_i) = plot(700,700,'.','color',colors_(cat_i,:));
        g(cat_i) = plot(700,700,'o','color',colors_(cat_i,:),'markerfacecolor',colors_(cat_i,:),'markersize',markersize);
    end 
    legendstr = {'Begin','Trop. depression','Trop. storm','Hurricane 1','Hurricane 2','Hurricane 3','Hurricane 4','Hurricane 5'};
    
    %%L = legend([h(end) g],legendstr,'location','se');
    L = legend([f g],legendstr,'location','se');
    %L = legend([f g],legendstr,'location','north','orientation','horizontal');
    legend('boxoff')
    set(L,'FontSize',8);
end

return






