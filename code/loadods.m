% LOADODS: Loads data from an open document spreadsheet (ods) file into a cell
%          array
%
% SYNTAX: data = loadods(filename,options)
%
% INPUTS:
%   filename:   String representing the path and name of the ods file
%   options:    Structural variable containing optional arguments
%
% OUTPUTS:
%   data:       MxN cell array containing data from the spreadsheet
%
% OPTIONS:
%   sheet_name: Name of a specific sheet to load [defaults to the first sheet]
%   blank:      Value to store for blank spreadsheet cells [NaN]
%
% VERSION: 1.0
%
% Copyright (C) 2007 Alex Marten - alex.marten@gmail.com
% see license at the bottom of this file
%-

function data = loadods(filename,options)

	% Set default options
	if nargin<2, options = []; end
	if ~isfield(options,'sheet_name'), options.sheet_name = []; end
	if ~isfield(options,'blank'), options.blank = nan; end

	% Check for the existence of the ods file
	if exist(filename)~=2
		error('The file does not exist');
	end
	
	% Create a temporary directory to unzip the ods file into
	if ~mkdir(tempdir,filename)
		error('Permission error');
	end
	dir_temp = strcat(tempdir,filename);
	
	% Unzip the contents of the ods file
	unzip(filename,dir_temp);
	
	% Load the XML file containing the spreadsheet data
	try
 		XMLfile = xmlread(strcat(dir_temp,'/content.xml'));
	catch
	   error('Unable to read the spreadsheet data');
	end
	
	% Parse down to the <office:spreadsheet> node
	nodes = XMLfile.getChildNodes;
	node = nodes.item(0);
	nodes = node.getChildNodes;
	node = nodes.item(3);
	nodes = node.getChildNodes;
	node = nodes.item(0);
	nodes = node.getChildNodes;

	% Find the requested sheet by name or default to the first sheet
	if ~isempty(options.sheet_name)
		numSheets = nodes.getLength;
		for count = 1:numSheets
			sheet = nodes.item(count-1);
			if strcmp(get_attribute(sheet,'table:name'),options.sheet_name)
				break
			end
		end
	else
		sheet = nodes.item(0);
	end

	% Get the number of columns 
	nodes = sheet.getChildNodes;
	num_nodes = nodes.getLength;
	num_cols = 0;
	for count = 1:num_nodes
		node = nodes.item(count-1);
		if strcmp(char(node.getNodeName),'table:table-column')
			temp = get_attribute(node,'table:number-columns-repeated');
			if ~isempty(temp)
				num_cols = num_cols+str2num(char(num_cols));
			end
		elseif strcmp(char(node.getNodeName),'table:table-row')
			count = count-2;
			break
		end
	end
	
	% Get the number of rows
	num_rows = num_nodes-count-1;
	
	% Initialize memory for the data
	data = cell(num_rows,num_cols);

	% Extract the data for the sheet
	for row_num = 1:num_rows
		row = nodes.item(count+row_num);
		cols = row.getChildNodes;
		col_num = 0;
		num_items = cols.getLength-1;
		for item_num = 0:num_items
			col = cols.item(item_num);
			num_repeated = get_attribute(col,'table:number-columns-repeated');
			num_repeated = str2num(char(num_repeated));
			value_type = get_attribute(col,'office:value-type');
			if strcmp(value_type,'string')
				temp = col.getChildNodes;
				temp = temp.item(0);
				temp = temp.getChildNodes;
				temp = temp.item(0);
				if any(strcmp(methods(temp),'getData'))
					value = char(temp.getData);
				else
					value = options.blank;
				end
			elseif strcmp(value_type,'float')
				value = str2num(get_attribute(col,'office:value'));
			else
				value = options.blank;
			end
			if ~isempty(num_repeated)
				for i = 1:num_repeated
					col_num = col_num+1;
				 	data{row_num,col_num} = value;
				end
			else
				col_num = col_num+1;
				data{row_num,col_num} = value;
			end
		end
	end

	% Remove the temporary files
	if ~rmdir(dir_temp,'s')
		warning('Temporary files could not be removed');
	end		

end



% Returns the value of the attribute_name in node
function attribute = get_attribute(node,attribute_name)
	attribute = [];
	if node.hasAttributes
		attributes = node.getAttributes;
		num_attributes = attributes.getLength;
		for count = 1:num_attributes
			item = attributes.item(count-1);
		 	if strcmp(char(item.getName),attribute_name)
				attribute = char(item.getValue);
			end
		end
	end	
end

% Copyright (c) 2007, Alex L. Marten
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.