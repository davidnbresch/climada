function ok=climada_opera_fetch(check_plot)
% climada template
% MODULE:
%   core
% NAME:
%   climada_opera_fetch
% PURPOSE:
%   fetch radar composite from OPERA, three days back until now
%
%   see http://eumetnet.eu/activities/observations-programme/current-activities/opera-radar-animation/ 
%   https://cdn.fmi.fi/demos/eumetnet-web-site-radar-animator/images/201806060900_Odyssey_Max_composite.gif
%
%   previous call: none
%   next call: <note the most usual next function call here>
% CALLING SEQUENCE:
%   ok=climada_opera_fetch
% EXAMPLE:
%   ok=climada_opera_fetch
%   % to display, see check_plot in code
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   check_plot: if =1, plot last image processed, =0 no plot (default)
% OUTPUTS:
%   ok: if fetch successful
%   writes .mat files to results folder, in sub-folder opera (creates this
%   folder in climada_global.data_dir, if not exists)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20180605
% David N. Bresch, david.bresch@gmail.com, 20180606 display added
% David N. Bresch, david.bresch@gmail.com, 20180613 switched to imread
%-

ok=0; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('check_plot','var'),check_plot=0;end 

% locate the module's (or this code's) data folder (usually  a folder
% 'parallel' to the code folder, i.e. in the same level as code folder)
%module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% the URL to fetch the images from
url_path='https://cdn.fmi.fi/demos/eumetnet-web-site-radar-animator/images/';
%
% local folder to write the figures
dst_path=[climada_global.data_dir filesep 'opera'];
if ~isdir(dst_path),[fP,fN]=fileparts(dst_path);mkdir(fP,fN);end % create it

web_data=[]; % init

for day=-3:0
    yyyymmdd_str=datestr(now+day,'yyyymmdd');
    
    for hh=0:23
        
        for mm=0:15:45
            
            yyyymmddhhmm_str=[yyyymmdd_str sprintf('%2.2i',hh) sprintf('%2.2i',mm)];
            url_str=[url_path yyyymmddhhmm_str '_Odyssey_Max_composite.gif'];
            dst_str=[dst_path filesep yyyymmddhhmm_str '.mat'];

            %if datenum(yyyymmddhhmm_str,'yyyymmddHHMM')>now,continue;end % see datetime due to summertime etc.
            
            if ~exist(dst_str,'file')   
                try
                    fprintf('fetching %s ...',yyyymmddhhmm_str);
                    %web_data = webread(url_str); % only image
                    [web_data,MAP] = imread(url_str); % includes colormap
                    save(dst_str,'web_data','MAP');
                    fprintf(' done\n');
                catch
                    fprintf(' not found\n');
                    % not yet on server (or not any more)
                end
            else
                fprintf('exists already: %s\n',yyyymmddhhmm_str);
            end
        end % mm
    end % hh
end % day

if ~isempty(web_data) && check_plot
    figure('Name','last image');imshow(web_data,MAP);
end

ok=1;

end % climada_opera_fetch