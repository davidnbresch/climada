function [country_name,country_ISO3,shape_index] = climada_country_name(input_name)
% check country name ISO3
% MODULE:
%   core climada
% NAME:
%   climada_country_name
% PURPOSE:
%   check for valid country name or valid ISO3 country code and return both
%   (hence it can also be used to get the respective code or full name)
% CALLING SEQUENCE:
%   [country_name,country_ISO3,shape_index] = climada_country_name(input_name)
% EXAMPLE:
% 	[country_name,country_ISO3,shape_index] = climada_country_name('Switzerland')
%   climada_country_name % to return a list of all valid country names (and their ISO3 codes)
% INPUTS:
%   input_name: name of country (string) or an ISO3 code (needs to be uppercase, like 'CHE')
%       if ='ALL' or empty, write all country names and the corresponding
%       ISO3 codes to stdout and return the full name, ISO and index list
%       if ='all', as 'ALL', but do not write the list to stdout
%       if ='Single' or 'Multiple', select single country or multiple
%       countries from a list dialog
% OUTPUTS:
%   country_name: country name(s), empty string if no match
%   country_ISO3: country ISO3 code(s) (like 'CHE'), empty if no match
%   shape_index: index(s) of the corresponding shapes (of the file as in climada_global.map_border_file
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20141016
% David N. Bresch, david.bresch@gmail.com, 20141209, ISO3 country code added
% David N. Bresch, david.bresch@gmail.com, 20141211, switched to admin0 instead of world*.gen
%-

country_name='';
country_ISO3='';
shape_index=[];

global climada_global
if ~climada_init_vars,return;end % init/import global variables
if ~exist('input_name','var'),input_name = ''; end


% prepare country list (based on the climada core admin0 shapes)
shapes=climada_shaperead(climada_global.map_border_file);
if isempty(shapes)
    fprintf('ERROR: no shape file found (%s)\n',climada_global.map_border_file)
    return
end

   
input_name = char(input_name); % as to create filenames etc., needs to be char

if isempty(input_name),input_name='ALL';end

if strcmpi(input_name,'ALL') 
    % if 'all' or 'All', show all valid names and ISO3
    
    country_NAMEs={};country_ISO3s={}; % init
    for shape_i=1:length(shapes)
        country_NAMEs{shape_i}=shapes(shape_i).NAME;
        country_ISO3s{shape_i}=shapes(shape_i).ADM0_A3;
    end % shape_i
    
    [~,sort_index] = sort(country_NAMEs); % sort alphabetically
    
    if strcmp(input_name,'ALL') % to stdout only if UPPERCASE
        for shape_i=1:length(sort_index)
            eff_shape_i=sort_index(shape_i);
            fprintf('%s|%s (shape %i)\n',country_NAMEs{eff_shape_i},country_ISO3s{eff_shape_i},eff_shape_i);
        end % shape_i
    end
    
    country_name=country_NAMEs;
    country_ISO3=country_ISO3s;
    shape_index =1:length(country_NAMEs);
    return
    
elseif strcmpi(input_name,'SINGLE') || strcmpi(input_name,'MULTIPLE') 
    % prompt country (one or many)
    
    country_NAMEs={};country_ISO3s={}; % init
    for shape_i=1:length(shapes)
        country_NAMEs{shape_i}=shapes(shape_i).NAME;
        country_ISO3s{shape_i}=shapes(shape_i).ADM0_A3;
    end % shape_i
    
    [liststr,sort_index] = sort(country_NAMEs); % sort alphabetically
    [selection,ok] = listdlg('PromptString','Select countries (or one):',...
        'ListString',liststr,'SelectionMode',input_name);
    pause(0.1)
    if ~isempty(selection)
        country_name = country_NAMEs(sort_index(selection));
        country_ISO3 = country_ISO3s(sort_index(selection));
        shape_index  = sort_index(selection);
    else
        fprintf('NOTE: no country chosen, aborted\n')
        return
    end
    
else
    
    country_name_i=[];
    country_ISO3_i=[];
    for shape_i = 1:length(shapes)
        if strcmp(shapes(shape_i).NAME,input_name),country_name_i=shape_i;end
        if strcmp(shapes(shape_i).ADM0_A3,input_name),country_ISO3_i=shape_i;end
    end % shape_i
    
    
    if isempty(country_name_i),country_name_i=country_ISO3_i;end
    if isempty(country_name_i),return;end % neither valid country nor ISO3
    
    shape_index=country_name_i;
    
    country_name=shapes(shape_index).NAME;
    country_ISO3=shapes(shape_index).ADM0_A3;
    
end


% old version, until 20141211
%
% borders = climada_load_world_borders;
% if isempty(borders), return, end
%
% country_pos=strcmp(country_name, borders.name); % check for name
% if ~(sum(country_pos) == 1) % check for full name
%     country_pos=strcmp(country_name, borders.ISO3); % check for ISO3
%     if ~(sum(country_pos) == 1) % check for full name
%         cprintf([1,0.5,0],'%s is not a valid country name. Unable to proceed.\n', country_name)
%         country_name = '';
%         country_ISO3 = '';
%         return
%     end
% end
%
% % valid country_name, find ISO3
% country_name=borders.name{country_pos};
% country_ISO3=borders.ISO3{country_pos};

end