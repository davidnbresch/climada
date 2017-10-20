function in=climada_inpolygon(xq,yq,xv,yv,check_plot)
% climada template
% MODULE:
%   core
% NAME:
%   climada_inpolygon
% PURPOSE:
%   wrapper for inpolygon to work with octave in case of segmented polygons
%   (segments separated by NaNs, see EXAMPLE)
%
%   NOTE: for complex cases, still use inpolygon in MATLAB (as it can handle more
%   complex intersecting shapes etc.). I.e. call climada_inpolygon only if
%   climada_global.octave_mode=1. But some places, we call
%   climada_inpolygon, as this way, one can, once Octave has fixed the
%   issues, just make the chnage here in climada_inpolygon once.
%
%   See also: climada_inshape to check within shapes directly
% CALLING SEQUENCE:
%   in=climada_inpolygon(xq,yq,xv,yv,TEST_mode)
% EXAMPLE:
%   xv = [1 2 2 1 1 NaN 2.5 2.5 3 3 2.5];yv = [1 1 2 2 1 NaN 2.5 3 3 2.5 2.5];
%   xv = [1 2 2 1 1 NaN 2.5 2.5 3 3 2.5 NaN NaN];yv = [1 1 2 2 1 NaN 2.5 3 3 2.5 2.5 NaN NaN];
%   xq = rand(500,1)*5;yq = rand(500,1)*5;
%   in=climada_inpolygon(xq,yq,xv,yv,1)
% INPUTS:
%   xq,yq,xv,yv: see help inpolygo
% OPTIONAL INPUT PARAMETERS:
%   check_plot: =1 to shown the result (default=0)
% OUTPUTS:
%   in: the indices of the points within the polygon (see help inpolygon)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161002, initial
% David N. Bresch, david.bresch@gmail.com, 20171020, hint to climada_inshape added
%-

in=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('xq','var'),return;end
if ~exist('yq','var'),return;end
if ~exist('xv','var'),return;end
if ~exist('yv','var'),return;end
if ~exist('check_plot','var'),check_plot=0;end

% PARAMETERS

if ~climada_global.octave_mode
    in = inpolygon(xq,yq,xv,yv); % MATLAB
else
    isnan_pos=find(isnan(xv)==1); % find segments
    in=false(length(xq),1); % allocate
    if  ~isempty(isnan_pos)
        last_i=1;
        for segment_i=1:length(isnan_pos)
            xv_i=xv(last_i:isnan_pos(segment_i)-1);
            yv_i=yv(last_i:isnan_pos(segment_i)-1);
            if ~isempty(xv_i),in_i = inpolygon(xq,yq,xv_i,yv_i);in(in_i)=1;end
            last_i=isnan_pos(segment_i)+1;
        end % segment_i
        if last_i<length(xv)
            % last segment
            xv_i=xv(last_i:end);
            yv_i=yv(last_i:end);
            if isnan(xv_i(end)),xv_i=xv_i(1:end-1);yv_i=yv_i(1:end-1);end
            if ~isempty(xv_i),in_i = inpolygon(xq,yq,xv_i,yv_i);in(in_i)=1;end
        end
    else
        in = inpolygon(xq,yq,xv,yv);
    end % ~isempty(isnan_pos)
end % octave_mode

if check_plot
    plot(xv,yv,'LineWidth',2) % polygon
    axis equal
    hold on
    plot(xq,yq,'bo') % all points
    plot(xq(in),yq(in),'gx') % points inside
    legend({'target','all','inside'});
end % check_plot

end % climada_inpolygon