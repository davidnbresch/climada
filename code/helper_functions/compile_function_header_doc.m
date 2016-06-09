function compile_function_header_doc(folder,recursive_flag,output_file,req_output_mode,out_fid)
% wk02 sounding
% MODULE:
%   core
% NAME:
%	compile_function_header_doc
% PURPOSE:
%   crawl through all .m files in a given folder and compile the headers
%   into one single text (.txt) or html (.html) document. The html document
%   starts with a header listing all routine names, followed by the full
%   header listings, each with a link to the full source code.
%
% CALLING SEQUENCE:
%	compile_function_header_doc(folder,recursive_flag,output_file);
% EXAMPLE:
%   compile_function_header_doc;
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   folder: folder with m-files
%       > asked for if not provided
%   recursive_flag: if =1, also crawl subfolder recursively
%       Does not seem to work properly, please re-check if using
%   output_file: file to write (.txt or .html)
%       > asked for if not provided
%   req_output_mode: for internal use only (in recursive_flag case)
%   out_fid: for internal use only (in recursive_flag case)
% OUTPUTS:
%   a file with all headers. Note that the output is appended to the file,
%   thus delete the file manually prior to running this code for a new
%   version.
% MODIFICATION HISTORY:
% david.n.bresch@alumni.ethz.ch, 20030930, during WK (military repetition course at IAC, ETH)
% Lea Mueller, 20111025
% David N. Bresch, david.bresch@gmail.com, 20141107, cleanup (on flight to Dubai)
% David N. Bresch, david.bresch@gmail.com, 20160608, new e-mail
%-

fprintf('OBSOLETE\n')
return

% PARAMETERS
%
% whether we link relative to the top folder (=1) or absolute (=0)
link_relative_to_top_folder=1;


% check input arguments
% ---------------------

if ~exist('folder','var')
    folder=uigetdir(pwd, 'Select a folder to process');
    if length(folder)<1,return;end % Cancel pressed
end

if ~exist('output_file','var')
    [filename, pathname] = uiputfile('*.txt;*.html', 'Save header overview as (either .txt or .html):');
    if isequal(filename,0) || isequal(pathname,0)
        return; % Cancel pressed
    else
        output_file=fullfile(pathname,filename);
    end
end

global top_folder % to pass the top folder (see link_relative_to_top_folder)
if link_relative_to_top_folder && isempty(top_folder)
    top_folder=fileparts(output_file);
    %%top_folder = uigetdir(top_folder,'Confirm top folder:'); % confirmation
    if length(top_folder)<1,link_relative_to_top_folder=0;end % Cancel pressed
end

if ~exist('recursive_flag','var'),recursive_flag=0;end % recursive by default
if ~exist('req_output_mode','var'),req_output_mode=[1,2];end % internal use

% figure out format to write
[~,~,fE]=fileparts(output_file);
if strcmp(fE,'.txt')
    write_html_formatted=0;
else
    write_html_formatted=1;
end

% get list of files
% -----------------
if iscell(folder)
    m_files=[]; % init
    folders={}; % init
    link_relative_to_top_folder=0; % as climada modules can be elsewhere
    for folder_i=1:length(folder)
        fprintf('pre-processing %s:\n',folder{folder_i});
        add_m_files=dir(folder{folder_i});
        for m_file_i=1:length(add_m_files);folders{end+1}=folder{folder_i};end
        m_files=[m_files ; add_m_files];
    end
else
    fprintf('processing %s:\n',folder);
    folders={}; % init
    m_files=dir(folder);
    for m_file_i=1:length(m_files);folders{end+1}=folder;end
end

fprintf('\n');

% for TESTs, prints all files potentially to be processed:
% for file_i=1:length(m_files)
%     fprintf('%s %s\n',folders{file_i},m_files(file_i).name);
% end

total_line_count=0; % init

% process files
% -------------

if ~isempty(m_files)
    if ~exist('out_fid','var')
        %fprintf('appending to: %s\n',output_file);
        %out_fid=fopen(output_file,'a'); % open output file in append mode
        out_fid=fopen(output_file,'w'); % open output file overwrite
    end
    
    if length(req_output_mode)>1
        if write_html_formatted
            % Title and intro info.
            html_title='Overview of climada routines';
            %%parent_file='parent_file';
            fprintf(out_fid,'<body>\r\n');
            %%fprintf(out_fid,'<H1><FONT COLOR="FF0000"><FONT SIZE=+4>\r\n',html_title,'</FONT></FONT></H1>\r\n');
            fprintf(out_fid,'<H1><FONT COLOR="FF0000">%s</FONT></FONT></H1>\r\n',html_title);
            fprintf(out_fid,'<P>\r\n');
            fprintf(out_fid,'Use <i>Find in page</i> ... from the Edit Menu to search for any text in all help-files.<P>\r\n');
            fprintf(out_fid,'Use the <i>which</i> command in MATLAB to locate the specific function.<P>\r\n');
            fprintf(out_fid,'This page has been automatically created by <i>compile_function_header_doc</i>.<P>\r\n');
            fprintf(out_fid,'Please consult <A HREF="climada_manual.pdf">climada_manual.pdf</A> for more information.<P>\r\n');
            fprintf(out_fid,'<P>\r\n');
            %%fprintf(out_fid,'<A HREF="%s">Back to top</A>\r\n',parent_file);
            fprintf(out_fid,'<P>');
            fprintf(out_fid,'<STRONG>Last modified: </STRONG>%s<P>\r\n',datestr(now));
            fprintf(out_fid,'\r\n');
            fprintf(out_fid,'<HR>\r\n');
            fprintf(out_fid,'\r\n');
            
            fprintf(out_fid,'<A NAME="ROUTINELIST">\r\n');
            %%fprintf(out_fid,'<H1>Alphabetical List of Routines</H1></A>\r\n'
            fprintf(out_fid,'<UL>\r\n');
        else
            fprintf(out_fid,'function overview:\r\n\r\n');
        end % html
    end
    
    output_mode=1
    
    for output_mode_i=1:length(req_output_mode)
        
        output_mode=req_output_mode(output_mode_i);
        % output_mode=1: function name only
        % output_mode=2: full function header
        
        % loop over all files
        for file_i=1:50
            % for file_i=1:length(m_files)
            m_file_name=m_files(file_i).name;
            if ~m_files(file_i).isdir
                % we have a file
                [~,fN,fE]=fileparts(m_file_name);
                
                if strcmp(fE,'.m') && ~strcmp(fN,'Contents')
                    % we have a .m file
                    fprintf('processing %s ...\n',m_file_name);
                    routine_name=fN;
                    if output_mode==1
                        if write_html_formatted
                            fprintf(out_fid,'<LI><A HREF="#%s">%s</A>\r\n',routine_name,routine_name);
                        else
                            fprintf(out_fid,'%s\r\n',routine_name); % just the name
                        end
                    else
                        if write_html_formatted
                            fprintf(out_fid,'\n\n<A NAME="%s">\r\n',routine_name);
                            fprintf(out_fid,'<H2>%s</H2></A>\r\n',routine_name);
                        else
                            fprintf(out_fid,'\r\n'); % just an empty line
                        end
                        line_count=local_process_function_header(out_fid,[folders{file_i} filesep m_file_name]);
                        total_line_count=total_line_count+line_count;
                        if write_html_formatted
                            full_name=which(routine_name); % only show link to source for routines in MATLAB path
                            if ~isempty(full_name)
                                if link_relative_to_top_folder
                                    full_name=strrep(full_name,top_folder,''); % only relative to top folder
                                    full_name=strrep(full_name,filesep,'/'); % switch to for html-separator
                                    while strcmp(full_name(1),'/'),full_name=full_name(2:end);end % get rid of leading /
                                    fprintf(out_fid,'View <A HREF=%s>source</A>\r\n',full_name);
                                else
                                    full_name=strrep(full_name,filesep,'/'); % switch to for html-separator
                                    fprintf(out_fid,'View <A HREF=file:%s>source</A>\r\n',full_name);
                                end
                            else
                                fprintf(out_fid,'No source code since not in active MATLAB path\r\n');
                            end
                            fprintf(out_fid,'<A HREF="#ROUTINELIST">[List of Routines]</A>\r\n');
                            fprintf(out_fid,'<PRE>\r\n');
                        end
                    end % output_mode
                end % m-file
            else
                fprintf('*** FOLDER %s ...\n',m_file_name);
                if recursive_flag && length(m_file_name)>2
                    subfolder=char([folder filesep m_files(file_i).name]);
                    if isdir(subfolder)
                        fprintf('*** recursively processing %s:\n',subfolder);
                        compile_function_header_doc(subfolder,1,output_file,output_mode,out_fid);
                        fprintf('*** end recursion (%s)\n',subfolder);
                        out_fid=fopen(output_file,'a'); % re-open output file in append mode
                    end
                end % recursive_flag
            end % not(isdir)
            
        end % file_i
        
        if length(req_output_mode)>1
            if write_html_formatted
                fprintf(out_fid,'</UL><P>\r\n');
                fprintf(out_fid,' \r\n');
                fprintf(out_fid,'<HR>\r\n');
                fprintf(out_fid,' \r\n');
                fprintf(out_fid,'<H1>Routine Descriptions</H1>\r\n');
                fprintf(out_fid,'<PRE>\r\n');
            else
                fprintf(out_fid,'\r\nfunction details:\r\n\r\n');
            end
        end
        
    end % output_mode
    
    fclose(out_fid); % close output file
    
else
    fprintf('ERROR: no files found\n');
end

fprintf('\ntotal line count %i\n',total_line_count);

end % compile_function_header_doc




% follows local helper function
% -----------------------------


function line_count=local_process_function_header(out_fid,filename)
% function overview
% NAME:
%	local_process_function_header
% PURPOSE:
%   open m-file and add header to specified fid
% CALLING SEQUENCE:
%	local_process_function_header(out_fid,filename)
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

end % local_process_function_header