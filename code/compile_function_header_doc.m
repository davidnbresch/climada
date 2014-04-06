function compile_function_header_doc(folder,recursive_flag,output_file,req_output_mode,out_fid)
% wk02 sounding
% NAME:
%	compile_function_header_doc
% PURPOSE:
%   crawl through all .m files in a given folder and compile the headers
%   into one single text (.txt) or html (.html) document. The html document
%   starts with a header listing all routine names, followed by the full
%   header listings, each with a link to the full source code.
%
%   see DEBUG_mode in PARAMETERS in code for debug mode
% CALLING SEQUENCE:
%	compile_function_header_doc(folder,recursive_flag,output_file);
% EXAMPLE:
%   compile_function_header_doc;
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   folder: folder with m-files
%       > asked for if not provided
%   recursive_flag: if =1, also crawl subfolder recursively
%   output_file: file to write (.txt or .html)
%       > asked for if not provided
%   req_output_mode: for internal use only (in recursive_flag case)
%   out_fid: for internal use only (in recursive_flag case)
% OUTPUTS:
%   a file with all headers. Note that the output is appended to the file,
%   thus delete the file manually prior to running this code for a new
%   version.
% MODIFICATION HISTORY:
% David N. Bresch, david.n.bresch@alumni.ethz.ch, 30.9.2003
% Lea Mueller, 20111025
%-

% PARAMETERS
%
% whether we link relative to the top folder (=1) or absolute (=0)
link_relative_to_top_folder=1;
%
% set =1 for DEBUG mode (=0 for normal operation)
DEBUG_mode=0; % default=0
%
if DEBUG_mode
    % hard-wired for DEBUG purposes only:
    % here, one can clearly see that this code has been written in a
    % military repetition course in 2002 (wk02)by srzdnb...
    if ~exist('folder','dir'),folder='O:\wk02\MATLAB\code';end % DEBUGGING, default: comment this line
    output_file='O:\wk02\MATLAB\function_overview.txt'; % DEBUGGING, default: comment this line
    recursive_flag=1; % DEBUGGING, default: comment this line
end

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
    [top_folder,fN]=fileparts(output_file);
    %%top_folder = uigetdir(top_folder,'Confirm top folder:'); % confirmation
    if length(top_folder)<1,link_relative_to_top_folder=0;end % Cancel pressed
end

if ~exist('recursive_flag','var'),recursive_flag=0;end % recursive by default
if ~exist('req_output_mode','var'),req_output_mode=[1,2];end % internal use

% figure out format to write
[fP,fN,fE]=fileparts(output_file);
if strcmp(fE,'.txt')
    write_html_formatted=0;
else
    write_html_formatted=1;
end

% get list of files
% -----------------
fprintf('processing %s:\n',folder);
m_files=dir(folder);

total_line_count=0; % init

% process files
% -------------

if length(m_files)>0
    if ~exist('out_fid','var')
        if DEBUG_mode
            out_fid=1; % for DEBUGGING to stdout
        else
            fprintf('appending to: %s\n',output_file);
            out_fid=fopen(output_file,'a'); % open output file in append mode
        end
    end

    if length(req_output_mode)>1
        if write_html_formatted
            % Title and intro info.
            html_title='MATLAB routines';
            %%parent_file='parent_file';
            fprintf(out_fid,'<body>\r\n');
            %%fprintf(out_fid,'<H1><FONT COLOR="FF0000"><FONT SIZE=+4>\r\n',html_title,'</FONT></FONT></H1>\r\n');
            fprintf(out_fid,'<H1><FONT COLOR="FF0000">%s</FONT></FONT></H1>\r\n',html_title);
            fprintf(out_fid,'<P>\r\n');
            fprintf(out_fid,'Use Find in page ... from the Edit Menu to search for any text in all help-files\r\n');
            fprintf(out_fid,'This page has been automatically created by compile_function_header_doc<P>\r\n');
            fprintf(out_fid,'Ask <A HREF="mailto:david.n.bresch@alumni.ethz.ch">David N. Bresch</A> if you want to add your own code.<P>\r\n');
            fprintf(out_fid,'<P>');
            fprintf(out_fid,'To save an editable copy of a program, press the right mouse button on the view source-Link and select Save Link as... form the pop-up menu <P>\r\n');
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
    
    for output_mode_i=1:length(req_output_mode)
                
        output_mode=req_output_mode(output_mode_i);
        % output_mode=1: function name only
        % output_mode=2: full function header

        % loop over all files
        for file_i=1:length(m_files)
            m_file_name=m_files(file_i).name;
            if not(m_files(file_i).isdir)
                % we have a file
                if strcmp(m_file_name(end-1:end),'.m')
                    % we have a .m file
                    fprintf('processing %s ...\n',m_file_name);
                    routine_name=m_file_name(1:end-2);
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
                        line_count=local_process_function_header(out_fid,[folder filesep m_file_name]);
                        total_line_count=total_line_count+line_count;
                        if write_html_formatted
                            full_name=which(routine_name); % only show link to source for routines in MATLAB path
                            if length(full_name)>0
                                if link_relative_to_top_folder
                                    full_name=strrep(full_name,top_folder,''); % only relative to top folder
                                    full_name=strrep(full_name,filesep,'/'); % switch to for html-separator
                                    while strcmp(full_name(1),'/'),full_name=full_name(2:end);end % get rid of leading /
                                    fprintf(out_fid,'View <A HREF=%s>source</A>\r\n',full_name);
                                else
                                    full_name=strrep(full_name,filesep,'/'); % switch to for html-separator
                                    fprintf(out_fid,'View <A HREF=file:/%s>source</A>\r\n',full_name);
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
                if recursive_flag && length(m_file_name)>2
                    subfolder=[folder filesep m_files(file_i).name];
                    fprintf('*** recursively processing %s:\n',subfolder);
                    compile_function_header_doc(subfolder,1,output_file,output_mode,out_fid);
                    fprintf('*** end recursion (%s)\n',subfolder);
                    if not(DEBUG_mode),out_fid=fopen(output_file,'a');end % re-open output file in append mode
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
    
    if not(DEBUG_mode),fclose(out_fid);end % close output file
    
else
    fprintf('ERROR: no files found\n');
end

fprintf('\ntotal line count %i\n',total_line_count);

return; % compile_function_header_doc


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

return; % local_process_function_header

