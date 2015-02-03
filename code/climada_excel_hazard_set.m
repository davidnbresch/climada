function hazard=climada_excel_hazard_set(excel_file,hazard_set_file,visualize)
% climada excel hazard event set generate
% NAME:
%   climada_excel_hazard_set
% PURPOSE:
%   generate a hazard event set based on Excel input. The Excel sheet
%   contains all the event footprints. 
%
%   An easy method to use climada with a finite (small) number of
%   predefined events (more hazard event scenarios then a full
%   probabilistic set). 
%
%   NOTE: no consistency checks performed, user to ensure that number of
%   events equals number of frequencies, events defined at all centroids...
%   
%   see also: e.g. climada_tc_hazard_set
%   next: diverse
% CALLING SEQUENCE:
%   hazard=climada_excel_hazard_set(excel_file,hazard_set_file,visualize)
% EXAMPLE:
%   hazard=climada_excel_hazard_set('','',1)
% INPUTS:
%   excel_file: an Excel file with the centroid and hazard information
%       required tabs: centroids, hazard_intensity and hazard_frequency
%       centroids, required columns: centroid_ID, Longitude, Latitude
%       hazard_intensity, required columns: centroid_ID, event001, event002, ...
%       hazard_frequency, required columns: event_ID, frequency, orig_event_flag
%       > promted for if not given
%       See file ../data/hazards/Excel_hazard.xls which contains a small
%       example (for Mozambique).
% OPTIONAL INPUT PARAMETERS:
%   hazard_set_file: the name of the hazard set file
%       > promted for if not given
%   visualize: whether we plot the centroids on a map (=1) or not (=0,default)
% OUTPUTS:
%   hazard: a struct, the hazard event set, more for tests, since the
%       hazard set is stored as hazard_set_file, see code
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
%       intensity(event_i,centroid_i),sparse: the hazard intensity of event_i at
%           centroid_i
%       frequency(event_i): the frequency of each event
%       matrix_density: the density of the sparse array hazard.intensity
%       windfield_comment: a free comment, not in all hazard event sets
%       filename: the filename of the hazard event set (if passed as a
%           struct, this is often useful)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20110328
% David N. Bresch, david.bresch@gmail.com, 20141217, climada_hazard_cleanup added
%-

hazard=[]; % init

% init global variables

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('excel_file','var'),excel_file=[];end
if ~exist('hazard_set_file','var'),hazard_set_file=[];end
if ~exist('visualize','var'),visualize=0;end

% PARAMETERS
%
% since we store the hazard as sparse array, we need an a-priory estimation
% of it's density
hazard_arr_density=0.1; % 3% sparse hazard array density (estimated)
%
% define the reference year for this hazard set
hazard_reference_year=climada_global.present_reference_year; % default for present hazard is normally 2010

% prompt for excel_file if not given
if isempty(excel_file) % local GUI
    excel_file=[climada_global.data_dir filesep 'system' filesep '*.xls'];
    [filename, pathname] = uigetfile(excel_file, 'Select hazard set Excel file:');
    if isequal(filename,0) || isequal(pathname,0)
        return % cancel
    else
        excel_file=fullfile(pathname,filename);
    end
end

% prompt for hazard_set_file if not given
if isempty(hazard_set_file) % local GUI
    [fP,fN]=fileparts(excel_file);
    hazard_set_file=[climada_global.data_dir filesep 'hazards' filesep fN '.mat'];
    [filename, pathname] = uiputfile(hazard_set_file, 'Save hazard set as:');
    if isequal(filename,0) || isequal(pathname,0)
        return % cancel
    else
        hazard_set_file=fullfile(pathname,filename);
    end
end

% read the Excel file
centroids=climada_xlsread('no',excel_file,'centroids',1);

if ~isfield(centroids,'Longitude'),fprintf('ERROR: Longitude needed\n');end
if ~isfield(centroids,'Latitude'),fprintf('ERROR: Latitude needed\n');end
if ~isfield(centroids,'centroid_ID')
    fprintf('WARNING: centroid_ID added\n');
    centroids.centroid_ID=1:length(centroids.lon);
end

if visualize
    plot(centroids.lon,centroids.lat,'.r');hold on
    climada_plot_world_borders;
end

fprintf('reading intensity table from Excel file...\n');
hazard_intensity=climada_xlsread('no',excel_file,'hazard_intensity',1);
hazard_frequency=climada_xlsread('no',excel_file,'hazard_frequency',1);

hazard.lon=centroids.lon;
hazard.lat=centroids.lat;
hazard.centroid_ID=centroids.centroid_ID;
hazard.peril_ID='XX';
hazard.comment=sprintf('hazard event set from Excel, generated %s',datestr(now));
hazard.orig_years=NaN;
hazard.event_count=length(hazard_frequency.event_ID);
hazard.event_ID=1:hazard.event_count;
hazard.date=datestr(now);
hazard.orig_event_count=0; % init
hazard.orig_event_flag=hazard_frequency.orig_event_flag;
hazard.orig_event_count=sum(hazard.orig_event_flag);

% allocate the hazard array (sparse, to manage memory)
hazard.intensity = spalloc(hazard.event_count,length(hazard.lon),...
    ceil(hazard.event_count*length(hazard.lon)*hazard_arr_density));

t0 = clock;
msgstr=sprintf('processing %i events',hazard.event_count);
fprintf('%s (updating waitbar with estimation of time remaining every 100th event)\n',msgstr);
if climada_global.waitbar,h = waitbar(0,msgstr);end
mod_step=10; % first time estimate after 10 tracks, then every 100
for event_i=1:hazard.event_count

    event_column_name=sprintf('event%3.3i',event_i);
    %%fprintf('%s, %f\n',event_column_name,max(hazard_intensity.(event_column_name)));
    hazard.intensity(event_i,:)=sparse(hazard_intensity.(event_column_name)); % fill hazard array
    
    if mod(event_i,mod_step)==0 && climada_global.waitbar
        mod_step=100;
        t_elapsed_events=etime(clock,t0)/event_i;
        events_remaining=hazard.event_count-event_i;
        t_projected_events=t_elapsed_events*events_remaining;
        msgstr=sprintf('est. %i seconds left (%i events)',ceil(t_projected_events),events_remaining);
        waitbar(event_i/hazard.event_count,h,msgstr); % update waitbar
    end

end %event_i
if climada_global.waitbar,close(h);end % dispose waitbar

t_elapsed=etime(clock,t0);
msgstr=sprintf('generating %i events took %f sec (%f sec/event)',hazard.event_count,t_elapsed,t_elapsed/hazard.event_count);
fprintf('%s\n',msgstr);

hazard.frequency=hazard_frequency.frequency; % not transposed, just regular
hazard.matrix_density=nnz(hazard.intensity)/numel(hazard.intensity);
hazard.generation_comment=msgstr;
hazard.filename=hazard_set_file;
hazard.excel_file=excel_file;

hazard.reference_year=hazard_reference_year;

fprintf('saving hazard set as %s\n',hazard_set_file);
save(hazard_set_file,'hazard')

climada_hazard_cleanup(hazard_set_file); % make sure hazard is ok
load(hazard_set_file)

return