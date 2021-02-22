## Development and validation of a reinforcement learning algorithm to dynamically optimize mechanical ventilation in critical care
### Arne Peine, Ahmed Hallawa, Johannes Bickenbach, Guido Dartmann, Lejla Begic Fazlic, Anke Schmeink, Gerd Ascheid, Christoph Thiemermann, Andreas Schuppert, Ryan Kindle, Leo Celi, Gernot Marx & Lukas Martin 
#### npj Digital Medicine volume 4, Article number: 32 (2021)


The query files in this folder should be run with the following order.

**STAGE 1:** Retrieve time series data and demographic info independently. SOFA and SIRS scores are excluded in this stage since they should be calculated after sampling.

**getGCS.sql:** Retrieves the GCS eye, motor, verbal and total score. Only total score will be used in remaining parts. 

**getVitalSigns.sql:** Retrieves vital signs of heart rate, systolic, diastolic and mean blood pressures, respiratory rate, temperature, SpO2 and GCS. GCS result is obtained from **getGCS.sql**.

**getLabValues.sql:** Retrieves lab values that can be obtained from LABEVENTS table of MIMIC-3 (this excludes SGOT, SGPT and ionized calcium). icustay_id cannot be found in the LABEVENTS table so it is artifficially added by exploiting subject/hadm_id infos and by comparing the time of the measurement to ICU stay interval of patient. <br />
**getOthers.sql:** Retrieves lab values that cannot be obtained from LABEVENTS.

**getVentilationParams.sql:** Retrieves mechanical ventilation and FiO2. <br />
**ventparameters.sql:** Retrieves additional ventilation parameters of PEEP and titdal volume.

**getIntravenous.sql:** Retrieves intravenous fluid intake using INPUTEVENTS_MV table for MetaVision patients and INPUTEVENTS_CV table for CareVue patients. <br />
**getVasopressors.sql:**  Retrieves vasopressor intake using INPUTEVENTS_MV table for MetaVision patients and INPUTEVENTS_CV table for CareVue patients. Before running this query, all the queries under folder 'Vasopressors' should be run which has separate queries for each vasopressor type. They are stored as separate query files since each of them are too long. <br />
**getUrineOutput.sql:** Retrieves urine output using OUTPUTEVENTS_MV table. 
**getCumFluid.sql:** Retrieves cumulative fluid balance using INPUTEVENTS_MV, INPUTEVENTS_CV and OUTPUTEVENTS tables. Here only the fluids recorded with a volume unit (ml, L etc) has been taken. Indeterminate units such as 'dose' have been excluded. 

**getElixhauser_score.sql:** Retrieves Elixhauser scores using ICD-9 billing codes. 
**demographics.sql:** Retrieves some demographic info and on top of that some static info like patient discharge/death times, several mortality flags. Weight is excluded here and is queried in a separate file.
**echo-data.sql:** Retrieves ECG info. This table is not used directly for ECG info but weights of some patients can be obtained from it. <br />
**getWeight.sql:** Retrieves weight info for patients. For some patients only admission weight is recorded while there is also continuous data for some patients. In this query all available info for weight is taken and result is given as the average for each patient. Before this query, the query **echo-data.sql** must be run. 

**STAGE 2:** Merge the results of the previous stage into two tables. The initial intention was having one single table for the merged results but that caused some memory issues and they are separated here into two.

**overalltable_Lab_withventparams.sql:** The info retrieved from getLabValues.sql and getOthers.sql queries are merged into a single table.
**overalltable_withoutLab_withventparams.sql:** The rest of the info excluding lab values are merged. The reason for excluding lab values here is due to memory issues. Overall merging will be done after sampling. 

**STAGE 3:** Sample the merged results with 4 hour intervals.

**sampling_lab_withventparams.sql:** Gets the sampled result of overalltable_Lab_withventparams.sql with 4 hour intervals.
**sampling_withoutlab_withventparams.sql:** Gets the sampled result of overalltable_withoutLab_withventparams.sql with 4 hour intervals. 
**sampling_all_withventparams.sql:** Merges the results of sampling_lab_withventparams.sql and sampling_withoutLab_withventparams.sql.

**STAGE 4:** Retrieve the scores of SOFA and SIRS after obtaining sampled table.

**getSIRS_withventparams.sql:** Calculates the SIRS score of sampled data. 
**getSOFA_withventparams.sql:** Calculates the SOFA score of sampled data.

**STAGE 5:** Combine everything into a single table.

**sampled_data_with_scdem_withventparams.sql:** Merges the sampled time series data, the scores and demographic information.

**STAGE 6:** Up to now, the tables were created to contain all the patients in MIMIC3. Here the cohort of interest is selected.

**cohort_withventparams_all.sql:** Within current form actually gives the same result with sampled_data_with_scdem_withventparams.sql but a simple 'WHERE' statement can be used for particular ICUSTAY_ID's.


------------------------------------------------------------------------------------------------------------------------

Here are some additional query files whose results will be used in latter MATLAB scripts.

**hospmortandinouttimes.sql:** Retrieves IN and OUT times of ICU stays. <br />
**getIdealBodyWeight.sql:** Retrieves ideal body weights of patients.
