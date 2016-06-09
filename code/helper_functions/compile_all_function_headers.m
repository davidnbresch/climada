function compile_all_function_headers(output_file)
% climada
% NAME:
%   compile_all_function_headers
% PURPOSE:
%   Crawl through all active climada code and modules and compile a file
%   with ALL function headers (comes very handy as a raw documentation).
%   Omits modules starting with _
%
%   This code calls compile_function_header_doc recursively for core
%   climada and all modules
%
%   RESTRICTION: the present code does NOT process code sub-folders
%
%   see also compile_function_header_doc
% CALLING SEQUENCE:
%   compile_all_function_headers(output_file)
% EXAMPLE:
%   compile_all_function_headers
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   output_file: file to write (.txt or .html)
%       set to ../climada/docs/_code_overview.html by default
% OUTPUTS:
%   writes the file ../climada/docs/_code_overview.html
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141107, initial (on flight to Dubai)
% David N. Bresch, david.bresch@gmail.com, 20160609, standardized, one sub-code level
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('output_file','var'), output_file = '';end

% PARAMETERS
%
if isempty(output_file),output_file=[climada_global.root_dir filesep 'docs' filesep '_code_overview.html'];end

% not interactive any more
% if isempty(output_file)
%     [filename, pathname] = uiputfile('code_overview.html', 'Save header overview as (either .txt or .html):');
%     if isequal(filename,0) || isequal(pathname,0)
%         return; % Cancel pressed
%     else
%         output_file=fullfile(pathname,filename);
%     end
% end

% first, compile a list of all code folders (and one level of sub-folders
% therein) to process
% -----------------------------------------------------------------------

% start with core code folder
folders{1}=[climada_global.root_dir filesep 'code'];

% check code sub-folders
subfolder_dir=folders{1};
D_sub=dir(subfolder_dir);
for subfolder_i=1:length(D_sub)
    if D_sub(subfolder_i).isdir && ~strcmp(D_sub(subfolder_i).name(1),'.')
        folders{end+1}=[subfolder_dir filesep D_sub(subfolder_i).name];
    end
end % subfolder_i

% add all local modules
D=dir(climada_global.modules_dir);
for module_i=1:length(D)
    if D(module_i).isdir && (~strcmp(D(module_i).name(1),'.') && ~strcmp(D(module_i).name(1),'_') && ~strcmp(D(module_i).name(1),'private'))
        folders{end+1}=[climada_global.modules_dir filesep D(module_i).name filesep 'code'];
        
        % check sub-folders
        subfolder_dir=folders{end};
        D_sub=dir(subfolder_dir);
        for subfolder_i=1:length(D_sub)
            if D_sub(subfolder_i).isdir && ~strcmp(D_sub(subfolder_i).name(1),'.')
                folders{end+1}=[subfolder_dir filesep D_sub(subfolder_i).name];
                
                % 2nd sub-folder switched off, as this level is used to
                % store real low-level functions
                % check sub-sub-folders
                % subsubfolder_dir=folders{end};
                % D_subsub=dir(subsubfolder_dir);
                % for subsubfolder_i=1:length(D_subsub)
                %     if D_subsub(subsubfolder_i).isdir && ~strcmp(D_subsub(subsubfolder_i).name(1),'.')
                %         folders{end+1}=[subsubfolder_dir filesep D_subsub(subsubfolder_i).name];
                %     end
                % end % subsubfolder_i
                
            end
        end % subfolder_i
        
    end
end % module_i

% second, build the list of all code files to treat
% -------------------------------------------------

% check folder list as compiled
code_file={}; % init
code_folder={}; % init
for folder_i=1:length(folders)
    %fprintf('%s\n',folders{folder_i}); % CHECK folder
    code_files=dir(folders{folder_i});
    for file_i=1:length(code_files)
        [~,fN,fE]=fileparts(code_files(file_i).name);
        if strcmp(fE,'.m') && ~strcmp(fN,'Contents')
            code_folder{end+1}=folders{folder_i};
            code_file{end+1}=fN;
            %fprintf('  %s\n',fN); % CHECK filename
        end
    end % file_i
end % folder_i

n_files=length(code_folder);

% third, write the header of the .html file
% -----------------------------------------

out_fid=fopen(output_file,'w'); % open output file overwrite

% Title and intro info.
html_title='Overview of climada routines';
fprintf(out_fid,'<body>\r\n');
fprintf(out_fid,'<H1><FONT COLOR="FF0000">%s</FONT></FONT></H1>\r\n',html_title);
fprintf(out_fid,'<P>\r\n');
fprintf(out_fid,'Use <i>Find in page</i> ... from the Edit Menu to search for any text in all help-files.<P>\r\n');
fprintf(out_fid,'Use the <i>which</i> command in MATLAB to locate the specific function.<P>\r\n');
fprintf(out_fid,'This page has been automatically created by <i>compile_function_header_doc</i>.<P>\r\n');
fprintf(out_fid,'Please consult <A HREF="climada_manual.pdf">climada_manual.pdf</A> for more information.<P>\r\n');
fprintf(out_fid,'<P>\r\n');
fprintf(out_fid,'<P>');
fprintf(out_fid,'<STRONG>Last modified: </STRONG>%s<P>\r\n',datestr(now));
fprintf(out_fid,'\r\n');
fprintf(out_fid,'<HR>\r\n');
fprintf(out_fid,'\r\n');
fprintf(out_fid,'<A NAME="ROUTINELIST">\r\n');
fprintf(out_fid,'<UL>\r\n');

% fourth, write the list of all code functions
% --------------------------------------------

fprintf('total %i functions ...',n_files);

last_code_folder='';
for function_i=1:n_files
    routine_name=code_file{function_i};
    if ~strcmp(last_code_folder,code_folder{function_i})
        full_code_folder=code_folder{function_i};
        full_code_folder=strrep(full_code_folder,climada_global.root_dir,'');
        % write folder name
        fprintf(out_fid,'\r\n');
        fprintf(out_fid,'<P><STRONG>%s:</STRONG>%s<P>\r\n',full_code_folder);
    end
    last_code_folder=code_folder{function_i};
    fprintf(out_fid,'<LI><A HREF="#%s">%s</A>\r\n',routine_name,routine_name);
end % function_i

fprintf(out_fid,'<P>\r\n');
fprintf(out_fid,'</UL><P>\r\n');
fprintf(out_fid,' \r\n');
fprintf(out_fid,'<HR>\r\n');
fprintf(out_fid,' \r\n');
fprintf(out_fid,'<H1>Routine Descriptions</H1>\r\n');
fprintf(out_fid,'<PRE>\r\n');
                
% fifth, write the function headers
% ---------------------------------
total_line_count=0; % init
for function_i=1:n_files
    routine_name=code_file{function_i};
    fprintf(out_fid,'\n\n<A NAME="%s">\r\n',routine_name);
    fprintf(out_fid,'<H2>%s</H2></A>\r\n',routine_name);
    
    line_count=LOCAL_process_function_header(out_fid,[code_folder{function_i} filesep routine_name '.m']);
    total_line_count=total_line_count+line_count;
    full_name=which(routine_name); % only show link to source for routines in MATLAB path
    full_name=strrep(full_name,filesep,'/'); % switch to for html-separator
    fprintf(out_fid,'View <A HREF=file:%s>source</A>\r\n',full_name);
    fprintf(out_fid,'<A HREF="#ROUTINELIST">[List of Routines]</A>\r\n');
    fprintf(out_fid,'<PRE>\r\n');
end % function_i

fclose(out_fid); % close output file

fprintf(' total code line count %i (average %i per file)\n',...
    total_line_count,ceil(total_line_count/n_files));

end % compile_all_function_headers

function line_count=LOCAL_process_function_header(out_fid,filename)
% function overview
% NAME:
%	LOCAL_process_function_header
% PURPOSE:
%   open m-file and add header to specified fid
% CALLING SEQUENCE:
%	LOCAL_process_function_header(out_fid,filename)
% EXAMPLE:
%   see compile_function_header_doc
% INPUTS:
%   fid: fid of an open text file
%   filename: filename (with path) of an m-file
%   write_html_formatted: =1 for html-formatted output
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   to fid
%   and line_count the number of lines
% MODIFICATION HISTORY:
% David N. Bresch, david.n.bresch@alumni.ethz.ch, 30.9.2003
%-
try
    in_fid=fopen(filename,'r');
    
    % read lines
    % line=fgetl(in_fid); % skip first line: function ...
    % line=fgetl(in_fid); % skip second line with keywords
    
    line_count=0; % init
    
    read_next_line=1;
    %%while not(feof(in_fid)) & read_next_line
    while not(feof(in_fid))
        line=fgetl(in_fid); % skip first function... line
        line_count=line_count+1;
        if length(line)>0 % line not empty
            if strcmp(line(1),'%') % is a comment
                if length(line)>1
                    if strcmp(line(1:2),'%-')
                        read_next_line=0; % header ended
                    end
                end
            end
            
            if read_next_line
                % replace html-reserved characters
                line=strrep(line,'<','&lt');
                line=strrep(line,'>','&gt');
                line=strrep(line,'&','&amp');
                line=strrep(line,'"','&quot');
                if strcmp(strtok(line),'function')
                    % write function header line
                    line = ['<font color="blue">' line ' </font>'];
                    fprintf(out_fid,'%s\r\n',line);
                else
                    fprintf(out_fid,'%s\r\n',line(2:end));% write header line
                end
            end
        else
            %%read_next_line=0; % empty line reached, header has ended
        end
        
    end % while
    
    fclose(in_fid); % close m-file
    
catch
    try
        % try to close the opened m-file
        fclose(in_fid);
    catch
        
    end
    fprintf('ERROR processing %s\n',filename);
end

end % LOCAL_process_function_header