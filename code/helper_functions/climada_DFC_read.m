function DFC=climada_DFC_read(DFC_file)
% climada
% NAME:
%   climada_DFC_read
% PURPOSE:
%   Read a damage frequency curve (DFC) with DFC from file, e.g. to compare with
%   other models.
%
%   Instead of a lengthy description of the exact content of the Excel
%   file, see the one example (climada_DFC_compare_file.xls) in the
%   core climada data results folder. Note that the code (and the format
%   of the Excel) is peril-independent. If troubles with .xls (or .xlsx),
%   save as Excel95 (or 97).
%
%   See also climada_DFC_compare, climada_EDS_DFC and climada_EDS_DFC_match
% CALLING SEQUENCE:
%   DFC=climada_DFC_read(DFC_file)
% EXAMPLE:
%   DFC_file=[climada_global.data_dir filesep 'results' filesep 'climada_DFC_compare_file.xls']; % the example file
%   DFC=climada_DFC_read(DFC_file)
%   % process a full folder, e.g.
%   folder=[climada_global.data_dir filesep 'results' filesep 'model_results'];D=dir([folder filesep '*.xlsx']);
%   for file_i=1:length(D),if ~D(file_i).isdir,DFC=climada_DFC_read([folder filesep D(file_i).name]);end;end
% INPUTS:
%   DFC_file: an Excel file with a DFC (currently only one single DFC
%       supported).If troubles with .xls, save as Excel95 first.
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   DFC: a strcture with a damage frequency curve (DFC)
%       return_period(i): the return periods
%       damage(i): the damage for return_period(i) (sometimes termed loss)
%       damage_of_value(i): damage as percentage of total asset value
%       peril_ID: the peril_ID
%       value: the total asset value (often referred to as TIV, i.e. total
%           insurable value)
%       ED: the annual expected damage (sometimes referred to as groun up
%           loss)
%       annotation_name: just a free annotation name
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150120, initial
%-

DFC=[];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('DFC_file','var'),DFC_file='';end

% PARAMETERS
%
% table to match peril codes
peril_match={
    'Winter Storm - Wind' 'WS'
    'Winter Storm' 'WS'
    'Tropical Cyclone' 'TC'
    'Tropical Cyclone - Wind' 'TC'
    'Tropical Cyclone - Surge' 'TS'
    'Earthquake' 'EQ'
    };
%
% TEST:
%DFC_file=[climada_global.data_dir filesep 'results' filesep 'climada_DFC_compare_file.xls'];

% prompt for DFC_file if not given
if isempty(DFC_file) % local GUI
    DFC_file=[climada_global.data_dir filesep 'results' filesep '*.xls'];
    [filename, pathname] = uigetfile(DFC_file, 'Select file with DFC:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        DFC_file=fullfile(pathname,filename);
    end
end

[fP,fN]=fileparts(DFC_file);
DFC_save_file=[fP filesep fN '.mat'];

if ~climada_check_matfile(DFC_file,DFC_save_file)
    
    fprintf('reading %s ... ',DFC_file);
    % read the file with DEF
    DFC=climada_xlsread('no',DFC_file,'Loss Frequency Curve',1);
    % DFC should contain (only what we need further down):
    % Return_Period: [n x 1 double]
    % Peril: {n x 1 cell}
    % Loss: [n x 1 double]
    % Loss_of_TIV: [n x 1 double]
    
    % rename fields
    DFC.return_period=DFC.Return_Period;
    DFC.damage=DFC.Loss;
    DFC.damage_of_value=DFC.Loss_of_TIV;
    DFC=rmfield(DFC,'Return_Period');
    DFC=rmfield(DFC,'Loss');
    DFC=rmfield(DFC,'Loss_of_TIV');
    
    DFC.annotation_name=fN; % just the filename to start with
    
    fprintf('done\n');
    
    % convert peril
    peril_pos=strmatch(DFC.Peril{1},peril_match);
    if ~isempty(peril_pos)
        DFC.peril_ID=peril_match{peril_pos(1),2};
    else
        DFC.peril_ID=DFC.Peril{1};
        fprintf('Warning: peril %s did not match, kept\n',DFC.peril_ID);
    end
    
    tab2=climada_xlsread('no',DFC_file,'Expected Loss',1);
    % tab2 should contain (only what we need further down):
    % TIV (we take the first number, i.e. TIV(1)
    % Ground_Up_Loss (we take the first number, i.e. Ground_Up_Loss(1)
    
    % a bit a safer way to get, as sometimes there might be {} instead of []
    TIV=[];
    try
        TIV=tab2.TIV{1};
    catch
        try
            TIV=tab2.TIV(1);
        end
    end
    DFC.value=TIV;
    
    % same for ED
    Ground_Up_Loss=[];
    try
        Ground_Up_Loss=tab2.Ground_Up_Loss{1};
    catch
        try
            Ground_Up_Loss=tab2.Ground_Up_Loss(1);
        end
    end
    DFC.ED=Ground_Up_Loss;
    
    fprintf('saving as %s\n',DFC_save_file);
    save(DFC_save_file,'DFC');
else
    load(DFC_save_file);
end % check_matfile

end % climada_DFC_read