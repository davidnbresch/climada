function ok=climada_lonlat_cleanup
% climada template
% MODULE:
%   core
% NAME:
%   climada_lonlat_cleanup
% PURPOSE:
%   cleans up old entities and centroids in renaming fields
%   .Latitude to .lat and .Longitude to .lon, i.e.:
%   entity.assets.Longitude/Latitude -> entity.assets.lon/lat
%   centroids.Longitude/Latitude -> centroids.lon/lat
%
%   Note: this code is currently invoked ONCE by climada_init_vars. There,
%   a small file ../system/climada_lonlat_cleanup_done.txt is written to
%   indicate successful execution. We will remove this cleanup in summer
%   2015 latest.
% CALLING SEQUENCE:
%   ok=climada_lonlat_cleanup
% EXAMPLE:
%   ok=climada_lonlat_cleanup
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok: =1 if all done, see error messages else
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150203
% David N. Bresch, david.bresch@gmail.com, 20150819, centroids folder added
%-

ok=0; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
folder_names={'entities','system','centroids'};

for folder_i=1:length(folder_names)
    
    folder_name=[climada_global.data_dir filesep folder_names{folder_i}];
    
    D=dir([folder_name filesep '*.mat']);
    
    for D_i=1:length(D)
        if ~D(D_i).isdir
            full_filename=[folder_name filesep D(D_i).name];
            [~,fN,fE]=fileparts(full_filename);
            
            % some files to ignore:
            if strcmp(fN,'admin0_oct'),fE='';end
            if strcmp(fN,'coastline_oct'),fE='';end
            
            if strcmp(fE,'.mat')
                fprintf('checking %s\n',fN);
                load(full_filename)
                save_file=0;
                
                if strcmp(folder_names{folder_i},'entities') && exist('entity','var')
                    
                    if isfield(entity.assets,'Longitude')
                        fprintf(' entity.assets.Longitude/Latitude -> entity.assets.lon/lat\n');
                        entity.assets.lon=entity.assets.Longitude;
                        entity.assets=rmfield(entity.assets,'Longitude');
                        save_file=1;
                    end
                    if isfield(entity.assets,'Latitude')
                        entity.assets.lat=entity.assets.Latitude;
                        entity.assets=rmfield(entity.assets,'Latitude');
                        save_file=1;
                    end
                    %                     if isfield(entity.assets,'Value')
                    %                         fprintf(' entity.assets.Value -> entity.assets.value\n');
                    %                         entity.assets.value=entity.assets.Value;
                    %                         entity.assets=rmfield(entity.assets,'Value');
                    %                         save_file=1;
                    %                     end
                    
                    if save_file,save(full_filename,'entity');end
                    clear entity
                    
                elseif (strcmp(folder_names{folder_i},'system') || ...
                        strcmp(folder_names{folder_i},'centroids')) && ...
                        exist('centroids','var')
                    
                    if isfield(centroids,'Longitude')
                        fprintf(' centroids.Longitude/Latitude -> centroids.lon/lat\n');
                        centroids.lon=centroids.Longitude;
                        centroids=rmfield(centroids,'Longitude');
                        save_file=1;
                    end
                    if isfield(centroids,'Latitude')
                        centroids.lat=centroids.Latitude;
                        centroids=rmfield(centroids,'Latitude');
                        save_file=1;
                    end
                    
                    if save_file,save(full_filename,'centroids');end
                    clear centroids
                    
                end % entity or centroids
                
            end % .mat
            
        end % isdir
    end % D_i
end % folder_i

ok=1; % if we got here, must be ok ;-)

end % climada_lonlat_cleanup
