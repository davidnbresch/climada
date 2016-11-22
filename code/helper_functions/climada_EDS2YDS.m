function [YDS,sampling_vect]=climada_EDS2YDS(EDS,hazard,number_of_years,sampling_vect)
% climada template
% MODULE:
%   core
% NAME:
%   climada_EDS2YDS
% PURPOSE:
%   convert an event (per occurrence) damage set (EDS) into a year damage
%   set (YDS), making reference to hazard.orig_yearset (if exists). If
%   there is no yearset in hazard, generate an artificial year damage set
%   by sampling the EDS into n_years, where n_years is determined based on
%   EDS.frequency (n_years=1/min(EDS.frequency), such that the yearset
%   'spans' the period the damage is 'representative' for).
%
%   The code does perform some consistency checks, but the user is
%   ultimately repsonsible for results ;-)
%
%   Note that for TS and TR, the TC hazard event set contains
%   hazard.orig_yearset, not each sub-peril hazard event set might contain
%   its own yearset. See climada_tc_hazard_set for a good example of how
%   such an hazard.orig_yearset is constructed.
% CALLING SEQUENCE:
%   YDS=climada_EDS2YDS(EDS,hazard,number_of_years)
% EXAMPLE:
%   YDS=climada_EDS2YDS(climada_EDS_calc('',hazard),hazard)
% INPUTS:
%   EDS: an event damage set (EDS), as produced by climada_EDS_calc
%       (see there)
% OPTIONAL INPUT PARAMETERS:
%   hazard: a hazard event set (either a struct or a full filename with
%       path) which contains a yearset in hazard.orig_yearset
%       Note that for TS and TR, the TC hazard event set contains
%       hazard.orig_yearset, not each sub-peril hazard event set
%       If empty, the hazard event set is inferred from
%       EDS.annotation_name, which often contains the filename (without
%       path) of the hazard event set. If this is the case, this hazard is
%       used, if not, the function prompts for the hazard event set to use.
%       If hazard does neither contain a valid hazard struct, nor an
%       existing hazard set name, one event per year is assumed and the EDS
%       is just replicated enough times to result in number_of_years (or,
%       if number_of_years is not provided, YDS=EDS)
%   number_of_years: the target number of years the damage yearset shall
%       contain. If shorter than the yearset in the hazard set, just cut,
%       otherwise replicate until target length is reached. No advanced
%       technique, such as re-sampling, is performed (yet).
%   sampling_vect: the sampling vector, techincal, see code (can be used to
%       re-create the exact same yearset). Needs to be obtained in a first
%       call, i.e. [YDS,sampling_vect]=climada_EDS2YDS(...) and then
%       provided in subsequent calls(s) to obtain the exact same sampling
%       structure of yearset, i.e YDS=climada_EDS2YDS(...,sampling_vect)
% OUTPUTS:
%   YDS: the year damage set (YDS), a struct with same fields as EDS (such
%       as Value, ED, ...) plus yyyy and orig_year_flag. All fields same
%       content as in EDS, except:
%       yyyy(i): the year i
%       damage(i): the sum of damage for year(i). Note that for a
%           probabilitic hazard event set, there are ens_size+1 same years,
%           the first instance being the original year.
%       frequency(i): the annual frequency, =1
%       orig_year_flag(i): =1 if year i is an original year, =0 else
%       Hint: if you want to staore a YDS back into an EDS, note that there
%       are two more fields in YDS than EDS: yyyy and orig_year_flag
%   sampling_vect: the sampling vector, techincal, see code (can be used to
%       re-create the exact same yearset)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141226, initial
% David N. Bresch, david.bresch@gmail.com, 20150116, YDS fields same order as in EDS
% David N. Bresch, david.bresch@gmail.com, 20150204, automatic hazard set detection
% David N. Bresch, david.bresch@gmail.com, 20150721, EDS is proxy for output, i.e. YDS=EDS to start with
% David N. Bresch, david.bresch@gmail.com, 20151231, artifical yearsets and number_of_years implemented
% David N. Bresch, david.bresch@gmail.com, 20160307, sampling_vect as optional output
% David N. Bresch, david.bresch@gmail.com, 20160308, allow for no hazard set
% David N. Bresch, david.bresch@gmail.com, 20160420, orig_year_flag improved
%-

YDS=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('EDS','var'),return;end
if ~exist('hazard','var'),hazard=[];end
if ~exist('number_of_years','var'),number_of_years=[];end
if ~exist('sampling_vect','var'),sampling_vect=[];end

% PARAMETERS
%

if isempty(hazard) % try to infer from EDS
    hazard_file=[climada_global.data_dir filesep 'hazards' filesep strtok(EDS.annotation_name) '.mat'];
    if exist(hazard_file,'file')
        load(hazard_file)
    else
        hazard.peril_ID=EDS.peril_ID;
        fprintf('Warning: %s not found, hazard event set used, dummy yearset\n',hazard_file)
    end % if it fails, hazard remains empty
end % isempty(hazard)

% prompt for hazard if not given
if isempty(hazard) % local GUI
    hazard_set_file=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    [filename, pathname] = uigetfile(hazard_set_file, 'Select hazard event set:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_set_file=fullfile(pathname,filename);
    end
    load(hazard_set_file) % contains hazard
end

if ischar(hazard) % a filename instead of a hazard set struct passed
    hazard_set_file=hazard; clear hazard
    [fP,fN]=fileparts(hazard_set_file);
    hazard_set_file=[fP filesep fN '.mat'];
    if exist(hazard_set_file,'file')
        load(hazard_set_file) % contains hazard
    else
        hazard.peril_ID=EDS.peril_ID;
        fprintf('Warning: no %s (%s) hazard event set used, dummy yearset\n',hazard.peril_ID,hazard_set_file)
    end
end

if ~isfield(hazard,'orig_yearset')
    fprintf('Warning: %s hazard event set does not contain orig_yearset\n',hazard.peril_ID)
    fprintf('  Note that for TS and TR, the TC hazard event set contains\n')
    fprintf('  hazard.orig_yearset, not each sub-peril hazard event set\n')
    
    % artificially generate a generic yearset (by just sampling the event damage set)
    % ---------------------------------------
    
    YDS=EDS; % essentially a copy, reset some fields:
    YDS.event_ID=[]; % to indicate not by event any more
    YDS.frequency=[]; % init, see below
    YDS.orig_event_flag=[]; % to indicate not by event any more
    
    n_years=ceil(1/min(EDS.frequency));
    ens_size=0;
    
    % init new fields
    YDS.damage=zeros(1,n_years);
    YDS.yyyy=1:n_years;
    YDS.orig_year_flag=zeros(1,n_years);
    
    nonzero_pos=find(EDS.damage>(10*eps));
    if ~isempty(nonzero_pos)
        fprintf('  -> generating artificial %s yearset\n',hazard.peril_ID)
        nonzero_damage=EDS.damage(nonzero_pos);
        % randomly populate years
        sorted_damage=sort(nonzero_damage);
        % sample from the sorted damage
        if isempty(sampling_vect),sampling_vect=ceil(rand(1,n_years)*length(nonzero_pos));end
        YDS.damage=sorted_damage(sampling_vect);
        %adjust for sampling error (i.e. rand will not pick each damage once...)
        YDS_ED=sum(YDS.damage)/n_years;
        EDS_ED=EDS.frequency*EDS.damage';
        YDS.damage=YDS.damage/YDS_ED*EDS_ED;
    end % ~isempty(nonzero_pos)
        
else
    
    % here starts the proper generation of the yearset
    % ------------------------------------------------
    
    % figure the probabilistic ensemble size (=0 if only original events)
    n_years = length(hazard.orig_yearset);
    ens_size=(hazard.event_count/hazard.orig_event_count)-1;
    orig_event_mismatch_count=0; % init
    prob_event_mismatch_count=0; % init
    
    % consistency check
    if abs(length(EDS.damage)-hazard.event_count)>eps
        fprintf('Error: EDS and hazard events do not match, aborted\n');
        return
    end
    
    YDS=EDS; % essentially a copy, reset some fields:
    YDS.event_ID=[]; % to indicate not by event any more
    YDS.damage=[]; % init, see below
    YDS.frequency=[]; % init, see below
    YDS.orig_event_flag=[]; % to indicate not by event any more
    % init new fields
    YDS.yyyy=[];
    YDS.orig_year_flag=[];
    
    % template for-loop with waitbar or progress to stdout
    t0       = clock;
    msgstr   = sprintf('processing %i years',n_years);
    mod_step = 10; % first time estimate after 10 years
    
    if climada_global.waitbar
        fprintf('%s (updating waitbar with estimation of time remaining every 10th year)\n',msgstr);
        h        = waitbar(0,msgstr);
        set(h,'Name','Yearset');
    else
        fprintf('%s (waitbar suppressed)\n',msgstr);
        format_str='%s';
    end
    
    next_damage_year=1;
    for year_i=1:n_years
        
        for ens_i=0:ens_size % note: ens_i=0 is orig year
            YDS.damage(next_damage_year)=0; % init
            YDS.yyyy(next_damage_year)  =hazard.orig_yearset(year_i).yyyy;
            for event_i=1:hazard.orig_yearset(year_i).event_count
                damage_event_i=hazard.orig_yearset(year_i).event_index(event_i)+ens_i;
                YDS.damage(next_damage_year)=YDS.damage(next_damage_year)+EDS.damage(damage_event_i);
                if EDS.orig_event_flag(damage_event_i)
                    YDS.orig_year_flag(next_damage_year)=1;
                else
                    YDS.orig_year_flag(next_damage_year)=0;
                end
                if ens_i==0 && EDS.orig_event_flag(damage_event_i)==0
                    orig_event_mismatch_count=orig_event_mismatch_count+1;
                elseif ens_i>0 && EDS.orig_event_flag(damage_event_i)==1
                    prob_event_mismatch_count=prob_event_mismatch_count+1;
                end
            end % event_i
            next_damage_year=next_damage_year+1;
        end % ens_i
        
        % the progress management
        if mod(year_i,mod_step)==0
            mod_step          = 100;
            t_elapsed_year   = etime(clock,t0)/year_i;
            events_remaining  = n_years-year_i;
            t_projected_sec   = t_elapsed_year*events_remaining;
            if t_projected_sec<60
                msgstr = sprintf('est. %3.0f sec left (%i/%i events)',t_projected_sec,   year_i,n_years);
            else
                msgstr = sprintf('est. %3.1f min left (%i/%i events)',t_projected_sec/60,year_i,n_years);
            end
            if climada_global.waitbar
                waitbar(year_i/n_years,h,msgstr); % update waitbar
            else
                fprintf(format_str,msgstr); % write progress to stdout
                format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
            end
        end
        
    end % year_i
    if climada_global.waitbar
        close(h) % dispose waitbar
    else
        fprintf(format_str,''); % move carriage to begin of line
    end
    t_elapsed = etime(clock,t0);
    msgstr    = sprintf('processing yearset (%i original years, %i prob years each) took %3.2f sec',n_years,ens_size,t_elapsed);
    fprintf('%s\n',msgstr);
    
    if orig_event_mismatch_count>0
        fprintf('Warning: there seem to be %i orig_event mismatches (YDS.orig_year_flag likely useless)\n',orig_event_mismatch_count);
    end
    if prob_event_mismatch_count>0
        fprintf('Warning: there seem to be %i prob_event mismatches (YDS.orig_year_flag possibly useless)\n',prob_event_mismatch_count);
    end
    
end % ~isfield(hazard,'orig_yearset')

YDS.frequency=YDS.damage*0+1/length(YDS.damage); % each year occurrs once...

% final check whether we picked up all damage
YDS_ED=sum(YDS.damage)/n_years/(ens_size+1);
if abs(YDS_ED-EDS.ED)/EDS.ED>0.0001 % not zero, as we deal with large numbers
    fprintf('Warning: expected damage mismatch (EDS: %g, YDS: %g)\n',EDS.ED,YDS_ED);
end

% follows a hands-on way to obtain target length yearsets (one could do
% better, i.e. re-sample - but might want to consider multi-year patterns)

if ~isempty(number_of_years)
    if length(YDS.damage)<number_of_years
        n_replicas=ceil(number_of_years/length(YDS.damage));
        fprintf('Note: %s yearset replicated %i times (orig: %i years)\n',...
            YDS.peril_ID,n_replicas,length(YDS.damage))
        YDS.damage=repmat(YDS.damage,1,n_replicas);
        YDS.frequency=repmat(YDS.frequency,1,n_replicas);
        YDS.yyyy=repmat(YDS.yyyy,1,n_replicas);
        %YDS.orig_year_flag=repmat(YDS.orig_year_flag,1,n_replicas); %until 20160420
        YDS.orig_year_flag=[YDS.orig_year_flag zeros(1,length(YDS.yyyy)-length(YDS.orig_year_flag))];
        issue_warning=0; % to suppress warning when cutting to exactly number_of_years below
        YDS.comment=[YDS.comment sprintf(' %i times replicated',n_replicas)];
    else
        issue_warning=1;
    end % length(YDS.damage)<number_of_years
    
    if length(YDS.damage)>number_of_years
        if issue_warning
            fprintf('Warning: length of (original) %s yearset concatenated from %i to %i years\n',...
                YDS.peril_ID,length(YDS.damage),number_of_years)
        end
        YDS.damage=YDS.damage(1:number_of_years);
        YDS.frequency=YDS.frequency(1:number_of_years);
        YDS.yyyy=YDS.yyyy(1:number_of_years);
        YDS.orig_year_flag=YDS.orig_year_flag(1:number_of_years);
        YDS.comment=[YDS.comment sprintf(' concatenated to %i years',number_of_years)];
    end % length(YDS.damage)>number_of_years
            
end % ~isempty(number_of_years)

return
