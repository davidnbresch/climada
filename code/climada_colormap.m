function cmap = climada_colormap(peril_ID)

% init global variables
global climada_global
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('peril_ID', 'var'), peril_ID = []; end

cmap    = []; %init
steps10 = 10;
cmap1   = [];
cmap2   = [];

switch peril_ID
    case 'TC'
        % create colormap for wind:
        cmap =[  1.0000    1.0000    1.0000;
                0.8100    0.8100    0.8100;
                0.6300    0.6300    0.6300;
                1.0000    0.8000    0.2000;
                0.9420    0.6667    0.1600;
                0.8839    0.5333    0.1200;
                0.8259    0.4000    0.0800;
                0.7678    0.2667    0.0400;
                0.7098    0.1333         0;
                0.5412    0.1020         0];
        
    case 'TR'
        % create colormap for rain
        startcolor   = [0.89	0.93	0.89];
        middlecolor1 = [0.55	0.78	0.59];
        middlecolor2 = [0.43	0.84	0.78];
        endcolor     = [0.05	0.37	0.55];
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/2)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [cmap1; cmap2];
        
    case 'TS'
        % create colormap for surge
        startcolor   = [238 224 229]/255;
        middlecolor1 = [119 136 153]/255;
        middlecolor2 = [255 181 197]/255;
        endcolor     = [104  34 139]/255;
        for i=1:3
            cmap1(:,i)= startcolor(i):(middlecolor1(i)-startcolor(i))/(ceil(steps10/3)-1):middlecolor1(i);
            cmap2(:,i)= middlecolor2(i):(endcolor(i)-middlecolor2(i))/(ceil(steps10/2)-1):endcolor(i);
        end
        cmap = [[1 1 1];cmap1; cmap2];

end
    
        
        
        
        
        