function fig = climada_hazard_plot_hr(hazard,event_i,label,caxis_range,plot_centroids,hist_check)
% climada plot single hazard event footprint
% NAME:
%   climada_hazard_plot_hr
% PURPOSE:
%   plot hazard event as high resolution contour on a map, works for all perils
%
%   See also the low-resolution version climada_hazard_plot
% CALLING SEQUENCE:
%   climada_hazard_plot_hr(hazard,event_i,label,caxis_range,plot_centroids,hist_check)
% EXAMPLE:
%   climada_hazard_plot_hr(hazard,1); % plot first event
%   climada_hazard_plot_hr; % prompt for hazard event set, plot largest event
% INPUTS:
%   hazard: hazard structure
%       > prompted for if empty
%   event_i: the i-th event in the hazard event set to be displayed
%       if event_i=0, the maximum intensity at each centroid is shown
%       if event_i=-i, the i-th 'largest' event (sum of intensities) is shown
%           e.g. for event_i=-2, the second largest event is shown
%       default=-1 (just to get something on the screen ;-)
% OPTIONAL INPUT PARAMETERS:
%   label: a struct with a label to add on the plot (i.e. a place)
%       longitude: the longitude (decimal)
%       latitude: the latitude (decimal)
%       name: the label itself, like 'gaga'
%   caxis_range: [minval maxval], the range of the color axis, e.g. [20 40]
%       to show colors for values brtween 20 and 40
%   plot_centroids: =1, plot centroids, =0 no (default)
%   hist_check: if =1, plot historic events only, =0 all (default)
% OUTPUTS:
%   creates a figure and returns figure handle
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com, 20150206
% David N. Bresch, david.bresch@gmail.com, 20150313, synchronized with climada_hazard_plot
%-

fig = []; % init

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard',     'var'), hazard=[];      end
if ~exist('event_i',    'var'), event_i=-1;     end
if ~exist('label',      'var'), label=[];       end
if ~exist('caxis_range','var'), caxis_range=[]; end
if ~exist('plot_centroids','var'), plot_centroids=0; end
if ~exist('hist_check', 'var'), hist_check = 1; end

if isempty(hazard),hazard=climada_hazard_load;end % prompt for and load hazard, if empty
if isempty(hazard),return;end

hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

% if interested in historical events only
if hist_check && event_i > 0
    event_i = interp1(hazard.event_ID(hazard.orig_event_flag ==1),hazard.event_ID(hazard.orig_event_flag ==1),event_i,'nearest');
end

% Prepare data
if event_i<0
    % search for i-th largest event
    event_sum=sum(hazard.intensity,2);
    [~,sorted_i]=sort(event_sum);
    event_ii=sorted_i(length(sorted_i)+event_i+1);
    hazard_intensity=full(hazard.intensity(event_ii,:)); % extract one event
    if event_i<-1
        title_str=sprintf('%s %i-largest event (%i) on %s',hazard.peril_ID,-event_i,event_ii,datestr(hazard.datenum(event_ii),'dddd dd mmmm yyyy'));
    else
        title_str=sprintf('%s largest event (%i) on %s',hazard.peril_ID,event_ii,datestr(hazard.datenum(event_ii),'dddd dd mmmm yyyy'));
    end
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard.name{event_ii},hazard.yyyy(event_ii),hazard.mm(event_ii),hazard.dd(event_ii),event_ii);
    end
    event_i = event_ii;
elseif event_i==0
    hazard_intensity=full(max(hazard.intensity)); % max intensity at each point
    title_str=sprintf('%s max intensity at each centroid',hazard.peril_ID);
else
    hazard_intensity=full(hazard.intensity(event_i,:)); % extract one event
    title_str=sprintf('%s event %i on %s',hazard.peril_ID,event_i,datestr(hazard.datenum(event_i),'dddd dd mmmm yyyy'));
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard.name{event_i},hazard.yyyy(event_i),hazard.mm(event_i),hazard.dd(event_i),event_i);
    end
end

[x, y] = meshgrid(unique(hazard.lon),unique(hazard.lat));

gridded_h_int = griddata(hazard.lon,hazard.lat,hazard_intensity,x,y);

fig = contourf(x,y,gridded_h_int, 'edgecolor','none');
hold on
title(title_str)
if isfield(hazard, 'peril_ID')
    % The following maps define the colour spectra, downloaded from https://www.ncl.ucar.edu/Document/Graphics/ColorTables/MeteoSwiss.shtml
    switch hazard.peril_ID
        case 'TS' 
            c_map = [
                254 254 254
                223 255 249
                154 217 202
                103 194 163
                64 173 117
                50 166 150
                90 160 205
                66 146 199
                76 141 196
                7  47 107
                7  30  70
                76   0 115]./255;
        case 'FL' 
            c_map = [
                254 254 254
                223 255 249
                154 217 202
                103 194 163
                64 173 117
                50 166 150
                90 160 205
                66 146 199
                76 141 196
                7  47 107
                7  30  70
                76   0 115]./255;
        case 'TC'
            % tc colours
            c_map = [
                255 255 255
                239 244 209
                232 244 158
                170 206  99
                226 237  22
                255 237   0
                255 237 130
                244 209 127
                237 165  73
                229 140  61
                219 124  61
                239   7  61
                232  86 163
                155 112 168
                99 112 247
                127 150 255
                142 178 255
                181 201 255]./255;
            % map_tc = [
            %     255 255 255
            %     255 245 204
            %     255 230 112
            %     255 204  51
            %     255 175  51
            %     255 153  51
            %     255 111  51
            %     255  85   0
            %     230  40  30
            %     200  30  20]./255;
        case 'TR' 
            c_map = [linspace(1,0,12)' linspace(1,0,12)' linspace(1,0.75,12)'];
        case 'MA'
            c_map = [linspace(1,0,12)' linspace(1,0,12)' linspace(1,0.75,12)'];
        case 'TR_m'
            c_map = [linspace(1,0,12)' linspace(1,0,12)' linspace(1,0.75,12)'];
        otherwise
            c_map = jet;
    end
end

colormap(c_map)

climada_plot_world_borders;
if plot_centroids,plot(hazard.lon,hazard.lat,'.b','MarkerSize',1);end

if ~isempty(label)
    text(label.lon, label.lat, label.name);
    plot(label.lon,label.lat,'xk');
end
if ~isempty(caxis_range), caxis(caxis_range); end
cb = colorbar;
if isfield(hazard,'units')
    ylabel(cb,sprintf('[%s]',hazard.units))
end
ylabel('Latitude')
xlabel('Longitude')


set(gcf,'color', 'w')
axis equal
axis([min(hazard.lon) max(hazard.lon) min(hazard.lat) max(hazard.lat)])

hold off
return
