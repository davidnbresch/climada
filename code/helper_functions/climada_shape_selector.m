function shapes = climada_shape_selector(fig,n_shapes,smooth_factor,hold_shapes,min_dist_frac,shape_file,disco_mode)
% select shapes
% MODULE:
%   climada core
% NAME:
%   climada_shape_selector
% PURPOSE:
%   select shapes in plot
% CALLING SEQUENCE:
%   shapes = climada_shape_selector(fig,N,hold_shapes,min_dist_frac)
% EXAMPLE:
%   shapes = climada_shape_selector(2,5,1,0.01)
%   shapes = climada_shape_selector
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   fig:    figure handle of figure in which you want to select shapes.
%           if not given, existing figure with largest handle number is
%           chosen. If no figures exist, climada_plot_world_borders is
%           called
%   n_shapes:       number of shapes you wish to draw
%   hold_shapes:    whether to keep plot of shapes on figure or remove
%                   them. Remove by default (=0)
%   min_dist_frac:  radius of circle within which a click would close the
%                   polygon (default = 2% of axis lims)
% OUTPUTS:
%   shapes:     structure array with fields X and Y defining the coordinates
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com, 20150729 init
% Gilles Stassen, gillesstassen@hotmail.com, 20150827, V2.0 :-)
% Lea Mueller, muellele@gmail.com, 20150915, set disco_mode to 0
% Lea Mueller, muellele@gmail.com, 20151106, move to core
% Lea Mueller, muellele@gmail.com, 20160314, rename to n_shapes from N, change input order
%-

shapes = struct([]);

global climada_global

if ~climada_init_vars,  return; end % init/import global variables
if ~exist('fig',            'var'), fig             = []; end
if ~exist('n_shapes',       'var'), n_shapes        = []; end
if ~exist('smooth_factor',  'var'), smooth_factor   = []; end
if ~exist('hold_shapes',    'var'), hold_shapes     = []; end
if ~exist('min_dist_frac',  'var'), min_dist_frac   = []; end
if ~exist('shape_file',     'var'), shape_file      = []; end
if ~exist('disco_mode',     'var'), disco_mode      = []; end

% set default parameters if not given
if isempty(n_shapes), n_shapes = 1; end
if isempty(smooth_factor), smooth_factor = 100; end
if isempty(hold_shapes), hold_shapes = 1; end
if isempty(min_dist_frac), min_dist_frac = 0.02; end
if isempty(shape_file), shape_file = 'NO_SAVE'; end
if isempty(disco_mode), disco_mode = 0; end
  
% if smooth_factor == 1,  disco_mode = 0; end % disco only when smoothing

% get handles of all existing figures
figs = findall(0,'Type','Figure');

if isempty(figs) && isempty(fig)
    % no existing figures, use default figure world borders.
    climada_plot_world_borders;
    axis equal
    axis tight
    fig = findall(0,'Type','Figure');
elseif isempty(fig)
    % get existing figure with highest number if no handle supplied as input
    fig = max(figs);
elseif ~ismember(fig,figs)
    % if fig handle specified in argument does not exist
    cprintf([1 0 0], 'ERROR: figure %i does not exist\n',fig)
    return
end

figure(fig)
hold on

% store old title, and set temporary title with instructions
title_str=get(get(gca,'Title'),'String');
title_fsz = get(get(gca,'Title'),'FontSize');
title_ang = get(get(gca,'Title'),'FontAngle');
title({sprintf('Select %i polygons:',n_shapes); 'click in circle to close shape'},'FontSize',14,'FontAngle','Italic')

p = []; % init
% The try-catch block is to avoid permanent lines on plot when something 
% goes wrong & should be commented out when developing function.
try 
    for n = 1:n_shapes
        S = 0;
        [X, Y] = ginput(1);
        
        % define radius of min dist as fraction of extent of exes
        [x_lim] = get(gca,'XLim');
        [y_lim] = get(gca,'YLim');
        
        x_buffer = min_dist_frac * abs(diff(x_lim));
        y_buffer = min_dist_frac * abs(diff(y_lim));
        
        min_dist = sqrt(x_buffer^2 + y_buffer^2);
        
        % draw circle with radius min_dist
        ang_res =   0:0.01:2*pi;
        x_circ  =   min_dist*cos(ang_res);
        y_circ  =   min_dist*sin(ang_res);
        circ(n) =   plot(X+x_circ,Y+y_circ,'color','r','linewidth',2);
        
        % color
        if disco_mode
            c_l = getelements(jet(n_shapes),n);
        else
            c_l = 'r';
        end
        
        dist = inf; % init
        
        % loop until user clicks inside circle centered on origin
        while dist > min_dist
            [X(end+1), Y(end+1)] = ginput(1);
            
            % to deal with duplicate points which cause issues
            if ismember(X(end),X(1:end-1))
                X(end) = X(end)*1.00000000001; % small shift
            end
            if ismember(Y(end),Y(1:end-1))
                Y(end) = Y(end)*1.00000000001; % small shift
            end
            % parameterise distance along curve
            S(end+1) = S(end) + sqrt((X(end)-X(end-1))^2 + (Y(end) - Y(end-1))^2);
            
            % plot segment
            p(end+1) = plot(X(end-1:end), Y(end-1:end),'color','r','linewidth',2);
            dist = sqrt((X(end)-X(1))^2 + (Y(end) - Y(1))^2);
        end
        X = [X X(1)];
        Y = [Y Y(1)];
        S(end+1) = S(end) + sqrt((X(end)-X(end-1))^2 + (Y(end) - Y(end-1))^2);
        p(end+1) = plot(X, Y,'color','r','linewidth',2);
        
        % smooth out polygon using interp1 according to distance
        % parameterisation.
        if smooth_factor >1
            X_ = []; Y_ = []; Sq =[];
            
            nS = round(smooth_factor/(length(S)-1));
            
            % get the same number of interpolation points for each segment
            for i = 1:length(S)-1
                Sq(end+1:end+nS) = linspace(S(i),S(i+1),nS);
            end
            X_ = interp1(S,X,Sq,'spline');
            Y_ = interp1(S,Y,Sq,'spline');
            
            X = X_; Y = Y_; clear X_ Y_
            
            p(end+1) = plot(X, Y,'color','b','linewidth',2);
            
            shapes(n).Sq = Sq; % save for disco mode
        end
                
        shapes(n).X = X; 
        shapes(n).Y = Y; 
        
        shapes(n).BoundingBox(:,1) = [nanmin(X) nanmax(X)];
        shapes(n).BoundingBox(:,2) = [nanmin(Y) nanmax(Y)];
        
        shapes(n).NAME = sprintf('shape %i',n);
        
        shapes(n).AREA = polyarea(X,Y);
        
        clear X
        clear Y
    end

    if smooth_factor > 1
        legend(p([1 end]), 'selected polygon', sprintf('smoothing parameter = %i',smooth_factor));
    end
    
    pause(1)
    
    if ~strcmpi(shape_file,'NO_SAVE')
        [fP, fN, fE] = fileparts(shape_file);
        if isempty(fP), fP = climada_global.data_dir;   end
        if isempty(fE), fE = '.mat';                    end
        fprintf('saving shapes to %s\n',[fP filesep fN fE])
        save([fP filesep fN fE],'shapes')
    end

catch
    % something went wrong, code does not get stuck, but continues to delete lines on plot
    cprintf([1 0 0],'ERROR: aborting\n') 
end

% delete circle
if exist('circ','var')
    for c_i = 1:length(circ)
        delete(circ(c_i))
    end
end

% delete lines
if exist('p','var') && ~hold_shapes
    for p_i = 1:length(p)
        delete(p(p_i))
    end
    legend off
end

if disco_mode
    legend off
    s = []; % init surface handle vector
    
    cmap = [jet(round(length(Sq)/2)+1); flipud(jet(round(length(Sq)/2)-1))];
    colormap(cmap)
    
    for n = 1:n_shapes
        X = shapes(n).X;    Y = shapes(n).Y;    Sq = shapes(n).Sq;
        
        s(end+1)  = surface([X;X],[Y;Y],ones([2 length(X)]),[Sq;Sq]./max(Sq),'edgecol','interp','linew',5, 'marker','o','markersize',1);
    end
    
    step = max(floor(length(cmap)/10),1);
    t0 = clock;
    while etime(clock,t0) < 10
        cmap = [cmap(end-step:end,:); cmap(1:end-step,:)];
        colormap(cmap)
        drawnow
        title('d(-_-)b DISCO d(-_-)b','FontWeight','Bold','Color',getelements(jet(50),max(floor(rand*50),1)),'interpreter','none')
        pause(0.1)
    end
    
    % delete surfs
    for s_i = 1:length(s)
        delete(s(s_i))
    end 
end

% remove Sq field from struct
if isfield(shapes,'Sq')
    shapes = rmfield(shapes,'Sq');
end

% restore title
title(title_str,'Fontsize',title_fsz,'FontAngle',title_ang)

return