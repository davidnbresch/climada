function [h h_points] = plotclr(x,y,v, marker, markersize, colorbar_on, miv, mav, map, zero_off, v_exp)
%FUNCTION PLOTC(X,Y,V,'MARKER') plots the values of v colour coded
% at the positions specified by x and y, and v (z-axis) in a 3-D axis
% system. A colourbar is added on the right side of the figure.
%
% The colorbar strectches from the minimum value of v to its
% maximum in 9 steps (10 values).
%
% The last argument is optional to define the marker being used. The
% default is a point. To use a different marker (such as circles, ...) send
% its symbol to the function (which must be enclosed in '; see example).
%
% The plot is actually a 3D plot but the orientation of the axis is set
% such that it appears to be a plane 2D plot. However, you can toggle
% between 2D and 3D view either by using the command 'view(3)' (for 3D
% view) or 'view(2)' (for 2D), or by interactively rotating the axis
% system.
%
% Example:
% Define three vectors
%    x=1:10;y=1:10;p=randn(10,1);
%    plotc(x,y,p)
%
%    x=randn(100,1);
%    y=2*x+randn(100,1);
%    p=randn(100,1);
%    plotc(x,y,p,'d')
%    view(3)
%
% Uli Theune, University of Alberta, 2004
% modified by Stephanie Contardo, British OCeanographic Data Centre, 2006
%-

if ~exist('marker'     , 'var'), marker      = [];end
if ~exist('markersize' , 'var'), markersize  = [];end
if ~exist('colorbar_on', 'var'), colorbar_on = [];end
if ~exist('miv'        , 'var'), miv         = [];end
if ~exist('mav'        , 'var'), mav         = [];end
if ~exist('map'        , 'var'), map         = [];end
if ~exist('zero_off'   , 'var'), zero_off    = [];end
if ~exist('v_exp'      , 'var'), v_exp       = [];end

if v_exp;
    v = log10(v);
    v(isinf(v))         = nan;
    v(logical(imag(v))) = nan;
end


if isempty(marker)    , marker     = '.'     ; end
if isempty(markersize), markersize = 5'      ; end
if isempty(miv)       , miv        = min(v)  ; end
if isempty(mav)       , mav        = max(v)  ; end
if isempty(zero_off)  , zero_off   = 0       ; end

if zero_off
    if miv == 0
        miv = unique(sort(v, 'ascend'));
        if miv(1) == 0
            miv = miv(2);
        else
            miv = miv(1);
        end
    end
end

if isempty(map)
    map = colormap;
    %     if mav-miv+1<64
    %         map = colormap(jet(round(mav-miv)+1));
    %     else
    %         map = colormap;
    %     end
end
map = [map(1,:); map];

clrstep = (mav-miv+1)/(size(map,1)-1);


% Plot the points
hold on
h_points = [];

%below threshold
if zero_off
    iv = find(v <= miv & v>0);
else
    iv = find(v <= miv & v>miv+clrstep);
end
h_points(end+[1:length(iv)]) = plot3(x(iv),y(iv),v(iv),marker,'color',map(1,:),'markerfacecolor',map(1,:),'markersize',markersize,'linewidth',0.1);

for nc = 2:size(map,1)
    iv = find(v > miv+(nc-3)*clrstep & v <= miv+(nc-2)*clrstep) ;
    h_points(end+[1:length(iv)]) = ...
        plot3(x(iv),y(iv),v(iv),marker,'color',map(nc,:),'markerfacecolor',map(nc,:),'markersize',markersize,'linewidth',0.1);
end
iv = find(v >= mav);
h_points(end+[1:length(iv)]) = ...
    plot3(x(iv),y(iv),v(iv),marker,'color',map(end,:),'markerfacecolor',map(end,:),'markersize',markersize,'linewidth',0.1);

if colorbar_on    
    caxis([miv-clrstep mav])
    colormap(map)
    h = colorbar('ylim',[miv-clrstep mav]);
    if v_exp
        ytick_ = get(h,'ytick');
        set(h,'YTick',ytick_,'YTickLabel',10.^ytick_)
        ytick_2 = ytick_;
        %ytick_2(2:2:end) = nan;
        set(h,'YTick',ytick_,'YTickLabel',sprintf('%1.2g|',10.^ytick_2))
    end
else
    h = [];
end
grid on
view(2)
