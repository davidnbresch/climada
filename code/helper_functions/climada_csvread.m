function res=climada_csvread(csv_filename,delimiter,noheader)
% climada read csv
% MODULE:
%   module name
% NAME:
%   climada_template
% PURPOSE:
%   climada read comma (or other) separated file, use first row to define
%   variable names (see noheader)
%
%   a csv test file (test.csv) might contain
%    name,val1,val2,val_descr
%    A,1,2,undef
%    B,3.4,5.6,def
%
%   it gets stored into
%    res.name: {'A' 'B'}
%    res.val1: [1 2]
%    res.val2: [3.4 5.6]
%    res.val_descr: {'undef' 'def'}
%
% CALLING SEQUENCE:
%   res=climada_csvread(csv_filename,delimiter,noheader)
% EXAMPLE:
%   res=climada_csvread('test.csv',',');
% INPUTS:
%   csv_filename: name and path of .csv file
%       > promted for if not given
%   OPTION param1: a structure with the fields...
%       this way, parameters can be passed on a fields, see below
% OPTIONAL INPUT PARAMETERS:
%   delimiter: the delimiter, default is climada_global.csv_delimiter,
%       usually thus , or ;
%   noheader: if =1, assume no header, just return values (calls cvsread)
%       otherwise (default, =0), use header row to define variable names
% OUTPUTS:
%   res: the output, empty if not successful
%       a structure with variable names as in first row of csv file
%       (or named var{i} if noheader=1)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161203, initial
% David N. Bresch, david.bresch@gmail.com, 20170121, CollapseDelimiters
% David N. Bresch, david.bresch@gmail.com, 20170125, empty lines skipped
%-

res=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('csv_filename','var'),csv_filename='';end
if ~exist('delimiter','var'),delimiter=climada_global.csv_delimiter;end
if ~exist('noheader','var'),noheader=0;end

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
csv_fieldnames=''; % init


% prompt for csv_filename if not given
if isempty(csv_filename) % local GUI
    csv_filename=[climada_global.data_dir filesep '*.csv'];
    [filename, pathname] = uigetfile(csv_filename, 'Select file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        csv_filename=fullfile(pathname,filename);
    end
end

if exist(csv_filename,'file')
    
    fid=fopen(csv_filename,'r');
    line_i=1;
    
    % read raw data
    while not(feof(fid))
        
        str=fscanf(fid,'%s',1);
        
        if ~isempty(str)
            
            if ~noheader % first line, we infer field names from
                csv_fieldnames=strsplit(str,delimiter);
                noheader=1; % now we have a header
            else
                % read data
                raw_line_data=strsplit(str,',','CollapseDelimiters', false); % treat multiple delimiters separately
                
                if isempty(csv_fieldnames) % if no header
                    for var_i=1:length(raw_line_data);csv_fieldnames{var_i}=['var' num2str(var_i)];end
                end
                
                for var_i=1:1:length(csv_fieldnames)
                    num_val=str2double(raw_line_data{var_i});
                    if isnan(num_val)
                        res.(csv_fieldnames{var_i}){line_i}=raw_line_data{var_i};
                    else
                        res.(csv_fieldnames{var_i})(line_i)=num_val;
                    end
                end
                line_i=line_i+1;
                
            end % ~noheader
            
        end % ~isempty(str)
        
    end % while
    fclose(fid);
    
end % exist(csv_filename,'file')

end % climada_csvread