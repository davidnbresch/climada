function measures_impact=climada(entity_today_file,entity_future_file,hazard_today_file,hazard_future_file,check_plots)
% climada all in one adaptaton cost curve climate scenarios economic grwoth projection
% MODULE:
%   core
% NAME:
%   climada
% PURPOSE:
%   Import entity today and entity future, ask for corresponding hazard
%   event sets, show a few plots for checks, run all calculations and
%   produce the final adaptation cost curve - all in one call.
%
%   Special: on subsequent calls, the routine suggest last inputs - and if
%   the first file selection is the same as on previous call, even asks to
%   re-run with previous call's inputs without asking for each's
%   confirmation.
%   It further checks for the entity file to have been edited since last
%   call. If not, it does not ask for plotting assets and damagefunctions
%   again. If one wants to plot, needs to either save the entity again or
%   select another file and then cancel.
%
%   NOTE: in order to allow a very intuitive interface to get started with
%   climada, the cases climada('TEST_CLIMADA', climada('DEMO') and
%   climada('TC') have been implemented, too, see discription below.
%
%   Programmes's note: The present code mainly handles asdmin, i.e.
%   checking files, while all calculations are run be the core climada
%   functions, i.e. climada_entity_read, climada_measures_impact, 
%   climada_adaptation_event_view and - last but not least -
%   climada_adaptation_cost_curve. 
% CALLING SEQUENCE:
%   measures_impact=climada(entity,entitiy_future,hazard_today_file,hazard_future_file)
% EXAMPLE:
%   measures_impact=climada % all prompted for
%   climada('TEST_CLIMADA'); % TEST mode
%   climada('DEMO'); % run the demo GUI (same as climada_demo)
%   climada('TC'); % run a TC event damage calculation
% INPUTS:
%   entity_today_file: entity (assets, damagefunctions and measures) today
%       a climada entity file, either an Excel (.xls or .xlsx) or Open
%       Office (.ods file) or an already encoded .mat file. Note that in
%       case a .mat file is provided, the code does not notice if the
%       original .xls or .ods got changed - hence preferable select the
%       source, i.e. .xls or .ods).   
%       > prompted for if empty
%       ='TEST_CLIMADA': special test mode, the code uses the test files
%       (as used in climada_demo and climada_demo_step_by_step)
%       ='TC': special mode to calculate TC event damage, calls
%       climada_tc_event_damage_ens_gui, i.e. allows you to select a basin,
%       track and country (optional) in order to calculate TC damage.
%       ='DEMO', invoke climada_demo
%   entity_future_file: future entity (assets, damagefunctions and measures) to
%       represent projected economic growth, a climada entity structure
%       (see climada_entity_read, same remark as above)
%       > prompted for if empty
%   hazard_today_file: a climada hazard event set for today
%       > promted for if not given
%   hazard_future_file: a climada hazard event set for future (climate scenario)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   check_plots: whether we show a few check plots (assets,
%       damagefunctions)
%       =0: no plots (default)
%       =1: show plots
%       The code also switches to ask for plot if it needs to prompt
%       for filenames, i.e. operates in interactive mode.
% OUTPUTS:
%   measures_impact: the same output as climada_measures_impact
%   and plots: adaptation cost curve, adaptation event view
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150101, initial
% David N. Bresch, david.bresch@gmail.com, 20160908, entities_dir and hazards_dir used
% David N. Bresch, david.bresch@gmail.com, 20170504, 'TC' and 'DEMO' added
%-

measures_impact=[]; % init output

% keep filenames for subsequent calls (as one might edit the entity files
% and wants to re-calculate) and suggest them in GUIs
persistent entity_today_file_def
persistent entity_future_file_def
persistent hazard_today_file_def
persistent hazard_future_file_def
persistent entity_today_file_last_date
persistent FIRST_CALL

% simple way to get started with climada
if isempty(FIRST_CALL),FIRST_CALL=0;end
if FIRST_CALL==0
    fprintf('if this is the first time you use climada, try\n climada(''TEST_CLIMADA'')\n climada(''DEMO'')\n climada(''TC'')\n\n');
    FIRST_CALL=1;
end

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('entity_today_file','var'), entity_today_file ='';end
if ~exist('entity_future_file','var'),entity_future_file='';end
if ~exist('hazard_today_file','var'), hazard_today_file ='';end
if ~exist('hazard_future_file','var'),hazard_future_file='';end
if ~exist('check_plots','var'),       check_plots       =0;end

% PARAMETERS
%
% whether we ask the user about plotting assets and damage functions
% if not all inputs parameters are provided, i.e. we prompt for filenames,
% we also will show the questdlg (see code).
show_questdlg=0; % default=0
%
% the files for TEST mode
if strcmpi(entity_today_file,'TEST_CLIMADA')
    TEST_mode=1;
    entity_today_file =[climada_global.entities_dir filesep 'demo_today' climada_global.spreadsheet_ext];
    entity_future_file=[climada_global.entities_dir filesep 'demo_today' climada_global.spreadsheet_ext];
    hazard_today_file =[climada_global.hazards_dir  filesep 'TCNA_today_small.mat'];
    hazard_future_file=[climada_global.hazards_dir  filesep 'TCNA_2030med_small.mat'];
    check_plots=1;
    show_questdlg=0;
    fprintf('SPECIAL climada TEST mode\n')
    FIRST_CALL=0; % might be a first time user
elseif strcmpi(entity_today_file,'DEMO')
    climada_demo;
    FIRST_CALL=0; % might be a first time user
    return
elseif strcmpi(entity_today_file,'TC')
    climada_tc_event_damage_ens_gui;
    FIRST_CALL=0; % might be a first time user
    return
else
    TEST_mode=0;
end

% prompt for entity_today_file if not given
if isempty(entity_today_file) % local GUI
    show_questdlg=1;
    if isempty(entity_today_file_def)
        entity_today_file=[climada_global.entities_dir filesep '*' climada_global.spreadsheet_ext];
    else
        entity_today_file=entity_today_file_def;
    end
    [filename, pathname] = uigetfile(entity_today_file, 'Select entity today:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_today_file=fullfile(pathname,filename);
        if strcmp(entity_today_file,entity_today_file_def)
            ButtonName=questdlg('Would you like to use all parameters from last call?','File dialogs','Yes','No','Yes');
            if strcmp(ButtonName,'Yes')
                % use all parameters as in last call
                entity_today_file =entity_today_file_def;
                entity_future_file=entity_future_file_def;
                hazard_today_file =hazard_today_file_def;
                hazard_future_file=hazard_future_file_def;
                check_plots=0;
                show_questdlg=0;
            end
        else
            entity_today_file_def=entity_today_file;
        end
    end
end

% prompt for hazard_today_file if not given
if isempty(hazard_today_file) % local GUI
    show_questdlg=1;
    if isempty(hazard_today_file_def)
        hazard_today_file=[climada_global.hazards_dir filesep '*.mat'];
    else
        hazard_today_file=hazard_today_file_def;
    end
    [filename, pathname] = uigetfile(hazard_today_file, 'Select hazard set today:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_today_file=fullfile(pathname,filename);
        hazard_today_file_def=hazard_today_file;
    end
end

% prompt for entity_future_file if not given
if isempty(entity_future_file) % local GUI
    show_questdlg=1;
    if isempty(entity_future_file_def)
        entity_future_file=[climada_global.entities_dir filesep '*' climada_global.spreadsheet_ext];
    else
        entity_future_file=entity_future_file_def;
        
    end
    [filename, pathname] = uigetfile(entity_future_file, 'Select entity future:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_future_file=fullfile(pathname,filename);
        entity_future_file_def=entity_future_file;
    end
end

% prompt for hazard_future_file if not given
if isempty(hazard_future_file) % local GUI
    show_questdlg=1;
    if isempty(hazard_future_file_def)
        hazard_future_file=[climada_global.hazards_dir filesep '*.mat'];
    else
        hazard_future_file=hazard_future_file_def;
    end
    [filename, pathname] = uigetfile(hazard_future_file, 'Select future hazard set:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_future_file=fullfile(pathname,filename);
        hazard_future_file_def=hazard_future_file;
    end
end

% check for the entity file to have been edited since last call
% if not, do not ask for plotting assets and damagefunctions again
% if one wants to plot, needs to either save the entity again or select
% another file and then cancel.
[fP,fN,fE]=fileparts(entity_today_file);
fN=[fN fE];
D=dir(fP);
for D_i=1:length(D)
    if strcmp(D(D_i).name,fN)
        if isempty(entity_today_file_last_date)
            entity_today_file_last_date=D(D_i).datenum;
        else
            if D(D_i).datenum-entity_today_file_last_date==0
                % same entity, not edited, hence no need to show plots again
                check_plots=0;
                show_questdlg=0;
            end
        end
    end
end % D_i

if show_questdlg
    ButtonName=questdlg('Would you like to see check plots (assets, damagefunctions) ?','Check plot dialog','Yes','No','Yes');
    if strcmp(ButtonName,'Yes'),check_plots=1;end
end

if exist(hazard_today_file,'file')
    load(hazard_today_file) % contains hazard
else
    fprintf('Error: hazard today not found (%s)\n',hazard_today_file)
    return
end
entity_today=climada_entity_read(entity_today_file,hazard); % contains entity

if check_plots
    figure('Name','entity assets today');
    if ~climada_global.octave_mode
        % entity plot with pcolor takes (far) too long in Octave
        climada_entity_plot(entity_today);
    else
        climada_circle_plot(entity_today.assets.Value,...
            entity_today.assets.lon,entity_today.assets.lat)
    end
    figure;climada_damagefunctions_plot(entity_today,hazard.peril_ID);
    drawnow % flush the event queue and update the figure window
end % check_plots

% force encode to today's hazard
entity_today=climada_assets_encode(entity_today,hazard);

% calculate EDS today    
EDS_today=climada_EDS_calc(entity_today,hazard);
    
% calculate today's measures impact, for reference
measures_impact_today=climada_measures_impact(entity_today,hazard,'no');

% read future entity
entity_future=climada_entity_read(entity_future_file,hazard); % hazard contains still today's hazard

% special for TEST mode inflate the Values (as in this case entity_future_file=entity_today_file)
if TEST_mode,entity_future.assets.Value=entity_future.assets.Value*1.1;end

% force encode to today's hazard
entity_future=climada_assets_encode(entity_future,hazard); % hazard contains still today's hazard

% calculate EDS with today's hazard to see economic growth impact    
EDS_future_econ=climada_EDS_calc(entity_future,hazard); % hazard contains still today's hazard

clear hazard % redundant, to be on the safe side

if exist(hazard_future_file,'file')
    load(hazard_future_file) % contains hazard, overwrites hazard today
else
    fprintf('Error: hazard future not found (%s)\n',hazard_future_file)
    return
end

% force encode to future hazard
entity_future=climada_assets_encode(entity_future,hazard); % hazard contains future hazard

% calculate EDS with future hazard to see economic growth and climate change impact    
EDS_future_econ_clim=climada_EDS_calc(entity_future,hazard); % hazard contains future hazard

% display waterfall graph
figure('Name','waterfall graph');
climada_waterfall_graph(EDS_today,EDS_future_econ,EDS_future_econ_clim,'AED');

% calculate future measures impact, discount to today - the final calculation
measures_impact=climada_measures_impact(entity_future,hazard,measures_impact_today); % hazard contains future hazard

% show adaptation cost curve and event view
figure('Name','adaptation event view');climada_adaptation_event_view(measures_impact); % 2nd last to
figure('Name','adaptation cost curve');climada_adaptation_cost_curve(measures_impact); % to be best visible
drawnow % flush the event queue and update the figure window

end
