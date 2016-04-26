function [cmap, c_ax] = climada_colormap(peril_ID, steps10)
% climada color map
% NAME:
%   climada_colormap
% PURPOSE:
%   a helper function, returns a color map for specified perils, if empty
%   peril ID cmap jet is returned
% CALLING SEQUENCE:
%   cmap = climada_colormap(peril_ID)
% EXAMPLE:
%   cmap = climada_colormap('TC')
% INPUTS:
%   peril_ID: a peril ID, currently implemented are TC, TS, TR, FL, LS, FS (factor of safety), 
%   can also be assets, damage, schematic or benefit (averted damage).
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
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
%-

cmap = []; c_ax = []; %init output

%global climada_global % init global variables
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('peril_ID', 'var'), peril_ID = ''; end
if ~exist('steps10' , 'var'), steps10  = ''; end

if isempty(steps10); steps10 = 10;end
cmap1   = []; cmap2   = [];

% special case if only one colour is required
only_one_step = 0;
if steps10 == 1, steps10 = steps10+1; only_one_step = 1; end

switch peril_ID
    case 'TC'
        % create colormap for wind:
        c_ax = [0 90];
        cmap =[  1.0000    1.0000    1.0000;
            %0.8100    0.8100    0.8100;
            0.6300    0.6300    0.6300;
            1.0000    0.8000    0.2000;
            %0.9420    0.6667    0.1600;
            0.8839    0.5333    0.1200;
            0.8259    0.4000    0.0800;
            %0.7678    0.2667    0.0400;
            0.7098    0.1333         0;
            0.5412    0.1020         0;
            0.4078    0.1333    0.5451;
            0.3333    0.1020    0.5451];
        
    case {'TR','XR'}
        % create colormap for rain
        % 3 green colors, 5 blue colors (instead of originally 10)
        c_ax = [20 80];
        startcolor   = [0.89	0.93	0.89];
        middlecolor1 = [0.55	0.78	0.59];
        middlecolor2 = [0.43	0.84	0.78];
        endcolor     = [0.05	0.37	0.55];
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/4)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [1.0 1.0 1.0; cmap1; cmap2];
        
    case 'TS'
        % create colormap for surge
        c_ax = [1 10];
        startcolor   = [238 224 229]/255; %lavenderblush 2
        middlecolor1 = [119 136 153]/255; %lightslategray
        middlecolor2 = [255 181 197]/255; %pink 1
        endcolor     = [104  34 139]/255; %darkorchid 4
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/3)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [[1 1 1];cmap1; cmap2]; 
        
    case 'FL'
        % create colormap for flood
        c_ax = [0.05 1.15];
        startcolor   = [0.89	0.93	0.89];
        middlecolor1 = [0.55	0.78	0.59];
        middlecolor2 = [0.43	0.84	0.78];
        endcolor     = [0.05	0.37	0.55];
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/2)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [1.0 1.0 1.0; cmap1; cmap2];
        
    case 'WS'
        % create colormap for wind storm:
        c_ax = [0 80];
        cmap =[  1.0000    1.0000    1.0000;
            %0.8100    0.8100    0.8100;
            0.6300    0.6300    0.6300;
            1.0000    0.8000    0.2000;
            %0.9420    0.6667    0.1600;
            0.8839    0.5333    0.1200;
            0.8259    0.4000    0.0800;
            %0.7678    0.2667    0.0400;
            0.7098    0.1333         0;
            0.5412    0.1020         0;
            0.4078    0.1333    0.5451;
            0.3333    0.1020    0.5451];    
        
    case 'MS'
        % create colormap for mudslides
        c_ax = [];
        startcolor   = [0.6118   0.4   0.1216]; %brick
        middlecolor  = [0.9569   0.6431   0.3765]; %sandybrown
        endcolor     = [0.1333   0.5451   0.1333]; %forest green
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor(i)-startcolor(i))/(ceil(steps10/2)-1):middlecolor(i);
            cmap2(:,i)= middlecolor(i):(endcolor(i)-middlecolor(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [cmap1; cmap2];  
        
        
    case 'LS' 
        % create colormap for landslide (distance to landslide)
        c_ax = [0 1];       
        cmap = flipud(jet(15));
        cmap(end-3:end,:) = [];
        cmap = [cmap; 1 1 1; 1 1 1];
        
    case 'FS' %factor of safety for landslides
        c_ax = [0 10];       
        cmap = flipud(jet(15));
        cmap(end-3:end,:) = [];
        cmap = [cmap; 1 1 1; 1 1 1];
        
    case 'LR'
        % create colormap for lack of rain (LR)
        c_ax = [ ];
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
        
     case 'LG'
        % create colormap for lack of greenness (NDVI)
        c_ax = [0 1.0];
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
        
    case 'assets'
        beginColor  = [232 232 232 ]/255; %light grey
        middleColor = [105 105 105 ]/255; %dark grey
        cmap1 = makeColorMap(beginColor, middleColor, 4);
        cmap2 = makeColorMap([255 236 139]/255, [255 97 3 ]/255, 6); %[255 153 18]/255 yellow
        cmap3 = makeColorMap([255 64 64 ]/255, [176 23 31 ]/255, 2); %[255 153 18]/255 yellow
        % cmap3 = makeColorMap([205 150 205 ]/255, [93 71 139 ]/255, 2); %[255 153 18]/255 yellow
        cmap  = [cmap1; cmap2; cmap3];
        
    case 'damage'
        % create colormap for surge
        c_ax = [ ];
        startcolor   = [238 224 229]/255; %lavenderblush 2
        middlecolor1 = [255 181 197]/255; %pink 1
        middlecolor2 = [238  18 137]/255; %deeppink 2
        endcolor     = [104  34 139]/255; %darkorchid 4
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/3)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [cmap1; cmap2]; 
        
    case 'schematic'
        % create schematic colormap (gray red)
        c_ax = [ ];
        startcolor   = [244 244 244]/255; %sgi gray 96
        middlecolor1 = [193 193 193]/255; %sgi gray 76
        middlecolor2 = [255 114  86]/255; %coral 1
        endcolor     = [205   0   0]/255; %red 3
        cmap1 = makeColorMap(startcolor, middlecolor1,10);
        cmap2 = makeColorMap(middlecolor1, middlecolor2,10);
        cmap3 = makeColorMap(middlecolor2, endcolor,10);
        cmap = [cmap1; cmap2; cmap3];  
        
    case 'waterfall'
        % create colormap for ECA waterfall graph
        c_ax = [ ];
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
        
    case 'benefit'
        % create colormap for climada_MI_plot (averted damage)
        c_ax = [ ];
        
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
        
     case 'measures'
        % create colormap for measures (adaptation_cost_curve)
        c_ax = [ ];
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
        
    case 'benefit_adaptation_bar_chart'
        % create colormap for climada_MI_plot (averted damage)
        c_ax = [ ];
        startcolor   = [ 51 153 51]/255; % green for benefits
        middlecolor  = [154 205 50]/255; % lighter green for reference benefits
        %endcolor     = [173 255 47]/255; % greenyellow
        endcolor     = [255 215  0]/255; % gold1
        cmap = makeColorMap(startcolor,middlecolor,endcolor,steps10);
end

if only_one_step
    cmap = cmap(1,:);
end

if isempty(cmap)
    cmap = jet(15);
end