this folder will contain results

since climada does allows to compare its results in a structured way with other models’ results, the file climada_DFC_compare_file.xls does provide the interface to communicate other model results with climada, see code climada_DFC_compare

additionally, target_DFC.xls does allow to provide climada with a whole series of (other) model results, by country and peril. See code cr_damagefunction_sensitivity and the calling code cr_country_DFC_sensitivity. See selected_countries_region_peril to run such comparisons for a series of countries, e.g. a full peril region, like TC North Atlantic (TC atl) or TC West Pacific (TC wpa).
