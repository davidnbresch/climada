function res=climada_xlsread(interactive_mode,excel_file,in_excel_sheet,silent_mode,misdat_value,misdat_out_value)
% climada excel data import read
% NAME:
%   climada_xlsread
% PURPOSE:
%   read one Excel sheet from an Excel file and return the content in a
%   structure.
%
%   Usually, just read each column of the Excel tab into one variable.
%
%   NOTE: for older MATLAB versions, only the array-type input works, not
%   the single variables (header) etc.
%
%   OCTAVE: Please install the io package first, ether directly from source
%   forge with: pkg install -forge io -auto
%   or, (e.g. in case this fails, get the io package first from Octave
%   source forge and then install from the downloaded package:
%   pkg install {local_path}/io-2.2.5.tar -auto
%   Note that it looks like Octave prefers .xlsx files
%
%   The sheet might contain as many single variables (a header)
%   and in the second part (data) as many columns as you like.
%   % preceedes rows used for comment
%   * denotes single variables (scalars) all read as text, the string after
%       the asterix is used as variable name and the next right cell as value.
%       Any further cells to the right are not processed (eg used for comments,
%       as shown below)
%   the last row before the data section is used to label the data columns
%
%   an Excel sheet of eg the following form will be processed:
%
% %climada post event TC trackdata sheet, fill in at least the bold data, either MaxSustainedWind or Pressure?
% *event_date	20030906	the date as yyyymmdd
% *event_name	Isabel	    the name
% *MaxSustainedWindUnit	kn	either kn (also use kn for kt), mph, km/h or m/s
% *CentralPressureUnit	mb	mb or hPa
% *CelerityUnit	kn	        either kn, mph, km/h or m/s
% *track_timestep	6	    in hours, used in Celerity calculation if Celerity and/or time not given below
% *unique_ID	0	        default=0
% *MaxSaffSimp	4	        maximum Safir Simson scale reached
% *record_date	20030919	date of this record
% *comment	test	        free comment
% %follows the track data (next line are headers, fill in as much as you know, do NOT change headers!)
% lat	lon	                MaxSustainedWind	CentralPressure	Celerity	SaffSimp	time	yyyy	mm	dd
% 14	-34	61.775			0	                                                            13	2003	9	6
% 13.6	-34.5	61.775	    0	                                                            15	2003	9	6
%   ...
% 13.4	-35.4	79.425		0	                                                            21	2003	9	6
%
%   and returned in a structure like:
%
%   res.event_date='20030906'
%   res.event_name='Isabel'
%   ...
%   res.comment='test'
%   res.lat the vector hold all latitudes
%   res.lon the vector holding all longitides
%   res.MaxSustainedWind the windspeed vector
%   ...
%   res.dd the day number vector
%
%   note that empty columns (like CentralPressure) are skipped
% CALLING SEQUENCE:
%   res=climada_xlsread(interactive_mode,excel_file,in_excel_sheet,silent_mode,misdat_value,misdat_out_value)
% EXAMPLE:
%   res=climada_xlsread(interactive_mode,excel_file,in_excel_sheet);
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   interactive_mode: 'interactive' or 'no'. If interactive, the user gets
%       prompted for the sheet in the Excel file
%       (Currently hard-wired to interactive)
%   excel_file: the Excel file to read
%   in_excel_sheet: the Excel sheet to read in the excel_file
%   silent_mode: if =1, do not write messages to stdout, default=0, means writing
%   misdat_value: a missing date value, all numeric data of exatly this
%       value are ste to NaN, default is no missing data treatment, i.e.
%       misdat_value=[].
%   misdat_out_value: the value missing data is set to on output,
%       default=NaN. Only active if misdat_value is set
% OUTPUTS:
%   res: a structure holding the data from the selected Excel sheet. Note
%       that colunm headers that contain a number (xxx) are named VALxxx 
%       in the structure
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20020901, 20080924
% Lea Mueller, muellele@gmail.com, 20120730, if ~isempty(NUMERIC) also possible
% David N. Bresch, david.bresch@gmail.com, 20141230, misdat_value added
% David N. Bresch, david.bresch@gmail.com, 20150101, simplified if file and sheet provided (no check for sheet to exist)
% David N. Bresch, david.bresch@gmail.com, 20150227, finally, column headers with numbers are named VALxxxx
% Lea Mueller, muellele@gmail.com, 20150505, bugfix for difficult header name
% David N. Bresch, david.bresch@gmail.com, 20160527, misdat_out_value introduced
% David N. Bresch, david.bresch@gmail.com, 20180514, climada_global.spreadsheet_ext
%-

global climada_global

if ~exist('interactive_mode','var'),interactive_mode=[];end
if ~exist('excel_file','var'),excel_file=[];end
if ~exist('in_excel_sheet','var'),in_excel_sheet=[];end
if ~exist('silent_mode','var'),silent_mode=[];end
if ~exist('misdat_value','var'),misdat_value=[];end
if ~exist('misdat_out_value','var'),misdat_out_value=NaN;end

if isempty(interactive_mode),interactive_mode='interactive';end
if isempty(silent_mode),silent_mode=0;end

res=[]; % init

if isempty(excel_file)
    [filename, pathname] = uigetfile(['*' climada_global.spreadsheet_ext], 'Select an Excel file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % Cancel pressed
    else
        excel_file=fullfile(pathname, filename);
    end
end

res.filename = excel_file;

% read excel sheet
% ----------------
if strcmp(interactive_mode,'no') && ~isempty(in_excel_sheet)
    % simple, force try reading the sheet as specified on input
    excel_sheet=in_excel_sheet;
else
    % check file content and ask user to select sheet (if more than one in file)
    [sheet_type,sheet_names]=xlsfinfo(excel_file);
    if not(strcmp(sheet_type,'Microsoft Excel Spreadsheet')),fprintf(' - WARNING: %s (not Excel?)\n',sheet_type);end
    if length(sheet_names)>1
        if strcmp(interactive_mode,'interactive')
            % we have more than one sheet in the file -> allow to select
            % the portfolio (the treaty has always to be named 'treaty')
            [selection,ok] = listdlg('Name','climada Excel import','PromptString','Select sheet:',...
                'SelectionMode','single','ListString',sheet_names,'ListSize',[200 100]);
            if ok
                excel_sheet=char(sheet_names(selection));
            else
                if ~silent_mode,fprintf(' - WARNING: first sheet (%s) used\n',char(sheet_names)); end
                excel_sheet=char(sheet_names(1));
            end
        else
            excel_sheet=[]; % init
            if ~isempty(in_excel_sheet) % first try user-requested sheet
                excel_sheet=strmatch(in_excel_sheet,char(sheet_names),'exact');
            end
            if ~isempty(excel_sheet)
                excel_sheet=char(sheet_names(excel_sheet));
            else
                excel_sheet=char(sheet_names(1)); % third try first sheet
                if ~silent_mode, fprintf(' - WARNING: first sheet (%s) used\n',char(sheet_names'));end
            end
        end
    else
        % there is only one sheet - assume it to be a portfolio
        excel_sheet=char(sheet_names(1));
    end
end

if ~silent_mode,fprintf('reading sheet %s from %s\n',excel_sheet,excel_file);end

% actually read the Excel sheet
% -----------------------------
%%try % TRY switched off, as the fallback is not very useful, hence this
% way, debugging is easier (i.e. if one reads strange Excel sheets etc)
% the xlsread for later MATLAB versions, works also for complex Excel sheets
[NUMERIC,TEXT,RAW]=xlsread(excel_file,excel_sheet);

% first, process all single variables
% -----------------------------------
warning off MATLAB:nonIntegerTruncatedInConversionToChar % to avoid WARNINGS
first_column=char(RAW{:,1}); % get first column
max_header_length=1;
for i=1:size(RAW,1)
    if ischar(RAW{i,1}),max_header_length=i;end
end

%second_column=char(RAW{1:max_header_length,2}); % get second column
single_pos=strmatch('*',first_column(1:max_header_length,1)); % get all *... values
for var_i=1:length(single_pos)
    eff_pos=single_pos(var_i);
    variable_name=first_column(eff_pos,2:end);
    variable_value=RAW{eff_pos,2};
    try
        res = setfield(res,variable_name,variable_value); % add to struct
        if ~ischar(variable_value)
            variable_value_str=num2str(variable_value);
        else
            variable_value_str=variable_value;
        end
        if ~silent_mode,fprintf(' - assigning %s: %s\n',deblank(variable_name),variable_value_str);end
    catch
        if ~silent_mode, fprintf(' - WARN: assigning %s failed\n',variable_name);end
    end
end

% figure out the header line position
comment_pos=strmatch('%',first_column(1:max_header_length,1)); % get all *... values
if length(single_pos)==0,single_pos=0;end
if length(comment_pos)==0,comment_pos=single_pos;end
header_pos=max(max(comment_pos),max(single_pos))+1;

% process the array data
% ----------------------
for header_i=1:size(RAW,2)
    
    header_tag=RAW{header_pos,header_i};
    if isnumeric(header_tag)
        header_tag=sprintf('VAL%i',header_tag);
    else
        header_tag=char(header_tag);
    end
    
    % purge from any special characters
    header_tag=strrep(header_tag,'(','');
    header_tag=strrep(header_tag,')','');
    header_tag=strrep(header_tag,'*','');
    header_tag=strrep(header_tag,'&','');
    header_tag=strrep(header_tag,'[','');
    header_tag=strrep(header_tag,']','');
    header_tag=strrep(header_tag,'?','');
    %header_tag=strrep(header_tag,' ',''); % see below, replaced by '_'
    header_tag=strrep(header_tag,'=','');
    header_tag=strrep(header_tag,'+','');
    header_tag=strrep(header_tag,'-','');
    header_tag=strrep(header_tag,'%','');
    header_tag=strrep(header_tag,'/','');
    header_tag=strrep(header_tag,'{','');
    header_tag=strrep(header_tag,'}','');
    header_tag=strrep(header_tag,':','');
    header_tag=strrep(header_tag,'.','');
    header_tag=strrep(header_tag,',','');
    header_tag=strrep(header_tag,' ','_');
    header_tag=strrep(header_tag,'__','_');
    header_tag=strrep(header_tag,'__','_');
    header_tag=deblank(header_tag);
        
    arr_values=[];
    
    if ~isempty(RAW{header_pos+1,header_i})
        if ~silent_mode,fprintf(' - processing %s\n',header_tag);end
        
        if isfield(res,header_tag)
            if ~silent_mode, fprintf('\tdouble entry for header %s (%i skipped)\n',header_tag, header_i);end
        else
            arr_values=RAW(header_pos+1:end,header_i);
            if isnumeric([arr_values{:}]) %isnumeric(arr_values{1})
                temp=[];
                for element_i=1:size(arr_values,1)
                    temp(element_i,1)=arr_values{element_i};
                end % element_i
                if ~silent_mode,fprintf('   -> converted to numeric\n');end
                arr_values=temp;
                if ~isempty(misdat_value)
                    arr_values(arr_values==misdat_value)=misdat_out_value; % replace misssing data with NaN
                end
            end
            
            if ~isempty(header_tag)
                % counter = 0;
                % while isfield(res,header_tag)
                %     %if ~silent_mode, fprintf('WARNING: (empty) header/column %i skipped\n',header_i);end
                %     counter       = counter+1;
                %     header_tag    = [header_tag '_' int2str(counter)];
                % end
                try
                    res = setfield(res,header_tag,arr_values); % add to struct
                catch
                    fprintf('consider simplyfying header tag %s\n',header_tag);
                    if ~isnan(str2double(header_tag(1))), header_tag = ['Att_' header_tag];end% Attribute starts with number, rewrite for setfield
                    header_tag = strrep(header_tag,' ',''); % deblank attributes
                    %res = setfield(res,header_tag{:},arr_values); % add to struct
                    res = setfield(res,header_tag,arr_values); % add to struct
                end
            else
                if ~silent_mode, fprintf('WARNING: (empty) header/column %i skipped\n',header_i);end
            end
        end %duplicate header_tag
    else
        if ~silent_mode,fprintf(' - %s skipped\n',header_tag);end
    end
end

% catch % try
%
%     fprintf('NOTE: simple xlsread\n');
%     [NUMERIC,TEXT]=xlsread(excel_file,excel_sheet);
%
%     for tag_i=1:size(NUMERIC,2)
%
%         header_tag = TEXT{1,tag_i};
%         % purge from any special characters
%         header_tag=strrep(header_tag,'(','');
%         header_tag=strrep(header_tag,')','');
%         header_tag=strrep(header_tag,'*','');
%         header_tag=strrep(header_tag,'&','');
%         header_tag=strrep(header_tag,'[','');
%         header_tag=strrep(header_tag,']','');
%         %header_tag=strrep(header_tag,' ','');
%         header_tag=strrep(header_tag,'?','');
%         header_tag=strrep(header_tag,'=','');
%         header_tag=strrep(header_tag,'+','');
%         header_tag=strrep(header_tag,'-','');
%         header_tag=strrep(header_tag,'%','');
%         header_tag=strrep(header_tag,'/','');
%         header_tag=strrep(header_tag,'{','');
%         header_tag=strrep(header_tag,'}','');
%         header_tag=strrep(header_tag,':','');
%         header_tag=strrep(header_tag,'.','');
%         header_tag=strrep(header_tag,' ','_');
%         header_tag=strrep(header_tag,'__','_');
%         header_tag=strrep(header_tag,'__','_');
%
%         header_tag=deblank(header_tag);
%
%         if ~isempty(NUMERIC)
%             fprintf('Column %d: %s\t', tag_i, header_tag)
%             if all(isnan(NUMERIC(:,tag_i)))
%                 fprintf('No data available\n')
%             else
%                 res = setfield(res,header_tag,NUMERIC(:,tag_i)); %#ok<SFLD> % add to struct
%                 fprintf('added to struct\n')
%             end
%         end
%     end
%
% end % try

return
