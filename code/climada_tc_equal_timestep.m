function tc_track_out=climada_tc_equal_timestep(tc_track,default_min_TimeStep)
% tropical cycline track
% NAME:
%   bago_tc_equal_timestep
% PURPOSE:
%   NOTE: just a local copy of the TCart code tc_equal_timestep for
%   stand-alone use
%
%   make sure the track has equal timesteps - we go for 1 hour or the shortest
%   TimeStep if smaller than 1h (TimeStep is calculated first if not existing)
%
% CALLING SEQUENCE:
%   tc_track_out=climada_tc_equal_timestep(tc_track)
% EXAMPLE:
%   tc_track_out=climada_tc_equal_timestep(tc_track)
% INPUTS:
%   tc_track: a TC structure, eg as returned by *_read_unisys_track
% OPTIONAL INPUT PARAMETERS:
%   default_min_TimeStep: the default minimum TimeStep, default=1 [hour]
%       default defined in climada_init_vars
% OUTPUTS:
%   tc_track: a TC structure, with equal timesteps
% MODIFICATION HISTORY:
% David N. Bresch, david_bresch@gmail.com, 20040911, 20081006
% Mathias Hauser, 20120507
% Lea Mueller, 20121203
% David N. Bresch, david_bresch@gmail.com, 20040911, new version of MATLAB does not like adding empty stuff
% David N. Bresch, david_bresch@gmail.com, 20141231, datevecmx replaced
%-

% init global variables
global climada_global
if ~climada_init_vars,return;end

if ~exist('tc_track','var'),return;end
if ~exist('default_min_TimeStep','var'),default_min_TimeStep=[];end

% PARAMETERS
%
% whether we want to see a check plot
check_result=0; % default=0
%
% define the default minimum TimeStep
if isempty(default_min_TimeStep), default_min_TimeStep = climada_global.tc.default_min_TimeStep; end % 1 hour
if ~isfield(tc_track,'TimeStep'), tc_track             = climada_tc_add_timestep(tc_track)     ; end % add timestep

tc_track_out     = tc_track; % copy
tc_track.datenum = datenum(tc_track.yyyy,tc_track.mm,tc_track.dd)+tc_track.hh/24;

min_TimeStep     = min(min(tc_track.TimeStep),default_min_TimeStep);
if min_TimeStep == 0
    fprintf('ERROR in %s (starts %4.4i%2.2i%2.2i): minimal TimeStep zero - double entry in track data?\n',mfilename,tc_track.yyyy(1),tc_track.mm(1),tc_track.dd(1));
    return
end

if min_TimeStep < 0
    fprintf('ERROR in %s (starts %4.4i%2.2i%2.2i): minimal TimeStep negative - check dates, check timestep! \n',mfilename,tc_track.yyyy(1),tc_track.mm(1),tc_track.dd(1));
end

time_fact = tc_track.TimeStep/min_TimeStep;

% interpolate to higher resolution
tc_track_out.lat  = [];
tc_track_out.lon  = [];
if isfield(tc_track,'MaxSustainedWind'), tc_track_out.MaxSustainedWind = []; end
if isfield(tc_track,'CentralPressure') , tc_track_out.CentralPressure  = []; end
if isfield(tc_track,'forecast')        , tc_track_out.forecast         = []; end
tc_track_out.yyyy = [];
tc_track_out.mm   = [];
tc_track_out.dd   = [];
tc_track_out.hh   = [];

% remove fields that need to be recalculated
if isfield(tc_track_out,'Celerity'),tc_track_out = rmfield(tc_track_out,'Celerity'); end
if isfield(tc_track_out,'Azimuth') ,tc_track_out = rmfield(tc_track_out,'Azimuth') ; end


n_steps_in_between = round(time_fact);
if size(unique(n_steps_in_between),2) == 1
    n_steps_in_between = unique(n_steps_in_between);
    tc_track_out.lat   = climada_tc_interp(tc_track.lat, n_steps_in_between-1);
    tc_track_out.lon   = climada_tc_interp(tc_track.lon, n_steps_in_between-1);
    if isfield(tc_track,'MaxSustainedWind')
        tc_track_out.MaxSustainedWind = climada_tc_interp(tc_track.MaxSustainedWind, n_steps_in_between-1);
    end
    if isfield(tc_track,'CentralPressure')
        tc_track_out.CentralPressure  = climada_tc_interp(tc_track.CentralPressure, n_steps_in_between-1);
    end
    if isfield(tc_track,'SaffSimp') && length(tc_track.SaffSimp)>1
        tc_track_out.SaffSimp         = ceil(climada_tc_interp(tc_track.SaffSimp, n_steps_in_between-1));
    end
    if isfield(tc_track,'forecast')
        tc_track_out.forecast         = climada_tc_interp(tc_track.forecast, n_steps_in_between-1);
    end
    if ~isempty(tc_track_out.yyyy) % david.bresch@gmail.com, 20130318, newer version of MATLAB does not like adding empty stuff
        tc_track_out.nodetime_mat = datenum(tc_track_out.yyyy,tc_track_out.mm,tc_track_out.dd)+tc_track_out.hh/24;
    else
        tc_track_out.nodetime_mat=[];
    end
    tc_track_out.nodetime_mat = climada_tc_interp(tc_track.nodetime_mat, n_steps_in_between-1);
    
    tc_track_out.yyyy=str2num(datestr(tc_track_out.nodetime_mat,'yyyy'));
    tc_track_out.mm  =str2num(datestr(tc_track_out.nodetime_mat,'mm'));
    tc_track_out.dd  =str2num(datestr(tc_track_out.nodetime_mat,'dd'));
    tc_track_out.hh  =str2num(datestr(tc_track_out.nodetime_mat,'HH'));
    % until 20141231:
    %     DateVector        = datevecmx(tc_track_out.nodetime_mat);
    %     tc_track_out.yyyy = DateVector(:,1)';
    %     tc_track_out.mm   = DateVector(:,2)';
    %     tc_track_out.dd   = DateVector(:,3)';
    %     tc_track_out.hh   = DateVector(:,4)';
    tc_track_out.TimeStep = round(diff(tc_track_out.nodetime_mat)*24);
else
    for node_i=1:length(tc_track.lat)-1
        if time_fact(node_i)>1
            n_steps_in_between=round(time_fact(node_i));
            %%fprintf('processing node %i %4.4i%2.2i%2.2i_%2.2i: n_steps_in_between %i\n',node_i,tc_track.yyyy(node_i),tc_track.mm(node_i),tc_track.dd(node_i),tc_track.hh(node_i),n_steps_in_between);
            d_lat=climada_tc_interp([tc_track.lat(node_i) tc_track.lat(node_i+1)],n_steps_in_between-1);
            d_lon=climada_tc_interp([tc_track.lon(node_i) tc_track.lon(node_i+1)],n_steps_in_between-1);
            tc_track_out.lat=[tc_track_out.lat d_lat(1:end-1)]; % add
            tc_track_out.lon=[tc_track_out.lon d_lon(1:end-1)]; % add
            if isfield(tc_track,'MaxSustainedWind')
                d_MaxSustainedWind=climada_tc_interp([tc_track.MaxSustainedWind(node_i) tc_track.MaxSustainedWind(node_i+1)],n_steps_in_between-1);
                tc_track_out.MaxSustainedWind=[tc_track_out.MaxSustainedWind d_MaxSustainedWind(1:end-1)]; % add
            end
            if isfield(tc_track,'CentralPressure')
                d_CentralPressure=climada_tc_interp([tc_track.CentralPressure(node_i) tc_track.CentralPressure(node_i+1)],n_steps_in_between-1);
                tc_track_out.CentralPressure=[tc_track_out.CentralPressure d_CentralPressure(1:end-1)]; % add
            end
            if isfield(tc_track,'SaffSimp') && length(tc_track.SaffSimp)>1
                d_SaffSimp=ceil(climada_tc_interp([tc_track.SaffSimp(node_i) tc_track.SaffSimp(node_i+1)],n_steps_in_between-1));
                tc_track_out.SaffSimp=[tc_track_out.SaffSimp d_SaffSimp(1:end-1)]; % add
            end
            if isfield(tc_track,'forecast')
                d_forecast=climada_tc_interp([tc_track.forecast(node_i) tc_track.forecast(node_i+1)],n_steps_in_between-1);
                tc_track_out.forecast=[tc_track_out.forecast d_forecast(1:end-1)]; % add
            end
            datenums = tc_track.datenum(node_i)+(0:n_steps_in_between-1)*min_TimeStep/24;
            
            yyyy=str2num(datestr(datenums,'yyyy'));
            mm  =str2num(datestr(datenums,'mm'));
            dd  =str2num(datestr(datenums,'dd'));
            hhs =str2num(datestr(datenums,'HH'));
            % until 20141231:
            %             DateVector = datevecmx(datenums);
            %             yyyy     = DateVector(:,1);
            %             mm       = DateVector(:,2);
            %             dd       = DateVector(:,3);
            %             %hhs      = datestr(datenums,15);
            %             hhs      = DateVector(:,4);
            tc_track_out.yyyy = [tc_track_out.yyyy yyyy'];
            tc_track_out.mm   = [tc_track_out.mm mm'];
            tc_track_out.dd   = [tc_track_out.dd dd'];
            tc_track_out.hh   = [tc_track_out.hh hhs'];
        else
            % no interpolation
            tc_track_out.lat  = [tc_track_out.lat tc_track.lat(node_i)];
            tc_track_out.lon  = [tc_track_out.lon tc_track.lon(node_i)];
            if isfield(tc_track,'MaxSustainedWind'),
                tc_track_out.MaxSustainedWind = [tc_track_out.MaxSustainedWind tc_track.MaxSustainedWind(node_i)];
            end
            if isfield(tc_track,'CentralPressure')
                tc_track_out.CentralPressure  = [tc_track_out.CentralPressure tc_track.CentralPressure(node_i)];
            end
            if isfield(tc_track,'SaffSimp') && length(tc_track.SaffSimp)>1
                tc_track_out.SaffSimp         = [tc_track_out.SaffSimp tc_track.SaffSimp(node_i)];
            end
            if isfield(tc_track,'forecast')
                tc_track_out.forecast         = [tc_track_out.forecast tc_track.forecast(node_i)];
            end
            tc_track_out.yyyy = [tc_track_out.yyyy tc_track.yyyy(node_i)];
            tc_track_out.mm   = [tc_track_out.mm tc_track.mm(node_i)];
            tc_track_out.dd   = [tc_track_out.dd tc_track.dd(node_i)];
            tc_track_out.hh   = [tc_track_out.hh tc_track.hh(node_i)];
        end
    end % node_i
    % second last not interpolated, thus we need to add
    tc_track_out.lat  = [tc_track_out.lat tc_track.lat(end)];
    tc_track_out.lon  = [tc_track_out.lon tc_track.lon(end)];
    if isfield(tc_track,'MaxSustainedWind')
        tc_track_out.MaxSustainedWind = [tc_track_out.MaxSustainedWind tc_track.MaxSustainedWind(end)];
    end
    if isfield(tc_track,'CentralPressure')
        tc_track_out.CentralPressure  = [tc_track_out.CentralPressure tc_track.CentralPressure(end)];
    end
    if isfield(tc_track,'SaffSimp') && length(tc_track.SaffSimp)>1
        tc_track_out.SaffSimp         = [tc_track_out.SaffSimp tc_track.SaffSimp(end)];
    end
    if isfield(tc_track,'forecast')
        tc_track_out.forecast         = [tc_track_out.forecast tc_track.forecast(end)];
    end
    tc_track_out.yyyy = [tc_track_out.yyyy tc_track.yyyy(end)];
    tc_track_out.mm   = [tc_track_out.mm tc_track.mm(end)];
    tc_track_out.dd   = [tc_track_out.dd tc_track.dd(end)];
    tc_track_out.hh   = [tc_track_out.hh tc_track.hh(end)];
    tc_track_out.hh(tc_track_out.hh==24) = 0;
    % pos_24            = find(tc_track_out.hh==24);
    % if length(pos_24)>0,tc_track_out.hh(pos_24)=0;end
    tc_track_out.TimeStep     = tc_track_out.lat(1:end-1)*0+min_TimeStep;
    tc_track_out.nodetime_mat = datenum(tc_track_out.yyyy,tc_track_out.mm,tc_track_out.dd)+tc_track_out.hh/24;
end


if isfield(tc_track_out,'on_land')
    try
        tc_track_out = rmfield(tc_track_out,'on_land'); % update on land flag for higher resolution
        tc_track_out = tc_add_on_land_flag(tc_track_out);
    catch
        %% fprintf('unable to add on_land flag\n');
    end
end

if check_result
    for node_i=1:length(tc_track_out.lon)
        fprintf('node %2.0f %4.4i%2.2i%2.2i_%2.2i: %3.1f %3.1f %3.1f\n',node_i,tc_track_out.yyyy(node_i),tc_track_out.mm(node_i),tc_track_out.dd(node_i),tc_track_out.hh(node_i),...
            tc_track_out.lon(node_i),tc_track_out.lat(node_i),tc_track_out.MaxSustainedWind(node_i));
    end
    plot(tc_track.lon,tc_track.lat,'+r');hold on;
    plot(tc_track_out.lon,tc_track_out.lat,'.g')
end
