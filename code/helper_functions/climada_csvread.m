function res=climada_csvread(csv_filename,delimiter,noheader)
% climada read csv
% MODULE:
%   core
% NAME:
%   climada_template
% PURPOSE:
%   climada read comma (or other) separated file, use first row to define
%   variable names (see noheader)
%
%   ERROR caption does indicate whether it is a numerical (num) or string
%   (str) variable that lesds to an issue, it displays just the number of
%   and full line content causing the error and (if possible) the single
%   element to convert in (..) at the end. Usual suspects are delimiters
%   within fields (eg if delimiter is comma (,) one cannot use commas in
%   fields; Pure number entries in fields which are alphanumerical in the
%   first data line (which defines the receiving field as cellstr).
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
%       Be very careful to use the output if ERRORs occurred
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161203, initial
% David N. Bresch, david.bresch@gmail.com, 20170121, CollapseDelimiters
% David N. Bresch, david.bresch@gmail.com, 20170125, empty lines skipped
% David N. Bresch, david.bresch@gmail.com, 20170217, ERROR catch
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
        
        %str=fscanf(fid,'%s',1);
        str=fgetl(fid);
        
        if ~isempty(str)
            
            if ~noheader % first line, we infer field names from
                csv_fieldnames=strsplit(str,delimiter);
                for field_i=1:length(csv_fieldnames)
                    csv_fieldnames{field_i}=strrep(csv_fieldnames{field_i},'#','');
                    csv_fieldnames{field_i}=strrep(csv_fieldnames{field_i},'.','');
                    csv_fieldnames{field_i}=strrep(csv_fieldnames{field_i},' ','');
                end
                noheader=1; % now we have a header
            else
                % read data
                raw_line_data=strsplit(str,',','CollapseDelimiters',false); % treat multiple delimiters separately
                
                if isempty(csv_fieldnames) % if no header
                    for var_i=1:length(raw_line_data);csv_fieldnames{var_i}=['var' num2str(var_i)];end
                end
                
                for var_i=1:1:length(csv_fieldnames)
                    try
                        num_val=str2double(raw_line_data{var_i});
                    catch ME
                        try
                            fprintf('ERROR %s line %i: %s (%s)\n',ME.message,line_i,str,raw_line_data{var_i});
                        catch
                            fprintf('ERROR %s line %i: %s\n',     ME.message,line_i,str);
                        end
                    end
                    if isnan(num_val)
                        try
                            res.(csv_fieldnames{var_i}){line_i}=raw_line_data{var_i};
                        catch
                            try
                                fprintf('ERROR (num), line %i: %s (%s)\n',line_i,str,raw_line_data{var_i});
                            catch
                                fprintf('ERROR (num), line %i: %s\n',line_i,str);
                            end
                        end
                    else
                        try
                            res.(csv_fieldnames{var_i})(line_i)=num_val;
                        catch
                            try
                                fprintf('ERROR (str), line %i: %s (%s)\n',line_i,str,raw_line_data{var_i});
                            catch
                                fprintf('ERROR (str), line %i: %s\n',line_i,str);
                            end
                        end
                    end
                end
                line_i=line_i+1;
                
            end % ~noheader
            
        end % ~isempty(str)
        
    end % while
    fclose(fid);
    
end % exist(csv_filename,'file')

end % climada_csvread