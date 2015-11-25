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
% Gilles Stassen, 20150428, special plotting routine for MS hazard added
% Gilles Stassen, 20150703, "**1st", "**2nd" "**3rd" etc. added in title
% Lea Mueller, muellele@gmail.com, 20150713, add LS special case (intensity = 1-1/cutoff*distance_m)
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
if ~exist('hist_check', 'var'), hist_check = 0; end

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
    if hist_check
        event_sum=sum(abs(hazard.intensity),2).*hazard.orig_event_flag';
    else
        event_sum=sum(abs(hazard.intensity),2);
    end
    [~,sorted_i]=sort(event_sum,'descend');
    event_ii=sorted_i(abs(event_i));
    hazard_intensity=full(hazard.intensity(event_ii,:)); % extract one event
    if event_i<-1
        title_str=sprintf('%s %i** largest event (%i) on %s',hazard.peril_ID,-event_i,event_ii,datestr(hazard.datenum(event_ii),'dddd dd mmmm yyyy'));
        switch ((abs(event_i)/10) - floor(abs(event_i)/10))*10 % get last digit before decimal
            case 1
                title_str = strrep(title_str,'**','st');
            case 2
                title_str = strrep(title_str,'**','nd');
            case 3
                title_str = strrep(title_str,'**','rd');
            otherwise
                title_str = strrep(title_str,'**','th');
        end
    else
        try
            title_str=sprintf('%s largest event (%i) on %s',hazard.peril_ID,event_ii,datestr(hazard.datenum(event_ii),'dddd dd mmmm yyyy'));
        catch
            title_str=sprintf('%s largest event (%i) on %s',hazard.peril_ID,event_ii,...
                datestr([hazard.dd(event_ii) hazard.mm(event_ii) hazard.yyyy(event_ii)],'dddd dd mmmm yyyy'));
        end
    end
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard.name{event_ii},hazard.yyyy(event_ii),hazard.mm(event_ii),hazard.dd(event_ii),event_ii);
    end
    event_i = event_ii;
    
elseif event_i==0
    if ~hist_check
        hazard_intensity=full(max(hazard.intensity)); % max intensity at each point
    else
        hazard_intensity=full(max(hazard.intensity(hazard.orig_event_flag ==1)));
    end
    title_str=sprintf('%s max intensity at each centroid',hazard.peril_ID);
else
    hazard_intensity=full(hazard.intensity(event_i,:)); % extract one event
    title_str=sprintf('%s event %i on %s',hazard.peril_ID,event_i,datestr(hazard.datenum(event_i),'dddd dd mmmm yyyy'));
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard.name{event_i},hazard.yyyy(event_i),hazard.mm(event_i),hazard.dd(event_i),event_i);
    end
end

% construct regular grid
[x, y] = meshgrid(unique(hazard.lon),unique(hazard.lat));

if strcmp(hazard.peril_ID,'LS') && isfield(hazard,'elevation_m') && ~isfield(hazard,'cutoff_m') %to be on the safe side
    % also plot DEM for mudslide hazard
    z           = griddata(hazard.lon,hazard.lat,hazard.elevation_m,x,y);
    [C,h] = contourf(unique(hazard.lon),unique(hazard.lat),z,10);
    l_h = clabel(C,h);
     for i=1:length(l_h)
         s = get(l_h(i),'String'); % get string
         s = str2num(s); % convert in to number
         s = sprintf('%4.1f',s); % format as you need
         set(l_h(i),'String',s); % place it back in the figure
     end
    colormap(flipud(bone(50)))
    freezeColors
    hold on
    fig = scatter(hazard.lon(hazard_intensity~=0),hazard.lat(hazard_intensity~=0),'filled');
    set(fig,'Marker', 'o','CData',hazard_intensity(hazard_intensity ~=0));
    if any(hazard_intensity)
        caxis([min(hazard_intensity(hazard_intensity~=0)) max(hazard_intensity)]);
    end    
else
    % gridded intensity for contour plot
    if strcmp(hazard.peril_ID,'LS') && isfield(hazard,'cutoff_m') %to be on the safe side
        % transform intensity back to distance, see
        % climada_hazard_encode_distance for more information
        hazard_intensity = (1-hazard_intensity)*hazard.cutoff_m;
        hazard.units = 'm';
    end
    gridded_h_int = griddata(hazard.lon,hazard.lat,hazard_intensity,x,y);
    fig = contourf(x,y,gridded_h_int, 'edgecolor','none');
end

hold on
if hist_check
    title_str = [title_str ' (historical)'];
end
title(title_str)
if isfield(hazard, 'peril_ID')
    % The following maps define the colour spectra, downloaded from https://www.ncl.ucar.edu/Document/Graphics/ColorTables/MeteoSwiss.shtml
    colormap(climada_colormap(hazard.peril_ID))
end

climada_plot_world_borders;
if plot_centroids,plot(hazard.lon,hazard.lat,'.b','MarkerSize',1);end

if ~isempty(label)
    text(label.lon, label.lat, label.name);
    plot(label.lon, label.lat, 'xk');
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
