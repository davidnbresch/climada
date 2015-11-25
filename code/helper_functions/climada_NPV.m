function NPV=climada_NPV(values,discount_rates)
% climada NPV
% NAME:
%   climada_NPV
% PURPOSE:
%   calculate net present value (NPV) of a temporal (yearly) series of
%   values (e.g. costs)
% CALLING SEQUENCE:
%   NPV=climada_NPV(values,discount_rates)
% EXAMPLE:
%   NPV=climada_NPV([10 10 10],[0.02 0.02 0.02])
% INPUTS:
%   values: the vector with values (any currency)
%       value(1) corresponds to todays's value, value(end) to the
%       futuremost value.
%   discount_rates: the vector with discount rates (decimal)
%       if not give, a zero discount rate is used
%       if only a single number is given, this is used as the discount rate
%       for all years
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   NPV: the net present value of values after application of the discount rates
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20100221
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

NPV=[];

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('values','var'),return;end
if ~exist('discount_rates','var'),discount_rates=[];end

% PARAMETERS
%
if isempty(discount_rates)
    discount_rates=values*0; % use zero discount rate if not given
end

if length(discount_rates)<length(values)
    discount_rate=discount_rates(1);
    discount_rates=values*0+discount_rate;
end

NPV=values(end); % last year
for year_i=length(values)-1:-1:1 % backward
    NPV=values(year_i)+NPV/(1+discount_rates(year_i+1));
end % year_i

return
