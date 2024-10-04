## MARA
**Version 1.01 2024-10-03**

**Description**

The Mass based AMS Relative ionisation efficiency cAlibration (MARA) Igor toolkit was created to handle the processing of mass based calibration data from ammonium nitrate (AN), ammonium sulphate (AS), and other compounds (O).
The raw measurement data has to be processed with Squirrel/Pika first.
The CPC particle concentration time series must be loaded manually.

MARA calculates the averages in intervals provided by the user, converts the units of the data and derives the (relative) ionisation efficiency of the investigated calibration compounds. All values relevant for the final calculations are stored with the input data.

MARA contains a method to estimate the contribution of multiple charged particles from pToF data. Additionally, MARA contains a separate Multi Charged particle Estimator (MCE) panel to estimate the contribution of double and triple charged particles.

More details about MARA can be found at:
[MARA user manual](https://docs.google.com/document/d/1g9_6UizgG57PbkH34DTIw1wTK1b5qWNsz7faqbAE0Vo/edit?usp=sharing)

MARA has been tested in Igor 9 but should be compatible with Igor 7&8.

To download everything, click the green "code" button and select "Download Zip".
