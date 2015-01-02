function climada_damagefunctions_plot(entity,unique_ID_sel)
% climada
% NAME:
%   climada_damagefunctions_plot
% PURPOSE:
%   Plot the damage functions within entity (if a damagefunctions struct is
%   passed, it works, too).
%
%   See also climada_damagefunctions_read
% CALLING SEQUENCE:
%   climada_damagefunctions_plot(entity,unique_ID_sel)
%   climada_damagefunctions_plot(climada_damagefunctions_read)
% EXAMPLE:
%   climada_damagefunctions_plot
% INPUTS:
%   entity: an entity, see climada_entity_read
%       > promted for if not given (calling climada_entity_load, not
%       climada_entity_read)
%       Works also, if just a damagefunctions structure is passed (i.e. the
%       same as in entity.damagefunctions, as returned by
%       climada_damagefunctions_read)
% OPTIONAL INPUT PARAMETERS:
%   unique_ID_sel: a single unique ID or the first n characters of an ID to
%       plot only selected damage function(s), as in the case of an entity
%       containing many functions, the single panes of the plot might get
%       too small). It is recommended to run climada_damagefunctions_plot 
%       first without specifying a unique_ID_sel and inspect the single 
%       sub-plot headers. Examples are:
%       unique_ID_sel='TC 001' % print only the one curve
%       unique_ID_sel='TC'     % print all TC curves
% OUTPUTS:
%   a figure
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, ICE
% David N. Bresch, david.bresch@gmail.com, 20141214, unique_ID_sel added
% David N. Bresch, david.bresch@gmail.com, 20141221, MDR calculated locally and unique_ID_sel improved
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('unique_ID_sel','var'),unique_ID_sel='';end

% PARAMETERS
%
% set default value for param2 if not given

% prompt for param1 if not given
if isempty(entity),entity=climada_entity_load;end
if isempty(entity),return;end

if isfield(entity,'damagefunctions')
    climada_damagefunctions_map(entity);
    damagefunctions=entity.damagefunctions;
else
    damagefunctions=entity; % entity is in fact already a damagefunctions struct
    % if not, we learn it the hard way as the code will fail ;-)
end


if isfield(damagefunctions,'peril_ID')
    % since there might be the same DamageFunID for two different
    % perils, re-define the damage function
    for i=1:length(damagefunctions.DamageFunID)
        unique_ID{i}=sprintf('%s %3.3i',damagefunctions.peril_ID{i},damagefunctions.DamageFunID(i));
    end % i
else
    for i=1:length(damagefunctions.DamageFunID)
        unique_ID{i}=sprintf('%3.3i',damagefunctions.DamageFunID(i));
    end % i
end

unique_IDs=unique(unique_ID);

% we also show MDR, to ease understanding of MDD*PAA
damagefunctions.MDR=damagefunctions.MDD.*damagefunctions.PAA;

if ~isempty(unique_ID_sel)
    % find matching curves
    unique_pos=strncmp(unique_ID_sel,unique_IDs,length(unique_ID_sel));
    % force single damage function to be plotted
    unique_IDs=unique_IDs(unique_pos);
end

% figure number of sub-plots and their arrangement
n_plots=length(unique_IDs);
N_n_plots=ceil(sqrt(n_plots));n_N_plots=N_n_plots-1;
if ~((N_n_plots*n_N_plots)>n_plots),n_N_plots=N_n_plots;end

for ID_i=1:length(unique_IDs)
    subplot(N_n_plots,n_N_plots,ID_i);
    dmf_pos=strmatch(unique_IDs{ID_i},unique_ID);
    if ~isempty(dmf_pos)
        fprintf('plot %i: %s\n',ID_i,char(unique_IDs(ID_i))); % this way, it's easy to use them (see unique_ID_sel)
        plot(damagefunctions.Intensity(dmf_pos),damagefunctions.MDR(dmf_pos),'-r','LineWidth',2);hold on
        plot(damagefunctions.Intensity(dmf_pos),damagefunctions.MDD(dmf_pos),'-b');
        plot(damagefunctions.Intensity(dmf_pos),damagefunctions.PAA(dmf_pos),'-g');
        legend('MDR','MDD','PAA');
        xlabel('Intensity','FontSize',9);
        ylabel('MDR')
        title(unique_IDs{ID_i});
        grid on
        grid minor
    else
        fprintf('Error: %s not found\n',char(unique_IDs(ID_i))); % this way, it's easy to use them (see unique_ID_sel)
    end
end
set(gcf,'Color',[1 1 1]);
set(gcf,'Name','damagefunctions');

end
