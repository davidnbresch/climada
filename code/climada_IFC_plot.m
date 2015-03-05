function climada_IFC_plot(IFC, hist_check, prob_check,Gumbel_check, check_log,color_index)
% climada
% NAME:
%   climada_IFC_plot
% PURPOSE:
%   Plots the intensity frequency curve of a given hazard set. See
%   climada_hazard2IFC to create the IFC structure to be plotted from a
%   climada hazard set.
% CALLING SEQUENCE:
%   climada_IFC_plot(IFC, hist_check, prob_check,check_log,color_index)
% EXAMPLE:
%   climada_IFC_plot(IFC, 1, 1,0,3)
%   climada_IFC_plot(IFC)
% INPUTS:
%   IFC:            A structure, created using climada_hazard2IFC.
% OPTIONAL INPUT PARAMETERS:
%   hist_check:     Whether to plot the historical data points  (default = 1)
%   prob_check:     Whether to plot the probabilistic points    (default = 0)
%   check_log:      Whether to use logarithmic x (return period) axis (default = 0)
%   color_index:    Specify the color pair:
%                   1:  Red/orange
%                   2:  Blue/light blue
%                   3:  Green/light green
%                   4:  Violet/light violet
%                   5:  Dark orange/golden
%                   6:  Black/gray
% OUTPUTS:
% MODIFICATION HISTORY:
%   Gilles Stassen, gillesstassen@hotmail.com, 20150130
%-
if ~exist('IFC',    'var'),
    cprintf([1 0 0],'ERROR: must provide IFC struct as input. See climada_hazard2IFC \n');
    return;
end

if ~exist('hist_check',     'var'), hist_check  = 1;    end
if ~exist('prob_check',     'var'), prob_check  = 0;    end
if ~exist('check_log',      'var'), check_log   = 0;    end
if ~exist('color_index',    'var'), color_index = 1;    end

%set colors
color1 = [255  122  0;... % orange
    67 110 238;... % light blue
    102 205   0;... % light green
    238 130 238;... % light violet
    255 193  37;... % golden
    128 128 128     % gray
    ]/255;

color2 = [255  20  20;... % red
    0   0 139;... % blue
    0 139   0;... % green
    85 26 139;... % violet
    238 118 0;... % dark orange
    0   0   0     % black
    ]/255;

%legend
lgd_struct = get(legend);
if ~isempty(lgd_struct)
    lgd_str = lgd_struct.UserData.lstrings';
    lgd_hdl = lgd_struct.UserData.handles';
else
    lgd_str = {};
    lgd_hdl = [];
end
for poi_i = length(IFC):-1:1
    
    clr_mod = poi_i/length(IFC);
    
    %%historical data
    if hist_check
        h_ndx = IFC(poi_i).orig_event_flag == 1;
        h(1) = plot(1./IFC(poi_i).cum_event_freq(h_ndx),  IFC(poi_i).intensity(h_ndx), '.' , 'markersize',8,'color',  clr_mod .* color1(color_index,:));
        hold on
        h(2) = plot(1./IFC(poi_i).cum_event_freq(h_ndx),  IFC(poi_i).polyval(h_ndx), '--', 'markersize',3,'color', clr_mod .* color1(color_index,:));
        lgd_str{end+1} = sprintf('Hist. data %s centroid %i',IFC(poi_i).peril_ID,IFC(poi_i).centroid_ID);
        lgd_str{end+1} = sprintf('Hist. data smoothed %s', IFC(poi_i).peril_ID);
        lgd_hdl = [lgd_hdl h];
    end
    if prob_check
        p_ndx = IFC(poi_i).orig_event_flag == 0;
        
        if any(p_ndx)
            h(1) = plot(1./IFC(poi_i).cum_event_freq(p_ndx),  IFC(poi_i).intensity(p_ndx), '.' , 'markersize',8,'color',  clr_mod .* color2(color_index,:));
            hold on
            h(2) = plot(1./IFC(poi_i).cum_event_freq(p_ndx),  IFC(poi_i).polyval(p_ndx), '--', 'markersize',3,'color', clr_mod .* color2(color_index,:));
            
            lgd_str{end+1} = sprintf('Prob. data %s centroid %i',IFC(poi_i).peril_ID,IFC(poi_i).centroid_ID);
            lgd_str{end+1} = sprintf('Prob. data %s smoothed', IFC(poi_i).peril_ID);
            lgd_hdl = [lgd_hdl h];
        else
            cprintf([0.25 0.25 1],sprintf('NOTE: %s hazard set contains only historical data \n',IFC(poi_i).peril_ID))
        end
        
    end
    if Gumbel_check
        g = plot(1./IFC(poi_i).return_freq,  IFC(poi_i).return_polyval, 'o:', 'markersize',3,'color', clr_mod .* color2(color_index,:));
        %lgd_str = [lgd_str {sprintf('Gumbel fit \\mu = %10.1f, \\sigma = %10.1f centroid %i \n',...
        %    -IFC(poi_i).polyfit(1),-IFC(poi_i).polyfit(2),IFC(poi_i).centroid_ID)}];
        lgd_str = [lgd_str {sprintf('Gumbel fit \\mu = %s, \\sigma = %s, %s centroid %i',...
            num2str(-IFC(poi_i).polyfit(1),4),num2str(-IFC(poi_i).polyfit(2),4),IFC(poi_i).peril_ID,IFC(poi_i).centroid_ID)}];

        lgd_hdl = [lgd_hdl g];
    end
end

legend('-DynamicLegend');
if check_log
    legend(lgd_hdl,lgd_str,'location','nw')
    set(gca,'XScale','log');
else
    legend(lgd_hdl,lgd_str,'location','se')
    set(gca,'XScale','linear');
end

set(gca,'XGrid','on')
set(gca,'YGrid','on')
xlabel('Return period (years)')
switch IFC.peril_ID
    case 'TC'
        ylabel('Wind speed [m s^{-1}]')
    case 'TS'
        ylabel('Surge height [m]')
    case 'TR' 
        ylabel('Rainfall [mm]')
    case 'MA' 
        ylabel('Rainfall [mm]')
    case 'TR_m'
        ylabel('Rainfall [mm]')
    otherwise
        ylabel('Hazard intensity')
end

return;

