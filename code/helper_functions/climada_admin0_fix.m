function [shapes,admin0_info]=climada_admin0_fix(shapes,check_plot)
% climada
% NAME:
%   climada_admin0_fix
% PURPOSE:
%   read a shape file (with admin0 shapes) and return shapes structure. Fix
%   some issues with countries (i.e. France and DOM/TOM as separate shapes.
%
%   See code for detials, especially the parameter section. All matching
%   within this code happens via 3-digit ISO code (to avoid ambiguities).
%   See e.g. climada_country_name to obtain the matching code(s).
%
%   for each shape, we chekc for NaNs (separating segments) and then check
%   whether these segments are indeed stand-alone admin regions. There is
%   no global consensus, hence this code solves this issue with some
%   pragmatism.
%
%   See PARAMETERS in the code for any further information.
%
%   This code usually treats the shape file ne_10m_coastline.shp obtained from
%   www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/...
%       cultural/ne_10m_admin_0_countries.zip
%   which comes witht he climada country risk module:
%   https://github.com/davidnbresch/climada_module_country_risk)
%
%   Usually called from shapes=climada_shaperead('SYSTEM_ADMIN0')
% CALLING SEQUENCE:
%   [shapes,admin0_info]=climada_admin0_fix(shapes,check_plot)
% EXAMPLE:
%   shapes=climada_shaperead('.../ne_10m_coastline/ne_10m_coastline.shp');
%   [shapes,admin0_info]=climada_admin0_fix(shapes,1)
% INPUTS:
%   shapes: s shapes strcuture, as returned by climada_shaperead
% OPTIONAL INPUT PARAMETERS:
%   check_plot: whether we show a check plot (=1, default) or not (=0)
% OUTPUTS:
%   shapes: same as input, with two additions:
%       in each shapes(i), there are two new variables, X_ALL and Y_ALL,
%       the original Y and Y.
%       at the end of the original shapes, the (sub) shapes of new admin0
%       are appended, but only their key fields (NAME, ,X,Y) are
%       propulated.
%   admin0_info: a strcut with 
%       ADM0_A3{i}: the ISO3 code for each shape, search e.g. using
%           strmatch('CUW',admin0_info.ADM0_A3)
%       NAME{i}: the name for each shape, search e.g. using
%           strmatch('United States',admin0_info.NAME)
%       BoundingBox{i}: the bounding box for each shape (to ease some
%           triage when searching geographically)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161008, initial, taken out of climada_shaperead
%-

admin0_info=[];

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('shapes','var'),shapes=[];end
if ~exist('check_plot','var'),check_plot=1;end
if isempty(shapes),return;end

% PARAMETERS
%
% the consolidated reference country names as in the Excel file
% ../data/system/admin0.xls (we provide the Excel file for users who want
% to check compatibility or match names in Excel, see tab 'combined' and
% column 'transfer for climada_shaperead')
reference_ISO3_country_name={
    'ABW','Aruba'
    'AFG','Afghanistan'
    'AGO','Angola'
    'AIA','Anguilla'
    'ALB','Albania'
    'ALD','Aland'
    'AND','Andorra'
    'ARE','United Arab Emirates'
    'ARG','Argentina'
    'ARM','Armenia'
    'ASM','American Samoa'
    'ATA','Antarctica'
    'ATC','Ashmore and Cartier Islands'
    'ATF','French Southern and Antarctic Lands '
    'ATG','Antigua and Barbuda'
    'AUS','Australia'
    'AUT','Austria'
    'AZE','Azerbaijan'
    'BDI','Burundi'
    'BEL','Belgium'
    'BEN','Benin'
    'BFA','Burkina Faso'
    'BGD','Bangladesh'
    'BGR','Bulgaria'
    'BHR','Bahrain'
    'BHS','Bahamas'
    'BIH','Bosnia and Herzegovina'
    'BJN','Bajo Nuevo Bank (Petrel Islands)'
    'BLM','St-Barthelemy'
    'BLR','Belarus'
    'BLZ','Belize'
    'BMU','Bermuda'
    'BOL','Bolivia'
    'BRA','Brazil'
    'BRB','Barbados'
    'BRN','Brunei'
    'BTN','Bhutan'
    'BWA','Botswana'
    'CAF','Central African Republic'
    'CAN','Canada'
    'CHE','Switzerland'
    'CHL','Chile'
    'CHN','China'
    'CIV','Cote dIvoire'
    'CLP','Clipperton Island'
    'CMR','Cameroon'
    'CNM','Cyprus UN Buffer Zone'
    'COD','Democratic Republic of the Congo'
    'COG','Congo'
    'COK','Cook Islands'
    'COL','Colombia'
    'COM','Comoros'
    'CPV','Cape Verde'
    'CRI','Costa Rica'
    'CSI','Coral Sea Islands'
    'CUB','Cuba'
    'CUW','Curacao'
    'CYM','Cayman Islands'
    'CYN','North Cyprus'
    'CYP','Cyprus'
    'CZE','Czech Republic'
    'DEU','Germany'
    'DJI','Djibouti'
    'DMA','Dominica'
    'DNK','Denmark'
    'DOM','Dominican Republic'
    'DZA','Algeria'
    'ECU','Ecuador'
    'EGY','Egypt'
    'ERI','Eritrea'
    'ESB','Dhekelia'
    'ESP','Spain'
    'EST','Estonia'
    'ETH','Ethiopia'
    'FIN','Finland'
    'FJI','Fiji'
    'FLK','Falkland Islands'
    'FRA','France'
    'FRO','Faeroe Islands'
    'FSM','Micronesia'
    'GAB','Gabon'
    'GBR','United Kingdom'
    'GEO','Georgia'
    'GGY','Guernsey'
    'GHA','Ghana'
    'GIB','Gibraltar'
    'GIN','Guinea'
    'GMB','Gambia'
    'GNB','Guinea-Bissau'
    'GNQ','Equatorial Guinea'
    'GRC','Greece'
    'GRD','Grenada'
    'GRL','Greenland'
    'GTM','Guatemala'
    'GUM','Guam'
    'GUY','Guyana'
    'HKG','Hong Kong'
    'HMD','Heard Island and McDonald Islands '
    'HND','Honduras'
    'HRV','Croatia'
    'HTI','Haiti'
    'HUN','Hungary'
    'IDN','Indonesia'
    'IMN','Isle of Man'
    'IND','India'
    'IOA','Indian Ocean Territory'
    'IOT','British Indian Ocean Territory'
    'IRL','Ireland'
    'IRN','Iran'
    'IRQ','Iraq'
    'ISL','Iceland'
    'ISR','Israel'
    'ITA','Italy'
    'JAM','Jamaica'
    'JEY','Jersey'
    'JOR','Jordan'
    'JPN','Japan'
    'KAB','Baikonur'
    'KAS','Siachen Glacier'
    'KAZ','Kazakhstan'
    'KEN','Kenya'
    'KGZ','Kyrgyzstan'
    'KHM','Cambodia'
    'KIR','Kiribati'
    'KNA','Saint Kitts and Nevis'
    'KOR','Korea'
    'KOS','Kosovo'
    'KWT','Kuwait'
    'LAO','Laos'
    'LBN','Lebanon'
    'LBR','Liberia'
    'LBY','Libya'
    'LCA','Saint Lucia'
    'LIE','Liechtenstein'
    'LKA','Sri Lanka'
    'LSO','Lesotho'
    'LTU','Lithuania'
    'LUX','Luxembourg'
    'LVA','Latvia'
    'MAC','Macao'
    'MAF','Saint Martin'
    'MAR','Morocco'
    'MCO','Monaco'
    'MDA','Moldova'
    'MDG','Madagascar'
    'MDV','Maldives'
    'MEX','Mexico'
    'MHL','Marshall Islands'
    'MKD','Macedonia'
    'MLI','Mali'
    'MLT','Malta'
    'MMR','Myanmar'
    'MNE','Montenegro'
    'MNG','Mongolia'
    'MNP','Northern Mariana Islands'
    'MOZ','Mozambique'
    'MRT','Mauritania'
    'MSR','Montserrat'
    'MUS','Mauritius'
    'MWI','Malawi'
    'MYS','Malaysia'
    'NAM','Namibia'
    'NCL','New Caledonia'
    'NER','Niger'
    'NFK','Norfolk Island'
    'NGA','Nigeria'
    'NIC','Nicaragua'
    'NIU','Niue'
    'NLD','Netherlands'
    'NOR','Norway'
    'NPL','Nepal'
    'NRU','Nauru'
    'NZL','New Zealand'
    'OMN','Oman'
    'PAK','Pakistan'
    'PAN','Panama'
    'PCN','Pitcairn Islands'
    'PER','Peru'
    'PGA','Spratly Islands'
    'PHL','Philippines'
    'PLW','Palau'
    'PNG','Papua New Guinea'
    'POL','Poland'
    'PRI','Puerto Rico'
    'PRK','North Korea'
    'PRT','Portugal'
    'PRY','Paraguay'
    'PSX','Palestine' % is switched to PSE on output (since 20161008)
    'PYF','French Polynesia'
    'QAT','Qatar'
    'ROU','Romania'
    'RUS','Russia'
    'RWA','Rwanda'
    'SAH','Western Sahara'
    'SAU','Saudi Arabia'
    'SCR','Scarborough Reef'
    'SDN','Sudan'
    'SDS','South Sudan'
    'SEN','Senegal'
    'SER','Serranilla Bank'
    'SGP','Singapore'
    'SGS','South Georgia and South Sandwich Islands'
    'SHN','Saint Helena'
    'SLB','Solomon Islands'
    'SLE','Sierra Leone'
    'SLV','El Salvador'
    'SMR','San Marino'
    'SOL','Somaliland'
    'SOM','Somalia'
    'SPM','Saint Pierre and Miquelon'
    'SRB','Serbia'
    'STP','Sao Tome and Principe'
    'SUR','Suriname'
    'SVK','Slovakia'
    'SVN','Slovenia'
    'SWE','Sweden'
    'SWZ','Swaziland'
    'SXM','Sint Maarten'
    'SYC','Seychelles'
    'SYR','Syria'
    'TCA','Turks and Caicos Islands'
    'TCD','Chad'
    'TGO','Togo'
    'THA','Thailand'
    'TJK','Tajikistan'
    'TKM','Turkmenistan'
    'TLS','Timor-Leste'
    'TON','Tonga'
    'TTO','Trinidad and Tobago'
    'TUN','Tunisia'
    'TUR','Turkey'
    'TUV','Tuvalu'
    'TWN','Taiwan'
    'TZA','Tanzania'
    'UGA','Uganda'
    'UKR','Ukraine'
    'UMI','US Minor Outlying Islands'
    'URY','Uruguay'
    'USA','United States'
    'USG','USNB Guantanamo Bay'
    'UZB','Uzbekistan'
    'VAT','Vatican'
    'VCT','Saint Vincent and the Grenadines'
    'VEN','Venezuela'
    'VGB','British Virgin Islands'
    'VIR','US Virgin Islands'
    'VNM','Vietnam'
    'VUT','Vanuatu'
    'WLF','Wallis and Futuna Islands'
    'WSB','Akrotiri'
    'WSM','Samoa'
    'YEM','Yemen'
    'ZAF','South Africa'
    'ZMB','Zambia'
    'ZWE','Zimbabwe' % up to here until 20161007
    'GUF','French Guyana' % from here on added 20161008
    'REU','Reunion' % FRA
    'MYT','Mayotte' % FRA
    'MTQ','Martinique' % FRA
    'GLP','Guadeloupe' % FRA
    '_AK','Alaska' % USA
    '_HI','Hawaii' % USA
    'AHT','Amchitka' % airport code (US)
    'BES','Bonaire, Saint Eustatius and Saba' % NLD
    'SJM','Svalbard and Jan Mayen' % NOR
    'TKL','Tokelau' % NZL
    };
%
% special treatment for some countries with overseas territories etc.
% the shapes(i).X will contain the core or domestic shape, not including
% all overseas territories (all shapes are back up in X_ALL and Y_ALL).
% if subshapes are defined, they are appended at the end of shapes
% set special_shape=[]; to suppress any restriction
special_shape(1).NAME='France';
special_shape(1).ADM0_A3='FRA'; % France
% subshape also for the main country, but special treatment (see below)
special_shape(1).subshape(1).NAME=special_shape(1).NAME;
special_shape(1).subshape(1).ADM0_A3=special_shape(1).ADM0_A3;
special_shape(1).subshape(1).xv=[-10 -10 15 15 -10]; % the vertices of the encompssing polygon
special_shape(1).subshape(1).yv=[ 35  55 55 35  35]; % the vertices of the encompssing polygon
special_shape(1).subshape(2).NAME='French Guyana';
special_shape(1).subshape(2).ADM0_A3='GUF';
special_shape(1).subshape(2).xv=[-55 -55 -51 -51 -55];
special_shape(1).subshape(2).yv=[  2   6   6   2   2];
special_shape(1).subshape(3).NAME='Reunion'; % ? replaced by e
special_shape(1).subshape(3).ADM0_A3='REU';
special_shape(1).subshape(3).xv=[ 55  55  56  56  55];
special_shape(1).subshape(3).yv=[-22 -20 -20 -22 -22];
special_shape(1).subshape(4).NAME='Mayotte';
special_shape(1).subshape(4).ADM0_A3='MYT';
special_shape(1).subshape(4).xv=[ 45  45  46  46  45];
special_shape(1).subshape(4).yv=[-14 -12 -12 -14 -14];
special_shape(1).subshape(5).NAME='Martinique';
special_shape(1).subshape(5).ADM0_A3='MTQ';
special_shape(1).subshape(5).xv=[-62 -62 -60 -60 -62];
special_shape(1).subshape(5).yv=[ 14  15  15  14  14];
special_shape(1).subshape(6).NAME='Guadeloupe';
special_shape(1).subshape(6).ADM0_A3='GLP';
special_shape(1).subshape(6).xv=[-62 -62 -60 -60 -62];
special_shape(1).subshape(6).yv=[ 15  17  17  15  15];
%
special_shape(2).NAME='Netherlands';
special_shape(2).ADM0_A3='NLD';
special_shape(2).subshape(1).NAME=special_shape(2).NAME;
special_shape(2).subshape(1).ADM0_A3=special_shape(2).ADM0_A3;
special_shape(2).subshape(1).xv=[ 0  0 10 10  0];
special_shape(2).subshape(1).yv=[50 55 55 50 50];
special_shape(2).subshape(2).NAME='Bonaire, Saint Eustatius and Saba ';
special_shape(2).subshape(2).ADM0_A3='BES';
special_shape(2).subshape(2).xv=[-69 -69 -62 -62 -69];
special_shape(2).subshape(2).yv=[ 12  18  18  12  12];
% see CUW Curacao for the other part of the Netherlands Antilles
%
special_shape(3).NAME='Norway';
special_shape(3).ADM0_A3='NOR';
special_shape(3).subshape(1).NAME=special_shape(3).NAME;
special_shape(3).subshape(1).ADM0_A3=special_shape(3).ADM0_A3;
special_shape(3).subshape(1).xv=[ 0  0 50 50  0];
special_shape(3).subshape(1).yv=[55 72 72 55 55];
special_shape(3).subshape(2).NAME='Svalbard and Jan Mayen';
special_shape(3).subshape(2).ADM0_A3='SJM';
special_shape(3).subshape(2).xv=[ 7  7 10 10  7 NaN  9  9 40 40  9];
special_shape(3).subshape(2).yv=[70 72 72 70 70 NaN 72 82 82 72 72];
% at about 3.4E, -54.4S: Bouvet Island (uninhabited)
%
special_shape(4).NAME='New Zealand';
special_shape(4).ADM0_A3='NZL';
special_shape(4).subshape(1).NAME=special_shape(4).NAME;
special_shape(4).subshape(1).ADM0_A3=special_shape(4).ADM0_A3;
special_shape(4).subshape(1).xv=[150 150 181 181 150];
special_shape(4).subshape(1).yv=[-60 -30 -30 -60 -60];
special_shape(4).subshape(2).NAME='Tokelau';
special_shape(4).subshape(2).ADM0_A3='TKL';
special_shape(4).subshape(2).xv=[-173 -173 -170 -170 -173];
special_shape(4).subshape(2).yv=[-8    -10  -10   -8   -8];
% note that Chatham Island is ignored (as on the other side of the date
% line, issues...)
%
special_shape(5).NAME='Portugal';
special_shape(5).ADM0_A3='PRT';
special_shape(5).subshape(1).NAME=special_shape(5).NAME;
special_shape(5).subshape(1).ADM0_A3=special_shape(5).ADM0_A3;
special_shape(5).subshape(1).xv=[-12 -12 -5 -5 -12];
special_shape(5).subshape(1).yv=[ 36  43 43 36  36];
%
special_shape(6).NAME='Russia';
special_shape(6).ADM0_A3='RUS';
special_shape(6).subshape(1).NAME=special_shape(6).NAME;
special_shape(6).subshape(1).ADM0_A3=special_shape(6).ADM0_A3;
special_shape(6).subshape(1).xv=[ 0  0 181 181  0];
special_shape(6).subshape(1).yv=[40 91  91  40 40];
%
special_shape(7).NAME='United States';
special_shape(7).ADM0_A3='USA';
special_shape(7).subshape(1).NAME=special_shape(7).NAME;
special_shape(7).subshape(1).ADM0_A3=special_shape(7).ADM0_A3;
special_shape(7).subshape(1).xv=[-150 -150 -50 -50 -150];
special_shape(7).subshape(1).yv=[  20   50  50  20   20];
special_shape(7).subshape(2).NAME='Alaska';
special_shape(7).subshape(2).ADM0_A3='_AK'; % SPECIAL
special_shape(7).subshape(2).xv=[-180 -180 -129 -129 -180];
special_shape(7).subshape(2).yv=[  50   72   72   50   50];
special_shape(7).subshape(3).NAME='Amchitka';
special_shape(7).subshape(3).ADM0_A3='AHT'; % airport code (US)
special_shape(7).subshape(3).xv=[172 172 180 180 172];
special_shape(7).subshape(3).yv=[ 51  54  54  51  51];
special_shape(7).subshape(4).NAME='Hawaii';
special_shape(7).subshape(4).ADM0_A3='_HI'; % SPECIAL
special_shape(7).subshape(4).xv=[-161 -161 -154 -154 -161];
special_shape(7).subshape(4).yv=[  18   23   23   18   18];
%
% to add further subshapes, it is best to plot the full shape (i.e.
% plot(shapes(i).X,shapes(i).Y) or plot(shapes(i).X_ALL,shapes(i).Y_ALL)
% and then determine xv and yv ....

if ~isfield(shapes(1),'ADM0_A3') || ~isfield(shapes(1),'NAME')
    fpritnf('ERROR: shapes do not contain fields ADM0_A3 and/or NAME\n');
    return
end

% replace country names by consolidated reference ones
match_count=0; % init
fprintf('checking %i shapes ...\n',length(shapes));

for shape_i=1:length(shapes)
    if check_plot,plot(shapes(shape_i).X,shapes(shape_i).Y,'-k');hold on;end % indicate check
    match_pos=strcmp(reference_ISO3_country_name(:,1),shapes(shape_i).ADM0_A3); % match ISO3
    if strcmpi(reference_ISO3_country_name(:,1),'PSX')
        shapes(shape_i).ADM0_A3='PSE';
        fprintf('SPECIAL: PSX switched to %s (%s)\n',shapes(shape_i).ADM0_A3,shapes(shape_i).NAME);
    end
    if sum(match_pos)>0
        % replace name
        shapes(shape_i).NAME=reference_ISO3_country_name{match_pos,2};
        match_count=match_count+1;
        if check_plot
            x=shapes(shape_i).X;y=shapes(shape_i).Y; % for readability
            plot(x,y,'-b');
            drawnow;hold on;  % to sync to show progress...
        end % check_plot
    else
        fprintf('WARNING: %s (%s) not matched\n',shapes(shape_i).NAME,shapes(shape_i).ADM0_A3);
    end
end % shape_i
if check_plot,hold on;xlabel('blue: OK, black: all shapes');drawnow;end
fprintf(' %i (%i%%) of %i country names matched\n',match_count,ceil(match_count/length(shapes)*100),length(shapes));

if isfield(shapes(1),'X_ALL') || isfield(shapes(1),'Y_ALL')
    fprintf('WARNING: sub-shapes seem to be treated already, not repeated\n');
    fprintf('consider deleting the .mat file to re-treat sub-shapes\n');
else
    if ~isempty(special_shape)
        fprintf('checking %i countries with subshapes:\n',length(special_shape));
        % SPECIAL treatment for some countries with overseas territories etc.
        for special_shape_i=1:length(special_shape)
            shape_i=[];
            for shape_ii=1:length(shapes) % find country
                if strcmp(shapes(shape_ii).NAME,special_shape(special_shape_i).NAME)
                    shape_i=shape_ii;
                end
            end % shape_ii
            if ~isempty(shape_i)
                fprintf('%s %s (shape %i) - checking for subshapes ...\n',...
                    special_shape(special_shape_i).ADM0_A3,special_shape(special_shape_i).NAME,shape_i);
                for subshape_i=1:length(special_shape(special_shape_i).subshape) % loop over sub-shapes to check for
                    fprintf(' %s %s (in %s)\n',special_shape(special_shape_i).subshape(subshape_i).ADM0_A3,...
                        special_shape(special_shape_i).subshape(subshape_i).NAME,special_shape(special_shape_i).NAME);
                    % make a copy of the vertices, as we need them a few times
                    % (for readability fo the code)
                    xv=special_shape(special_shape_i).subshape(subshape_i).xv;
                    yv=special_shape(special_shape_i).subshape(subshape_i).yv;
                    isnan_pos=find(isnan(shapes(shape_i).X)); % find segments
                    i1=1;X_sub=[];Y_sub=[]; % init
                    for isnan_pos_i=1:length(isnan_pos)
                        i2=isnan_pos(isnan_pos_i);
                        X=shapes(shape_i).X(i1:i2);
                        Y=shapes(shape_i).Y(i1:i2);
                        % check for this section being within the vertices
                        
                        in = inpolygon(X,Y,xv,yv);
                        if sum(in)>0
                            if check_plot,plot(X,Y,'.r','MarkerSize',0.5);plot(xv,yv,'-r');drawnow;hold on;end
                            X_sub=[X_sub NaN X]; % NaN to separate segments
                            Y_sub=[Y_sub NaN Y];
                        end
                        i1=i2; % next segment
                        
                    end % isnan_pos_i
                    if subshape_i==1 % special case for 'mother' country
                        X_mother=X_sub;Y_mother=Y_sub;
                    else % ADD shape at the end
                        next_shape=length(shapes)+1; % next free shape at end (append)
                        shapes(next_shape).NAME=special_shape(special_shape_i).subshape(subshape_i).NAME;
                        shapes(next_shape).NAME_LONG=shapes(next_shape).NAME;
                        shapes(next_shape).ADMIN=shapes(next_shape).NAME;
                        shapes(next_shape).ADM0_A3=special_shape(special_shape_i).subshape(subshape_i).ADM0_A3;
                        shapes(next_shape).X=X_sub;
                        shapes(next_shape).Y=Y_sub;
                        
                        % copy a few fields we migt need
                        shapes(next_shape).Geometry=shapes(shape_i).Geometry;
                        shapes(next_shape).TYPE=shapes(shape_i).TYPE;
                        shapes(next_shape).CONTINENT=shapes(shape_i).CONTINENT;
                        shapes(next_shape).REGION_UN=shapes(shape_i).REGION_UN;
                        shapes(next_shape).SUBREGION=shapes(shape_i).SUBREGION;
                        shapes(next_shape).REGION_WB=shapes(shape_i).REGION_WB;
                        shapes(next_shape).BoundingBox(1,1)=min(xv);
                        shapes(next_shape).BoundingBox(2,1)=max(xv);
                        shapes(next_shape).BoundingBox(1,2)=min(yv);
                        shapes(next_shape).BoundingBox(2,2)=max(yv);
                    end
                    if check_plot
                        plot(X_sub,Y_sub,'-g');hold on;
                        text(mean(X_sub(~isnan(X_sub))),mean(Y_sub(~isnan(Y_sub))),...
                            char(special_shape(special_shape_i).subshape(subshape_i).NAME));
                        drawnow;hold on;
                    end
                end  % subshape_i
                % now restrict original shapes to the 'mother' ones
                shapes(shape_i).X_ALL=shapes(shape_i).X;shapes(shape_i).Y_ALL=shapes(shape_i).Y; % backup (so to say)
                shapes(shape_i).X=X_mother;
                shapes(shape_i).Y=Y_mother;
                shapes(shape_i).ADM0_A3=special_shape(special_shape_i).subshape(1).ADM0_A3;
                shapes(shape_i).NAME=special_shape(special_shape_i).subshape(1).NAME;
                shapes(shape_i).NAME_LONG=shapes(shape_i).NAME;
                shapes(shape_i).ADMIN=shapes(shape_i).NAME;
            end % ~isempty(shape_i)
        end % special_shape_i
    end % special_shape
    if check_plot,hold on;xlabel('blue: OK, green: OK additional separete shapes, red: check boxes');drawnow;end
end

% finally, loop once more over shapes and compile admin0_info
for shape_i=1:length(shapes)
    admin0_info.NAME{shape_i}=shapes(shape_i).NAME;
    admin0_info.ADM0_A3{shape_i}=shapes(shape_i).ADM0_A3;
    admin0_info.BoundingBox{shape_i}=shapes(shape_i).BoundingBox;
    
    if check_plot % lablel all
        hold on
        x=shapes(shape_i).X;y=shapes(shape_i).Y; % for lisibility
        text(mean(x(~isnan(x))),mean(y(~isnan(y))),...
            char(shapes(shape_i).NAME));
    end % check_plot
    
end % shape_i
if check_plot,set(gcf,'Name','admin0 fixes'),set(gcf,'Color',[1 1 1]);drawnow;end % push it all

end % climada_admin0_fix