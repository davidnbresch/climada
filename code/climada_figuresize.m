function fig = climada_figuresize(height, width)
% figure size for printing/saving pdf figures
% NAME:
%   climada_figuresize
% PURPOSE:
%   create figure so that pdf not A4 but customed to matlab figure
%   and set default axes font size, line width, marker line width and text
%   font size bigger, so that approriate for export
% CALLING SEQUENCE:
%   fig = climada_figuresize(height, width)
% EXAMPLE:
%   fig = climada_figuresize(0.4, 0.5)
% INPUTS:
%   none
% OPTIONAL INPUT PARAMETERS:
%   height: percentage of height of screen
%   width:  percentage of height of screen
% %   width:  percentage of width of screen
% OUTPUTS:
%   figure with handle fig with requested height and width
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Lea Mueller, 20110616
%-

if nargin < 2, width  = 0.7; end
if nargin < 1, height = 0.8; end

scrsz = get(0,'ScreenSize');

if scrsz(3)<1400 %laptop instead of big desktop
    width  = width *1.5;
    height = height*1.3;
end
fig = figure('Position'  , [10  35               scrsz(4)*width*1.0  scrsz(4)*height*1.],...
       'PaperUnits','points', 'paperpositionmode','auto','PaperSize',[1600*height  1000*height*1.],'Color',[1 1 1]);%,...
   
% fig = figure('Position'  , [10  35               scrsz(3)*width*1.0  scrsz(4)*height*1.],...
%        'PaperUnits','points', 'paperpositionmode','auto','PaperSize',[1200*width  1000*height*1.]);%,...
% %        'paperpositionmode','auto');%[scrsz(3) scrsz(4)]);
% % set(gcf,'PaperUnits','points','papersize',[200 200])

% set(0, 'DefaultAxesFontsize'  , 13)
% set(0, 'defaultTextFontSize'  , 13)

set(0, 'DefaultAxesFontsize'  ,12)
set(0, 'defaultlinelinewidth' ,1.0)
set(0, 'defaultpatchlinewidth',1.0)
set(0, 'defaultTextFontSize'  , 9)

