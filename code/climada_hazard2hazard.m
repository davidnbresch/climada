function hazard=climada_hazard2hazard(hazard_set_file_in,hazard_set_file_out)
% climada
% NAME:
%   climada_hazard2hazard
% PURPOSE:
%   convert a hazard event set, a struct with fields like:
%       comment: 
%       peril_ID:
%       date: '13-Dec-2005'
%       lat:
%       lon:
%       CalculationUnitID:
%       event_count:
%       arr: 
%       orig_event_flag:
%       frequency:
%       event_ID:
%       orig_years: 30
%       event_years: 150
%       matrix_density: 0.2539
%   into a climada hazard event set: a struct, the hazard event set, with:
%       lon(centroid_i): the longitude of each centroid
%       lat(centroid_i): the latitude of each centroid
%       centroid_ID(centroid_i): a unique ID for each centroid
%       peril_ID: just an ID identifying the peril, e.g. 'TC' for
%       tropical cyclone or 'ET' for extratropical cyclone
%       comment: a free comment, normally containing the time the hazard
%           event set has been generated
%       orig_years: the original years the set is based upon
%       orig_event_count: the original events
%       event_count: the total number of events in the set, including all
%           probabilistic ones, hence event_count>=orig_event_count
%       orig_event_flag(event_i): a flag for each event, whether it's an original
%           (1) or probabilistic (0) one
%       event_ID: a unique ID for each event
%       date: the creation date of the set
%       arr(event_i,centroid_i),sparse: the hazard intensity of event_i at
%           centroid_i
%       frequency(event_i): the frequency of each event
%       matrix_density: the density of the sparse array hazard.intensity
%       windfield_comment: a free comment, not in all hazard event sets
%       filename: the filename of the hazard event set (if passed as a
%           struct, this is often useful)
%
%   please check the PARAMETERS section below, e.g. for
%       hazard_reference_year, the reference year for the hazard set
% CALLING SEQUENCE:
%   hazard=climada_hazard2hazard(hazard_set_file_in,hazard_set_file_out)
% EXAMPLE:
%   climada_hazard2hazard
% INPUTS:
%   hazard_set_file_in: hazard set file (a .mat file with a stored hazard
%       structure)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   hazard_set_file_out: the name of the new hazard set file
%       > promted for if not given
% OUTPUTS:
%   hazard event set to file
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090920
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('hazard_set_file_in','var'),hazard_set_file_in=[];end
if ~exist('hazard_set_file_out','var'),hazard_set_file_out=[];end

% PARAMETERS
%
% define the reference year for this hazard set
hazard_reference_year=climada_global.present_reference_year; % default for present hazard is normally 2010

% prompt for hazard_set_file_in if not given
if isempty(hazard_set_file_in) % local GUI
    hazard_set_file_in=[climada_global.data_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(hazard_set_file_in, 'Open existing hazard event set:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_set_file_in=fullfile(pathname,filename);
    end
end

% prompt for hazard_set_file_out if not given
if isempty(hazard_set_file_out) % local GUI
    fP=fileparts(hazard_set_file_in);
    hazard_set_file_out=[fP filesep '*.mat'];
    [filename, pathname] = uiputfile(hazard_set_file_out, 'Save converted hazard set as:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_set_file_out=fullfile(pathname,filename);
    end
end

load(hazard_set_file_in)

if ~isfield(hazard,'CalculationUnitID')
    fprintf('ERROR: hazard event set not in old format, aborted\n');
    return
end

hazard.centroid_ID=hazard.CalculationUnitID;
hazard=rmfield(hazard,'CalculationUnitID');
hazard.event_count=size(hazard.intensity,1);
hazard.intensity=hazard.intensity'; % TRANSPOSED for speed-up
hazard.frequency=hazard.frequency'; % TRANSPOSED
% lon, lat, peril_ID, comment, orig_years, event_ID, date, orig_event_count, orig_event_flag the same
hazard.filename=hazard_set_file_out;

hazard.hazard_reference_year=hazard_reference_year;

% clean not needed fields
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

% save to .mat file
save(hazard_set_file_out,'hazard','-v6'); % -v6 for speed-up(no compression)
%%save(hazard_set_file_out,'hazard'); % -v6 for speed-up(no compression)

return