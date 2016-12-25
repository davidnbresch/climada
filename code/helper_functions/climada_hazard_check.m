function res=climada_hazard_check(hazard,input_res)
% climada hazard check
% MODULE:
%   core
% NAME:
%   climada_hazard_check
% PURPOSE:
%   check a climada hazard set
%
%   previous call: e.g. climada_tc_hazard_set
%   next call: climada_EDS_calc
% CALLING SEQUENCE:
%   res=climada_hazard_check(hazard)
% EXAMPLE:
%   res =climada_hazard_check(hazard)      % show stats for hazard
%   res2=climada_hazard_check(hazard2,res) % compare with hazard2
% INPUTS:
%   hazard: a climada hazard event set
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   input_res: the output from a previous call, allows to compare two hazard sets
% OUTPUTS:
%   res: the output, empty if not successful, with fields
%       bin: the bins
%       N: the percentage of intensity values within bins
%       units: the units of hazard.intensity
%       legend: the legend
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161205
%-

res=[]; % init output

%global climada_global
%if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('hazard','var'),hazard=[];end
if ~exist('input_res','var'),input_res=[];end

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below

hazard=climada_hazard_load(hazard);

if ~ishazard(hazard)
    fprintf('Warning: hazard does not contain minimum required fields\n');
end

[~,fN]=fileparts(hazard.filename);
legend_str{1}=strrep(fN,'_',' ');

% plot histogram of hazard intensity
switch hazard.peril_ID
    case 'TC'
        intensity_threshold=20;
        intensity_bins=intensity_threshold:5:100;
    otherwise
        intensity_threshold=0;
        intensity_bins=[0:ceil(max(max(hazard.intensity)))];
end
intensity_above_thresh=hazard.intensity(hazard.intensity>=intensity_threshold);
N = hist(intensity_above_thresh,intensity_bins);
N=N/sum(N)*100;

if ~isempty(input_res) % add histogram of previously analysed hazard
    N=[N;input_res.N]';
    legend_str{2}=input_res.legend_str{1};
end
xlim([min(intensity_bins) max(intensity_bins)]);axis tight


subplot(2,2,1)
bar_handle=bar(intensity_bins,N,1.5,'EdgeColor','none');
set(bar_handle(1),'FaceColor',[.5 .5 .9]);% color
if ~isempty(input_res)
    set(bar_handle(2),'FaceColor',[.9 .5 .5]);% color comparison
end
if isfield(hazard,'units'),xlabel(hazard.units);end
ylabel('% of nonzero elements');
legend(legend_str);
title([hazard.peril_ID ' intensity histogram']);
set(gcf,'Color',[1 1 1]);

pos=find(intensity_above_thresh>max(intensity_bins));
if ~isempty(pos)
    fprintf('Warning: %i points above range [%2.2g..%2.2g]\n',length(pos),min(intensity_bins),max(intensity_bins));
    
    % find events with points above range
    for event_i=1:length(hazard.frequency)
        pos=find(hazard.intensity(event_i,:)>max(intensity_bins));
        if ~isempty(pos)
            fprintf(' event %i: %i points above range\n',event_i,length(pos));
        end
    end % event_i
end

res.bins=intensity_bins;
res.N=N;
if isfield(hazard,'units'),res.units=hazard.units;end
res.legend_str=legend_str;

subplot(2,2,2)
climada_hazard_plot(hazard,0,'',[min(intensity_bins) max(intensity_bins)]);
title('maxmium intensity');

subplot(2,2,3)
climada_hazard_plot(hazard,-1,'',[min(intensity_bins) max(intensity_bins)]);
title('biggest event');

subplot(2,2,4)
climada_hazard_plot(hazard,-2,'',[min(intensity_bins) max(intensity_bins)]);
title('2^{nd} biggest event');

end % climada_hazard_check