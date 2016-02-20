function data=RivDIS_read(data_file,verbose)
% climada template
% MODULE:
%   _LOCAL
% NAME:
%   data=RivDIS_read(data_file)
% PURPOSE:
%   Read RivDIS data from ftp://daac.ornl.gov/data/rivdis/STATIONS.HTM#I
%   http://daac.ornl.gov/RIVDIS/rivdis.shtml
%   See ftp://daac.ornl.gov/data/rivdis/README
%   Units: cubic meters/sec
%
%   file format as:
%     Buretto,44.96 N,10.39 E,E4,Italy,Europe,Po,20,55183
%     Monthly average discharge in cubic meters/sec  180 records
%     POINTID|YEAR|MONTH|DISCHRG
%     750|1965|1|823
%     750|1965|2|683
%     750|1965|3|901
%     750|1965|4|630
%     750|1965|5|341
%     750|1965|6|803
%     750|1965|7|382
%     750|1965|8|743
%     750|1965|9|2110
%     750|1965|10|2000
%     ...
%
% CALLING SEQUENCE:
%   data=RivDIS_read(data_file,verbose)
% EXAMPLE:
%   data=RivDIS_read
%
%   data01=RivDIS_read('TABLE01.DAT',0);
%   data02=RivDIS_read('TABLE02.DAT',0);
%   data03=RivDIS_read('TABLE03.DAT',0);
%   plot(data01.datenum,data01.DISCHRG,'-r');datetick; hold on
%   legend_str{1}=data01.station_name;
%   plot(data02.datenum,data02.DISCHRG,'-g');datetick; hold on
%   legend_str{2}=data02.station_name;
%   plot(data03.datenum,data03.DISCHRG,'-b');datetick; hold on
%   legend_str{3}=data03.station_name;
%   legend(legend_str);ylabel(data01.units);
%   title(['river ' data01.river_name ' monthly maximum discharge']);set(gcf,'Color',[1 1 1])
% INPUTS:
%   data_file: the filename of the data (.DAT) file.
%       If without path, default path is appended and tried
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   verbose: =1: print some verbose (default),
%       =2: show check plot, too, =0: silent
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160121
%-

data=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('data_file','var'),data_file='';end
if ~exist('verbose','var'),verbose=1;end

% locate the module's (or this code's) data folder (usually  afolder
% 'parallel' to the code folder, i.e. in the same level as code folder)
module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
default_data_dir=[fileparts(climada_global.root_dir) filesep 'LOCAL_STUFF' filesep 'Italy_Veneto_Tuscany'];
if ~exist(default_data_dir,'dir'),default_data_dir=climada_global.data_dir;end


% prompt for data_file if not given
if isempty(data_file) % local GUI
    data_file=[default_data_dir filesep '*.DAT'];
    [filename, pathname] = uigetfile(data_file, 'Select data file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        data_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(data_file);
if isempty(fP),data_file=[default_data_dir filesep fN fE];end

if exist(data_file,'file')
    if verbose,fprintf('importing from %s\n',data_file);end
    
    data_fid=fopen(data_file,'r');
    
    data.filename=data_file; % assign
    data.units='m^3/s';
    
    % read header
    % -----------
    
    if verbose,fprintf('reading header:\n');end
    
    line_header = fgetl(data_fid); % first line
    % Buretto,44.96 N,10.39 E,E4,Italy,Europe,Po,20,55183
    line_header_items=textscan(line_header,'%s','Delimiter',','); % convert to list
    line_header_items=line_header_items{1}; % convert to cell str
    
    data.station_name=line_header_items{1}; % assign
    data.country_name=line_header_items{5}; % assign
    data.river_name=line_header_items{7}; % assign
    
    lonlat_str=line_header_items{2};
    data.lat=str2double(strtok(lonlat_str));
    if findstr('S',lonlat_str),data.lat=-data.lat;end
    
    lonlat_str=line_header_items{3};
    data.lon=str2double(strtok(lonlat_str));
    if findstr('W',lonlat_str),data.lon=-data.lon;end
    
    line_header = fgetl(data_fid); % second line
    % Monthly average discharge in cubic meters/sec  180 records
    data.comment=line_header;
    
    % read data
    % ---------
    
    % read field names of data block
    line_header = fgetl(data_fid); % field names
    % POINTID|YEAR|MONTH|DISCHRG
    line_header_items=textscan(line_header,'%s','Delimiter','|'); % convert to list
    line_header_items=line_header_items{1}; % extract
    
    n_fields=length(line_header_items);
    
    if verbose,fprintf('reading data ...');end
    % from here on, read all data in one go (as a block, fast)
    format_str='%f';for field_i=1:n_fields-1,format_str=[format_str '|%f'];end
    data_block = fscanf(data_fid,format_str,[n_fields,inf]);
    fclose(data_fid); % close the file
    
    if verbose,fprintf(' done, assigning ...');end
    % assign values to names (all dynamic)
    for field_i=1:n_fields
        field_name=strrep(char(line_header_items(field_i)),' ','_');
        data.(field_name)=data_block(field_i,:); % dynamic field name and assignment
    end % field_i
    if verbose,fprintf(' done\n');end
    
    % convert date information
    data.datenum=datenum(data.YEAR,data.MONTH,data.YEAR*0+1);
    
    if verbose>1
        plot(data.datenum,data.DISCHRG);datetick
        ylabel(data.units);
    end
else
    fprintf('ERROR: file not found (%s)\n',data_file)
end % exist(data_file,'file')

end % RivDIS_read
