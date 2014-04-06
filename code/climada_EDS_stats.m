function EDS = climada_EDS_stats(EDS, EDS_save_file, return_period, check_plot)
% calculating return periods with their corresponding EL
% NAME:
%   climada_EDS_stats
% PURPOSE:
%   calculating return periods with their corresponding event damage from the EDS
%   file
% CALLING SEQUENCE:
%   EDS_stats = climada_EDS_stats(EDS, EDS_save_file, return_period)
% EXAMPLE:
%   EDS_stat=climada_EDS_stats(EDS,EDS_stat.mat,50)
% INPUTS:
%   none
% OPTIONAL INPUT PARAMETERS:
%   EDS: Event damage set, see climada_EDS_calc(entity, hazard)
%       > promted for if not given
%   EDS_save_file: the name of the EDS return periods file
%       > promted for if not given
%   return_period: user defined return periods
%       > calculates predefined return periods if not given
%   check_plot: whether we show a check plot (=1) or not (=0), default=0
% OUTPUTS:
%   EDS, the event damage set with:
%       reference_year   : the year the damages are references to
%       event_ID(event_i): the unique ID for each event_i
%       damage(event_i)    : the damage amount for event_i
%       Value            : the sum of allValues used in the calculation (to e.g. express
%                          damages in percentage of total Value)
%       frequency(event_i)      : the per occurrence event frequency for each event_i
%       orig_event_flag(event_i): whether an original event (=1) or a
%                                 probabilistic one (=0)
%       hazard           : itself a structure, with:
%                          .filename: the filename of the hazard event set
%                          .comment : a free comment
%       comment          : a free comment, contains time for calculation
%       assets.filename  : the filename of the assets
%       damagefunctions.filename: the filename of the damagefunctions
%       annotation_name  : a kind of default title (sometimes empty)
%       .AEL             : annual expected damage for the event set 
%       .damage_sort       : downward sorted damages
%       .damage_ori_sort   : downward sorted damages for original events 
%       .R               : corresponding return periods for damage_sort 
%       .R_ori           : corresponding return periods for damage_sort_orig
%       .R_fit           : specified return periods
%       .damage_fit        : damages for specified return periods
%       .damage_fit_ori    : damages for specified return periods
% 
% MODIFICATION HISTORY:
% Reto Stockmann, 20120813  
% Lea Mueller, 20120816
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS'          , 'var'), EDS = []; end
if ~exist('EDS_save_file', 'var'), EDS_save_file = 0; end
if ~exist('return_period', 'var'), return_period = []; end
if ~exist('check_plot'   , 'var'), check_plot    = 0; end

% assign predefined return periods
if isempty(return_period), return_period = climada_global.DFC_return_periods; end

% prompt for EDS if not given
if isempty(EDS) % local GUI
    EDS=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(EDS, 'Select EDS:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        EDS=fullfile(pathname,filename);
    end
end
% load the EDS, if a filename has been passed
if ~isstruct(EDS)
    EDS_file = EDS; EDS = [];
    load(EDS_file);
end
 
% create fields
EDS.damage_sort     = [];
EDS.damage_ori_sort = [];
EDS.R               = [];
EDS.R_ori           = [];
EDS.R_fit           = [];
EDS.damage_fit_ori  = [];
EDS.damage_fit      = [];


%% add some statistics
% calculate return periods for damages for 
% - probabilistic data
[sorted_damage,exceedence_freq]...
                = climada_damage_exceedence(EDS.damage, EDS.frequency);
EDS.damage_sort = sorted_damage;
EDS.R           = 1./exceedence_freq;
EDS.R_fit       = return_period;
EDS.damage_fit  = interp1(EDS.R, EDS.damage_sort, EDS.R_fit);


% - historical data
no_generated      = length(EDS.orig_event_flag) / sum(EDS.orig_event_flag);
[sorted_damage,exceedence_freq]...
                  = climada_damage_exceedence(EDS.damage(logical(EDS.orig_event_flag)), EDS.frequency(logical(EDS.orig_event_flag))*no_generated);
EDS.damage_ori_sort = sorted_damage;  
EDS.R_ori         = 1./exceedence_freq;
EDS.damage_fit_ori  = interp1(EDS.R_ori, EDS.damage_ori_sort, EDS.R_fit);


%figure to check fit
if check_plot
    figure
    plot(EDS.R     , EDS.damage_sort    , '.-')
    hold on
    plot(EDS.R_fit , EDS.damage_fit     , '*r')   
    plot(EDS.R_ori , EDS.damage_ori_sort, 'o-')
    plot(EDS.R_fit , EDS.damage_fit_ori , 'p:r')
    strValues = strtrim(cellstr(num2str([EDS.R_fit' EDS.damage_fit'],'(%d, %2.1E)'))); 
    text(EDS.R_fit, EDS.damage_fit, strValues,'VerticalAlignment','top','fontsize',7)
    title('Damage frequency curve');xlabel('Return period (years)'); ylabel('Damage');xlim([0 1000])
    legend('Probabilistic data','Specified return periods','location','se');
    set(gca,'YGrid','on');  % major y-grid lines  
end


%% prompt for EDS_save_file if not given
if EDS_save_file % local GUI
    if  ~ischar(EDS_save_file)
        EDS_save_file        = [climada_global.data_dir filesep 'results' filesep 'EDS_XXXX.mat'];
        EDS_default          = [climada_global.data_dir filesep 'results' filesep 'save event damage set as EDS_2010...2030...clim... .mat'];
        [filename, pathname] = uiputfile(EDS_save_file, 'Save EDS set as:',EDS_default);
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            EDS_save_file = fullfile(pathname,filename);
        end
    else
        [token remain]= strtok(EDS_save_file,'\');
        if isempty(remain)
            EDS_save_file = [climada_global.data_dir filesep 'results' filesep EDS_save_file];
        end   
    end
end

if EDS_save_file
    fprintf('saving EDS as %s\n',EDS_save_file);
    save(EDS_save_file,'EDS')
end



return
