function [damage,track_filename,err_msg]=climada_tc_event_damage_ens(UNISYS_regi,UNISYS_year,UNISYS_name,n_tracks,auto_sel_assets,call_from_GUI)
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
%   [damage,track_filename]=climada_tc_event_damage_ens(UNISYS_regi,UNISYS_year,UNISYS_name,n_tracks,auto_sel_assets,call_from_GUI)
% EXAMPLE:
%   damage=climada_tc_event_damage_ens('w_pacific','2015','KOPPU',5)
%   [damage,track_filename]=climada_tc_event_damage_ens('','NONE','NONE',5) % prompt for track file
%   climada_tc_event_damage_ens('atlantic','2017','HARVEY',5,'United States'); % no GUI at all
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
%   auto_sel_assets: whether the code automatically selects assets 
%       (=1) or not (=0, default)
%       OR: a valid country name, exact spelling as in climada_country_name('SINGLE')
%       If =0, the last menu entry is 'browse for assets...' which opens a
%       file dialog to select any entity (as .mat)
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
% David N. Bresch, david.bresch@gmail.com, 20161009, massive speedup using only assets in vicinity of track
% David N. Bresch, david.bresch@gmail.com, 20161009, auto_sel_assets added
% David N. Bresch, david.bresch@gmail.com, 20170828, explicit country name in auto_sel_assets added
% David N. Bresch, david.bresch@gmail.com, 20170830, ability to browse for entity (last menu entry)
%-

damage=[];track_filename='';err_msg=''; % init output

% init global variables
global climada_global
if ~climada_init_vars,return;end

% poor man's version to check arguments
if ~exist('UNISYS_regi','var'),UNISYS_regi        ='';end
if ~exist('UNISYS_year','var'),UNISYS_year        ='';end
if ~exist('UNISYS_name','var'),UNISYS_name        ='';end
if ~exist('n_tracks','var'),   n_tracks           =100;end % number of tracks (incl original one)
if ~exist('auto_sel_assets','var'),auto_sel_assets=0;end % number of tracks (incl original one)
if ~exist('call_from_GUI','var'),call_from_GUI    =[];end

% PARAMETERS
%
% for experimenting, you might set parameters here (otherwise asked at first call)
% track_filename = [climada_global.data_dir filesep 'tc_tracks' filesep '20071116_SIDR_track.dat'];
% country_name='Bangladesh';
%
FontSize=12; % 18 for plots for e.g. pptx
%
% width of bounding box (BB) around track
BB_width_degree=5;
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

% resolve issue with +/-180 at dateline
tc_track.lon=climada_dateline_resolve(tc_track.lon);

if ischar(auto_sel_assets)
    country_list{1}=auto_sel_assets;
elseif auto_sel_assets
    % automatically detect country/ies
    country_list={};
    shapes=climada_shaperead(climada_global.map_border_file); % get country shapes
    for shape_i = 1:length(shapes)
        %in = inpolygon(tc_track.lon,tc_track.lat,shapes(shape_i).X,shapes(shape_i).Y); % until 20170828
        in = climada_inpolygon(tc_track.lon,tc_track.lat,shapes(shape_i).X,shapes(shape_i).Y);
        if sum(in)>0
            country_list{end+1}=shapes(shape_i).NAME;
        end
    end % shape_i
else
    country_list=''; % force prompting
end

if isempty(country_list) % prompt for country, as no direct hit
    country_list{1}=climada_country_name('SINGLE','Select entity ...'); % obtain country
    if isempty(country_list{1}),return;end
end

for country_i=1:length(country_list)
    
    country_name=char(country_list{country_i});
    
    if strcmpi (country_name,'Select entity ...')
        entity_file=[climada_global.entities_dir filesep '*.mat'];
        [filename, pathname] = uigetfile(entity_file, 'Select entity:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            entity_file=fullfile(pathname,filename);
        end
    else
        fprintf('*** processing %s:\n',country_name);
        [country_name,country_ISO3,~]=climada_country_name(country_name); % just get ISO3
        country_name=char(country_name);
        country_ISO3=char(country_ISO3);
        
        %entity_filename=[country_ISO3 '_' strrep(country_name,' ','') '_entity']; % until 20170828
        entity_filename=[country_ISO3 '_' strrep(country_name,' ','') '_10x10']; % since 20170828
        entity_file=[climada_global.entities_dir filesep entity_filename '.mat'];
    end
    
    tc_tracks=climada_tc_random_walk(tc_track,n_tracks-1,0.1,pi/30); % /15
    
    if exist(entity_file,'file')
        fprintf('loading %s ...\n',entity_file);
        entity=climada_entity_load(entity_file);
    else
        % try to create the entity
        %if exist('climada_create_GDP_entity','file')
        % until 20170828: invoke the country_risk module to generate the entity
        % since 20170828: use core climada (10x10km)
        fprintf('*** creating %s (takes a moment)\n\n',entity_filename)
        if ~isempty(call_from_GUI)
            cla(call_from_GUI.axes_left)
            axes(call_from_GUI.axes_left);
            text(0.1,0.5,' creating assets (takes a moment) ...','FontSize',FontSize);drawnow
        end
        entity=climada_nightlight_entity(country_name); % 20170828, use core climada
        % [~,entity] = climada_create_GDP_entity(country_name,[],0,1);
        % save(entity_file,'entity');
        % climada_entity_value_GDP_adjust(entity_file); % assets based on GDP
        % entity=climada_entity_load(entity_file);
        fprintf('%s created\n\n',entity_filename)
        %else
        %    fprintf(['%s not found. Please download ' ...
        %        '<a href="https://github.com/davidnbresch/climada_module_country_risk">' ...
        %        'climada_module_country_risk</a> from Github in order to create it.\n'],entity_filename)
        %    err_msg=sprintf('Please create %s entity first, see command line',country_name);
        %    return
        %end
    end % exist(entity_file,'file')
    fprintf('estimate based on assets from %s\n',entity_file);
    
    % resolve issue with +/-180 at dateline
    entity.assets.lon=climada_dateline_resolve(entity.assets.lon);
    
    if isempty(call_from_GUI)
        figure('Name',['TC ensemble ' country_name],'Position',[199 55 1076 618],'Color',[1 1 1]);
        subplot(1,2,1)
    else
        cla(call_from_GUI.axes_left)
        axes(call_from_GUI.axes_left);
    end
    
    % restrict entity to a reasonable area around the track (speedup)
    n_assets=length(entity.assets.lon);
    if n_assets>5000
        milo=min(tc_track.lon)-BB_width_degree;malo=max(tc_track.lon)+BB_width_degree;
        mila=min(tc_track.lat)-BB_width_degree;mala=max(tc_track.lat)+BB_width_degree;
        vx=[milo milo malo malo milo];
        vy=[mila mala mala mila mila];
        in=inpolygon(entity.assets.lon,entity.assets.lat,vx,vy);
        entity.assets.lon=entity.assets.lon(in);
        entity.assets.lat=entity.assets.lat(in);
        entity.assets.Value=entity.assets.Value(in);
        entity.assets.DamageFunID=entity.assets.DamageFunID(in);
        entity.assets.Deductible=entity.assets.Deductible(in);
        entity.assets.Cover=entity.assets.Cover(in);
        if isfield(entity.assets,'isgridpoint'),entity.assets.isgridpoint=entity.assets.isgridpoint(in);end
        if isfield(entity.assets,'Value_today'),entity.assets=rmfield(entity.assets,'Value_today');end
        entity.assets.centroid_index=1:length(entity.assets.lon);
        if isfield(entity.assets,'distance2coast_km'),entity.assets.distance2coast_km=entity.assets.distance2coast_km(in);end
        fprintf('entity restricted from %i to %i points (%i%%)\n',...
            n_assets,length(entity.assets.lon),ceil(length(entity.assets.lon)/n_assets*100));
    end
    
    Value_unit=climada_global.Value_unit;
    if isfield(entity.assets,'Value_unit'),Value_unit=entity.assets.Value_unit{1};end
    
    % plot assets and tracks
    % ----------------------
    params.figure_scale=0;climada_entity_plot(entity,4,params);hold on
    plot(tc_track.lon,tc_track.lat,'-r')
    plot(tc_track.lon(logical(tc_track.forecast)),tc_track.lat(logical(tc_track.forecast)),'xr')
    for track_i=1:length(tc_tracks),plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b');end
    plot(tc_tracks(1).lon,tc_tracks(1).lat,'-r','LineWidth',2); % orig track
    axis off
    ylabel('');
    xlabel('red: forecast timesteps, blue: ensemble members','FontSize',8);
    title(country_name,'FontSize',FontSize,'FontWeight','normal');
    
    if isempty(call_from_GUI)
        subplot(1,2,2)
        axis off
    else
        cla(call_from_GUI.axes_right)
        axes(call_from_GUI.axes_right);
    end
    
    % create hazard set
    cla;text(0.5,0.5,sprintf('generating hazard set ...'),'FontSize',FontSize);drawnow
    hazard=climada_tc_hazard_set(tc_tracks,'NOSAVE',entity);
    
    % calculate EDS
    cla;text(0.5,0.5,sprintf('calculating damages ...'),'FontSize',FontSize);drawnow
    EDS=climada_EDS_calc(entity,hazard);
    damage=EDS.damage;
    
    if sum(damage)>0
        [counts,X]=hist(damage); % get info
        cla;bar(X,counts);hold on;
        set(gca,'FontSize',FontSize),xlabel(['damage [' Value_unit ']'],'FontSize',FontSize),ylabel('event count','FontSize',FontSize)
        plot(damage(1),0,'xr');xlim([0,max(damage)]);y_lim=ylim;
        ddamage=(max(damage)-min(damage))/(2*length(counts));
        x_pos=damage(1)+ddamage;
        y_pos=(y_lim(end)-y_lim(1))*.2;
        text(x_pos,y_pos,'original track damage','Rotation',90,'Color','red','FontSize',FontSize);
        [~,track_i] = max(damage);
        msg_str1=sprintf('original track: %3.2g [%s]',damage(1),Value_unit);
        msg_str2=sprintf('min/max: %3.2g / %3.2g',min(damage),max(damage));
        x_pos=(max(damage)-min(damage))/5;
        y_pos=(y_lim(end)-y_lim(1))/1.75;
        text(x_pos,y_pos,msg_str1,'Color','r','FontSize',FontSize);
        text(x_pos,y_pos*0.85,msg_str2,'Color','b','FontSize',FontSize);
        fprintf('%s %s\n',msg_str1,msg_str2);
    else
        xlim([0 1]);ylim([0 1]);
        text(.2,.5,'no damage','Color','r','FontSize',FontSize);
        axis off
    end
    tc_track_name=lower(tc_track.name);
    title([[upper(tc_track_name(1)) tc_track_name(2:end)]  ' @ ' country_name],'FontSize',FontSize,'FontWeight','normal');
    
    if ~climada_global.octave_mode
        if isempty(call_from_GUI)
            subplot(1,2,1); % does clear the axes in Octave
        else
            axes(call_from_GUI.axes_left);
        end
        hold on;plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b','LineWidth',2); % max damage track
    end
    
    drawnow
    call_from_GUI=[]; % second plot in new figure
    
end % country_i