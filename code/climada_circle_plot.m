function climada_circle_plot(values,lon,lat,title_str,circle_diam,circle_format,marker_size,marker_format,overlay_plot,axis_range,max_value);
% climada catos event damage hazard probabilistic stochastic
% NAME:
%   climada_circle_plot
% PURPOSE:
%   plot circles with diameters scaled by values
%   in the range min(values)..max(values)
%   the routine does not open a new figure if one exists
%
%   see climada_circle_plot_legend for a legend to this plot
%
%   %% precedes a switched off option, not a comment
%
% CALLING SEQUENCE:
%   climada_circle_plot(values,lon,lat,title_str,circle_diam,circle_format,marker_size,marker_format,overlay_plot,axis_range,max_value);
% EXAMPLE:
%   climada_circle_plot('Test',lon,lat,values,10)
% INPUTS:
%   title_str: plot title
%   lon,lat,values: arrays of same size
% OPTIONAL INPUT PARAMETERS:
%   circle_diam: max diameter of the circles
%   circle_format: like 'or' for red circles
%   marker_size: size of markers denoting centers
%   marker_format: like '+b'
%   overlay_plot: if set to 1, only do an overlay, no country borders...
%   axis: if set [min(lon) max(lon) min(lat) max(lat)], otherwise
%   determined in the function
%   max_value: if set, use this value to scale circle diameters
% OUTPUTS:
%   figure
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
%-

%global climada_global
if ~climada_init_vars,return;end; % init/import global variables

values=full(values);

if ~exist('title_str','var'),title_str='';end;
if ~exist('circle_diam','var'),circle_diam=[];end;
if ~exist('circle_format','var'),circle_format=[];end;
if ~exist('marker_size','var'),marker_size=[];end;
if ~exist('marker_format','var'),marker_format=[];end;
if ~exist('overlay_plot','var'),overlay_plot=[];end;
if ~exist('axis_range','var'),axis_range=[];end;
if ~exist('max_value','var'),max_value=[];end;

% PARAMETERS
%
% set default values
if isempty(circle_diam),circle_diam=10;end; % default
if isempty(circle_format),circle_format='or';end; % default
if isempty(marker_size),marker_size=2;end; % default
if isempty(marker_format),marker_format='+b';end; % default
if isempty(overlay_plot),overlay_plot=0;end; % default
if isempty(axis_range),axis_range=[min(lon)-1 max(lon)+1 min(lat)-1 max(lat)+1];end; % default
if isempty(max_value),max_value=max(values);end; % default

circle_linewidth=1; % default=1

% if ~strcmp(title_str,'none') & ~overlay_plot
%     figure('Name',title_str,'NumberTitle','off','Color',[1 1 1]); % change BG color to white
% end;

minval=0.0;maxval=sqrt(abs(max_value)); % not minval=sqrt(abs(min(values)))
if maxval-minval~=0.0
    % establish plot
    if overlay_plot,hold on;end;
    if marker_size>0,plot(lon,lat,marker_format,'MarkerSize',marker_size);end % blue + at each centroid
    hold on;
    if ~overlay_plot,axis equal;axis(axis_range);end % set axis for good zoom
    MarkerSizes=sqrt(abs(values-minval))/(maxval-minval)*circle_diam;
    pos=find(isnan(MarkerSizes));
    if length(pos)>0,MarkerSizes(pos)=0;end;
    pos=find(MarkerSizes<1);if length(pos)>0,MarkerSizes(pos)=0;end;
    ok_points_pos=find(MarkerSizes>0);
    for ii=1:length(ok_points_pos)
        abs_ii=ok_points_pos(ii);
        plot(lon(abs_ii),lat(abs_ii),circle_format,'MarkerSize',MarkerSizes(abs_ii),'LineWidth',circle_linewidth);
        hold on;
    end
    
    if ~overlay_plot,climada_plot_world_borders(1);title(title_str);end;
    hold off;drawnow;

else
    fprintf('all locations have the same value - nothing plotted\n');
    %%msgbox('all locations have the same value - nothing plotted','plot warning');
end

return
