function hazard = climada_hazard_clim_scen(hazard,hazard_clim_file,frequency_screw,intensity_screw,intensity_shift)
% climada
% NAME:
%   climada_template
% PURPOSE:
%   starting from a given hazard event set (hazard), construct the
%   climate scenario hazard event set (hazard_clim_file)
%
%   Modifications done in code, so please visit/edit the code prior to use,
%   please check the PARAMETERS section below, e.g. for
%       frequency_screw, intensity_screw
%       hazard_reference_year: the reference year for the hazard set
% CALLING SEQUENCE:
%   hazard=climada_tc_hazard_clim_scen(hazard,hazard_clim_file)
% EXAMPLE:
%   hazard=climada_tc_hazard_clim_scen
% INPUTS:
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   hazard_clim_file: the filename of the new climate scenario hazard event set
%       > promted for if not given
% OUTPUTS:
%   hazard: the hazard event set for the climate scenario, also stored to hazard_clim_file
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090920
% Lea Mueller, 20110720
% Reto Stockmann 20120719
% David N. Bresch, david.bresch@gmail.com, 20150906, allow for name without path on input
% Lea Mueller, muellele@gmail.com, 20151021, add intensity shift
%-

% % SAFETY message prior to first call - user is asked to comment the return statement
% fprintf('!!!   Modifications done in code, so please visit/edit the code prior to use\n');
% %%return % comment out, but activate once code is subject to use by newcomer

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('hazard','var'),hazard=[];end
if ~exist('hazard_clim_file','var'),hazard_clim_file=[];end
if ~exist('frequency_screw','var'),frequency_screw=[];end
if ~exist('intensity_screw','var'),intensity_screw=[];end
if ~exist('intensity_shift','var'),intensity_shift=[];end

% PARAMETERS
%
% the key parameters to change the hazard event set:
% new hazard frequency=orig hazard frequency * frequency_screw
% =1.0 for identity
if isempty(frequency_screw)
    frequency_screw = 1.10;
end
% new hazard intensity=orig hazard intensity * intensity_screw
% =1.0 for identity
if isempty(intensity_screw)
    intensity_screw = 1.05;
end
% new hazard intensity=orig hazard intensity + intensity_shift
% =0.0 for identity
if isempty(intensity_shift)
    intensity_shift = 0;
end

% define the reference year for this hazard set
% default for future or scenario hazard is normally 2030
hazard_reference_year = climada_global.future_reference_year;

% prompt for hazard if not given
if isempty(hazard) % local GUI
    hazard               = [climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    hazard_default       = [climada_global.data_dir filesep 'hazards' filesep 'choose a hazard.mat'];
    [filename, pathname] = uigetfile(hazard, 'Open existing hazard event set:',hazard_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard = fullfile(pathname,filename);
    end
end
% load the hazard, if a filename has been passed
if ~isstruct(hazard)
    hazard_file = hazard;
    hazard      = [];
    load(hazard_file);
end

hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

% modify the hazard event set

% assumption 1) frequency increase
hazard.frequency = hazard.frequency*frequency_screw;

% assumption 2) intensity increase
hazard.intensity = hazard.intensity*intensity_screw;

% assumption 3) intensity shift for nonzero elements
if intensity_shift~= 0
    [i,j,values] = find(hazard.intensity);
    [m,n] = size(hazard.intensity);
    hazard.intensity= sparse(i,j,values+intensity_shift,m,n);
end


pause(1)

% prompt for where to save hazard_clim_file if not given
if isempty(hazard_clim_file) % local GUI
    hazard_clim_file = [climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    if ~exist('filename','var'); filename = '_clim'; else filename = [strtok(filename,'.') '_clim'];end
    hazard_clim_default  = [climada_global.data_dir filesep 'hazards' filesep filename '.mat'];
    [filename, pathname] = uiputfile(hazard_clim_file, 'Save climate change scenario hazard event set as:',hazard_clim_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_clim_file = fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(hazard_clim_file);
if isempty(fP),hazard_clim_file=[climada_global.data_dir filesep 'hazards' filesep fN fE];end


% store as additional fields in hazard:
hazard.frequency_screw_applied = frequency_screw;
hazard.intensity_screw_applied = intensity_screw;

hazard.filename                = hazard_clim_file;
hazard.comment                 = ['climate change scenario based on ' hazard.comment];
hazard.hazard_reference_year   = hazard_reference_year;
hazard.date                    = datestr(now);


save(hazard_clim_file,'hazard')

hazard_units = '';
if isfield(hazard,'units'),  hazard_units = hazard.units; end
fprintf('Apply climate change scenario (%d)\n \t-frequency_screw = %10.4f \n \t-intensity screw = %10.4f \n \t-intensity shift = %10.4f %s \nsaved in \n%s \n\n',...
    climada_global.future_reference_year,frequency_screw,intensity_screw,intensity_shift,hazard_units,[climada_global.data_dir hazard_clim_file])

return
