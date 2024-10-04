

	ReadMe for MARA v1.01
	---------------------

Description
------------
The Mass based AMS Relative ionisation efficiency cAlibration (MARA) Igor toolkit was created to handle the processing of mass based calibration data from ammonium nitrate (AN), ammonium sulphate (AS), and other compounds (O).
The raw measurement data has to be processed with Squirrel/Pika first.
The CPC particle concentration time series must be loaded manually.

MARA calculates the averages in intervals provided by the user, converts the units of the data and derives the (relative) ionisation efficiency of the investigated calibration compounds. All values relevant for the final calculations are stored with the input data.

MARA contains a method to estimate the contribution of multiple charged particles from pToF data. Additionally, MARA contains a separate Multi Charged particle Estimator (MCE) panel to estimate the contribution of double and triple charged particles.

More details about MARA can be found at:
	https://docs.google.com/document/d/1g9_6UizgG57PbkH34DTIw1wTK1b5qWNsz7faqbAE0Vo/edit?usp=sharing

How to run MARA
---------------
+ process AMS data with Squirrel/Pika and calculating the time series waves of the calibrant compound
+ load the CPC number concentration time series into your Igor experiment
+ include the file "MARA_main_v1_01.ipf" in your Igor experiment
	this file automatically loads all needed function files.
+ start the panel from the Menu Item MARA->open MARA
+ accept the license agreement
+ fill in the names of the waves containing the time series of NH4, NO3, and SO4 for AN and AS if available
	MARA can handle subfolders (root:subFOlder:WaveName, root can be omitted)
+ pToF data (average size distribution for one species) can be added to derive the fraction of single charged particles. (this can be omitted completly)
+ use the "plot tseries" button to visualise the AMS and CPC time series data.
+ define the averaging intervals with either of these options:
	- manually enter start and end times in the table in the panel
	- copy a two column matrix into the table
	- use the controls in the tseries graph to asign intervals using the cursors
+ check the instrument parameter on the right side of the table in the main panel
+ click the "calc (R)IE" button to start the calcualation and display the results in the right hand side of the MARA Panel
+ repeat these steps for all compounds in your calibration data set.

MCE Panel
---------
+ Open the MCE panel with the pink button (no data is needed for this)
+ Insert the desired electromobility size of the selected particles
	The corresponding double and triple charged particle sizes are calculated automatically.
+ Insert the measured particle number concentration for each of the sizes
+ Press “calculate” to estimate the fraction of single charged particles to the overall signal



