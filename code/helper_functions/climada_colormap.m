function [cmap,c_ax,xtickvals,cbar_str,intensity_threshold,peril_units] = climada_colormap(peril_ID,steps10,peril_units)
% climada color map
% NAME:
%   climada_colormap
% PURPOSE:
%   a helper function, returns a color map for specified perils, if empty
%   peril ID cmap jet is returned
% CALLING SEQUENCE:
%   cmap = climada_colormap(peril_ID)
% EXAMPLE:
%   [cmap,c_ax,xtickvals,cbar_str,intensity_threshold,peril_units]=climada_colormap('TC') % test with:
%   colormap(cmap);caxis(c_ax);hcbar=colorbar;set(hcbar,'XTick',xtickvals);
%   set(get(hcbar,'xlabel'),'String',cbar_str)
% INPUTS:
%   peril_ID: a 2-digit char peril ID, currently implemented are 'TC',
%       'TS', 'TR', 'FL', 'LS', 'FS' (factor of safety), see code for latest.
%       ='fraction': to plot hazard.fraction instead of hazard.intensity
%           This sets some other parameters accordingly, since fraction is
%           in the range 0..1
%       Or some (very) specific color maps, like:
%       ='assets','damage','schematic' or 'benefit', peril_units in this
%           case is just set = peril_ID and c_ax, xtickvals, cbar_str and
%           intensity_threshold are not defined
%       ='colorbrewer_sequential' for a colormap for sequential data that
%           prints well in b/w and even when photocopied (http://colorbrewer2.org)
%       ='colorbrewer_diverging': if values range -x..o..y
%   peril_units: the units of the respective peril, usuallly, pass hazard.units
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   cmap: the colormap, e.g. used in colormap(cmap)
%   c_ax: the axis min ans max, e.g. used in caxis(c_ax)
%   xtickvals: the tick values on the axis, e.g. hcbar=coloarbar;set(hcbar,'XTick',xtickvals);
%   cbar_str: the annotation of the colorbar, e.g. set(get(hcbar,'xlabel'),'String',cbar_str)
%   intensity_threshold: a threshould below which not to show intensities,
%       applied such as values(values<intensity_threshold)=NaN before plotting
%   peril_units: as on input, if defined on input, otherwise defaut units
%       for givdn peril
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, raw documentation
% Lea Mueller, muellele@gmail.com, 20140429, add colormaps for damage and schematic
% Lea Mueller, muellele@gmail.com, 20140429, add waterfall colormap
% Lea Mueller, muellele@gmail.com, 20150522, add mudslides (MS) colormap
% Lea Mueller, muellele@gmail.com, 20150607, add benefit colormap (grey-green) for averted damage in climada_MI_plot
% Lea Mueller, muellele@gmail.com, 20150713, add LS colormap
% Lea Mueller, muellele@gmail.com, 20150720, add FS (factor of safety) colormap
% Lea Mueller, muellele@gmail.com, 20150729, add assets colormap
% Lea Mueller, muellele@gmail.com, 20150729, add measures colormap
% Lea Mueller, muellele@gmail.com, 20150922, add benefit for adaptation bar chart colormap
% Lea Mueller, muellele@gmail.com, 20150924, special case if only one colour is required
% Lea Mueller, muellele@gmail.com, 20151201, update benefit colors (grey, yellow, green, turqoise)
% Lea Mueller, muellele@gmail.com, 20160201, add excess or rain (XR), lack of rain (LR) and lack of greenness (LG)
% Lea Mueller, muellele@gmail.com, 20160314, for TS and XR use only 8 colors (3 green, 5 blue)
% Lea Mueller, muellele@gmail.com, 20160316, add separate lack of greenness (LG) colormap (brown - yellow - green)
% Lea Mueller, muellele@gmail.com, 20160426, finetune lack of greenness colors
% Lea Mueller, muellele@gmail.com, 20160816, set number of colours to step10, in schematic, landslide and factor of safety
% David N. Bresch, david.bresch@gmail.com, 20170728, http://colorbrewer2.org maps  added
% David N. Bresch, david.bresch@gmail.com, 20171230, TC and WS maps updated
% David N. Bresch, david.bresch@gmail.com, 20180101, outputs xtickvals,cbar_str,intensity_threshold and peril_units added
% David N. Bresch, david.bresch@gmail.com, 20180102, 'fraction' added
%-

cmap=[];c_ax=[];xtickvals=[]; %init outputs
cbar_str='';
intensity_threshold=0;

%global climada_global % init global variables
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('peril_ID',    'var'), peril_ID     = ''; end
if ~exist('steps10' ,    'var'), steps10      = ''; end
if ~exist('peril_units', 'var'), peril_units  = ''; end

if isempty(steps10); steps10 = 10;end
cmap1   = []; cmap2   = [];

% special case if only one colour is required
only_one_step = 0;
if steps10 == 1, steps10 = steps10+1; only_one_step = 1; end

switch peril_ID
    
    case 'TC' % create colormap for wind:
        c_ax      = [0 90];
        if isempty(peril_units),peril_units='m/s';end
        cbar_str  = sprintf('wind speed (%s)',peril_units);
        xtickvals = 10:10:c_ax(2);
        intensity_threshold = 10;
        cmap = makeColorMap([1 0.8 0.2],[0.7098 0.1333 0],[0.3333 0.1020 0.5451],c_ax(2)/5-3);
        cmap = [1 1 1;0.81 0.81 0.81; 0.63 0.63 0.63;cmap];
        
        % until 20171230
        % cmap =[  1.0000    1.0000    1.0000;
        %     %0.8100    0.8100    0.8100;
        %     0.6300    0.6300    0.6300;
        %     1.0000    0.8000    0.2000;
        %     %0.9420    0.6667    0.1600;
        %     0.8839    0.5333    0.1200;
        %     0.8259    0.4000    0.0800;
        %     %0.7678    0.2667    0.0400;
        %     0.7098    0.1333         0;
        %     0.5412    0.1020         0;
        %     0.4078    0.1333    0.5451;
        %     0.3333    0.1020    0.5451];
        
    case {'TR','XR'} % create colormap for rain
        % 3 green colors, 5 blue colors (instead of originally 10)
        c_ax = [20 80];
        
        %         caxis_max = 300; %caxis_max = 500;
        %         xtick_    = caxis_max/5:caxis_max/5:caxis_max;
        %         cbar_str  = [hist_str 'rain sum (mm)'];
        
        startcolor   = [0.89	0.93	0.89];
        middlecolor1 = [0.55	0.78	0.59];
        middlecolor2 = [0.43	0.84	0.78];
        endcolor     = [0.05	0.37	0.55];
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/4)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [1.0 1.0 1.0; cmap1; cmap2];
        
    case {'TS','FL'} % create colormap for surge and flood
        
        c_ax      = [0 10];
        xtickvals = [ .2 .5 1 2 3 4 5 7.5 10];
        if isempty(peril_units),peril_units='m';end
        cbar_str  = sprintf('surge height (%s)',peril_units);
        intensity_threshold = 10;
        cmap = makeColorMap([1 0.8 0.2],[0.7098 0.1333 0],[0.3333 0.1020 0.5451],c_ax(2)-3);
        cmap = [1 1 1;0.81 0.81 0.81; 0.63 0.63 0.63;cmap];
        
        cmap=[0.2081    0.1663    0.5292
            0.2116    0.1898    0.5777
            0.2123    0.2138    0.6270
            0.2081    0.2386    0.6771
            0.1959    0.2645    0.7279
            0.1707    0.2919    0.7792
            0.1253    0.3242    0.8303
            0.0591    0.3598    0.8683
            0.0117    0.3875    0.8820
            0.0060    0.4086    0.8828
            0.0165    0.4266    0.8786
            0.0329    0.4430    0.8720
            0.0498    0.4586    0.8641
            0.0629    0.4737    0.8554
            0.0723    0.4887    0.8467
            0.0779    0.5040    0.8384
            0.0793    0.5200    0.8312
            0.0749    0.5375    0.8263
            0.0641    0.5570    0.8240
            0.0488    0.5772    0.8228
            0.0343    0.5966    0.8199
            0.0265    0.6137    0.8135
            0.0239    0.6287    0.8038
            0.0231    0.6418    0.7913
            0.0228    0.6535    0.7768
            0.0267    0.6642    0.7607
            0.0384    0.6743    0.7436
            0.0590    0.6838    0.7254
            0.0843    0.6928    0.7062
            0.1133    0.7015    0.6859
            0.1453    0.7098    0.6646
            0.1801    0.7177    0.6424
            0.2178    0.7250    0.6193
            0.2586    0.7317    0.5954
            0.3022    0.7376    0.5712
            0.3482    0.7424    0.5473
            0.3953    0.7459    0.5244
            0.4420    0.7481    0.5033
            0.4871    0.7491    0.4840
            0.5300    0.7491    0.4661
            0.5709    0.7485    0.4494
            0.6099    0.7473    0.4337
            0.6473    0.7456    0.4188
            0.6834    0.7435    0.4044
            0.7184    0.7411    0.3905
            0.7525    0.7384    0.3768
            0.7858    0.7356    0.3633
            0.8185    0.7327    0.3498
            0.8507    0.7299    0.3360
            0.8824    0.7274    0.3217
            0.9139    0.7258    0.3063
            0.9450    0.7261    0.2886
            0.9739    0.7314    0.2666
            0.9938    0.7455    0.2403
            0.9990    0.7653    0.2164
            0.9955    0.7861    0.1967
            0.9880    0.8066    0.1794
            0.9789    0.8271    0.1633
            0.9697    0.8481    0.1475
            0.9626    0.8705    0.1309
            0.9589    0.8949    0.1132
            0.9598    0.9218    0.0948
            0.9661    0.9514    0.0755
            0.9763    0.9831    0.0538];
        
    case 'WS' % create colormap for wind storm:
        c_ax      = [0 60];
        xtickvals = 10:10:c_ax(2);
        if isempty(peril_units),peril_units='m/s';end
        cbar_str  = sprintf('wind speed (%s)',peril_units);
        intensity_threshold = 10;
        cmap = makeColorMap([1 0.8 0.2],[0.7098 0.1333 0],[0.3333 0.1020 0.5451],c_ax(2)/5-3);
        cmap = [1 1 1;0.81 0.81 0.81; 0.63 0.63 0.63;cmap];
        
    case 'HS'
        c_ax      = [200 2000];
        xtickvals = c_ax(1):c_ax(1):c_ax(2);
        if isempty(peril_units),peril_units='Ekin';end
        cbar_str  = peril_units;
        intensity_threshold = 200;
        cmap = makeColorMap([1 0.8 0.2],[0.7098 0.1333 0],[0.3333 0.1020 0.5451],c_ax(2)/5-3);
        cmap = [1 1 1;0.81 0.81 0.81; 0.63 0.63 0.63;cmap];
        
    case 'EQ' % earthquake
        c_ax      = [0 15];
        if isempty(peril_units),peril_units='MMI';end
        cbar_str  = peril_units;
        xtickvals = [1 2 3 4 5 6 7 8 9 10 11 12 15];
        intensity_threshold = 1;
        
    case 'MS' % create colormap for mudslides
        c_ax = [0 3];
        xtickvals    = 0:c_ax(2)/10:c_ax(2);
        if isempty(peril_units),peril_units='m/m';end
        cbar_str  = peril_units;
        startcolor   = [0.6118   0.4   0.1216]; %brick
        middlecolor  = [0.9569   0.6431   0.3765]; %sandybrown
        endcolor     = [0.1333   0.5451   0.1333]; %forest green
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor(i)-startcolor(i))/(ceil(steps10/2)-1):middlecolor(i);
            cmap2(:,i)= middlecolor(i):(endcolor(i)-middlecolor(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [cmap1; cmap2];
        
    case 'LS' % landslide
        % create colormap for landslide (distance to landslide)
        c_ax = [0 1];
        xtickvals    = 0:c_ax(2)/10:c_ax(2);
        if isempty(peril_units),peril_units='m/m';end
        cbar_str  = peril_units;
        cmap = flipud(jet(steps10));
        cmap(end-3:end,:) = [];
        cmap = [cmap; 1 1 1; 1 1 1];
        %cmap = flipud(cmap);
        
    case 'FS' % factor of safety for landslides
        c_ax = [0 10];
        if isempty(peril_units),peril_units='factor';end
        cbar_str  = peril_units;
        xtickvals    = 0:c_ax(2)/10:c_ax(2);
        cmap = flipud(jet(steps10));
        cmap(end-3:end,:) = [];
        cmap = [cmap; 1 1 1; 1 1 1];
        
    case 'LR' % create colormap for lack of rain (LR)
        c_ax = [-10 10];
        xtickvals    = 0:c_ax(2)/10:c_ax(2);
        if isempty(peril_units),peril_units='mm';end
        cbar_str  = peril_units;
        cmap = [  1.0000    1.0000    1.0000;
            %0.8100    0.8100    0.8100;
            0.6300    0.6300    0.6300;
            1.0000    0.8000    0.2000;
            %0.9420    0.6667    0.1600;
            0.8839    0.5333    0.1200;
            0.8259    0.4000    0.0800;
            %0.7678    0.2667    0.0400;
            0.7098    0.1333         0;
            0.5412    0.1020         0;
            0.4078    0.1333    0.5451];
        %;  0.3333    0.1020    0.5451
        cmap = flipud(cmap);
        
    case 'LG' % create colormap for lack of greenness (NDVI)
        c_ax = [0 1.0];
        xtickvals    = 0:c_ax(2)/10:c_ax(2);
        if isempty(peril_units),peril_units='NDVI';end
        cbar_str  = peril_units;
        % create colormap for rain
        % 4 brown to yellow colors, 4 green colors (instead of originally 10)
        startcolor   = [199 97 20]/255;  %brown
        middlecolor1 = [1.00 0.80 0.20]; %yellow
        middlecolor2 = [0.89 0.93 0.89]; %light green
        endcolor     = [0.55 0.78 0.59]; %green
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/3)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/3)-1):endcolor(i);
        end
        cmap = [cmap1; cmap2];
        
    case 'fraction' % create colormap for hazard.fraction
        c_ax = [0 1.0];
        xtickvals    = c_ax(1):c_ax(2)/10:c_ax(2);
        if isempty(peril_units),peril_units='fraction';end
        cbar_str  = peril_units;
        cmap = [ % =flipud(colormap('gray'))
            1.0000    1.0000    1.0000
            0.9841    0.9841    0.9841
            0.9683    0.9683    0.9683
            0.9524    0.9524    0.9524
            0.9365    0.9365    0.9365
            0.9206    0.9206    0.9206
            0.9048    0.9048    0.9048
            0.8889    0.8889    0.8889
            0.8730    0.8730    0.8730
            0.8571    0.8571    0.8571
            0.8413    0.8413    0.8413
            0.8254    0.8254    0.8254
            0.8095    0.8095    0.8095
            0.7937    0.7937    0.7937
            0.7778    0.7778    0.7778
            0.7619    0.7619    0.7619
            0.7460    0.7460    0.7460
            0.7302    0.7302    0.7302
            0.7143    0.7143    0.7143
            0.6984    0.6984    0.6984
            0.6825    0.6825    0.6825
            0.6667    0.6667    0.6667
            0.6508    0.6508    0.6508
            0.6349    0.6349    0.6349
            0.6190    0.6190    0.6190
            0.6032    0.6032    0.6032
            0.5873    0.5873    0.5873
            0.5714    0.5714    0.5714
            0.5556    0.5556    0.5556
            0.5397    0.5397    0.5397
            0.5238    0.5238    0.5238
            0.5079    0.5079    0.5079
            0.4921    0.4921    0.4921
            0.4762    0.4762    0.4762
            0.4603    0.4603    0.4603
            0.4444    0.4444    0.4444
            0.4286    0.4286    0.4286
            0.4127    0.4127    0.4127
            0.3968    0.3968    0.3968
            0.3810    0.3810    0.3810
            0.3651    0.3651    0.3651
            0.3492    0.3492    0.3492
            0.3333    0.3333    0.3333
            0.3175    0.3175    0.3175
            0.3016    0.3016    0.3016
            0.2857    0.2857    0.2857
            0.2698    0.2698    0.2698
            0.2540    0.2540    0.2540
            0.2381    0.2381    0.2381
            0.2222    0.2222    0.2222
            0.2063    0.2063    0.2063
            0.1905    0.1905    0.1905
            0.1746    0.1746    0.1746
            0.1587    0.1587    0.1587
            0.1429    0.1429    0.1429
            0.1270    0.1270    0.1270
            0.1111    0.1111    0.1111
            0.0952    0.0952    0.0952
            0.0794    0.0794    0.0794
            0.0635    0.0635    0.0635
            0.0476    0.0476    0.0476
            0.0317    0.0317    0.0317
            0.0159    0.0159    0.0159
            0         0         0];
        
    case 'assets'
        cbar_str = peril_ID;
        cmap = [ % =flipud(colormap('autumn'))
            1.0000    1.0000         0
            1.0000    0.9841         0
            1.0000    0.9683         0
            1.0000    0.9524         0
            1.0000    0.9365         0
            1.0000    0.9206         0
            1.0000    0.9048         0
            1.0000    0.8889         0
            1.0000    0.8730         0
            1.0000    0.8571         0
            1.0000    0.8413         0
            1.0000    0.8254         0
            1.0000    0.8095         0
            1.0000    0.7937         0
            1.0000    0.7778         0
            1.0000    0.7619         0
            1.0000    0.7460         0
            1.0000    0.7302         0
            1.0000    0.7143         0
            1.0000    0.6984         0
            1.0000    0.6825         0
            1.0000    0.6667         0
            1.0000    0.6508         0
            1.0000    0.6349         0
            1.0000    0.6190         0
            1.0000    0.6032         0
            1.0000    0.5873         0
            1.0000    0.5714         0
            1.0000    0.5556         0
            1.0000    0.5397         0
            1.0000    0.5238         0
            1.0000    0.5079         0
            1.0000    0.4921         0
            1.0000    0.4762         0
            1.0000    0.4603         0
            1.0000    0.4444         0
            1.0000    0.4286         0
            1.0000    0.4127         0
            1.0000    0.3968         0
            1.0000    0.3810         0
            1.0000    0.3651         0
            1.0000    0.3492         0
            1.0000    0.3333         0
            1.0000    0.3175         0
            1.0000    0.3016         0
            1.0000    0.2857         0
            1.0000    0.2698         0
            1.0000    0.2540         0
            1.0000    0.2381         0
            1.0000    0.2222         0
            1.0000    0.2063         0
            1.0000    0.1905         0
            1.0000    0.1746         0
            1.0000    0.1587         0
            1.0000    0.1429         0
            1.0000    0.1270         0
            1.0000    0.1111         0
            1.0000    0.0952         0
            1.0000    0.0794         0
            1.0000    0.0635         0
            1.0000    0.0476         0
            1.0000    0.0317         0
            1.0000    0.0159         0
            1.0000         0         0];
        % beginColor  = [232 232 232 ]/255; %light grey
        % middleColor = [105 105 105 ]/255; %dark grey
        % cmap1 = makeColorMap(beginColor, middleColor, 4);
        % cmap2 = makeColorMap([255 236 139]/255, [255 97 3 ]/255, 6); %[255 153 18]/255 yellow
        % cmap3 = makeColorMap([255 64 64 ]/255, [176 23 31 ]/255, 2); %[255 153 18]/255 yellow
        % % cmap3 = makeColorMap([205 150 205 ]/255, [93 71 139 ]/255, 2); %[255 153 18]/255 yellow
        % cmap  = [cmap1; cmap2; cmap3];

    case 'damage' % create colormap for damage
        cbar_str = peril_ID;
        startcolor   = [238 224 229]/255; %lavenderblush 2
        middlecolor1 = [255 181 197]/255; %pink 1
        middlecolor2 = [238  18 137]/255; %deeppink 2
        endcolor     = [104  34 139]/255; %darkorchid 4
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/3)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [cmap1; cmap2];
        
    case 'schematic' % create schematic colormap (gray red)
        cbar_str = peril_ID;
        startcolor   = [244 244 244]/255; %sgi gray 96
        middlecolor1 = [193 193 193]/255; %sgi gray 76
        middlecolor2 = [255 114  86]/255; %coral 1
        endcolor     = [205   0   0]/255; %red 3
        cmap1 = makeColorMap(startcolor, middlecolor1, steps10);
        cmap2 = makeColorMap(middlecolor1, middlecolor2, steps10);
        cmap3 = makeColorMap(middlecolor2, endcolor, steps10);
        cmap = [cmap1; cmap2; cmap3];
        
    case 'waterfall' % create colormap for ECA waterfall graph
        cbar_str = peril_ID;
        startcolor   = [255 193  37]/255; %goldenrod 1
        middlecolor1 = [254 125  64]/255; %flesh
        middlecolor2 = [205  51  51]/255; %brown 3
        %endcolor     = [122 55 139]/255; %mediumorchid 4
        endcolor     = [139  28  98]/255; %maroon 4
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/2)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        % add grey color for dotted line
        cmap = [cmap1; cmap2; [120 120 120]/256];
        % yellow, orange, red and add grey color for dotted line
        %cmap = [255 215   0 ;...   %today
        %        255 127   0 ;...   %eco
        %        238  64   0 ;...   %clim
        %        205   0   0 ;...   %total risk
        %        120 120 120]/256;  %dotted line]/255;
        %cmap(1:4,:) = brighten(cmap(1:4,:),0.3);
        
    case 'benefit' % create colormap for climada_MI_plot (averted damage)
        cbar_str = peril_ID;
        
        beginColor1  = [232 232 232]/255; %light grey
        middleColor1 = [105 105 105]/255; %dark grey
        
        beginColor2  = [255 236 139]/255; %lightgolden
        %beginColor2  = [255 215   0]/255; %gold 1
        middleColor2 = [102 205 0 ]/255; %chartreuse3
        beginColor3 = [32 178 170 ]/255; %lightseagreen
        middleColor3  = [ 0 134 139]/255; %turquoise 4
        cmap1 = makeColorMap(beginColor1, middleColor1, 3);
        cmap2 = makeColorMap(beginColor2, middleColor2, 8); %[255 153 18]/255 yellow
        cmap3 = makeColorMap(beginColor3, middleColor3, 2); %[255 153 18]/255 yellow
        cmap  = [cmap1(1:end-1,:); cmap2; cmap3];
        
        %startcolor   = [193	205	193]/255; %honeydew 4
        %middlecolor  = [  0	201	 87]/255; %emeraldgreen
        %endcolor     = [ 61	145	 64]/255; %cobaltgreen
        %for i=1:3
        %    cmap1(:,i)= startcolor(i):(middlecolor(i)-startcolor(i))/(ceil(steps10/2)-1):middlecolor(i);
        %    cmap2(:,i)= middlecolor(i):(endcolor(i)-middlecolor(i))/(ceil(steps10/2)-1):endcolor(i);
        %end
        %cmap = [cmap1; cmap2];
        
    case 'measures' % create colormap for measures (adaptation_cost_curve)
        cbar_str = peril_ID;
        startcolor   = [  0 139  69]/255; %springgreen 3 %[ 69 139 116]/255; %aquamarine 4
        middlecolor  = [255 215   0]/255; %gold1
        endcolor     = [255 127   0]/255; %darkorange 1
        endcolor2    = [193 193 193]/255; %sgi gray 76
        
        n_steps = ceil(steps10/3);
        if n_steps>1, cmap1 = makeColorMap(startcolor,middlecolor,n_steps); else cmap1 = startcolor; end
        if steps10-2*n_steps>1, cmap2 = makeColorMap(middlecolor,endcolor,steps10-2*n_steps); else cmap2 = middlecolor; end
        if n_steps>1, cmap3 = makeColorMap(endcolor,endcolor2,n_steps); else cmap3 = endcolor; end
        cmap  = [cmap1; cmap2; cmap3];
        
        %beginColor  = [232 232 232 ]/255; %light grey
        %middleColor = [105 105 105 ]/255; %dark grey
        %cmap1 = makeColorMap(beginColor, middleColor, 4);
        %cmap2 = makeColorMap([255 236 139]/255, [255 97 3 ]/255, 6); %[255 153 18]/255 yellow
        %cmap3 = makeColorMap([255 64 64 ]/255, [176 23 31 ]/255, 2); %[255 153 18]/255 yellow
        %%cmap3 = makeColorMap([205 150 205 ]/255, [93 71 139 ]/255, 2); %[255 153 18]/255 yellow
        %cmap  = [cmap1; cmap2; cmap3];
        
    case 'benefit_adaptation_bar_chart' % create colormap for climada_MI_plot (averted damage)
        cbar_str = peril_ID;
        startcolor   = [ 51 153 51]/255; % green for benefits
        middlecolor  = [154 205 50]/255; % lighter green for reference benefits
        %endcolor     = [173 255 47]/255; % greenyellow
        endcolor     = [255 215  0]/255; % gold1
        cmap = makeColorMap(startcolor,middlecolor,endcolor,steps10);
        
    case 'colorbrewer_sequential' % from http://colorbrewer2.org/#type=sequential&scheme=OrRd&n=4
        cbar_str = peril_ID;
        cmap=[254,240,217;253,204,138;252,141,89;215,48,31];
        
    case 'colorbrewer_diverging' % from http://colorbrewer2.org/#type=sequential&scheme=OrRd&n=4
        cbar_str = peril_ID;
        cmap=[230,97,1;253,184,99;178,171,210;94,60,153];
        
    otherwise
        fprintf('WARNING %s not defined in %s\n',peril_ID,mfilename)
end

if only_one_step
    cmap = cmap(1,:);
end

if isempty(cmap),cmap = jet(15);end

end % climada_colormap