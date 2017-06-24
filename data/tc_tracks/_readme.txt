this folder contains tropical cyclone (TC) track data
while data for other perils rather rests ins specific modules, TC data comes with
core climada in order to provide a ‘default’ peril (also for TESTs).

See e.g. the code climada_tc_get_unisys_databases to automatically fetch the (latest) global TC database from www. 

Please note that filenames of the form *.???.txt are reserved for HURDAT datasets, as they are automatically processed by climada (e.g. centroids_generate_hazard_sets)

But please feel free to store any TC data in this folder or subfolders thereof, such as ibtracs.

copyright (c) 2017, David N. Bresch, david.bresch@gmail.com
all rights reserved.
