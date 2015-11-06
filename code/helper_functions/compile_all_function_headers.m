function compile_all_function_headers(output_file)
% climada
% NAME:
%   compile_all_function_headers
% PURPOSE:
%   Crawl through all active climada code and modules and compile a file
%   with ALL function headers (comes very handy as a raw documentation).
%
%   This code calls compile_function_header_doc recursively for core
%   climada and all modules
%
%   see also compile_function_header_doc
% CALLING SEQUENCE:
%   compile_all_function_headers(output_file)
% EXAMPLE:
%   compile_all_function_headers
% INPUTS:
%   output_file: file to write (.txt or .html)
%       > asked for if not provided
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141107, initial (on flight to Dubai)
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('output_file','var'), output_file = '';end

% PARAMETERS
%

if isempty(output_file)
    [filename, pathname] = uiputfile('code_overview.html', 'Save header overview as (either .txt or .html):');
    if isequal(filename,0) || isequal(pathname,0)
        return; % Cancel pressed
    else
        output_file=fullfile(pathname,filename);
    end
end

% start with core code folder
folders{1}=[climada_global.root_dir filesep 'code'];

% add all local modules
D=dir(climada_global.modules_dir);
rep_i=1;
for module_i=1:length(D)
    if D(module_i).isdir && ~strcmp(D(module_i).name(1),'.')
        folders{rep_i+1}=[climada_global.modules_dir filesep D(module_i).name filesep 'code'];
        rep_i=rep_i+1;
    end
end % module_i

compile_function_header_doc(folders,0,output_file);

end
