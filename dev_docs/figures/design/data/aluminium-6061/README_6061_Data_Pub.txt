NIST Public Data Resource:
Aluminum 6061-T6 Dynamic Stress-Strain Data at Various Temperatures with Rapid Heating
Version 1.0.0
DOI: TBD

Contact:
  Steven P. Mates
    steven.mates@nist.gov

Description:

This dataset contains raw mechanical data (strain, stress and strain rate curves
and initial temperatures) for compression experiments performed on aluminum alloy 6061-T6
using the NIST pulse-heated Kolsky Bar at strain rates between 2400 1/s and 2700 1/s and initial 
temperatures from 23 C to 527 C and heating times ranging betwen 0.2 s and 3.5 s. At this time,
the thermal history of the specimen during heating is not included in the dataset but this information
may be included in a future update. The pulse-heated Kolsky bar method is described in reference [1].
Additional regarding the temperature measurement methods specific to aluminum are found in 
reference [2] as well as a supplementary included in this data publication [3]. This dataset 
includes measurements of right-circular cylindrical samples measuring 6 mm diameter by 3 mm thick, 
fabricated by conventional machining. The effect of the surface condition on the thermographic temperature
measurements and the temperature uncertainty calculations are described in reference [3], which is 
included in this dataset as metadata. 


References
[1] Mates, S.P., et al., A Pulse-Heated Kolsky Bar Technique for Measuring the Flow Stress of Metals
at High Loading and Heating Rates. Experimental Mechanics, 2008. 48(6): p. 799-807. 
DOI 10.1007/s11340-008-9137-1

[2] Lopez-Hawa, H., et al., On the Mechanical Response of Aluminum Alloy 6061-T6 under Extreme Strains
 and Strain Rates, and Rapid Heating. Manufacturing Letters, 2022. 33: p. 292-301.

[3] Aluminum_insitu_calibration.docx



-------------------
General Information
-------------------

This data was created at NIST between 2020 and 2023.

--------------
Data Use Notes
--------------

This data is publically available according to the NIST statements of
copyright, fair use and licensing; see
https://www.nist.gov/director/copyright-fair-use-and-licensing-statements-srd-data-and-software

You may cite the use of this data as follows:
https://doi.org/TBD (Accessed: [give download date])


-------------
Data Overview
-------------

Files included in this publication:

Datafile_master_list_6061T6.csv

    File contains a master list of the datafile names with starting heat treatment condition (T6), 
	test temperature [units degrees celsius], test temperature uncertainty [degrees celsius]
	average ture strain rate 1/s], true strain rate standard deviation[1/s], heating time [s], 
	and thermal measurement notes. All column headings are defined at the top of the file.
    Format: comma separated value

Datafiles_aluminum_6061T6.zip
    Zip file containing each individual data file listed in Datafile_master_list.csv. 
    Format: .zip file

xxxx_analyzed_w_unc.csv
    File containing true stress and true strain rate versus true strain along with uncertainty
	estimates for strain and stress. Adiabatic temperatures are not calculated at present,
	but they may be in a future update of this dataset. File is associated with a single
	experiment with a 4 digit experiment number identifier here denoted by "xxxx". These 
	files reside within Datafiles_aluminum_6061T6.zip.
    Format: comma separated value



---------------
Version History
---------------

1.0.0 (this version)
  initial release

--------------------------
Methodological Information
--------------------------

Methods for data collection, processing and equipment used are described in the related publications