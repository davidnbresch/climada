function [damage,track_filename]=climada_tc_event_damage_ens(UNISYS_regi,UNISYS_year,UNISYS_name,n_tracks,call_from_GUI)
% MODULE:
%   advanced
% NAME:
%   climada_tc_event_damage_ens
% PURPOSE:
%   Given a single track file, calculate the damage for all countries
%   posibbly hit (i.e. at least one node within country boders)
%
%   Plus generate ensemble 'forecast' damage
%
%   Fetches data from: weather.unisys.com/hurricane, but since the format
%   and layout of the webpage changed, it only works back to about 2006...
%   earier years will,likely lead to errors. In such cases, retrieve the TC
%   track file manually and run the code by passing the track file in the
%   first variable (UNISYS_regi)
%
%   See also climada_tc_event_damage_ens_gui
% CALLING SEQUENCE:
%   [damage,track_filename]=climada_tc_event_damage_ens(UNISYS_regi,UNISYS_year,UNISYS_name,n_tracks,call_from_GUI)
% EXAMPLE:
%   damage=climada_tc_event_damage_ens('w_pacific','2015','KOPPU',5)
%   [damage,track_filename]=climada_tc_event_damage_ens('','NONE','NONE',5) % prompt for track file
% INPUTS:
%   UNISYS_regi: the UNISYS region, i.e. 'atlantic','e_pacific','w_pacific'
%       's_pacific','s_indian' or 'n_indian'
%       SPECIAL: if a TC track filename (with path) is passed instead of a region
%       and UNISYS_year and UNISYS_name are both set to 'NONE', the track file
%       is used. This way, any TC track file can be passed as input.
%   UNISYS_year: the year yyyy (as string). Note that years before 2006
%       likely do not work properly (since UNISYS changed the layout of
%       their webpage and the code reads the html source to figure the
%       event names...). If set to 'NONE' together with UNISYS_name, the
%       user gets prompted for the TC track file
%   UNISYS_name: the name of the event (without Hurricane-1 ..., usually uppercase).
%       If set to 'NONE' together with UNISYS_year, the user gets prompted
%       for the TC track file.
%   >   if all three parameters above are empty: Select the region and event
%       from selection lists, the single TC track file is downloaded from
%       UNISYS and processed
%   n_tracks: number of tracks (incl original one), default=100
%   call_from_GUI: switch to direct to the correct axes
%       if empty, not called from GUI, otherwise contains the axes handles
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   damage: the vector with the calculated damages, damage(1) is the one
%       for the reported track, all following ones for ensemble members
%   track_filename: the TC track filename with path
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20151009, initial
% David N. Bresch, david.bresch@gmail.com, 20151018, automatic country detection
% David N. Bresch, david.bresch@gmail.com, 20151019, converted into a function, see also climada_tc_event_damage_ens_gui
% David N. Bresch, david.bresch@gmail.com, 20151021, special case for no web access added

damage=[];track_filename=''; % init output

% init global variables
global climada_global
if ~climada_init_vars,return;end

% poor man's version to check arguments
if ~exist('UNISYS_regi','var'),UNISYS_regi='';end
if ~exist('UNISYS_year','var'),UNISYS_year='';end
if ~exist('UNISYS_name','var'),UNISYS_name='';end
if ~exist('n_tracks','var'),   n_tracks   =100;end % number of tracks (incl original one)
if ~exist('call_from_GUI','var'),call_from_GUI=[];end

% PARAMETERS
%
% for experimenting, you might set parameters here (otherwise asked at first call)
% track_filename = [climada_global.data_dir filesep 'tc_tracks' filesep '20071116_SIDR_track.dat'];
% country_name='Bangladesh';
%
FontSize=12; % 18 for plots for e.g. pptx
%
% UNISYS regions (hard-wired)
UNISYS_regis{1}='atlantic';
UNISYS_regis{2}='e_pacific';
UNISYS_regis{3}='w_pacific';
UNISYS_regis{4}='s_pacific';
UNISYS_regis{5}='s_indian';
UNISYS_regis{6}='n_indian';

if strcmpi(UNISYS_name,'nowebaccess>presscalculatebutton')
    % special case to select local file
    UNISYS_name='NONE';
    UNISYS_year='NONE';
end

if isempty(UNISYS_name)
    
    if isempty(UNISYS_regi)
        % prompt for the region
        [selection,ok] = listdlg('PromptString','Select region:',...
            'ListString',UNISYS_regis,'SelectionMode','SINGLE');
        pause(0.1)
        if ok
            UNISYS_regi=UNISYS_regis{selection};
        end
    end % isempty(UNISYS_regi)
    
    if isempty(UNISYS_year)
        % UNISYS year (usually the actual one)
        UNISYS_year=datestr(today,'yyyy'); % e.g. '2015'
    end
    
    % fetch the index of all events
    url_str=['http://weather.unisys.com/hurricane/' UNISYS_regi '/' UNISYS_year '/index.php'];
    fprintf('fetching %s\n',url_str);
    [index_str,STATUS] = urlread(url_str);
    if STATUS
        % kind of parse index_str to get names
        UNISYS_names={};
        for event_i=100:-1:1
            for black_red=1:2
                if black_red==1
                    check_str=['<tr><td width="20" align="right" style="color:black;">' num2str(event_i) '</td><td width="250" style="color:black;">'];
                else
                    check_str=['<tr><td width="20" align="right" style="color:red;">' num2str(event_i) '</td><td width="250" style="color:red;">'];
                end
                
                pos=strfind(index_str,check_str);
                if pos>0
                    UNISYS_names{end+1}=index_str(pos+length(check_str):pos+length(check_str)+25);
                end
            end % black_red
        end % event_i
        
        [selection,ok] = listdlg('PromptString','Select event:',...
            'ListString',UNISYS_names,'SelectionMode','SINGLE');
        pause(0.1)
        if ok
            UNISYS_name=UNISYS_names{selection};
            % get rid of all clutter
            UNISYS_name=strrep(UNISYS_name,'Super ','');
            UNISYS_name=strrep(UNISYS_name,'Tropical Depression','');
            UNISYS_name=strrep(UNISYS_name,'Tropical Storm','');
            UNISYS_name=strrep(UNISYS_name,'Typhoon-1','');
            UNISYS_name=strrep(UNISYS_name,'Typhoon-2','');
            UNISYS_name=strrep(UNISYS_name,'Typhoon-3','');
            UNISYS_name=strrep(UNISYS_name,'Typhoon-4','');
            UNISYS_name=strrep(UNISYS_name,'Typhoon-5','');
            UNISYS_name=strrep(UNISYS_name,'Hurricane-1','');
            UNISYS_name=strrep(UNISYS_name,'Hurricane-2','');
            UNISYS_name=strrep(UNISYS_name,'Hurricane-3','');
            UNISYS_name=strrep(UNISYS_name,'Hurricane-4','');
            UNISYS_name=strrep(UNISYS_name,'Hurricane-5','');
            UNISYS_name=strrep(UNISYS_name,'Cyclone-1','');
            UNISYS_name=strrep(UNISYS_name,'Cyclone-2','');
            UNISYS_name=strrep(UNISYS_name,'Cyclone-3','');
            UNISYS_name=strrep(UNISYS_name,'Cyclone-4','');
            UNISYS_name=strrep(UNISYS_name,'Cyclone-5','');
            UNISYS_name=strrep(UNISYS_name,' ','');
            UNISYS_name=strrep(UNISYS_name,' ','');
        else
            return
        end
    else
        UNISYS_name='NONE';
    end
end % isempty(UNISYS_name)

if strcmp(UNISYS_name,'NONE')
    track_filename=''; % force prompting for track file
    if exist(UNISYS_regi,'file'),track_filename=UNISYS_regi;end
else
    % fetch the tc track data from the internet
    url_str=['http://weather.unisys.com/hurricane/' UNISYS_regi '/' UNISYS_year '/' UNISYS_name '/track.dat'];
    fprintf('fetching %s\n',url_str);
    track_data_str = urlread(url_str);
    track_filename=[climada_global.data_dir filesep 'tc_tracks' filesep  UNISYS_regi '_' UNISYS_year '_' UNISYS_name '.dat'];
    fprintf('saving as %s\n',track_filename);
    fid=fopen(track_filename,'w');
    % write to single track file
    fprintf(fid,'%s\r\n',track_data_str);
    fclose(fid);
end

% get TC track (prompting for file to be selected)
[tc_track,track_filename]=climada_tc_read_unisys_track(track_filename);

% automatically detec country/ies
country_list={};
shapes=climada_shaperead(climada_global.map_border_file); % get country shapes
for shape_i = 1:length(shapes)
    in = inpolygon(tc_track.lon,tc_track.lat,shapes(shape_i).X,shapes(shape_i).Y);
    if sum(in)>0
        country_list{end+1}=shapes(shape_i).NAME;
    end
end % shape_i

if isempty(country_list) % prompt for country, as no direct hit
    country_list{1}=climada_country_name('SINGLE'); % obtain country
end

for country_i=1:length(country_list)
    %for country_i=1:1
    
    country_name=char(country_list{country_i});
    
    fprintf('*** processing %s:\n',country_name);
    
    if isempty(country_name) % usually not the case any more, but left in, in case one would like to use this
        [country_name,country_ISO3,~]=climada_country_name('SINGLE'); % obtain country
    else
        [country_name,country_ISO3,~]=climada_country_name(country_name); % just get ISO3
    end
    country_name=char(country_name);
    country_ISO3=char(country_ISO3);
    
    tc_tracks=climada_tc_random_walk(tc_track,n_tracks-1,0.1,pi/30); % /15
    
    % get entity and centroids
    entity=climada_entity_load([country_ISO3 '_' strrep(country_name,' ','') '_entity']);
    centroids=climada_centroids_load([country_ISO3 '_' strrep(country_name,' ','') '_centroids']);
    %entity=climada_assets_encode(entity,centroids);
    
    if isempty(call_from_GUI)
        figure('Name',['TC ensemble ' country_name],'Position',[199 55 1076 618],'Color',[1 1 1]);
        subplot(1,2,1)
    else
        cla(call_from_GUI.axes_left)
        axes(call_from_GUI.axes_left);
    end
    
    climada_entity_plot(entity,4)
    % plot(tc_track.lon,tc_track.lat,'-r');axis equal; hold on
    % climada_plot_world_borders(1,country_name,'',1)
    plot(tc_track.lon,tc_track.lat,'-r')
    plot(tc_track.lon(logical(tc_track.forecast)),tc_track.lat(logical(tc_track.forecast)),'xr')
    
    for track_i=1:length(tc_tracks),plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b');end
    plot(tc_tracks(1).lon,tc_tracks(1).lat,'-r','LineWidth',2); % orig track
    axis off
    xlabel('red crosses: forecast timesteps, blue:ensemble members','FontSize',8);
    title(country_name,'FontSize',FontSize,'FontWeight','normal');drawnow
    
    if isempty(call_from_GUI)
        subplot(1,2,2)
    else
        cla(call_from_GUI.axes_right)
        axes(call_from_GUI.axes_right);
    end
    damage=zeros(1,length(tc_tracks)); % allocate
    n_tracks=length(tc_tracks);
    for track_i=1:n_tracks
        hazard=climada_tc_hazard_set(tc_tracks(track_i),'NOSAVE',centroids);
        hazard.frequency=1;
        EDS(track_i)=climada_EDS_calc(entity,hazard);
        damage(track_i)=EDS(track_i).damage;
        calc_sec=str2double(strtok(strrep(EDS(track_i).comment,'calculation took ',''),'sec'));
        cla;text(0.1,0.5,sprintf('%i seconds calculation remaining (%i tracks)',...
            ceil((n_tracks-track_i)*calc_sec),n_tracks-track_i),'FontSize',FontSize);drawnow
        %fprintf('%i seconds calculation remaining\n',ceil((length(tc_tracks)-track_i)*calc_sec));
    end % track_i
    
    hist(damage); % plot
    [counts,~]=hist(damage); % get info
    set(gca,'FontSize',FontSize),xlabel('damage [USD]','FontSize',FontSize),ylabel('event count','FontSize',FontSize)
    hold on;plot(damage(1),0,'xr');
    ddamage=(max(damage)-min(damage))/(2*length(counts));
    text(damage(1)+ddamage,1,'damage','Rotation',90,'Color','red','FontSize',FontSize);
    [~,track_i] = max(damage);
    tc_track_name=lower(tc_track.name);
    title([[upper(tc_track_name(1)) tc_track_name(2:end)]  ' @ ' country_name],'FontSize',FontSize,'FontWeight','normal');drawnow
    %plot(damage(track_i),0,'xb');
    %text(damage(track_i),0,'max ensemble damage','Rotation',90);
    if isempty(call_from_GUI)
        subplot(1,2,1);hold on;
    else
        axes(call_from_GUI.axes_left);
        hold on
    end
    plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b','LineWidth',2); % max damage track
    
    call_from_GUI=[]; % second plot in new figure
    
end % country_i