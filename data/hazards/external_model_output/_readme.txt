This folder contains output from external (or photo) hazard models.

For example, there might be ASCII files that are produced by an external hazard model (e.g. SOBEK flood model). Every ASCII file is one hazard event. The ASCII file contains the hazard event information in a raster format. The ASCII files can be imported into climada into a hazard structure with the function

hazard=climada_asci2hazard;


------------------------------
Example ASCII file (see example_asci_1.asc)
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
