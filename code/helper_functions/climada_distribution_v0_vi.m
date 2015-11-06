function [mu, sigma, A] = climada_distribution_v0_vi(tc_track, output_unit, check_visible, check_printplot)
% distribution of initial wind speed v0 and change in in wind speed vi
% tc_track has to be recorded at 6h intervals with wind speed in kn
% NAME:
%   climada_distribution_v0_vi
% PURPOSE:
%   fit normal distribution to inital wind speed from tc tracks and 
%   fit normal distribution to 
%   previous:   .....
%   next:       ....
% CALLING SEQUENCE:
%   [mu, sigma] = climada_distribution_v0_vi(tc_name, check_printplot)
% EXAMPLE:
%   [mu, sigma] = climada_distribution_v0_vi('all', 1);
% INPUTS:
%   none
% OPTIONAL INPUT PARAMETERS:
%   tc_track:     historical tc tracks, prompted for if not given
%   output_unit:      output unit of mu and sigma, e.g. 'kn' for knots or
%   'm/s' for m/s, default m/s
%   check_visible:    if set to 1 will show figure, default 1
%   check_printplot:  if set to 1 will print (save) figure, default 0
% OUTPUTS:
%   mu and sigma, mean and standard deviation of fitted normal distribution
%   mu:     mean for initial wind speed v0 mu(1) and difference in wind
%   speed vi mu(2)
%   sigma:  standard deviation for initial wind speed v0 sigma(1) and difference in wind
%   speed vi sigma(2)
% MODIFICATION HISTORY:
% Lea Mueller, 20110616
%-


mu    = [];
sigma = [];
global climada_global
if ~climada_init_vars, return; end % init/import global variables
if ~exist('tc_track'       ,'var'), tc_track        = []   ; end
if ~exist('output_unit'    ,'var'), output_unit     = 'm/s'; end
if ~exist('check_visible'  ,'var'), check_visible   = 1    ; end
if ~exist('check_printplot','var'), check_printplot = []   ; end
if isempty(output_unit)           , output_unit     = 'm/s'; end


%% prompt for tc_track if not given
if isempty(tc_track)
    tc_track             = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    tc_track_default     = [climada_global.data_dir filesep 'tc_tracks' filesep 'Select HISTORICAL tc track .mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select HISTORICAL tc track set:',tc_track_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track = fullfile(pathname,filename);
    end
end
% load the tc track set, if a filename has been passed
if ~isstruct(tc_track)
    tc_track_file = tc_track;
    tc_track      = [];
    vars = whos('-file', tc_track_file);
    load(tc_track_file);
    if ~strcmp(vars.name,'tc_track')
        tc_track = eval(vars.name);
        clear (vars.name)
    end
end




%% initial wind speed for every track
%  difference in wind speed for every track node and track
vi = [];
for track_i = 1:length(tc_track)
    v0(track_i) = tc_track(track_i).MaxSustainedWind(1);
    vi_         = diff(tc_track(track_i).MaxSustainedWind);
    vi(end+1:end+length(vi_)) = vi_;
end
clear vi_
clear vi_length
clear track_i


%% conversion from kn to m/s
v0 = v0 * 1.852 * 1000/60/60;
vi = vi * 1.852 * 1000/60/60;
        



%% fit normal distribution
% [v0_count, v0_bin]      = hist   (v0,0:2.5:60);
% [muhat, sigmahat]       = normfit(v0,0:2.5:60);
% x                       = linspace(0, 120, 1000);
% y                       = normpdf(x,muhat,sigmahat);
% y                       = y/sum(y);
% 
% [vi_count, vi_bin     ] = hist   (vi,-15:2.5:15);
% [muhat(2), sigmahat(2)] = normfit(vi,-15:2.5:15);
% x_                      = linspace(-15,15,1000);
% y_                      = normpdf(x_,muhat(2),sigmahat(2));
% y_                      = y_/sum(y_);
% 
% mu    = muhat;
% sigma = sigmahat;

mu_(1)    = mean(v0(v0<35));
sigma_(1) = std(v0(v0<35));
mu_(2)    = mean(vi);
sigma_(2) = std(vi);

x_fit_0   = linspace(0, 100, 100);
y_fit_0   = 1/(sigma_(1)*sqrt(2*pi)) * exp(-0.5*((x_fit_0 - mu_(1))/sigma_(1)).^2);
x_fit_1   = linspace(-15,15,100);
y_fit_1   = 1/(sigma_(2)*sqrt(2*pi)) * exp(-0.5*((x_fit_1 - mu_(2))/sigma_(2)).^2);

[v0_count, v0_bin]      = hist(v0,0:2.5:60);
[sigma   , mu,  A]      = mygaussfit(v0_bin, v0_count/sum(v0_count),0);
if ~isreal(sigma) % trouble with gauss curve fit
    [sigma   , mu,  A]      = mygaussfit(v0_bin, v0_count/sum(v0_count));
end
% [sigma   , mu,  A]      = mygaussfit(v0_bin, v0_count/sum(v0_count));
x                       = linspace(0, 120, 1000);
y                       = A * exp(- (x-mu).^2 / (2*sigma^2));

[vi_count, vi_bin     ] = hist(vi,-15:2.5:15);
[sigma(2), mu(2), A(2)] = mygaussfit(vi_bin, vi_count/sum(vi_count));
x_                      = linspace(-15,15,1000);
y_                      = A(2) * exp(-(x_ - mu(2)).^2/(2*sigma(2)^2));



%% figure in m/s

if check_visible
   
    fig = climada_figuresize(0.5,0.8);
    subaxis(2,1,1,'sv',0.12,'ml',0.14)
        bar(v0_bin, v0_count/sum(v0_count))
        h = findobj(subaxis(1),'Type','patch');
        set(h,'FaceColor',[139 131 134 ]/255,'EdgeColor','w')
        hold on
        %plot fitted normal distribution
        h(2) = plot(x,y,'-r');
        h(3) = plot(x_fit_0,y_fit_0,':b');

        legend(h,'Hist. data',['Normal fit, \mu = ' num2str(mu(1),'%10.2f')  ', \sigma = ' num2str(sigma(1),'%10.2f')],'location','ne')
        legend('boxoff')
        xlabel('Initial wind speed v_0 (m s^{-1})')
        ylabel({['Relative count in'] ; [int2str(length(tc_track)) ' tc tracks']})
        %ylim([0 10])
        ylim([0 max(y)*1.7])
        ylim([0 max(v0_count/sum(v0_count))*1.2])
        xlim([-3 63])
        set(subaxis(1),'layer','top')
    
    subaxis(2)
        bar(vi_bin, vi_count/sum(vi_count))
        h = findobj(subaxis(2),'Type','patch');
        set(h,'FaceColor',[139 131 134 ]/255,'EdgeColor','w')
        %plot fitted normal distribution
        hold on
        h(2) = plot(x_, y_, '-r');   
        h(3) = plot(x_fit_1,y_fit_1,':b');

        legend(h,'Hist. data',['Normal fit, \mu = ' num2str(mu(2),'%10.2f')  ', \sigma = ' num2str(sigma(2),'%10.2f')],'location','ne')
        legend('boxoff')
        xlabel('Difference in wind speed v_i (m s^{-1})')  
        ylabel({['Relative count in ' int2str(length(vi)) ]; ['nodes of ' int2str(length(tc_track)) ' tc tracks']})
        % ylim([0 8000])
        % ylim([0 4000])
        ylim([0 max(y_)*1.2])
        xlim([-17 17])
        set(subaxis(2),'layer','top')
else
    check_printplot = 0;
end



if isempty(check_printplot)
    choice = questdlg('print?','print');
        switch choice
        case 'Yes'
            check_printplot = 1;
        case 'No'
            check_printplot = 0;
        case 'Cancel'
            return
        end
end   

if check_printplot
    foldername = [filesep 'results' filesep 'tc_track_distribution_v0_vi.pdf'];
    print(fig, '-dpdf',[climada_global.data_dir foldername])
    fprintf('FIGURE saved in folder %s \n', foldername); 
end

switch output_unit
    case 'kn'
        mu    = mu   /(1.852 * 1000/60/60);
        sigma = sigma/(1.852 * 1000/60/60);
        fprintf('mu and sigma in KNOTS \n')
    case 'm/s'
end;




%%
