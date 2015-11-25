function y = climada_tc_interp(x,sample_rate)
% TC new event set windfield calculation
% NAME:
%   climada_tc_interp
% PURPOSE:
%   increase resolution of any data by linear interpolation between nodes
% CALLING SEQUENCE:
%   y = climada_tc_interp(x,sample_rate)
% EXAMPLE:
%   y = climada_tc_interp([1 2 3],1); y = [1 1.5 2 2.5 3];
% INPUTS:
%   x: one-dimensional vector to be interpolated between nodes
%   sample_rate: number of interpolation points between nodes
%       =0 returns x unchanged
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   y: the resampled vector x
% RESTRICTIONS:
% MODIFICATION HISTORY:
% srzdnb, 29.4.2003
%-

% for tests:
% x           = 1:3;
% sample_rate = 2;

if not(exist('sample_rate')), sample_rate = 0; end;
sample_rate = sample_rate+1; % we need two to interpolate one point

if sample_rate == 1, y = x; return; end;

% dx     = (x(2:end) - x(1:end-1)) /sample_rate;
dx       = diff(x) /sample_rate;
orig_pos = (1:length(x)-1)*sample_rate;
y        = zeros(1,length(x)*sample_rate);
for sample_i = 1:sample_rate
    y(orig_pos+(sample_i-1))=x(1:end-1)+dx*(sample_i-1);
end
y(end) = x(end);
y      = y(sample_rate:end);

%plot(x,'.r');hold on;plot(y,'.g');drawnow;

return;
