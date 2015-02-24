function tc_track = climada_tc_read_unisys_track(track_filename)
% climada unisys TC track
% NAME:
%   climada_tc_read_unisys_track
% PURPOSE:
%   read a single track data file as downloaded from 
%   http://www.weather.unisys.com/hurricane/
%   can be used to add to existing tc_track structure like:
%   tc_track(end+1)=climada_tc_read_unisys_track
%
%   See also e.g. climada_event_damage_data_tc
% CALLING SEQUENCE:
%   tc_track=climada_tc_read_unisys_track(filename)
% EXAMPLE:
%   tc_track=climada_tc_read_unisys_track
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   filename: the filename with path of a UNISYS *.dat file
%       > user gets prompted for if not specified
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20110429
% Lea Mueller, 20110718
% David N. Bresch, david.bresch@gmail.com, 20150220, init_vars reset removed
%-

global climada_global
if ~climada_init_vars,return;end; % init/import global variables

if ~exist('track_filename','var'),track_filename=[];end

% PARAMETERS
% whether we only warn (=0) or really delete pressure (=1) if forecast
% timesteps (with no pressure) exist
really_delete_pressure = 0;

month_names = ['JAN';'FEB';'MAR';'APR';'MAY';'JUN';'JUL';'AUG';'SEP';'OCT';'NOV';'DEC'];
tc_track    = []; % init

% ask for the track data filename
% --------------------------------
if isempty(track_filename)
    track_filename=[climada_global.data_dir filesep 'tc_tracks' filesep '*.dat'];
    [filename,pathname] = uigetfile(track_filename,'Select single TC event file:');
    if length(filename)<2
        return % Cancel pressed
    else
        track_filename=[pathname filename];
    end 
end

if exist(track_filename,'file')
    
    tc_track_param.EyeDiameterFactor=[];
    
    % read header
    % -----------
    fid=fopen(track_filename,'r');
    % get and convert data date, eg "Date: 06-19 SEP 2003"
    continue_reading_header = 1; % init
    while continue_reading_header
        one_line=fgetl(fid); % read next line
        if findstr(one_line,'Date:');
            try
                one_line      = upper(strrep(strrep(one_line,'Date:',''),' ',''));
                tc_track.yyyy = str2num(one_line(end-3:end));
                track_year    = str2num(one_line(end-3:end));
                tc_track.dd   = str2num(one_line(4:5));
                mmstr         = one_line(6:8);tc_track.mm=strmatch(mmstr,month_names);
            catch
                fprintf('WARNING: Date not properly read\n');
                tc_track.yyyy = 9999; % set to default
                tc_track.dd   = 99;
                tc_track.mm   = 99;
            end
        end % Date

        if findstr(one_line,'Hurricane');
            try
                tc_track.name=strrep(strrep(one_line,'Hurricane',''),' ','');
            catch
                tc_track.name='NNN';
            end
        end % Hurricane
        if findstr(one_line,'Typhoon');
            try
                tc_track.name=strrep(strrep(one_line,'Typhoon',''),' ','');
                tc_track.name=strrep(strrep(tc_track.name,'Super',''),' ','');
            catch
                tc_track.name='NNN';
            end
        end % Typhoon
        if findstr(one_line,'Cyclone');
            try
                tc_track.name=strrep(strrep(one_line,'Cyclone',''),' ','');
            catch
                tc_track.name='NNN';
            end
        end % Cyclone
        if findstr(one_line,'Tropical');
            try
                tc_track.name=strrep(strrep(one_line,'Tropical',''),' ','');
                tc_track.name=strrep(strrep(tc_track.name,'Depression',''),' ','');
                tc_track.name=strrep(strrep(tc_track.name,'Storm',''),' ','');
            catch
                tc_track.name='NNN';
            end
        end % Tropical

        if findstr(one_line,'*EyeDiameterFactor');
            try
                tc_track.EyeDiameterFactor=str2num( strrep(strrep(one_line,'*EyeDiameterFactor=',''),' ','') );
            catch
                fprintf('WARNING: EyeDiameterFactor not properly read\n');
                if ~isfield(tc_track,'EyeDiameterFactor')
                    tc_track.EyeDiameterFactor=1.0; % set to default
                end
            end
        end % EyeDiameterFactor

        % continue reading header until you get the ADV... line
        if findstr(one_line,'ADV') & ( findstr(one_line,'TIME') & findstr(one_line,'WIND'))
            continue_reading_header=0;
        end
    end % continue_reading_header
    
    % read data
    % ---------    
    %     1  14.00  -34.00 09/06/13Z   35  1005 TROPICAL STORM
    %     2  13.60  -34.50 09/06/15Z   35  1005 TROPICAL STORM
    %     3  13.40  -35.40 09/06/21Z   45  1000 TROPICAL STORM
    %     4  13.40  -36.10 09/07/03Z   50   997 TROPICAL STORM
    %     5  13.70  -37.10 09/07/09Z   55   994 TROPICAL STORM
    %     6  14.50  -37.70 09/07/15Z   65   987 HURRICANE-1
    %     7  15.20  -39.10 09/07/21Z   70   984 HURRICANE-1
    %     8  16.10  -40.20 09/08/03Z   80   979 HURRICANE-1
    %     9  16.90  -41.40 09/08/09Z   90   970 HURRICANE-2
    %     10  17.20  -42.60 09/08/15Z  100   962 HURRICANE-3
    %     11  17.90  -43.70 09/08/21Z  110   952 HURRICANE-3
    %     12  18.50  -44.50 09/09/03Z  115   948 HURRICANE-4
    %     
    node_i            = 1;
    use_pressure_data = 1;
    while not(feof(fid))
        tc_track.forecast(node_i) = 0; % init
        one_line              = fgetl(fid);
        [token,one_line]      = strtok(one_line); % split ADV
        if findstr(token,'+'),tc_track.forecast(node_i)=1;end
        
        [token,one_line]      = strtok(one_line); % split LAT
        tc_track.lat(node_i)  = str2num(token);
        [token,one_line]      = strtok(one_line); % split LON
        tc_track.lon(node_i)  = str2num(token);
        [token,one_line]      = strtok(one_line); % split TIME
        time_token            = token;
    %        try
        tc_track.mm(node_i)   = str2num(time_token(1:2)); % month
        tc_track.dd(node_i)   = str2num(time_token(4:5)); % day
        tc_track.hh(node_i)   = str2num(time_token(7:8)); % time (Z)
        tc_track.yyyy(node_i) = track_year; % year
                 
        %         catch
        %             % could be without month
        %             fprintf('WARNING: track file does NOT contain month: %s (dummy month=1 used)\n',time_token);
        %             tc_track.mm(node_i)=1; % just dummy month
        %             tc_track.dd(node_i)=str2num(time_token(1:2)); % day
        %             tc_track.time(node_i)=str2num(time_token(4:5)); % time (Z)
        %             track_year
        %             tc_track.yyyy(node_i)=track_year; % year
        %         end
                [token,one_line] = strtok(one_line); % split WIND
                try
                    tc_track.MaxSustainedWind(node_i)=str2num(token);
                catch
                    fprintf('WARNING: no valid MaxSustainedWind for %s\n',time_token);
                    tc_track.MaxSustainedWind(node_i)=0;
                end
                [token,one_line] = strtok(one_line); % split PR
                try
                    tc_track.CentralPressure(node_i)=str2num(token);
                catch
                    if use_pressure_data,fprintf('WARNING: %s, %s is (likely) a forecast timestep - pressure data thus not complete\n',track_filename,time_token);end
                    use_pressure_data=0;
                    tc_track.CentralPressure(node_i)=NaN;
                end
                [token,one_line] = strtok(one_line); % split STAT
                token=upper(strrep(token,' ',''));
                if strcmp(token,'TROPICAL')
                    tc_track.SaffSimp(node_i)=0;
                else
                    try
                        if strcmp(upper(deblank(token)),'SUPER'),token=one_line;end
                        token=strrep(upper(token),'HURRICANE-','');
                        token=strrep(upper(token),'TYPHOON-','');
                        token=deblank(strrep(upper(token),'SUPER',''));
                        tc_track.SaffSimp(node_i)=str2num(token);
                    catch
                        tc_track.SaffSimp(node_i)=0;
                    end
                end
            node_i=node_i+1; % increment
    end
    fclose(fid);
    
    % remove pressure if not in sync with wind
    if ~use_pressure_data && really_delete_pressure,tc_track=rmfield(tc_track,'CentralPressure');end
    
    %     track_timestep
    % 
    %     
    %     - processing time
    %     - processing yyyy
    %     - processing mm
    %     - processing dd
    
    % some hard-wired stuff
    tc_track.MaxSustainedWindUnit = 'kn';
    tc_track.CentralPressureUnit  = 'mb';
    tc_track.CelerityUnit         = 'kn';
    tc_track.unique_ID            = 1;
    tc_track.MaxSaffSimp          = max(tc_track.SaffSimp);
    tc_track.comment              = 'UNISYS single event';
    
    % some conversions
    if isfield(tc_track,'track_timestep'),tc_track.TimeStep=tc_track.track_timestep;end; % convert
    %%if isfield(tc_track,'MaxSaffSimp'),tc_track.SaffSimp=tc_track.MaxSaffSimp;end; % convert
    if isfield(tc_track,'unique_ID'),tc_track.ID_no=tc_track.unique_ID;end; % convert
    
    if findstr(tc_track.name,'-')
        tc_track.name=tc_track.name(3:end); % remove -X from name, where X is max SS class
    end
    
    if isfield(tc_track,'event_date') % convert to yyyy, mm and dd
        yyyymmddstr   = num2str(tc_track.event_date,'%8.8i');
        tc_track.yyyy = str2num(yyyymmddstr(1:4));
        tc_track.mm   = str2num(yyyymmddstr(5:6));
        tc_track.dd   = str2num(yyyymmddstr(7:8));
    end

else
    fprintf('ERROR: track data file %s does not exist\n',track_filename);
    return
end


% to convert to exact same order as in other climada routines:
tc_track_out.MaxSustainedWindUnit = tc_track.MaxSustainedWindUnit;
tc_track_out.CentralPressureUnit  = tc_track.CentralPressureUnit;


%--Lea,5.5.2011--
tc_track.datenum = datenum(tc_track.yyyy,tc_track.mm,tc_track.dd,tc_track.hh,0,0);

% find and delete duplicate entries
index_sametime = find(diff(tc_track.datenum)==0)+1;

tc_track.lon             (index_sametime) = [];
tc_track.lat             (index_sametime) = [];
tc_track.MaxSustainedWind(index_sametime) = [];
tc_track.CentralPressure (index_sametime) = [];
tc_track.yyyy            (index_sametime) = [];
tc_track.mm              (index_sametime) = [];
tc_track.dd              (index_sametime) = [];
tc_track.hh              (index_sametime) = [];
tc_track.datenum    (index_sametime) = [];

% calculate timestep between measurement and the following measurement in
% hours
for timestep_i = 1:length(tc_track.datenum)-1
    tc_track.TimeStep(timestep_i) = (tc_track.datenum(timestep_i+1) - tc_track.datenum(timestep_i))*24; %[h]
end
tc_track.TimeStep(length(tc_track.datenum)) = tc_track.TimeStep(length(tc_track.datenum)-1);
%------
  


% to convert to exact same order as in other climada routines:
tc_track_out.MaxSustainedWindUnit = tc_track.MaxSustainedWindUnit;
tc_track_out.CentralPressureUnit  = tc_track.CentralPressureUnit;
tc_track_out.TimeStep             = tc_track.TimeStep;
tc_track_out.lon                  = tc_track.lon;
tc_track_out.lat                  = tc_track.lat;
tc_track_out.MaxSustainedWind     = tc_track.MaxSustainedWind;
tc_track_out.CentralPressure      = tc_track.CentralPressure;
tc_track_out.yyyy                 = tc_track.yyyy;
tc_track_out.mm                   = tc_track.mm;
tc_track_out.dd                   = tc_track.dd;
tc_track_out.hh                   = tc_track.hh;
tc_track_out.ID_no                = tc_track.ID_no;
tc_track_out.orig_event_flag      = 1;
tc_track_out.datenum         = tc_track.datenum;
tc_track_out.extratrop            = ''; % dummy
tc_track_out.name                 = tc_track.name;

tc_track = []; % reset
tc_track = tc_track_out;

return

