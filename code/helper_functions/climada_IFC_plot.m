function climada_IFC_plot(IFC,hist_check,check_log,color_index)
% climada
% NAME:
%   climada_IFC_plot
% PURPOSE:
%   Plots the intensity frequency curve of a given hazard set. See
%   climada_hazard2IFC to create the IFC structure to be plotted from a
%   climada hazard set.
%   Previous call: climada_hazard2IFC
% CALLING SEQUENCE:
%   climada_IFC_plot(IFC,hist_check,prob_check,Gumbel_check,check_log,color_index)
% EXAMPLE:
%   climada_IFC_plot(IFC,1,1,0,3)
%   climada_IFC_plot(climada_hazard2IFC)
% INPUTS:
%   IFC:  An intensity frequency curve structure, created using
%       climada_hazard2IFC. Either one IFC or an array of structures, i.e. IFC(i)
% OPTIONAL INPUT PARAMETERS:
%   hist_check: Whether to plot the historical data points  (default = 1)
%   check_log: Whether to use logarithmic x (return period) axis (default = 0)
%   color_index: Specify the color pair:
%       1:  Red/orange
%       2:  Blue/light blue
%       3:  Green/light green
%       4:  Violet/light violet
%       5:  Dark orange/golden
%       6:  Black/gray
% OUTPUTS:
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com, 20150130
% David N. Bresch, david.bresch@gmail.com, 20150309, bugfixes
% Lea Mueller, muellele@gmail.com, 20150318, changes according to hazard2IFC
% David N. Bresch, david.bresch@gmail.com, 20150405, IFC as struct array, white background
% Lea Mueller, muellele@gmail.com, 20160308, bugfix if no historical data
%-

if ~exist('IFC','var'),
    fprintf('ERROR: provide IFC struct as input. See climada_hazard2IFC\n');
    return
end

if ~exist('hist_check',     'var'), hist_check  = 1;    end
if ~exist('check_log',      'var'), check_log   = 0;    end
if ~exist('color_index',    'var'), color_index = 1;    end
% if ~exist('Gumbel_check',   'var'), Gumbel_check= 1;    end

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
%lgd_struct = get(legend);
lgd_struct={}; % bug fix
if ~isempty(lgd_struct)
    lgd_str = lgd_struct.UserData.lstrings';
    lgd_hdl = lgd_struct.UserData.handles';
else
    lgd_str = {};
    lgd_hdl = [];
end

IFCs=IFC; % bug-fix, such that we can use struct arrays, i.e. IFC(i) to contain one IFC, not IFC.intensity(i,:) etc.
for poi_ii = 1:length(IFCs)
    
    IFC=IFCs(poi_ii);
    poi_i=1; % bug fix, such that we can use struct arrays
    
    % probabilistic data
    %h_ndx = IFC(poi_i).orig_event_flag == 1;
    pos_indx = IFC.intensity(poi_i,:)>0;
    if sum(pos_indx)>0
        h(1) = plot(IFC.return_periods(poi_i,pos_indx),IFC.intensity(poi_i,pos_indx),'.' ,'markersize',10,'color',color2(color_index,:));
        hold on
        h(2) = plot(IFC.fit_return_periods,IFC.intensity_fit(poi_i,:),'--','markersize',3,'color',color2(color_index,:));
        lgd_str{end+1} = sprintf('%s intensity at centroid no. %i',IFC.peril_ID,IFC.centroid_ID(poi_i));
        lgd_str{end+1} = sprintf('%s fitted intensity', IFC.peril_ID);
        lgd_hdl = [lgd_hdl h(1:2)];
        
        % historical data
        if hist_check
            pos_indx = IFC.hist_intensity(poi_i,:)>0;
            if any(pos_indx)
                h(3) = plot(IFC.hist_return_periods(poi_i,pos_indx),IFC.hist_intensity(poi_i,pos_indx),'*' ,'markersize',5,'color',color1(color_index,:));
                lgd_str{end+1} = sprintf('%s historical intensity at centroid no. %i',IFC.peril_ID,IFC.centroid_ID(poi_i));
                lgd_hdl = [lgd_hdl h(3)];
            end
        end
        
        color_index = color_index+1;
        if color_index>length(color1)
            color_index=1;
        end
        
    end
    
    
    %     if Gumbel_check
    %         g = plot(1./IFC(poi_i).return_freq,  IFC(poi_i).return_polyval, 'o:', 'markersize',3,'color', clr_mod .* color2(color_index,:));
    %         %lgd_str = [lgd_str {sprintf('Gumbel fit \\mu = %10.1f, \\sigma = %10.1f centroid %i \n',...
    %         %    -IFC(poi_i).polyfit(1),-IFC(poi_i).polyfit(2),IFC(poi_i).centroid_ID)}];
    %         lgd_str = [lgd_str {sprintf('Gumbel fit \\mu = %s, \\sigma = %s, %s centroid %i',...
    %             num2str(-IFC(poi_i).polyfit(1),4),num2str(-IFC(poi_i).polyfit(2),4),IFC(poi_i).peril_ID,IFC(poi_i).centroid_ID)}];
    %
    %         lgd_hdl = [lgd_hdl g];
    %     end
end % poi_ii

legend('-DynamicLegend');
if check_log
    legend(lgd_hdl,lgd_str,'location','nw')
    set(gca,'XScale','log');
else
    legend(lgd_hdl,lgd_str,'location','se')
    set(gca,'XScale','linear');
end

% set axis
max_rp  = max(max(IFC.return_periods))*1.1;
max_int = max(max(IFC.intensity))*1.1;
if max_rp*max_int>0axis([0 max_rp 0 max_int]);end

% set(gca,'XGrid','on')
% set(gca,'YGrid','on')
xlabel('Return period (years)')
switch IFC.peril_ID
    case 'TC'
        ylabel('Wind speed (m/s)')
    case 'WS'
        ylabel('Wind speed (m/s)')
    case 'TS'
        ylabel('Surge height (m)')
    case 'TR'
        ylabel('Rainfall (mm)')
    case 'EQ'
        ylabel('MMI')
    case 'MA'
        ylabel('Rainfall (mm)')
    case 'TR_m'
        ylabel('Rainfall (mm)')
    case 'VQ'
        ylabel('Ash depth (cm)')
    %case 'XR'
    %    ylabel('Excess rain (mm in multiple days)')
    otherwise
        ylabel('Hazard intensity')
end

set(gcf,'Color',[1 1 1]) % white background

end % climada_IFC_plot