function [tc_track,tc_track_hist_file]=climada_tc_hurdat_read(hurdat_filename,check_plot)
% climada template
% MODULE:
%   core
% NAME:
%   climada_tc_hurdat_read
% PURPOSE:
%   Read HURDAT database, www.nhc.noaa.gov/data
%
%   The code does check for at least 3 nodes (see parameter min_nodes) and
%   sets missing CentralPressure and negative MaxWInd to NaN.
%
%   Atlantic hurricane database (HURDAT2) 1851-2014:
%   www.nhc.noaa.gov/data/hurdat/hurdat2-1851-2014-060415.txt
%
%   Northeast and North Central Pacific hurricane database (HURDAT2)
%   1949-2013: www.nhc.noaa.gov/data/hurdat/hurdat2-nencpac-1949-2013-070714.txt
%
%   for format and details, see www.nhc.noaa.gov/data/hurdat/hurdat2-format-atlantic.pdf
%
%   For debugging, there is a simple try/catch which stops and shows the
%   line number and its content in case of trouble.
%
%   next step: see climada_tc_random_walk and climada_tc_hazard_set
%
%   See also climada_tc_read_unisys_database and climada_tc_jtwc_fetch
% CALLING SEQUENCE:
%   tc_track=climada_tc_hurdat_read(hurdat_filename)
% EXAMPLE:
%   tc_track=climada_tc_hurdat_read;
% INPUTS:
%   hurdat_filename: name (and path) of the HURDAT2 text file
%       > promted for if not given
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
%
%       PLUS: optional field (only in HURDAT)
%       tc_track(i).WindRadii(j,1:12): wind radii maximum extent (in
%           nautical miles) for quadrants:
%           tc_track(i).WindRadii(j,1): northeastern quadrant
%                    2): southeastern quadrant
%                    3): southwestern quadrant
%                    4): northwestern quadrant
%                    5): northeastern quadrant
%                    6): southeastern quadrant
%                    7): southwestern quadrant
%                    8): northwestern quadrant
%                    9): northeastern quadrant
%                   10): southeastern quadrant
%                   11): southwestern quadrant
%                   12): northwestern quadrant
%
%       To really start from the raw text file again, please delete the
%       binary file (*_hist.mat).
%
%   tc_track_hist_file: the filename with path to the binary file
%       tc_track is stored in (see NOTE above)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150730, intial
% David N. Bresch, david.bresch@gmail.com, 20150824, made fully consistent with unisys and jtwc
%-

tc_track=[]; % init output
tc_track_hist_file='';

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mhurdat_filename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('hurdat_filename','var'),hurdat_filename='';end
if ~exist('check_plot','var'),check_plot=0;end

% PARAMETERS
%
min_nodes=3;    % minimal nodes a track must have to be selected
%
% CHECK MaxSustainedWindUnit and CentralPressureUnit hard-wired in code
%
% TEST
%hurdat_filename =[climada_global.data_dir filesep 'tc_tracks' filesep 'hurdat' filesep 'hurdat2-1851-2014-060415.txt'];
%hurdat_filename =[climada_global.data_dir filesep 'tc_tracks' filesep 'hurdat' filesep 'hurdat2-nencpac-1949-2013-070714.txt'];

% template to prompt for hurdat_filename if not given
if isempty(hurdat_filename) % local GUI
    hurdat_filename=[climada_global.data_dir filesep 'tc_tracks' filesep 'hurdat' filesep '*.txt'];
    [hurdat_filename, pathname] = uigetfile(hurdat_filename, 'Select HURDAT2 text file:');
    if isequal(hurdat_filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hurdat_filename=fullfile(pathname,hurdat_filename);
    end
end

% construct the binary file names
[fP,fN]=fileparts(hurdat_filename);
tc_track_hist_file=[fP filesep fN '_hist.mat'];

if ~exist(hurdat_filename,'file'),fprintf('ERROR: file %s not found\n',hurdat_filename);return;end

if ~isempty(strfind(fN,'nencpac'))
    Pacific_centric=1;
    fprintf('Pacific centric data detected, longitude -360..0\n');
else
    Pacific_centric=0;
end

if ~climada_check_matfile(hurdat_filename,tc_track_hist_file)
    
    fid=fopen(hurdat_filename,'r');
    
    % init
    track_record_count=-1;total_record_count=1;
    line_count=0;
    
    fprintf('reading raw data from %s ...\n',hurdat_filename);
    
    NumberOfEntries=0; % init
    track_i=0; % init
    format_str='%s';
    last_promt_year=0; % init
    lon_correction_count=0;
    min_nodes_count=0;
    CentralPressure_NaN_count=0;
    MaxSustainedWind_NaN_count=0;
    
    % read raw data
    while not(feof(fid))
        
        % read one line
        line=fgetl(fid);
        line_count=line_count+1;
        
        if ~isempty(line)
            
            try
                
            if NumberOfEntries==0
                
                track_i=track_i+1; % next track
                
                % process header line
                tc_track(track_i).basin=line(1:2);
                %tc_track(track_i).ATCF=str2double(line(3:4));
                tc_track(track_i).year=str2double(line(5:8));
                [~,remain]=strtok(line,',');[token,remain]=strtok(remain,',');
                tc_track(track_i).name=strtrim(strrep(token,',',''));
                NumberOfEntries=str2double(deblank(strrep(remain,',','')));
                node_i=1; % (re)init
                tc_track(track_i).MaxSustainedWindUnit='kn'; % others allowed: 'mph', 'm/s' or 'km/h'
                tc_track(track_i).CentralPressureUnit ='mb';
                tc_track(track_i).WindRadiiUnit='nm'; % nautical mile
                
                if tc_track(track_i).year>last_promt_year
                    % prompt progress to stdout
                    msgstr=sprintf('processing year %i (first storm: %s)',tc_track(track_i).year,tc_track(track_i).name);
                    fprintf(format_str,msgstr); % write progress to stdout
                    format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
                    last_promt_year=tc_track(track_i).year;
                end
                
            else
                % process data line
                tc_track(track_i).yyyy(node_i)=str2double(line(1:4));
                tc_track(track_i).mm(node_i)=str2double(line(5:6));
                tc_track(track_i).dd(node_i)=str2double(line(7:8));
                tc_track(track_i).hh(node_i)=str2double(line(11:12));
                tc_track(track_i).minutes(node_i)=str2double(line(13:14));
                tc_track(track_i).datenum(node_i)=...
                    datenum(tc_track(track_i).yyyy(node_i),...
                    tc_track(track_i).mm(node_i),tc_track(track_i).dd(node_i),...
                    tc_track(track_i).hh(node_i),tc_track(track_i).minutes(node_i),0);
                
                tc_track(track_i).lat(node_i)=str2double(line(24:27));
                if strcmp(line(28),'S'),tc_track(track_i).lat(node_i)=-tc_track(track_i).lat(node_i);end
                
                tc_track(track_i).lon(node_i)=str2double(line(31:35));
                if strcmp(line(36),'W'),tc_track(track_i).lon(node_i)=-tc_track(track_i).lon(node_i);end
                % special treatment to keep longitude in -180..180 range:
                if tc_track(track_i).lon(node_i)<-180
                    tc_track(track_i).lon(node_i)=tc_track(track_i).lon(node_i)+360;
                    lon_correction_count=lon_correction_count+1;
                end
                
                % special treatment to keep longitude in -180..180 range:
                if tc_track(track_i).lon(node_i)<-180
                    tc_track(track_i).lon(node_i)=tc_track(track_i).lon(node_i)+360;
                    lon_correction_count=lon_correction_count+1;
                end
                
                tc_track(track_i).MaxSustainedWind(node_i)=str2double(line(39:41));
                if tc_track(track_i).MaxSustainedWind(node_i)<0
                    tc_track(track_i).MaxSustainedWind(node_i)=NaN;
                    MaxSustainedWind_NaN_count=MaxSustainedWind_NaN_count+1;
                end
                
                tc_track(track_i).CentralPressure(node_i)=str2double(line(44:47));
                if tc_track(track_i).CentralPressure(node_i)<0
                    tc_track(track_i).CentralPressure(node_i)=NaN;
                    CentralPressure_NaN_count=CentralPressure_NaN_count+1;
                end
                
                % wind radii maximum extent (in nautical miles)
                tc_track(track_i).WindRadii(node_i, 1)=str2double(line( 50: 53)); % northeastern quadrant
                tc_track(track_i).WindRadii(node_i, 2)=str2double(line( 56: 59)); % southeastern quadrant
                tc_track(track_i).WindRadii(node_i, 3)=str2double(line( 62: 65)); % southwestern quadrant
                tc_track(track_i).WindRadii(node_i, 4)=str2double(line( 68: 71)); % northwestern quadrant
                tc_track(track_i).WindRadii(node_i, 5)=str2double(line( 74: 77)); % northeastern quadrant
                tc_track(track_i).WindRadii(node_i, 6)=str2double(line( 80: 83)); % southeastern quadrant
                tc_track(track_i).WindRadii(node_i, 7)=str2double(line( 86: 89)); % southwestern quadrant
                tc_track(track_i).WindRadii(node_i, 8)=str2double(line( 92: 95)); % northwestern quadrant
                tc_track(track_i).WindRadii(node_i, 9)=str2double(line( 98:101)); % northeastern quadrant
                tc_track(track_i).WindRadii(node_i,10)=str2double(line(104:107)); % southeastern quadrant
                tc_track(track_i).WindRadii(node_i,11)=str2double(line(110:113)); % southwestern quadrant
                tc_track(track_i).WindRadii(node_i,12)=str2double(line(116:119)); % northwestern quadrant
                
                NumberOfEntries=NumberOfEntries-1; % one entry processed
                node_i=node_i+1; % next node
                
                if NumberOfEntries==0 % track data segment finished
                    if length(tc_track(track_i).lon)<min_nodes
                        reset_track=1;
                    elseif isnan(min(tc_track(track_i).MaxSustainedWind))
                        reset_track=1;
                    else
                        reset_track=0;
                    end
                    if reset_track
                        % too few nodes, skip this track, reset arrays
                        tc_track(track_i).yyyy=[];
                        tc_track(track_i).mm=[];
                        tc_track(track_i).dd=[];
                        tc_track(track_i).hh=[];
                        tc_track(track_i).minutes=[];
                        tc_track(track_i).datenum=[];
                        tc_track(track_i).lat=[];
                        tc_track(track_i).lon=[];
                        tc_track(track_i).MaxSustainedWind=[];
                        tc_track(track_i).CentralPressure=[];
                        tc_track(track_i).TimeStep=[];
                        tc_track(track_i).WindRadii=[];
                        track_i=track_i-1; % re-use record
                        min_nodes_count=min_nodes_count+1;
                    else
                        % complete the track
                        tc_track(track_i).ID_no=track_i; % just for compatibility
                        tc_track(track_i).orig_event_flag=1; % by default
                        % add TimeStep (in hours)
                        tc_track(track_i).TimeStep=diff(tc_track(track_i).datenum)*24;
                        tc_track(track_i).TimeStep(end+1)=tc_track(track_i).TimeStep(end); % add last entry
                        if Pacific_centric
                            pos=find(tc_track(track_i).lon>0);
                            tc_track(track_i).lon(pos)=tc_track(track_i).lon(pos)-360;
                        end % Pacific_centric
                    end % reset_track
                end % NumberOfEntries==0 (data record complete)
                
            end % NumberOfEntries==0 (is header line)
            
            catch 
                fprintf('ERROR in line %i: %s likely bad format\n',line_count,line)
                return
            end
            
        end % ~isempty(line)
        
    end % while
    fprintf(format_str,''); % move carriage to begin of line

    fprintf('saving as %s\n',tc_track_hist_file);
    save(tc_track_hist_file,'tc_track');
    
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
    
else
    fprintf('loading from %s\n',tc_track_hist_file);
    load(tc_track_hist_file)
end

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

end % climada_tc_hurdat_read