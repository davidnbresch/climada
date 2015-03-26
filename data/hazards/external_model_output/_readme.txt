This folder contains the asci-files that are produced by an external hazard model (e.g. SOBEK flood model).
Every asci file is one hazard event. The asci file contains the hazard event information in a raster format.
The asci files can be inputted into climada into a hazard structure with the function hazard=climada_asci2hazard;


------------------------------
Example asci file
------------------------------
ncols	4

nrows	4
xllcorner	530285.438

yllcorner	504276.750
cellsize	100.000
NODATA_value	-9999

-9999	-9999	1	2
2	1	0.5	1
1	1	0.5	0.5	
-9999	1	-9999	-9999
------------------------------


