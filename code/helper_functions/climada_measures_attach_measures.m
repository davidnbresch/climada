function measures = climada_measures_attach_measures(measures1,measures2,silent_mode)
% climada measures attach another measures
% MODULE:
%   core/helper_functions
% NAME:
%   climada_measures_impact_attach_measures_impact
% PURPOSE:
%   Attach/enlarge measures with another measures, so that the new measures
%   structure contains all measures (.name, .cost.,
%   .hazard_intensity_impact_a, ...)
%
% CALLING SEQUENCE:
%   measures = climada_measures_attach_measures(measures1,measures2,silent_mode)
% EXAMPLE:
%   measures = climada_measures_attach_measures((measures1,measures2,silent_mode)
% INPUTS:
%   measures1: a climada measures, as read from climada_measures_read;
%   measures2: a climada measures, as read from climada_measures_read;
% OPTIONAL INPUT PARAMETERS:
%   silent_mode: default is 0, set to 1, if you do not want command line output
% OUTPUTS:
%   measures: the measures containing all information
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151217, init 
%-

measures = []; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures1','var'),return;end
if ~exist('measures2','var'),return;end
if ~exist('silent_mode','var'), silent_mode = ''; end


% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given
if isempty(silent_mode), silent_mode = 0; end 

% init output
measures = measures1; 

% get number of measures in each of the two structures
n_measures1 = numel(measures1.name);
n_measures2 = numel(measures2.name);

% get all fieldnames
fieldname1_list = fieldnames(measures1);
fieldname2_list = fieldnames(measures2);
fieldname_list = unique({fieldname1_list{:} fieldname2_list{:}},'stable');

% enlarge/attach the fieldnames if they exist in both measures
for f_i = 1:numel(fieldname_list)
    if isfield(measures1,fieldname_list{f_i}) && isfield(measures2,fieldname_list{f_i})
        if size(getfield(measures1,fieldname_list{f_i}),1) == n_measures1 && ...
                size(getfield(measures2,fieldname_list{f_i}),1) == n_measures2
            if ~silent_mode, fprintf('Attach field %s vertically \n',fieldname_list{f_i}); end
            value = [getfield(measures1,fieldname_list{f_i}); getfield(measures2,fieldname_list{f_i})];
            measures = setfield(measures,fieldname_list{f_i},value);
            
        elseif size(getfield(measures1,fieldname_list{f_i}),2) == n_measures1 && ...
                size(getfield(measures2,fieldname_list{f_i}),2) == n_measures2
            if ~silent_mode, fprintf('Attach field %s horizontally \n',fieldname_list{f_i}); end
            value = [getfield(measures1,fieldname_list{f_i}) getfield(measures2,fieldname_list{f_i})];
            measures = setfield(measures,fieldname_list{f_i},value);
        end
        
    %elseif isfield(measures1,fieldname_list{f_i}) && ~isfield(measures1,fieldname_list{f_i}) 
    %    value = [getfield(measures1,fieldname_list{f_i}); getfield(measures2,fieldname_list{f_i})];
    %    measures = setfield(measures,fieldname_list{f_i},value);
    end
    
end



