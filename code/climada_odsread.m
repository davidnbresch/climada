function res=climada_odsread(interactive_mode,ods_file,ods_sheet,silent_mode)
% climada ods (open data spreadsheet) data import read
% NAME:
%   climada_odsread
% PURPOSE:
%   read one ods sheet from an ods file and return the content in a
%   structure. Mainly a wrapper to invoke loadods and then sort into a 
%   struct as uased in climada. 
%   Limited functionality compared to climada_xlsread
%   
%   The sheet might contain as  many columns as you like, the first row (1)
%   is interpreted as header and converted into field names, the data in.
%   Empty columns are skipped
%
%   HINT: Sometimes, not all columns of an .ods sheet are read, just
%   copy/paste as values in ods, it often helps. It looks as if columns
%   with results of functions are skiped... therefore, copy/paste as values
%
% CALLING SEQUENCE:
%   res=climada_odsread(interactive_mode,ods_file,ods_sheet);
% EXAMPLE:
%   res=climada_odsread(interactive_mode,ods_file,ods_sheet);
% INPUTS:
%   interactive_mode: 'interactive' or 'no'. If interactive, the user gets
%       prompted for the sheet in the Excel file
%       (Currently hard-wired to interactive)
%   ods_file: the Excel file to read, prompted for if not given
%   ods_sheet: the ods sheet to read in the ods_file
%       given the simplicity of the ods implementation, the sheet name is
%       needed, the oce fails if not given (does not even read the first
%       sheet, sorry)
% OPTIONAL INPUT PARAMETERS:
%   silent_mode: if =1, do not write messages to stdout, default=0, means writing
% OUTPUTS:
%   res: a structure holding the data from the selected Excel sheet
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20130401
%-

res=[]; % init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('interactive_mode','var'),interactive_mode=[];end
if ~exist('ods_file','var'),ods_file=[];end
if ~exist('ods_sheet','var'),ods_sheet=[];end
if ~exist('silent_mode','var'),silent_mode=[];end

if isempty(interactive_mode),interactive_mode='interactive';end
if isempty(silent_mode),silent_mode=0;end


% PARAMETERS
%
% TEST
%%interactive_mode='no',silent_mode=0,ods_sheet='measures',
%%ods_file=[climada_global.data_dir filesep 'entities' filesep 'USFL_MiamiDadeBrowardPalmBeach2012.ods']

% prompt for file if empty or interactive mode (often used to pass on a default file)
if isempty(ods_file) || strcmp(interactive_mode,'interactive')
    if isempty(ods_file),ods_file='*.ods';end
    [filename, pathname] = uigetfile(ods_file, 'Select an ods file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % Cancel pressed
    else
        ods_file=fullfile(pathname, filename);
    end
end

% read raw ods data
options.sheet_name=ods_sheet;
RAW = loadods(ods_file,options); % call the raw routine by Alex Marten

if isempty(RAW)
    if ~silent_mode,fprintf('ERROR reading sheet %s from %s, failed\n',ods_sheet,ods_file);end
    return
else
    if ~silent_mode,fprintf('reading sheet %s from %s\n',ods_sheet,ods_file);end
    res.filename = ods_file;
end

first_column=char(RAW{:,1}); % get first column
max_header_length=1;
for i=1:size(RAW,1)
    if ischar(RAW{i,1}),max_header_length=i;end
end

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

max_isnan=0; % init

% process the array data
% ----------------------
for header_i=1:size(RAW,2)
    header_tag=char(RAW{header_pos,header_i});
    % purge from any special characters
    header_tag=strrep(header_tag,'(','');
    header_tag=strrep(header_tag,')','');
    header_tag=strrep(header_tag,'*','');
    header_tag=strrep(header_tag,'&','');
    header_tag=strrep(header_tag,'[','');
    header_tag=strrep(header_tag,']','');
    header_tag=strrep(header_tag,'?','');
    %header_tag=strrep(header_tag,' ','');
    header_tag=strrep(header_tag,'=','');
    header_tag=strrep(header_tag,'+','');
    header_tag=strrep(header_tag,'-','');
    header_tag=strrep(header_tag,'%','');
    header_tag=strrep(header_tag,'/','');
    header_tag=strrep(header_tag,'{','');
    header_tag=strrep(header_tag,'}','');
    header_tag=strrep(header_tag,':','');
    header_tag=strrep(header_tag,'.','');
    header_tag=strrep(header_tag,' ','_');
    header_tag=strrep(header_tag,'__','_');
    header_tag=strrep(header_tag,'__','_');
    header_tag=deblank(header_tag);
    arr_values=[];
    
    if length(RAW{header_pos+1,header_i})>0
        
        if isfield(res,header_tag)
            if ~silent_mode, fprintf('\tdouble entry for header %s (%i skipped)\n',header_tag, header_i);end
        else
            if length(header_tag) > 0
                
                if ~silent_mode,fprintf(' - processing %s\n',header_tag);end

                arr_values=RAW(header_pos+1:end,header_i);
                if isnumeric([arr_values{:}]) %isnumeric(arr_values{1})
                    temp=[];
                    for element_i=1:size(arr_values,1)
                        temp(element_i,1)=arr_values{element_i};
                    end % element_i
                    if ~silent_mode,fprintf('   -> converted to numeric\n');end
                    arr_values=temp;
                    % strange enough, last entries are often NaN, hence:
                    arr_values=arr_values(~isnan(arr_values)); % get rid of NaN
                end
                
                try
                    res = setfield(res,header_tag,arr_values); % add to struct
                catch
                    if ~isnan(str2double(header_tag(1))), header_tag = ['Att_' header_tag];end% Attribute starts with number, rewrite for setfield
                    header_tag = smat_removeBlanks({header_tag},'_'); % deblank attributes
                    res = setfield(res,header_tag{:},arr_values); % add to struct
                end
            else
                %%if ~silent_mode, fprintf('WARNING: (empty) header/column %i skipped\n',header_i);end
            end
        end %duplicate header_tag
    else
        if ~silent_mode,fprintf(' - %s skipped\n',header_tag);end
    end
end

return