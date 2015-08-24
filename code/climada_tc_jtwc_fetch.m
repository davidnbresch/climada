function [tc_track,tc_track_hist_file]=climada_tc_jtwc_fetch(check_plot)
% climada_tc_jtwc_fetch
% MODULE:
%   core
% NAME:
%   climada_tc_jtwc_fetch
% PURPOSE:
%   fetch TC track files from web, as (very) cumbersome for TC Southern
%   Hemisphere, and convert into tc_track structure. See
%   www.usno.navy.mil/NOOC/nmfc-ph/RSS/jtwc/best_tracks/shindex.php
%
%   See parameter Pacific_centric in code, with sets longitudes such that
%   event set generation works for South Psacific ocean (most likely use,
%   as there is no UNISYS data for this region). Set Pacific_centric=0 in
%   case you'd like to use jtwc data for South Indian ocean.
%
%   Note: we do NOT store empty (no wind nor pressure) or too short (less
%   than 3 nodes) tracks in tc_track, as any subsequent climada code would
%   struggle to use it anyway.
%
%   next step: see climada_tc_random_walk and climada_tc_hazard_set
%
%   See also climada_tc_read_unisys_database and climada_tc_hurdat_read
% CALLING SEQUENCE:
%   [tc_track,tc_track_hist_file]=climada_tc_jtwc_fetch(check_plot)
% EXAMPLE:
%   tc_track=climada_tc_jtwc_fetch(1)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   check_plot: =1, plot for check, =0, no plot (default)
% OUTPUTS:
%   tc_track: a structure with the track information for each cyclone i and
%           data for each node j (times are at 00Z, 06Z, 12Z, 18Z):
%       tc_track(i).lat(j): latitude at node j of cyclone i
%       tc_track(i).lon(j): longitude at node j of cyclone i
%       tc_track(i).MaxSustainedWind(j): Maximum sustained (1 minute)
%           surface (10m) windspeed in knots (in general, these are to the nearest 5 knots).
%       tc_track(i).MaxSustainedWindUnit, almost always 'kn'
%           (others allowed: 'mph', 'm/s' or 'km/h')
%       tc_track(i).CentralPressure(j): optional
%       tc_track(i).CentralPressureUnit: 'mb'
%       tc_track(i).yyyy: 4-digit year, optional
%       tc_track(i).mm: month, optional
%       tc_track(i).dd: day, optional
%       tc_track(i).hh: hours
%       tc_track(i).datenum:  matlab notation for date and time (see function datestr)
%       tc_track(i).TimeStep(j)=time step [h] from this to next node
%           Nearly all HURDAT2 records correspond to the synoptic times of 0000, 0600, 1200, and 1800.
%           Recording best track data to the nearest minute became available within the b-decks
%           beginning in 1991 and some tropical cyclones since that year have the landfall best track to the nearest minute.
%       tc_track(i).ID_no: unique ID, optional
%       tc_track(i).name: name, optional
%       tc_track(i).orig_event_flag: whether it is an mother(=1) or daugther(=0) storm
%   tc_track_hist_file: the filename with path to the binary file
%       tc_track is stored in (see NOTE above)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150823
% David N. Bresch, david.bresch@gmail.com, 20150824, made fully consistent with unisys and hurdat
%-

tc_track=[]; % init output
tc_track_hist_file=''; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('check_plot','var'),check_plot=0;end

% PARAMETERS
%
% minimal nodes a track must have to be selected (otherwise operators such
% as forward speed will not work properly)
min_nodes=3;    
%
% define first and last year of data (see )
year_start=1945; % really no wind/pressure until 1957
year_end=2014;
%
% whether we want track's longitudes be Pacific centric (i.e. dateline) or
% not, see code for details
Pacific_centric=1; % default=1, since we use UNISYS for other basins
%
% define the folder the track data files will be stored to
tc_track_subfolder='jtwc_bsh';

if ~exist([climada_global.data_dir filesep 'tc_tracks' filesep '' tc_track_subfolder],'dir')
    mkdir([climada_global.data_dir filesep 'tc_tracks'],tc_track_subfolder);
end
tc_track_subfolder=[climada_global.data_dir filesep 'tc_tracks' filesep tc_track_subfolder];

tc_track_hist_file=[tc_track_subfolder filesep 'jtwc_tc_track_hist.mat'];

if exist(tc_track_hist_file,'file')
    load(tc_track_hist_file)
else
    track_i=1; % init
    lon_correction_count=0;
    min_nodes_count=0;
    MaxSustainedWind_NaN_count=0;
    CentralPressure_NaN_count=0;
    
    for year_i=year_start:year_end
        year_str=num2str(year_i);
        
        % first, get the table of event per year
        url_str=['http://www.usno.navy.mil/NOOC/nmfc-ph/RSS/jtwc/best_tracks/' year_str '/' year_str 's-bsh'];
        fprintf('fetching %s (index)\n',url_str);
        str = urlread(url_str);
        
        start_pos=strfind(str,'<TR><TD>');
        end_pos=strfind(str,'</td><td>');
        
        for file_i=1:length(start_pos)
            sub_str=str(start_pos(file_i)+8:end_pos(1+(file_i-1)*3)-1);
            % sub_str contains a <ahref... sequence, remove it:
            [~,b]=strtok(strrep(sub_str,' ',''),'"');
            sub_str=strtok(b,'"');
            sub_str=deblank(strtrim(sub_str));
            %fprintf('dealing with %s\n',sub_str)
            
            if strcmp(sub_str(end-3:end),'.txt') || strcmp(sub_str(end-3:end),'.dat')
                
                % construct the full url to fetch single track from
                url_sub_str=[url_str '/' sub_str];
                % construct full filename to store single track to
                out_file=[tc_track_subfolder filesep sub_str];
                
                if ~exist(out_file,'file')
                    % get the single track data
                    fprintf('fetching %s\n',url_sub_str);
                    track_data_str = urlread(url_sub_str);
                    
                    % write to single track file
                    fid=fopen(out_file,'w');
                    fprintf(fid,'%s\n',track_data_str);
                    fclose(fid);
                else
                    %fprintf('local %s already exists\n',sub_str);
                end % ~exist(out_file,'file')
                
                % read the single track file and store to tc_track
                
                % init next tc_track
                tc_track(track_i).MaxSustainedWindUnit='kn';
                tc_track(track_i).CentralPressureUnit='mb';
                node_i=1; % init
                
                %fprintf('adding %s to tc_track ...',sub_str);
                fid=fopen(out_file,'r');
                while ~feof(fid)
                    line_str=fgetl(fid);
                    if ~isempty(line_str)
                        
                        % only later years have names, hence store .txt or .dat filename
                        %tc_track(track_i).name='noname'; % real default
                        tc_track(track_i).name=deblank(strrep(sub_str,'.txt',''));
                        tc_track(track_i).name=strrep(tc_track(track_i).name,'.dat','');
                        
                        [~,line_str]=strtok(line_str,','); % get rid of 'SH'
                        [~,line_str]=strtok(line_str,','); % get rid of number
                        [date_str,line_str]=strtok(line_str,','); % get date
                        % convert date
                        date_str=deblank(strtrim(date_str)); % blanks everywhere ...
                        tc_track(track_i).yyyy(node_i)=str2double(date_str(1:4));
                        tc_track(track_i).mm(node_i)=str2double(date_str(5:6));
                        tc_track(track_i).dd(node_i)=str2double(date_str(7:8));
                        tc_track(track_i).hh(node_i)=str2double(date_str(9:10));
                        tc_track(track_i).datenum(node_i)=...
                            datenum(tc_track(track_i).yyyy(node_i),...
                            tc_track(track_i).mm(node_i),tc_track(track_i).dd(node_i),...
                            tc_track(track_i).hh(node_i),0,0);
                        
                        [~,line_str]=strtok(line_str,','); % get rid of empty
                        [~,line_str]=strtok(line_str,','); % get rid of 'BEST'
                        [~,line_str]=strtok(line_str,','); % get rid of '0'
                        [lat_str,line_str]=strtok(line_str,','); % get latitude
                        % convert latitude
                        tc_track(track_i).lat(node_i)=str2double(lat_str(1:end-1))/10;
                        if strcmp(lat_str(end),'S'),tc_track(track_i).lat(node_i)=-tc_track(track_i).lat(node_i);end
                        [lon_str,line_str]=strtok(line_str,','); % get longitude
                        % convert longitude
                        tc_track(track_i).lon(node_i)=str2double(lon_str(1:end-1))/10;
                        if strcmp(lon_str(end),'W'),tc_track(track_i).lon(node_i)=-tc_track(track_i).lon(node_i);end
                        
                        % special treatment to keep longitude in -180..180 range:
                        if tc_track(track_i).lon(node_i)<-180
                            tc_track(track_i).lon(node_i)=tc_track(track_i).lon(node_i)+360;
                            lon_correction_count=lon_correction_count+1;
                        end
                        
                        [vmax_str,line_str]=strtok(line_str,','); % get MaxSustainedWind
                        tc_track(track_i).MaxSustainedWind(node_i)=str2double(vmax_str);
                        if tc_track(track_i).MaxSustainedWind(node_i)==-999
                            tc_track(track_i).MaxSustainedWind(node_i)=NaN;
                            MaxSustainedWind_NaN_count=MaxSustainedWind_NaN_count+1;
                        end
                        
                        if ~isempty(line_str)
                            [p_str,line_str]=strtok(line_str,','); % get CentralPressure
                            tc_track(track_i).CentralPressure(node_i)=str2double(p_str);
                            if tc_track(track_i).CentralPressure(node_i)==0
                                tc_track(track_i).CentralPressure(node_i)=NaN;
                                CentralPressure_NaN_count=CentralPressure_NaN_count+1;
                            end
                        else
                            tc_track(track_i).CentralPressure(node_i)=NaN;
                            CentralPressure_NaN_count=CentralPressure_NaN_count+1;
                        end
                        
                        node_i=node_i+1; % point to next node
                    end
                    
                end % ~eof(fid)
                fclose(fid);
                %fprintf(' %i nodes\n',node_i-1);
                
                % complete the track
                tc_track(track_i).ID_no=track_i; % just for compatibility
                tc_track(track_i).orig_event_flag=1; % by default
                % add TimeStep (in hours)
                tc_track(track_i).TimeStep=diff(tc_track(track_i).datenum)*24;
                tc_track(track_i).TimeStep(end+1)=tc_track(track_i).TimeStep(end); % add last entry
                
                valid_pos=find(tc_track(track_i).TimeStep>0); % check for duplicate records
                tc_track(track_i).yyyy=tc_track(track_i).yyyy(valid_pos);
                tc_track(track_i).mm=tc_track(track_i).mm(valid_pos);
                tc_track(track_i).dd=tc_track(track_i).dd(valid_pos);
                tc_track(track_i).hh=tc_track(track_i).hh(valid_pos);
                tc_track(track_i).datenum=tc_track(track_i).datenum(valid_pos);
                tc_track(track_i).lat=tc_track(track_i).lat(valid_pos);
                tc_track(track_i).lon=tc_track(track_i).lon(valid_pos);
                tc_track(track_i).MaxSustainedWind=tc_track(track_i).MaxSustainedWind(valid_pos);
                tc_track(track_i).CentralPressure=tc_track(track_i).CentralPressure(valid_pos);
                tc_track(track_i).TimeStep=tc_track(track_i).TimeStep(valid_pos);
                
                if Pacific_centric
                    pos=find(tc_track(track_i).lon>0);
                    tc_track(track_i).lon(pos)=tc_track(track_i).lon(pos)-360;
                end % Pacific_centric
                
                reset_track=0;
                if length(tc_track(track_i).lon)<min_nodes
                    reset_track=1;
                    min_nodes_count=min_nodes_count+1;
                elseif isnan(min(tc_track(track_i).MaxSustainedWind))
                    if isnan(min(tc_track(track_i).CentralPressure))
                        reset_track=1;
                    end
                end
                
                if reset_track
                    % too few nodes and/or no valid MaxSustainedWind
                    % nor CentralPressure
                    tc_track(track_i).yyyy=[];
                    tc_track(track_i).mm=[];
                    tc_track(track_i).dd=[];
                    tc_track(track_i).hh=[];
                    tc_track(track_i).datenum=[];
                    tc_track(track_i).lat=[];
                    tc_track(track_i).lon=[];
                    tc_track(track_i).MaxSustainedWind=[];
                    tc_track(track_i).CentralPressure=[];
                    tc_track(track_i).TimeStep=[];
                
                    track_i=track_i-1; % re-use record
                end % reset_track
                
                track_i=track_i+1; % point to next track
                
            end % ~strcmp(sub_str(end-4:end),'.kmz')
        end % file_i
        
    end % year_i
    
    if lon_correction_count>0
        fprintf('NOTE: %i longitudes corrected for range -180..180\n',lon_correction_count);
    end
    
    if MaxSustainedWind_NaN_count>0
        fprintf('NOTE: %i nodes with no valid MaxSustainedWind\n',MaxSustainedWind_NaN_count);
    end
    
    if CentralPressure_NaN_count>0
        fprintf('NOTE: %i nodes with no valid CentralPressure\n',CentralPressure_NaN_count);
    end
    
    if min_nodes_count>0
        fprintf('NOTE: %i tracks skipped since <%i nodes\n',min_nodes_count,min_nodes);
    end
    
    fprintf('saving tc_track in %s\n',tc_track_hist_file);
    save(tc_track_hist_file,'tc_track');
    
    % for speedup, also create the probabilistic track set
    tc_track_hist=tc_track;
    tc_track=climada_tc_random_walk(tc_track_hist);
    tc_track_prob_file=strrep(tc_track_hist_file,'hist','prob');
    fprintf('saving probabilstic tc_track in %s\n',tc_track_prob_file);
    save(tc_track_prob_file,'tc_track');
    tc_track=tc_track_hist; % set back
    
end % exist(tc_track_hist_file,'file')

if check_plot
    fprintf('preparing plot...\n');
    ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    hold on;
    % show some properties
    subaxis(2,2,1,'SpacingVertical',0.1,'SpacingHorizontal',0.07);
    hold on;
    for i=1:length(tc_track);plot(tc_track(i).MaxSustainedWind,tc_track(i).CentralPressure,'.r');hold on;end; % all tracks
    xlabel('v_{max}');ylabel('p_{min}');title('v_{max} - p_{min} relation');
    set(gcf,'Color',[1 1 1]); % background to white
    
    subaxis(2)
    for i=1:length(tc_track);plot(tc_track(i).lon,tc_track(i).lat,'-b');hold on;end; % all tracks
    hold on
    climada_plot_world_borders; % plot coastline
    subaxis(3)
    for i=1:length(tc_track);plot(tc_track(i).CentralPressure);hold on;end;
    xlabel('# of nodes per track');ylabel('(mb)');title('CentralPressure')
    subaxis(4)
    for i=1:length(tc_track);plot(tc_track(i).MaxSustainedWind);hold on;end;
    xlabel('# of nodes per track');ylabel('(kn)');title('MaxSustainedWind')
end

end % climada_tc_jtwc_fetch