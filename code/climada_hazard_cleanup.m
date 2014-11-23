function hazard=climada_hazard_cleanup(hazard_file)
% climada
% NAME:
%   climada_hazard_cleanup
% PURPOSE:
%   Check a hazard event set for full climada compatibility, i.e.
%   - switch from hazard.arr to hazard.intensity
%   - check for orientation of vectors and matrices (speedup)
%   - check consistency (e.g. hazard.event_count)
%
%   We decided 20141017 to switch from hazard.arr to hazard.intensity,
%   since this fieldname is more telling.
%
% CALLING SEQUENCE:
%   hazard=climada_hazard_cleanup(hazard_file)
% EXAMPLE:
%   hazard=climada_hazard_cleanup % prompts for
% INPUTS:
%   hazard_file: the filename with path of an existing hazard event set
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   hazard: a struct, see e.g. climada_tc_hazard_set
%       the cleaned hazard is saved back to the original .mat file
%   file
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141017
% David N. Bresch, david.bresch@gmail.com, 20141121, hazard.lon check added
% David N. Bresch, david.bresch@gmail.com, 20141123, converted to full check
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard_file','var'),hazard_file=[];end

% PARAMETERS
%

show_hazard=0;

% prompt for hazard_file if not given
if isempty(hazard_file) % local GUI
    hazard_file=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    [filename, pathname] = uigetfile(hazard_file, 'Load hazard event set:');
    if isequal(filename,0) || isequal(pathname,0)
        hazard = []; return; % cancel
    else
        hazard_file=fullfile(pathname,filename);
    end
end

load(hazard_file); % loads hazard

% switch from hazard.arr to hazard.intensity
if isfield(hazard,'arr')
    hazard.intensity=hazard.arr;
    hazard=rmfield(hazard,'arr');
elseif isfield(hazard,'intensity')
    fprintf('hazard does already contain a field hazard.intensity, no change necessary\n');
else
    fprintf('WARNING: further inspection needed, hazard does not contain neither .arr nor .intensity\n');
end

% cleanup old names
if isfield(hazard,'CalculationUnitID') % old name
    hazard.centroid_ID=hazard.CalculationUnitID;
    hazard=rmfield(hazard,'CalculationUnitID');
end

if isfield(hazard,'orig_event_years') % old name
    hazard.orig_years=hazard.orig_event_years;
    hazard=rmfield(hazard,'orig_event_years');
end

% check for correct orientation of vectors
if size(hazard.lat,1)>size(hazard.lat,2),hazard.lat=hazard.lat';end
if size(hazard.lon,1)>size(hazard.lon,2),hazard.lon=hazard.lon';end
if size(hazard.lon,1)>1,fprintf('WARING: hazard.lon strange\n');show_hazard=1;end
if size(hazard.lat,1)>1,fprintf('WARING: hazard.lat strange\n');show_hazard=1;end
if size(hazard.centroid_ID,1)>size(hazard.centroid_ID,2),hazard.centroid_ID=hazard.centroid_ID';end
if size(hazard.frequency,1)>size(hazard.frequency,2),hazard.frequency=hazard.frequency';end
if size(hazard.event_ID,1)>size(hazard.event_ID,2),hazard.event_ID=hazard.event_ID';end
if isfield(hazard,'orig_event_flag')
    if size(hazard.orig_event_flag,1)>size(hazard.orig_event_flag,2),hazard.orig_event_flag=hazard.orig_event_flag';end
end

if size(hazard.intensity,1)~=size(hazard.frequency,2)
    if size(hazard.intensity,2)==size(hazard.frequency,2)
        hazard.intensity=hazard.intensity'; % transpose
    else
        fprintf('SEVERE WARNING: hazard.intensity and hazard.frequency incompatible:\n');
        show_hazard=1;
    end
end

if size(hazard.intensity,2)~=size(hazard.lon,2)
    fprintf('SEVERE WARNING: hazard.intensity and hazard.frequency incompatible:\n');
    show_hazard=1;
end

hazard.event_count=size(hazard.intensity,1);

% clean not needed fields (to be on thr safe side)
if isfield(hazard,'CalculationUnitName'),hazard=rmfield(hazard,'CalculationUnitName');end
if isfield(hazard,'interp_method'),hazard=rmfield(hazard,'interp_method');end
if isfield(hazard,'RatingZoneID'),hazard=rmfield(hazard,'RatingZoneID');end
if isfield(hazard,'CostInflationFactor'),hazard=rmfield(hazard,'CostInflationFactor');end
if isfield(hazard,'severity'),hazard=rmfield(hazard,'severity');end
if isfield(hazard,'yyyymmddstr'),hazard=rmfield(hazard,'yyyymmddstr');end
if isfield(hazard,'adjustment'),hazard=rmfield(hazard,'adjustment');end
if isfield(hazard,'event_years'),hazard=rmfield(hazard,'event_years');end
if isfield(hazard,'wind_calculation_time_min'),hazard=rmfield(hazard,'wind_calculation_time_min');end
if isfield(hazard,'yearset'),hazard=rmfield(hazard,'yearset');end
if isfield(hazard,'fgu_loss_method'),hazard=rmfield(hazard,'fgu_loss_method');end
if isfield(hazard,'ClimateCostInflationFactor'),hazard=rmfield(hazard,'ClimateCostInflationFactor');end
if isfield(hazard,'ClimateCostInflationFactor_comment'),hazard=rmfield(hazard,'ClimateCostInflationFactor_comment');end
if isfield(hazard,'celerity_correction_mode'),hazard=rmfield(hazard,'celerity_correction_mode');end
if isfield(hazard,'pressure_method'),hazard=rmfield(hazard,'pressure_method');end
if isfield(hazard,'year_comment'),hazard=rmfield(hazard,'year_comment');end
if isfield(hazard,'orig_event_years_comment'),hazard=rmfield(hazard,'orig_event_years_comment');end
if isfield(hazard,'frequency_screw'),hazard=rmfield(hazard,'frequency_screw');end
if isfield(hazard,'frequency_screw_comment'),hazard=rmfield(hazard,'frequency_screw_comment');end

% make sure some additional fiels exist
if ~isfield(hazard,'reference_year'),hazard.reference_year=climada_global.present_reference_year;end
hazard.filename=hazard_file;

fprintf('saving hazard as %s\n',hazard_file);
save(hazard_file,'hazard','-v6'); % -v6 for speed-up(no compression)

if show_hazard
    hazard % ok to show to stdour
end

return

