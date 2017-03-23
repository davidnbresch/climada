this folder contains system files, like the shape file for the global map (admin0.mat), some colormaps and the images (demo_*.png) for the demo.

admin0.* are the files to draw admin0 (country) borders etc. see admin0.txt
coastline.mat global coastline, see coastline.txt for details

colormap*.mat are various color maps, used for hazard intensity plots etc.

demo_illu?.png are the three images used in climada_demo on the upper left panel

economic_indicators_mastertable.* is the master table with GDP per country etc. Used especially by climada module country risk (https://github.com/davidnbresch/climada_module_country_risk), but we provide it here, as there are some basic uses in core climada, too. 

The file night_light_2010_10km.mat really belongs to climada module country risk (https://github.com/davidnbresch/climada_module_country_risk), but we provide it here to allow for easy generation of country entities at 10km resolution for any country of the world (see climada_entity_country).

In past versions, this folder also contained world_50m.gen, a generalised shape file. This file is now with climada module country risk (https://github.com/davidnbresch/climada_module_country_risk), as core climada moved to admin0.mat (see e.g. climada_plot_world_borders).

david.bresch@gmail.com, 2017
