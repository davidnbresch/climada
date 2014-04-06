function climada_waterfall_graph_animation(EDS1, EDS2, EDS3)
% waterfall figure, expected damage for specified return period for 
% - today,
% - increase from economic growth, 
% - increase from high climate change, total expected damage 2030
% for the three EDS quoted above
% NAME:
%   climada_waterfall_graph_animation
% PURPOSE:
%   plot expected damage for specific return period
% CALLING SEQUENCE:
%   climada_waterfall_graph_animation(EDS1, EDS2, EDS3)
% EXAMPLE:
%   climada_waterfall_graph_animation
% INPUTS:
%   none
% OPTIONAL INPUT PARAMETERS:
%   EDS:            three event damage sets 
%                   - today
%                   - economic growth
%                   - cc combined with economic growth, future       
% OUTPUTS:
%   waterfall graph animation
% MODIFICATION HISTORY:
% Lea Mueller, 20110622
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
%-

global climada_global
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('EDS1'           ,'var'), EDS1 = []; end
if ~exist('EDS2'           ,'var'), EDS2 = []; end
if ~exist('EDS3'           ,'var'), EDS3 = []; end


%---------------------------------------------
%% load EVENT DAMAGE SET if not given
%---------------------------------------------
% prompt for EDS if not given
if isempty(EDS1) % local GUI
    EDS                  = [climada_global.data_dir filesep 'results' filesep '*.mat'];
    EDS_default          = [climada_global.data_dir filesep 'results' filesep 'select exactly three EDS .mat'];
    [filename, pathname] = uigetfile(EDS, 'Select EDS:',EDS_default,'MultiSelect','on');
    if isequal(filename,0) || isequal(pathname,0)
        %return; % cancel
        EDS1   = climada_EDS_stats(climada_EDS_calc, 0); 
        if ischar(EDS1); fig = []; return; end
        climada_EDS_save(EDS1,'EDS_today')
        
        EDS2   = climada_EDS_stats(climada_EDS_calc, 0); 
        if ischar(EDS2); fig = []; return; end
        climada_EDS_save(EDS2,'EDS_future_eco')
        
        EDS3   = climada_EDS_stats(climada_EDS_calc, 0); 
        if ischar(EDS3); fig = []; return; end
        climada_EDS_save(EDS3,'EDS_future_cc')
        
        EDS    = struct([]);
        EDS    = EDS1;
        EDS(2) = EDS2;
        EDS(3) = EDS3;
    end
else
    % check if statistics are given, if not add statistics
    if ~isfield(EDS1,'damage_sort')
        EDS1 = climada_EDS_stats(EDS1, 0);
    end
    if ~isfield(EDS2,'damage_sort')
        EDS2   = climada_EDS_stats(EDS2, 0);
    end
    if ~isfield(EDS3,'damage_sort')
        EDS3 = climada_EDS_stats(EDS3, 0);
    end
    EDS    = struct([]);
    EDS    = EDS1;
    EDS(2) = EDS2;
    EDS(3) = EDS3;
end
% load the EDS, if a filename has been passed
if ~isstruct(EDS1)
    if iscell(filename)
        for i = 1:length(filename);
            % rename EDS to EDS1
            vars = whos('-file', fullfile(pathname,filename{i}));
            load(fullfile(pathname,filename{i}))
            EDS1 = eval(vars.name);
            % add statistics if not yet there
            if ~isfield(EDS1,'damage_sort')
                EDS1 = climada_EDS_stats(EDS1, 0);
            end
            clear (vars.name)
            %temporarily save in EDS
            EDS_(i) = EDS1;
        end
        %rename to EDS
        EDS = EDS_;
        clear EDS_ 
    else
        load(fullfile(pathname,filename))
    end
end

% find common return periods
common_R = intersect(EDS(1).R_fit, EDS(2).R_fit);
common_R = intersect(EDS(3).R_fit, common_R);

% go through all common return periods
for R_i = common_R
    damage = [];
    for EDS_i = 1:length(EDS)
        r_index           = R_i == EDS(EDS_i).R_fit;
        damage(EDS_i)     = EDS(EDS_i).damage_fit(r_index);
        % identification of EDS_i
        hazard_name       = strtok(EDS(EDS_i).hazard.comment,',');
        hazard_name       = horzcat(hazard_name, ' ', int2str(EDS(EDS_i).reference_year));
        [fP, assets_name] = fileparts(EDS(EDS_i).assets.filename);
        str               = sprintf('%s | %s',assets_name, hazard_name);
        str               = strrep(str,'_',' '); % since title is LaTEX format
        str               = strrep(str,'|','\otimes'); % LaTEX format
        legend_str{EDS_i} = str;    
    end % EDS_i
    damage_r(r_index,:) = damage; 
end % all return periods

% rename
damage = [];
damage = damage_r;

% order damage so that: today, eco, cc (including eco)
[damage_max index] = sort(damage(end,:));
damage             = damage(:,index);
damage(:,4)        = damage(:,3);

% scale to 10^3 or 10^6
digits = log10(max(damage_max));
if digits>3 & digits<6
    damage = damage*10^-3;
    dig  = 3;
elseif digits>6
    damage = damage*10^-6;
    dig = 6;
else
    dig = 0;
end


%-----------
%% figure
%-----------
fig = climada_figuresize(0.55,0.8);
% color_     = [185 211 238;...
%                 0 104 139;...
%               154 205  50;...
%               154 205  50]/255;
% yellow - red color scheme
color_     = [255 215   0 ;...   %today
              255 127   0 ;...   %eco 
              238  64   0 ;...   %clim
              205   0   0 ;...   %total risk
              120 120 120]/256;  %dotted line]/255;
color_(1:4,:) = brighten(color_(1:4,:),0.3);           
stretch    = 0.2;
damage_count = size(damage,2);
damage       = [zeros(length(common_R),1) damage]; 


print_reply = '';

% % legend, but too slow for animation
% l(1) = area(7,0,'facecolor',[  0 104 139]/255,'edgecolor','none');
% hold on
% l(2) = area(8,0,'facecolor',[154 205  50]/255,'edgecolor','none');
% l(3) = area(9,0,'facecolor',[139 131 134]/255,'edgecolor','none');
% L = legend(legend_str(index),'location','NorthOutside');
% set(L,'FontSize',10)

xlim([0.5 5.5])
ylim([0   max(max(damage))*1.25])
set(gca,'xtick',[1:1:4],'xticklabel',{'today','eco','cc','future'},'layer','top')
ylabel(['Damage amount \cdot 10^' int2str(dig) ])
        

while ~strcmp(print_reply,'x')

    for r_index = 1:length(common_R)
        hold on
        g(1) = area([damage_count-stretch damage_count+stretch], damage(r_index,4)*ones(1,2),'facecolor',[139 131 134]/255,'edgecolor','none');
        for i = 1:size(damage,2)-2
            h(i,1) = patch( [i-stretch i+stretch i+stretch i-stretch],...
                            [damage(r_index,i) damage(r_index,i) damage(r_index,i+1) damage(r_index,i+1)],...
                            color_(i,:),'edgecolor','none');
            h(i,2) = plot([i-stretch 4.7],[damage(r_index,i+1) damage(r_index,i+1)],':','color',[81 81 81]/255);
        end
        
        % round damage numers for displaying on the graph
        N            = -abs(floor(log10(max(damage(r_index,:))))-2);
        damage_disp(1) = round(  damage(r_index,2)                  *10^N)/10^N;
        damage_disp(2) = round( (damage(r_index,3)-damage(r_index,2)) *10^N)/10^N;
        damage_disp(3) = round( (damage(r_index,4)-damage(r_index,3)) *10^N)/10^N;
        damage_disp(4) = round(  damage(r_index,4)                  *10^N)/10^N;


        g(2) = text(1, damage(r_index,2),   int2str(damage_disp(1)), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom');
        g(3) = text(2, damage(r_index,2) + (damage(r_index,3)-damage(r_index,2))/2, ...
                                          int2str(damage_disp(2)), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle');
        g(4) = text(3, damage(r_index,3) + (damage(r_index,4)-damage(r_index,3))/2, ...
                                          int2str(damage_disp(3)), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','middle');
        g(5) = text(4, damage(r_index,4),   int2str(damage_disp(4)), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom');

        g(6) = climada_arrow([4.7 damage(r_index,2)], [4.7 damage(r_index,4)], 40, 10, 30,'width',10, 'BaseAngle',60, 'EdgeColor','w', 'FaceColor',[139 131 134]/255);
        ellipse_h = max(damage(r_index,:))*1.25/20;
        g(7) = climada_ellipse(0.4, ellipse_h, 0, 4.7, damage(r_index,2)+(damage(r_index,4)-damage(r_index,2))/2*0.8, [185 211 238]/255);
        g(8) = text   (4.7, damage(r_index,2)+(damage(r_index,4)-damage(r_index,2))/2*0.8, ...
                ['+ ' int2str((damage(r_index,4)-damage(r_index,2))/damage(r_index,2)*100) '%'],...
                 'color','k','HorizontalAlignment','center');
             
        title(['Return period = ' int2str(common_R(r_index)) ' years'])
        %xlabel(['Return period = ' int2str(common_R(r_index)) ' years'])
        
        %pause
        print_reply = input('to print press p otherwise enter. to end press x. [p, enter, x]: ', 's');
        if strcmp(print_reply,'p')
            %filename = ['\results\mozambique\V\waterfall_' int2str(EDS.gumbel_R(r_index)) '_' centroids.names{centroid} '.pdf'];   
            filename = [filesep 'results' filesep 'waterfall_graph_' int2str(common_R(r_index)) '_years_animation.pdf'];            
            print(fig,'-dpdf',[climada_global.data_dir filename])
            fprintf('figure saved in %s \n', filename)
        end
        if strcmp(print_reply,'x')
            close
            return
        end
        delete(h)
        delete(g)
    end % r_index
end % graphic loop    

return




