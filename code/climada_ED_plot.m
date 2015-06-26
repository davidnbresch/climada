function climada_ED_plot(EDS, percentage_of_value_flag,currency,unit_exp,logscale_check)
% visualize Annual Expected Damage per centroid as a map
% NAME:
%   climada_ED_plot
% PURPOSE:
%   plot annual expected damage
% CALLING SEQUENCE:
%   climada_ED_plot(EDS, percentage_of_value_flag)
% EXAMPLE:
%   climada_ED_plot(EDS, percentage_of_value_flag)
% INPUTS:
%   EDS, the event damage set with fields:
%       reference_year: the year the losses are references to
%       event_ID(event_i): the unique ID for each event_i
%       damage(event_i): the loss amount for event_i
%       Value: the sum of allValues used in the calculation (to e.g. express
%           losses in percentage of total Value)
%       frequency(event_i): the per occurrence event frequency for each event_i
%       orig_event_flag(event_i): whether an original event (=1) or a
%           probabilistic one (=0)
%       comment: a free comment, contains time for calculation
%       hazard: itself a structure, with:
%           filename: the filename of the hazard event set
%           comment: a free comment
%       assets: struct with lon, lat, value and filename of assets
%       damagefunctions.filename: the filename of the damage functions
%       annotation_name: a kind of default title (sometimes empty)
% OPTIONAL INPUT PARAMETERS:
%   percentage_of_value_flag: Set to 1 if you wish to plot damages as
%                             percentage of asset values
% OUTPUTS:
%   figure
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091228
% Gilles Stassen, gillesstassen@hotmail.com, 20150519 - update and cleanup
% Gilles Stassen, gillesstassen@hotmail.com, 20150528 - currency, unit_exp input args added
% Gilles Stassen, gillesstassen@hotmail.com, 20150528 - logscale_check added
% Gilles Stassen, gillesstassen@hotmail.com, 20150619 - sum damages at non-unique coords, caxis for log scale bug fix
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS'                     ,'var'),    EDS     =   [];             end
if ~exist('percentage_of_value_flag','var'),    percentage_of_value_flag=0; end
if ~exist('currency'                ,'var'),    currency=   'USD';          end
if ~exist('unit_exp'                ,'var'),    unit_exp=   0;              end
if ~exist('logscale_check'          ,'var'),    logscale_check = 1;         end

% PARAMETERS
% prompt for event damage set if not given
if isempty(EDS) % local GUI
    EDS=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(EDS, 'Select EDS for ED visualisation:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        EDS=fullfile(pathname,filename);
    end
end

% load the event damage set, if a filename has been passed
if ~isstruct(EDS)
    EDS_file=EDS;EDS=[];
    load(EDS_file);
end

% set currency unit
if unit_exp == 0
    ED = EDS.ED;
    while ED > 1000
        unit_exp    = unit_exp + 3;
        ED          = ED./1000;
    end
end

unit_exp = interp1([0 3 6 9],[0 3 6 9],unit_exp,'nearest');
switch unit_exp
    case 0
        unit_char = '';
    case 3
        unit_char = 'k';
    case 6
        unit_char = 'm';
    case 9
        unit_char = 'bn';
    case 12
        unit_char = 'tn';
    otherwise
        unit_char = sprintf('10^%i',unit_exp);
end

for EDS_i = 1: length(EDS)
    if length(EDS) > 1
        figure
        hold on
    end
    % create the figure
    scale  = max(EDS(EDS_i).assets.lon) - min(EDS(EDS_i).assets.lon);
    ax_buffer = 3; %ax_buffer = 30;
    ax_lim = [min(EDS(EDS_i).assets.lon)-scale/ax_buffer  max(EDS(EDS_i).assets.lon)+scale/ax_buffer ...
        max(min(EDS(EDS_i).assets.lat),-60)-scale/ax_buffer  min(max(EDS(EDS_i).assets.lat),80)+scale/ax_buffer];
    
    markersize = 2;
    
    % to deal with multi-valued points
    lon_lat = unique([EDS(EDS_i).assets.lon EDS(EDS_i).assets.lat],'rows');
    if length(lon_lat) ~= length(EDS(EDS_i).assets.lon)
        for i = 1:length(lon_lat)
            ndx = EDS(EDS_i).assets.lon == lon_lat(i,1) & EDS(EDS_i).assets.lat == lon_lat(i,2);
            ED_sum_centroid(i)  = sum(EDS(EDS_i).ED_at_centroid(ndx));
            val_sum_centroid(i) = sum(EDS(EDS_i).assets.Value(ndx));
        end
    else
        lon_lat = [EDS(EDS_i).assets.lon EDS(EDS_i).assets.lat];
        ED_sum_centroid     = EDS(EDS_i).ED_at_centroid;
        val_sum_centroid    = EDS(EDS_i).assets.Value;
    end
    
    % fig = climada_figuresize(height,height*scale2+0.15);
    cmap = climada_colormap('schematic');
    if percentage_of_value_flag
        nz = ED_sum_centroid>0;
        dam_TAV = (ED_sum_centroid(nz) ./ val_sum_centroid(nz)) *100;
        cbar = plotclr(lon_lat(nz,1)', lon_lat(nz,2)', dam_TAV','s',markersize,1,...
            [],[],colormap(cmap),0,logscale_check);
        
        name_str = sprintf('Expected damage (as percentage of value) for %s',num2str(EDS(EDS_i).reference_year));
    else        
        nz = ED_sum_centroid>0;
        cbar = plotclr(lon_lat(nz,1), lon_lat(nz,2), ED_sum_centroid(nz),'s',markersize,1,...
            [],[],colormap(cmap),0,logscale_check);
        if logscale_check
            caxis(log([min(ED_sum_centroid(nz)) max(ED_sum_centroid(nz))]))
        else
            caxis([min(ED_sum_centroid(nz)) max(ED_sum_centroid(nz))])
        end
        
        name_str = sprintf('Expected damage for %s:  %s %2.2f %s', ...
            num2str(EDS(EDS_i).reference_year),currency,...
            ED(EDS_i),unit_char);
        
    end
    if strfind(upper(currency),'PEOPLE')>0
        name_str = strrep(name_str,'damage','no. of casualties');
        name_str = strrep(name_str,'value','population');
        name_str = [strtok(name_str,':') ':' sprintf('  %2.2f %s %s',...
            ED(EDS_i),unit_char,currency)];
    end
    
    % set(fig,'Name',name_str)
    
    if percentage_of_value_flag
        cbar_lbl = 'Expected Damage (% of value)';
        if strfind(upper(currency),'PEOPLE')>0,cbar_lbl = 'Expected no. of casualties (% of population)'; end
        set(get(cbar,'ylabel'),'String',cbar_lbl,'fontsize',12);
    else
        cbar_lbl = 'Expected Damage (%s)';
        if strfind(upper(currency),'PEOPLE')>0,cbar_lbl = 'Expected no. of casualties'; end
        if logscale_check
            label_str = sprintf([cbar_lbl ' (exponential scale)'],currency);
        else
            label_str = sprintf(cbar_lbl,currency);
        end
        set(get(cbar,'ylabel'),'String', label_str ,'fontsize',12);
    end
    xlabel('Longitude')
    ylabel('Latitude')
    
    box on
    climada_plot_world_borders(1)
    axis(ax_lim)
    axis equal
    axis(ax_lim)
    title({name_str,strrep(EDS(EDS_i).annotation_name,'_',' ')})
end
