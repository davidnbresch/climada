function [tc_track,tc_track_hist_file]=climada_tc_read_unisys_database(unisys_file,check_plot)
% TC event set track database UNISYS
% NAME:
%   climada_tc_read_unisys_database
% PURPOSE:
%   read UNISYS database file, raw data file to be downloaded from
%   http://weather.unisys.com/hurricane/index.html (see
%   climada_tc_get_unisys_databases), filter the raw data, namely:
%   - a VALID record (=node) is required to have lat, lon and either pressure
%     or windspeed (so recrods with only geographical information are skipped)
%   - pressure [mb] needs to be in the range 800..1100, otherwise set to
%     NaN, windspeeds of zero are also set to NaN
%   - longitudes are converted such that east is positive and that the
%     coordinates within one region (basin) are uniform, means no jump from
%     180 to -180 (done based on median longitude of basin database)
%   - latitudes (always North in UNISYS data) are converted for Southern
%     Hemipshere datasets, if the unisys_file contains 'she' or 'bsh' in the filename
%     (see parameter  convert_latitude, she: southern hemisphere, bsh: best track southern hemisphere)
%
%   NOTE: if the binary file (see tc_track_hist_file) containing tc_track
%   exists, the code just returns tc_track. This allows for recurent calls
%   to the code and results in substantial speed-up.
%   If the binary file (see tc_track_raw_file) exists, reading of raw
%   data is skipped. This allows faster iteration iro filtering (as often
%   required, since raw data contains missing and errors).
%   One needs to delete the binary files to re-read the raw ASCII data.
%
%   previous step: see climada_tc_get_unisys_databases
%   next step: see climada_tc_random_walk
% CALLING SEQUENCE:
%   tc_track=climada_tc_read_unisys_database(unisys_file);
% EXAMPLE:
%   tc_track=climada_tc_read_unisys_database(unisys_file);
% INPUTS:
%   unisys_file: the filename of the raw databse file (as downloaded from
%       UNISYS), prompted for, if not given
%   see also PARAMETERS section, especially for filters
% OPTIONAL INPUT PARAMETERS:
%   check_plot: if =1, show plots, =0 not (default)
% OUTPUTS:
%   tc_track: a structure with the track information for each cyclone i and
%           data for each node j (times are at 00Z, 06Z, 12Z, 18Z):
%       tc_track(i).lat(j): latitude at node j of cyclone i
%       tc_track(i).lon(j): longitude at node j of cyclone i
%       tc_track(i).MaxSustainedWind(j): Maximum sustained (1 minute)
%           surface (10m) windspeed in knots (in general, these are to the nearest 5 knots).
%       tc_track(i).MaxSustainedWindUnis, almost always 'kn'
%           (others allowed: 'mph', 'm/s' or 'km/h')
%       tc_track(i).CentralPressure(j): optional
%       tc_track(i).CentralPressureUnit: 'mb'
%       tc_track(i).yyyy: 4-digit year, optional
%       tc_track(i).mm: month, optional
%       tc_track(i).dd: day, optional
%       tc_track(i).hh: hours
%       tc_track(i).datenum:  matlab notation for date and time (see function datestr)
%       tc_track(i).TimeStep(j)=time step [h] from this to next node
%       tc_track(i).ID_no: unique ID, optional
%       tc_track(i).name: name, optional
%       tc_track(i).orig_event_flag: whether it is an mother(=1) or daugther(=0) storm
%
%       Please note that a binary file of raw_data is stored (in the
%       background). The raw_data is stored to ease (and speedup) re-reading the
%       data. To really start from the raw text file again, please delete the
%       binary file (*_raw.mat).
%
%   tc_track_hist_file: the filename with path to the binary file
%       tc_track is stored in (see NOTE above)
%
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090728
% Joeri Rogelj, jr@env.ethz.ch, 20120429 / correct time step computation
% Reto Stockmann, 20120808 / added axes labels and limits
% Lea Mueller, 20120813, added overview of years in plot and codewort 'she'
% for southern hemisphere filename
% David N. Bresch, david.bresch@gmail.com, 20140221, world border plotted on top of tracks
% David N. Bresch, david.bresch@gmail.com, 20140922 (over the Atlantic, LX016), tc_track_hist_file as output added and storing processed as mat
%-

% init output
tc_track=[];
tc_track_hist_file='';

% init global variables
global climada_global
if ~climada_init_vars,return;end

% check inputs
if ~exist('unisys_file','var'),unisys_file=[];end
if ~exist('check_plot','var'),check_plot=0;end

% PARAMETERS
%
% general settings
% ----------------
min_nodes=3;    % minimal nodes a track must have to be selected
%
% some likely basin/dataset specific settings
% -------------------------------------------
% the UNISYS latitude comes with no sign, so one needs to know the
% hemisphere, either 'keepNorth', or 'convert2South' for datasets in
% Southern Hemisphere
% if the unisys_file contains 'she' or 'bsh' in the filename, SouthernHemisphere is
% automatically assumed (see code below)
convert_latitude='keepNorth';
%
% the unique_ID is constructed from year and even number within this year,
% a basin_number can be used to distinguish basins, e.g. North Atlantic is
% 1, such that unique_ID=ByyyyNN with B the basin number, yyyy the year
%  and NN the number of track within the year.
basin_number=1; % range 0..9
%
% we can easily skip all tracks prior to a given year, so we allow this
% option here
min_year=0; %e.g. 1992, default=0 to select all years
%
% the time stamps [Z] and the correcponsing offsets (position in string),
% likely NOT to change, be careful
time_stamps=[0 6 12 18];
time_offsets=[0 17 34 51];
%
% TEST data
%unisys_file=[climada_global.data_dir filesep 'tc_tracks' filesep 'TEST_tracks.atl.txt']

% prompt for unisys_file if not given
if isempty(unisys_file) % local GUI
    [filename, pathname] = uigetfile({'*.txt';'*.asc'},'Select raw UNISYS database file:',...
        [climada_global.data_dir filesep 'tc_tracks' filesep 'TEST_tracks.atl.txt']);
    if isequal(filename,0) || isequal(pathname,0)
        return % cancel
    else
        unisys_file=fullfile(pathname,filename);
    end
end

% construct the binary file names
[fP,fN]=fileparts(unisys_file);
tc_track_raw_file=[fP filesep fN '_raw.mat'];
tc_track_hist_file=[fP filesep fN '_hist.mat'];

if ~isempty(strfind(unisys_file,'she')) || ~isempty(strfind(unisys_file,'bsh')) %findstr(unisys_file,'bsh')
    convert_latitude = 'convert2South'; % Southern Hemisphere
    fprintf('abbreviation ''she'' or ''bsh'' found in UNISYS filename, hence SouthernHemisphere assumed\n');
end

next_track                    = 1; % init
tc_track.MaxSustainedWindUnit = 'kn';
tc_track.CentralPressureUnit  = 'mb';
tc_track.TimeStep             = 6; % check!

if ~climada_check_matfile(unisys_file,tc_track_hist_file)
    
    if ~climada_check_matfile(unisys_file,tc_track_raw_file)
        
        if climada_global.waitbar,h = waitbar(0.5,'Reading and converting data ...');end
        % open the database for reading
        if ~exist(unisys_file,'file'),fprintf('ERROR: file %s not found\n',unisys_file);return;end
        fid=fopen(unisys_file,'r');
        
        % init
        track_record_count=-1;total_record_count=1;
        line_count=0;
        
        fprintf('reading raw data from %s ...\n',unisys_file);
        % read raw data
        while not(feof(fid))
            
            % read one line
            line=fgetl(fid);
            
            line_count=line_count+1;
            if length(line)>0
                
                % line
                if track_record_count>0,record_type=2;end; % track record
                if track_record_count==0,record_type=3;end; % after track records
                if track_record_count==-1,record_type=1;end; % header
                %waitbar(line_count/nr_lines,h); % update waitbar
                
                switch record_type
                    case 1 % header
                        
                        % process line type 1 - the header, looks like (next 2 lines to help count position)
                        % 000000000111111111122222222223333333333444444444455555555556
                        % 123456789012345678901234567890123456789012345678901234567890
                        % 00005 04/19/1945 M= 8  1 SNBR=   0 NOT NAMED   XING=0 SSS=9
                        
                        header_year=str2num(line(13:16));
                        header_number=str2num(line(23:24));
                        header_name=line(36:47);
                        track_record_count=str2num(line(20:21));
                    case 2 % body
                        
                        % try
                        % body format:
                        % 000000000111111111122222222223333333333444444444455555555556
                        % 123456789012345678901234567890123456789012345678901234567890
                        % 92580 04/22S2450610  30 1003S2490615  45 1002S2520620  45 1002S2550624  45 1003*
                        % Card# MM/DD&LatLongWindPress&LatLongWindPress&LatLongWindPress&LatLongWindPress
                        
                        %fprintf('%s\n',line(1:5)) % DEBUG only
                        
                        % loop over (four) timesteps per day
                        for offset_i=1:length(time_offsets)
                            offset=time_offsets(offset_i);
                            try
                                if sum(str2num(line(13+offset:28+offset)))>0
                                    raw_data.year(total_record_count)=header_year;
                                    raw_data.month(total_record_count)=str2num(line(7:8));
                                    raw_data.day(total_record_count)=str2num(line(10:11));
                                    raw_data.extratrop(total_record_count)=line(12);
                                    raw_data.time(total_record_count)=time_stamps(offset_i);
                                    raw_data.number(total_record_count)=header_number;
                                    raw_data.name(total_record_count,:)=num2str(header_name);
                                    raw_data.lat(total_record_count)=str2num(line(13+offset:15+offset))/10.0; % lat
                                    raw_data.lon(total_record_count)=str2num(line(16+offset:19+offset))/10.0; % lonc
                                    raw_data.vmax(total_record_count)=str2num(line(20+offset:23+offset)); % wind [kn]
                                    raw_data.pmin(total_record_count)=str2num(line(24+offset:28+offset)); % pressure [mb]
                                end
                            catch
                                fprintf('line %i (offset %i): %s\n',line_count,offset,line); % DEBUG
                            end
                            total_record_count=total_record_count+1;
                        end % offset_i
                        
                        track_record_count=track_record_count-1; % we read one line
                        
                        %             catch
                        %                 fprintf('ERROR reading line %i (body)\n',line_count);
                        %                 fprintf('%s\n',line);
                        %                 rethrow(lasterror);
                        %             end;
                        
                    case 3 % Maximum intensity of storm
                        % we ignore this
                        track_record_count=-1; % indicate next track
                    otherwise
                        fprintf('WARNING: unrecognized record_type\n');
                end % record_type
            else
                fprintf('WARNING: line %i empty\n',line_count);
            end
            
        end
        
        fclose(fid);
        if exist('h','var'), close(h), end % close waitbar
        
        % store raw data (so following filtering setps can be repeated faster)
        fprintf('writing binary file %s\n',tc_track_raw_file);
        save(tc_track_raw_file,'raw_data');
    else
        fprintf('reading binary file %s\n',tc_track_raw_file);
        %fprintf('> please delete this file to read data from raw file again\n');
        load(tc_track_raw_file);
    end
    
    fprintf('filtering raw data (%i nodes) ...\n',length(raw_data.pmin));
    
    % filter lat==0 and/or lon==0, and (vmax==0 and pmin==0)
    %------------------------------------------------------
    raw_data.pmin(raw_data.pmin > 1100)=0; % replace silly pressure data
    raw_data.pmin(raw_data.pmin < 800)=0; % replace silly pressure data
    nonzero_pos=find(raw_data.lat~=0.0 & raw_data.lon~=0.0 & (raw_data.vmax~=0 | raw_data.pmin~=0) & raw_data.year>=min_year);
    
    no_pmin=find(raw_data.pmin==0);
    no_vmax=find(raw_data.vmax==0);
    neither_nor=find(raw_data.vmax==0 & raw_data.pmin==0);
    if length(no_pmin)+length(no_vmax)+length(neither_nor)>0,...
            fprintf('WARNING: %i nodes w/o pressure, %i nodes w/o wind, %i without neither (but no records deleted)\n',...
            length(no_pmin),length(no_vmax),length(neither_nor));
    end
    
    raw_data.pmin(raw_data.pmin==0)=NaN; % from now on, use NaN for bad data
    raw_data.vmax(raw_data.vmax==0)=NaN; % from now on, use NaN for bad data
    
    if length(nonzero_pos)>0
        raw_data.year=raw_data.year(nonzero_pos);
        raw_data.month=raw_data.month(nonzero_pos);
        raw_data.day=raw_data.day(nonzero_pos);
        raw_data.extratrop=raw_data.extratrop(nonzero_pos);
        raw_data.time=raw_data.time(nonzero_pos);
        raw_data.number=raw_data.number(nonzero_pos);
        raw_data.name=raw_data.name(nonzero_pos,:);
        raw_data.lat=raw_data.lat(nonzero_pos);
        raw_data.lon=raw_data.lon(nonzero_pos);
        raw_data.vmax=raw_data.vmax(nonzero_pos);
        raw_data.pmin=raw_data.pmin(nonzero_pos);
        
        % convert longitude
        %------------------
        % first into the range [-360 untill 0 W] as unisys data is in +W
        raw_data.lon = -raw_data.lon;  % now all negative, as West is negative
        
        % second convert to range [-180 ...180]
        lt180pos               = find(raw_data.lon<-180);
        raw_data.lon(lt180pos) = raw_data.lon(lt180pos)+360;
        
        % third, figure out best range (automatic!)
        median_lon = median(raw_data.lon);
        min_lon    = median_lon-180;
        max_lon    = median_lon+180;
        min_pos    = find(raw_data.lon<min_lon); raw_data.lon(min_pos) = raw_data.lon(min_pos)+360;
        max_pos    = find(raw_data.lon>max_lon); raw_data.lon(max_pos) = raw_data.lon(max_pos)-360;
        
        % convert latitude
        %-----------------
        % the UNISYS latitude comes with no sign, so one needs to know the
        % hemisphere, either 'keepNorth', or 'convert2South' for datasets in
        % Southern Hemisphere
        if strcmp(convert_latitude,'convert2South'),raw_data.lat=-raw_data.lat;end % convert all tracks to Southern hemisphere
        
    else
        fprintf('ERROR: file contains no useful data, aborted\n');
        return
    end
    
    if check_plot
        climada_figuresize(0.7,1);
        %overall title
        ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
        hold on;
        % show some properties
        subaxis(2,2,1,'SpacingVertical',0.1,'SpacingHorizontal',0.07);
        hold on;
        pos=find(raw_data.pmin>0);
        plot(raw_data.vmax(pos),raw_data.pmin(pos),'.r');xlabel('v_{max}');ylabel('p_{min}');title('v_{max} - p_{min} relation');
        subaxis(2);
        plot(raw_data.lon,raw_data.lat,'.','color',[216 191 216]/255,'markersize',6);xlabel('lon');ylabel('lat');title('all nodes');hold on;
        pos=find(raw_data.pmin>0 & raw_data.vmax>0);
        plot(raw_data.lon(pos),raw_data.lat(pos),'.g','markersize',5);xlabel('lon');ylabel('lat');title('all nodes');hold on;
        legend('all nodes','with valid wind/pressure','location','sw');
        if exist('climada_plot_world_borders'),climada_plot_world_borders;end % plot coastline
        %set(gcf,'Color',[1 1 1]); % background to white
        xlim([-180 180]);
    end
    
    % filling the selected tracks in tc_track structure
    %--------------------------------------------------
    
    unique_ID=basin_number*1e6+raw_data.year*100+raw_data.number*1;
    unique_unique_ID=unique(unique_ID); % list of unique_ID's
    
    n_tracks=length(unique_unique_ID);  % amount of read tracks
    msgstr=sprintf('Processing %i tracks ...',n_tracks);
    fprintf('%s\n',msgstr);
    if climada_global.waitbar,h = waitbar(0,msgstr);end
    
    % for printing some features (tests)
    selected_tracks=0;   % init: number of tracks selected
    unselected_tracks=0; % init: number of tracks unselected
    
    for ID_i=1:n_tracks
        if climada_global.waitbar,waitbar(ID_i/n_tracks,h);end % update waitbar
        
        pos=find(unique_ID==unique_unique_ID(ID_i)); %find all datapoints which belong to the same ID (=same track)
        
        if length(pos)>min_nodes  % min_nodes: minmal nodes a track must have to be selected
            selected_tracks=selected_tracks+1; %for tests
            
            %if check_plot,plot(lon(pos),lat(pos),'.'),hold on;end;
            
            %fill in...
            tc_track(next_track).lon=raw_data.lon(pos);
            tc_track(next_track).lat=raw_data.lat(pos);
            tc_track(next_track).MaxSustainedWind=raw_data.vmax(pos);
            tc_track(next_track).CentralPressure=raw_data.pmin(pos);
            tc_track(next_track).yyyy=raw_data.year(pos);
            tc_track(next_track).mm=raw_data.month(pos);
            tc_track(next_track).dd=raw_data.day(pos);
            tc_track(next_track).hh=raw_data.time(pos);
            tc_track(next_track).ID_no=unique_unique_ID(ID_i);
            tc_track(next_track).MaxSustainedWindUnit='kn';
            tc_track(next_track).CentralPressureUnit='mb';
            tc_track(next_track).orig_event_flag=1; % as we read the raw data
            tc_track(next_track).extratrop=raw_data.extratrop(pos);
            
            % correct year for storm tracks that run from one year to the next
            %-----------------------------------------------------------------
            if any(tc_track(next_track).mm==1)&&any(tc_track(next_track).mm==12)
                % we here assume that storm tracks are never longer than 1 year
                last_fy_timestep = find(tc_track(next_track).mm==12, 1, 'last' );
                tc_track(next_track).yyyy(last_fy_timestep+1:end)=tc_track(next_track).yyyy(1)+1;
            end
            
            tc_track(next_track).datenum=datenum(tc_track(next_track).yyyy,tc_track(next_track).mm,tc_track(next_track).dd,tc_track(next_track).hh,0,0) ;
            
            % re-calculate timestep
            tc_track(next_track).TimeStep=tc_track(next_track).lon*0.0; % init
            for time_i=1:length(tc_track(next_track).datenum)-1
                d_hours=(tc_track(next_track).datenum(time_i+1)-tc_track(next_track).datenum(time_i))*24; % [h]
                if abs(d_hours)>6
                    d_hours;
                end
                tc_track(next_track).TimeStep(time_i)=d_hours;
            end
            tc_track(next_track).TimeStep(end)=tc_track(next_track).TimeStep(end-1);
            
            % construct a unique storm name if there is none
            useful_name=raw_data.name(pos(1),:);
            if strmatch('NOT NAMED',useful_name)
                % make useful name
                useful_name=['NNN_' num2str(unique_unique_ID(ID_i),'%7.7i')];
            end;
            tc_track(next_track).name=useful_name;
            
            next_track=next_track+1;
            
        else
            unselected_tracks=unselected_tracks+1;
            fprintf('WARNING: %4.4i ID %i, less than %i nodes, skipped\n',...
                raw_data.year(pos(1)),unique_unique_ID(ID_i),min_nodes);
        end
        
    end % ID_i
    fprintf('%i tracks read, %i tracks chosen, %i tracks not chosen\n',n_tracks,selected_tracks,unselected_tracks)
    if exist('h','var'), close(h), end % close waitbar
    
    clear raw_data % to save space
    
    % store raw data (so following filtering setps can be repeated faster)
    fprintf('writing processed file %s\n',tc_track_hist_file);
    save(tc_track_hist_file,'tc_track');
    
    
    if check_plot
        subaxis(2)
        for i=1:length(tc_track);plot(tc_track(i).lon,tc_track(i).lat,'-b');hold on;end; % all tracks
        hold on
        if exist('climada_plot_world_borders'),climada_plot_world_borders;end % plot coastline
        subaxis(3)
        for i=1:length(tc_track);plot(tc_track(i).CentralPressure);hold on;end;xlabel('# of nodes per track');ylabel('(mb)');title('CentralPressure')
        subaxis(4)
        for i=1:length(tc_track);plot(tc_track(i).MaxSustainedWind);hold on;end;xlabel('# of nodes per track');ylabel('(kn)');title('MaxSustainedWind')
        
        ha = axes('Position',[0 0.93 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off', 'Visible','off', 'Units','normalized', 'clipping','off');
        titlestr = sprintf('%d - %d, %d tracks\n %d tracks not chosen',tc_track(1).yyyy(1), tc_track(end).yyyy(end),selected_tracks, unselected_tracks);
        text(0.5, 0,titlestr,'fontsize',12,'fontweight','bold','HorizontalAlignment','center','VerticalAlignment', 'bottom')
    end
    
else
    fprintf('reading processed file %s\n',tc_track_hist_file);
    %fprintf('> please delete this file to read data from raw file again\n');
    load(tc_track_hist_file);
end

return