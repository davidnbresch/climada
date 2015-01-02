function res=climada_spreadsheet_read(interactive_mode,spreadsheet_file,spreadsheet_sheet,silent_mode)
% climada spreadhseet data import read
% NAME:
%   climada_spreadsheet_read
% PURPOSE:
%   a wrapper that reads spreadsheet data
%
%   currently implemented are climada_xlsread and climada_odsread
%
%   see all further details in mentioned implementations, the wrapper just
%   passes all variables over to them
% CALLING SEQUENCE:
%   res=climada_spreadsheet_read(interactive_mode,spreadsheet_file,spreadsheet_sheet,silent_mode);
% EXAMPLE:
%   res=climada_spreadsheet_read
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   interactive_mode: 'interactive' or 'no'. If interactive, the user gets
%       prompted for the sheet in the Excel file
%       (Currently hard-wired to interactive)
%   spreadsheet_file: the spreadsheet file to read
%   spreadsheet_sheet: the sheet to read in the spreadsheet file
%   silent_mode: if =1, do not write messages to stdout, default=0, means writing
% OUTPUTS:
%   res: a structure holding the data from the selected Excel sheet
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20130330
%-

res=[]; % init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('interactive_mode','var'),interactive_mode=[];end
if ~exist('spreadsheet_file','var'),spreadsheet_file=[];end
if ~exist('spreadsheet_sheet','var'),spreadsheet_sheet=[];end
if ~exist('silent_mode','var'),silent_mode=[];end

% if no file given, call the default implementation
if isempty(spreadsheet_file)
    fE=climada_global.spreadsheet_ext; % default
else
    % figure out the file type
    [fP,fN,fE]=fileparts(spreadsheet_file);
end

if strcmp(fE,'.xls') || strcmp(fE,'.xlsx')
    res=climada_xlsread(interactive_mode,spreadsheet_file,spreadsheet_sheet,silent_mode);
elseif strcmp(fE,'.ods')
    res=climada_odsread(interactive_mode,spreadsheet_file,spreadsheet_sheet,silent_mode);
else
    fprintf('ERROR: %s not implemented\n',fE);
end

return
