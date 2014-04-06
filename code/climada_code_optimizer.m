function climada_code_optimizer(code_file)
% climada
% NAME:
%   climada_code_optimizer
% PURPOSE:
%   optimize climada code by removing waitbars etc. Very simple mechanisms,
%   just any line which comprises the tag % CLIMADA_OPT is removed
%   so the optimization is fully controlled by the programmer
% CALLING SEQUENCE:
%   climada_code_optimizer(code_file)
% EXAMPLE:
%   climada_code_optimizer
% INPUTS:
%   code_file: the code file to be optimized
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   the optimized, code, _OPT added at the end (prior to the suffix)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091228
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('code_file','var'),code_file=[];end

% PARAMETERS
%
% the tag which indentifies lines to be removed for optimization
OPT_tag='% CLIMADA_OPT';

% prompt for code_file if not given
if isempty(code_file) % local GUI
    code_file=[climada_global.root_dir filesep 'code' filesep '*.m'];
    [filename, pathname] = uigetfile(code_file, 'Select code to optimize:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        code_file=fullfile(pathname,filename);
    end
end

[fP,fN,fE]=fileparts(code_file);
code_file_out=[fP filesep fN '_OPT' fE];
in_fid=fopen(code_file,'r');
out_fid=fopen(code_file_out,'w');

% loop through code file and write optimized file
while 1
    tline = fgetl(in_fid);
    if ~ischar(tline), break, end
    if isempty(findstr(tline,OPT_tag)); % line with no OPT tag
        fprintf(out_fid,'%s\r\n',tline);
    end
end
        
fclose(in_fid);
fclose(out_fid);

fprintf('optimized code written to %s\n',[fN '_OPT' fE]);

return
