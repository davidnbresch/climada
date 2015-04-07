function varargout = climada_interp1(varargin)
%INTERP1 1-D interpolation (table lookup)
%
%   SPECIAL: copy of original interp1 with some checks removed for speedup,
%   since called thousands of times from climada_EDS_calc
%   In case you encounter troubles, just replace calls of climada_interp1
%   with interp1 in climada_EDS_calc. 
%   20150320, david.bresch@gmail.com
%
%   Some features of INTERP1 will be removed in a future release.
%   See the R2012a release notes for details.
%
%   Vq = INTERP1(X,V,Xq) interpolates to find Vq, the values of the
%   underlying function V=F(X) at the query points Xq. X must
%   be a vector of length N.
%   If V is a vector, then it must also have length N, and Vq is the
%   same size as Xq.  If V is an array of size [N,D1,D2,...,Dk], then
%   the interpolation is performed for each D1-by-D2-by-...-Dk value
%   in V(i,:,:,...,:).
%   If Xq is a vector of length M, then Vq has size [M,D1,D2,...,Dk].
%   If Xq is an array of size [M1,M2,...,Mj], then Vq is of size
%   [M1,M2,...,Mj,D1,D2,...,Dk].
%
%   Vq = INTERP1(V,Xq) assumes X = 1:N, where N is LENGTH(V)
%   for vector V or SIZE(V,1) for array V.
%
%   Interpolation is the same operation as "table lookup".  Described in
%   "table lookup" terms, the "table" is [X,V] and INTERP1 "looks-up"
%   the elements of Xq in X, and, based upon their location, returns
%   values Vq interpolated within the elements of V.
%
%   Vq = INTERP1(X,V,Xq,METHOD) specifies alternate methods.
%   The default is linear interpolation. Use an empty matrix [] to specify
%   the default. Available methods are:
%
%     'nearest'  - nearest neighbor interpolation
%     'linear'   - linear interpolation
%     'spline'   - piecewise cubic spline interpolation (SPLINE)
%     'pchip'    - shape-preserving piecewise cubic interpolation
%     'cubic'    - same as 'pchip'
%     'v5cubic'  - the cubic interpolation from MATLAB 5, which does not
%                  extrapolate and uses 'spline' if X is not equally
%                  spaced.
%
%   Vq = INTERP1(X,V,Xq,METHOD,'extrap') uses the interpolation algorithm
%   specified by METHOD to perform extrapolation for elements of Xq outside
%   the interval spanned by X.
%
%   Vq = INTERP1(X,V,Xq,METHOD,EXTRAPVAL) replaces the values outside of the
%   interval spanned by X with EXTRAPVAL.  NaN and 0 are often used for
%   EXTRAPVAL.  The default extrapolation behavior with four input arguments
%   is 'extrap' for 'spline' and 'pchip' and EXTRAPVAL = NaN (NaN +NaNi for 
%   complex values) for the other methods.
%
%   PP = INTERP1(X,V,METHOD,'pp') will use the interpolation algorithm specified
%   by METHOD to generate the ppform (piecewise polynomial form) of V. The
%   method may be any of the above METHOD except for 'v5cubic'. PP may then
%   be evaluated via PPVAL. PPVAL(PP,Xq) is the same as
%   INTERP1(X,V,Xq,METHOD,'extrap').
%
%   For example, generate a coarse sine curve and interpolate over a
%   finer abscissa:
%       X = 0:10; V = sin(X); Xq = 0:.25:10;
%       Vq = climada_interp1(X,V,Xq); plot(X,V,'o',Xq,Vq)
%
%   For a multi-dimensional example, we construct a table of functional
%   values:
%       X = [1:10]'; V = [ X.^2, X.^3, X.^4 ];
%       Xq = [ 1.5, 1.75; 7.5, 7.75]; Vq = climada_interp1(X,V,Xq);
%
%   creates 2-by-2 matrices of interpolated function values, one matrix for
%   each of the 3 functions. Vq will be of size 2-by-2-by-3.
%
%   Class support for inputs X, V, Xq, EXTRAPVAL:
%      float: double, single
%
%   See also INTERP1Q, INTERPFT, SPLINE, PCHIP, INTERP2, INTERP3, INTERPN, PPVAL.
%   Copyright 1984-2012 The MathWorks, Inc.
%   $Revision: 5.41.4.25 $  $Date: 2012/10/29 19:19:25 $
%   david.bresch@gmail.com, 20150301, copied as climada_interp1 for speedup (but limited functionality compared to interp1)
%-

% Determine input arguments.
% Work backwards parsing from the end argument.

% Set up the defaults
% next two lines commented out compared to original interp1 for speedup
%narginchk(2,5);
%[method,extrapval,ndataarg,pp] = parseinputs(varargin{:});
% and kind of hard-wired next three lines:
method=varargin{4};
extrapval=[];
ndataarg=3;

% next four lines also commented out compared to original interp1 for speedup
% if ~isempty(pp)
%     varargout{1} = pp;
%     return
% end
% Set up X, V, and Xq and sanity check the data
% At this point we have two possible scenarios
% (X,V,Xq) or (V,Xq) and V may not be a vector
% if ndataarg ~= 2 or  ndataarg ~=3, error

if ndataarg == 2
    V = varargin{1};
    if isvector(V)
        orig_size_v = size(V);
        V = V(:); % Reorient not considered a resize
    else
        orig_size_v = size(V);
        n = orig_size_v(1);
        ds = orig_size_v(2:end);
        prodDs = prod(ds);
        V = reshape(V,[n prodDs]);
    end
    Xq = varargin{2};
    X =(1:size(V,1))';
elseif ndataarg == 3
    X = varargin{1};
    if ~isnumeric(X)
        error(message('MATLAB:climada_interp1:Xnumeric'));
    end
    V = varargin{2};
    if isvector(V)
        orig_size_v = size(V);
        V = V(:); % Reorient not considered a resize
    else
        orig_size_v = size(V);
        n = orig_size_v(1);
        ds = orig_size_v(2:end);
        prodDs = prod(ds);
        V = reshape(V,[n prodDs]);
    end
    X = X(:);
    if any(diff(X)<0)
        [X, idx] = sort(X);
        V = V(idx,:);
    end
    Xq = varargin{3};
else
    error(message('MATLAB:climada_interp1:nargin'));
end
if ~isfloat(V)
    error(message('MATLAB:climada_interp1:NonFloatValues'));
end

if isscalar(X)
    if isempty(Xq)
        varargout{1} = zeros(size(Xq));
        return
    end
end

if isvector(V)% V is a vector so size(Vq) == size(Xq)
    siz_vq = size(Xq);
else
    if isvector(Xq)% V is not a vector but Xq is. Batch evaluation.
        siz_vq = [length(Xq) orig_size_v(2:end)];
    else% Both V and Xq are non-vectors
        siz_vq = [size(Xq) orig_size_v(2:end)];
    end
end

if ~isempty(extrapval)
    if ischar(extrapval)
        extrapval = NaN;
        if ~isreal(V)
            extrapval = NaN + 1i*NaN;
        end
    end
    if ~isempty(Xq) && isfloat(Xq) && isreal(Xq)
        % Impose the extrap val; this is independent of method
        extptids = Xq < X(1) | Xq > X(end);
        if any(extptids(:))
            Xq = Xq(~extptids);
        else
            extrapval = [];
        end
    else
        extrapval = [];
    end
end

Xqcol = Xq(:);
num_vals = size(V,2);
if any(~isfinite(V(:))) || (num_vals > 1 && strcmpi(method,'pchip'))
    F = griddedInterpolant(X,V(:,1),method);
    if any(strcmpi(F.Method,{'spline','pchip'})) && any(find(isnan(V)))
        VqLite = Interp1DStripNaN(X,V,Xq,F.Method);
    else
        VqLite = zeros(numel(Xqcol),num_vals);
        VqLite(:,1) = F(Xqcol);
        for iv = 2:num_vals
            F.Values = V(:,iv);
            VqLite(:,iv) = F(Xqcol);
        end
    end
else % can use ND
    if (num_vals > 1)
        Xext = {cast(X,'double'),(1:num_vals)'};
        F = griddedInterpolant(Xext,V,method);
        VqLite = F({cast(Xqcol,class(Xext{1})),Xext{2:end}});
    else
        F = griddedInterpolant(X,V,method);
        VqLite = F(Xqcol);
    end
end

if ~isempty(extrapval)
    % Vq is too small since elems of Xq were removed.
    sizeVqLite = size(VqLite);
    Vq = zeros([siz_vq(1) sizeVqLite(2:end)],superiorfloat(X,V,Xq));
    Vq(~extptids,:) = VqLite;
    Vq(extptids,:)  = extrapval;
    % Reshape result, possibly to an ND array
    varargout{1} = reshape(Vq,siz_vq);
else
    VqLite = reshape(VqLite,siz_vq);
    varargout{1} = cast(VqLite,superiorfloat(X,V,Xq));
end

end % INTERP1

%-------------------------------------------------------------------------%
function Vq = Interp1DStripNaN(X,V,Xq,method)

Xqcol = Xq(:);
num_value_sets = 1;
numXq = numel(Xqcol);
if ~isvector(V)
    num_value_sets = size(V,2);
end

% Allocate Vq
Vq = zeros(numXq,num_value_sets);
nans_stripped = false;
for i = 1:num_value_sets
    numvbefore = numel(V(:,i));
    [xi, vi] = stripnansforspline(X,V(:,i));
    numvafter = numel(vi);
    if numvbefore > numvafter
        nans_stripped = true;
    end
    F = griddedInterpolant(xi,vi,method);
    if isempty(Xq)
        Vq(:,i) = Xqcol;
    else
        Vq(:,i) = F(Xqcol);
    end
end
if nans_stripped
    warning(message('MATLAB:climada_interp1:NaNstrip'));
end
end

%-------------------------------------------------------------------------%
function sanitycheck(X,V)
if ~isvector(X)
    error(message('MATLAB:climada_interp1:Xvector'));
end
if ~isnumeric(X)
    error(message('MATLAB:climada_interp1:Xnumeric'));
end
if length(X) ~= size(V,1);
    if isvector(V)
        error(message('MATLAB:climada_interp1:YVectorInvalidNumRows'))
    else
        error(message('MATLAB:climada_interp1:YInvalidNumRows'));
    end
end
end
%-------------------------------------------------------------------------%
%     'nearest'  - nearest neighbor interpolation
%     'linear'   - linear interpolation
%     'spline'   - piecewise cubic spline interpolation (SPLINE)
%     'pchip'    - shape-preserving piecewise cubic interpolation
%     'cubic'    - same as 'pchip'
%     'v5cubic'  - the cubic interpolation from MATLAB 5, which does not
function methodname = sanitycheckmethod(method)
if isempty(method)
    methodname = 'linear';
else
    if method(1) == '*'
        method(1) = [];
    end
    switch lower(method(1))
        case 'n'
            methodname = 'nearest';
        case 'l'
            methodname = 'linear';
        case 's'
            methodname = 'spline';
        case {'p', 'c'}
            methodname = 'pchip';
        case 'v'  % 'v5cubic'
            methodname = 'cubic';
        otherwise
            error(message('MATLAB:climada_interp1:InvalidMethod'));
    end
end
end

%-------------------------------------------------------------------------%
function pp = ppinterp(X,V, orig_size_v, method)
%PPINTERP ppform interpretation.
n = size(V,1);
ds = 1;
prodDs = 1;
if ~isvector(V)
    ds = orig_size_v(2:end);
    prodDs = size(V,2);
end

switch method(1)
    case 'n' % nearest
        breaks = [X(1); ...
            (X(1:end-1)+X(2:end))/2; ...
            X(end)].';
        coefs = V.';
        pp = mkpp(breaks,coefs,ds);
    case 'l' % linear
        breaks = X.';
        page1 = (diff(V)./repmat(diff(X),[1, prodDs])).';
        page2 = (reshape(V(1:end-1,:),[n-1, prodDs])).';
        coefs = cat(3,page1,page2);
        pp = mkpp(breaks,coefs,ds);
    case 'p' % pchip and cubic
        pp = pchip(X.',reshape(V.',[ds, n]));
    case 's' % spline
        pp = spline(X.',reshape(V.',[ds, n]));
    case 'c' % v5cubic
        b = diff(X);
        if norm(diff(b),Inf) <= eps(norm(X,Inf))
            % data are equally spaced
            a = repmat(b,[1 prodDs]).';
            yReorg = [3*V(1,:)-3*V(2,:)+V(3,:); ...
                V; ...
                3*V(n,:)-3*V(n-1,:)+V(n-2,:)];
            y1 = yReorg(1:end-3,:).';
            y2 = yReorg(2:end-2,:).';
            y3 = yReorg(3:end-1,:).';
            y4 = yReorg(4:end,:).';
            breaks = X.';
            page1 = (-y1+3*y2-3*y3+y4)./(2*a.^3);
            page2 = (2*y1-5*y2+4*y3-y4)./(2*a.^2);
            page3 = (-y1+y3)./(2*a);
            page4 = y2;
            coefs = cat(3,page1,page2,page3,page4);
            pp = mkpp(breaks,coefs,ds);
        else
            % data are not equally spaced
            pp = spline(X.',reshape(V.',[ds, n]));
        end
end

% Even if method is 'spline' or 'pchip', we still need to record that the
% input data V was oriented according to INTERP1's rules.
% Thus PPVAL will return Vq oriented according to INTERP1's rules and
% Vq = INTERP1(X,Y,Xq,METHOD) will be the same as
% Vq = PPVAL(INTERP1(X,Y,METHOD,'pp'),Xq)
pp.orient = 'first';

end % PPINTERP

function [method,extrapval,ndataarg,pp] = parseinputs(varargin)
method = 'linear';
extrapval = 'default';
pp = [];
ndataarg = nargin; % Number of X,V,Xq args. Init to nargin and reduce.
if nargin == 2 && isfloat(varargin{2})
    return
end
if nargin == 3 && isfloat(varargin{3})
    if ischar(varargin{2})
        error(message('MATLAB:climada_interp1:nargin'));
    end
    return
end
if ischar(varargin{end})
    if strcmp(varargin{end},'pp')
        if (nargin ~= 4)
            error(message('MATLAB:climada_interp1:ppOutput'))
        end
        method = sanitycheckmethod(varargin{end-1});
        % X and V should be vectors of equal length
        X = varargin{1};
        V = varargin{2};
        if isvector(V)
            orig_size_v = size(V);
            V = V(:); % Reorient not considered a resize
        else
            orig_size_v = size(V);
            n = orig_size_v(1);
            ds = orig_size_v(2:end);
            prodDs = prod(ds);
            V = reshape(V,[n prodDs]);
        end
        sanitycheck(X,V);
        X = X(:);
        if isscalar(X)
            error(message('MATLAB:climada_interp1:NotEnoughPts'))
        end
        if any(diff(X)<0)
            [X, idx] = sort(X);
            V = V(idx,:);
        end
        griddedInterpolant(X,V(:,1));  % Use this to sanity check the input.
        pp = ppinterp(X, V, orig_size_v, method);
        return
    elseif strcmp(varargin{end},'extrap')
        if (nargin ~= 4 && nargin ~= 5)
            error(message('MATLAB:climada_interp1:nargin'));
        end
        if ~(isempty(varargin{end-1}) || ischar(varargin{end-1}))
            error(message('MATLAB:climada_interp1:ExtrapNoMethod'));
        end
        method = sanitycheckmethod(varargin{end-1});
        ndataarg = nargin-2;
        extrapval = [];
        if(strcmp(method,'cubic'))
            extrapval = 'default';
            warning(message('MATLAB:climada_interp1:NoExtrapForV5cubic'))
        end  
    else
        if ischar(varargin{end-1})
            error(message('MATLAB:climada_interp1:InvalidSpecPPExtrap'))
        end
        method = sanitycheckmethod(varargin{end});
        needextrapval = ~any(strcmpi(method,{'spline','pchip'}));
        if ~needextrapval
            extrapval = [];
        end
        ndataarg = nargin-1;
    end
    return
end
endisscalar = isscalar(varargin{end});
if endisscalar && ischar(varargin{end-1})
    extrapval = varargin{end};
    ndataarg = nargin-2;
    method = sanitycheckmethod(varargin{end-1});
    return 
end
if endisscalar && isempty(varargin{end-1}) && (nargin == 4 || nargin == 5)
    % default method via []
    extrapval = varargin{end};
    ndataarg = nargin-2;
    return 
end
if isempty(varargin{end})
    % This is potentially ambiguous, the assumed intent is case I
    % I)    X, V, []   Empty query
    % II)   V, [], [] Empty query and empty method,
    % III)  V, Xq, [] Empty method
    if nargin ~= 3
        ndataarg = nargin-1;
    end
    return
end
end
