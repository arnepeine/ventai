-- code is inspired from https://stackoverflow.com/questions/15576794/best-way-to-count-records-by-arbitrary-time-intervals-in-railspostgres/15577413#15577413
-- and https://stackoverflow.com/questions/27351079/query-aggregated-data-with-a-given-sampling-time

--This code samples the data within table 'overalltable' with a resolution of 4 hours. 
-- The resultant table is called sampled_data_tmp since it will be a temporary table excluding scores and demographics.
--There is also another file called sampling.sql written for the same purpose but it was taking long hours (even when patient id's were partitioned into 5 separate groups the longest query took 14 hours)
-- but this version queried everything in 2 minutes. Still sampling.sql will be kept for some time since it extracts more rows than this current version. It should be examined to see if this is an error for the current or old version.

--NOTE: Took 22 minutes to query.
DROP MATERIALIZED VIEW IF EXISTS sampled_withoutlab_withventparams;
CREATE MATERIALIZED VIEW sampled_withoutlab_withventparams as

-- This part is in order to generate time binning.
WITH minmax as(
SELECT subject_id, hadm_id, icustay_id , min(charttime) as mint, max(charttime) as maxt
FROM overalltable_withoutlab_withventparams
GROUP BY icustay_id, subject_id, hadm_id
ORDER BY icustay_id, subject_id, hadm_id
	), grid as (
	SELECT icustay_id, subject_id, hadm_id, generate_series(mint,maxt,interval '4 hours') as start_time
	FROM minmax
	GROUP BY icustay_id, subject_id, hadm_id,mint,maxt
    ORDER BY icustay_id, subject_id, hadm_id)
	
SELECT ot.icustay_id, ot.subject_id, ot.hadm_id, start_time
     , round(avg(gcs)) as gcs , avg(heartrate) as heartrate , avg(sysbp) as sysbp , avg(diasbp) as diasbp , avg(meanbp) as meanbp
	 , avg(shockindex) as shockindex, avg(RespRate) as RespRate
     , avg(TempC) as TempC , avg(SpO2) as SpO2 
	 --lab values
	 , avg(POTASSIUM) as POTASSIUM , avg(SODIUM) as SODIUM , avg(CHLORIDE) as CHLORIDE , avg(GLUCOSE) as GLUCOSE
	 , avg(BUN) as BUN , avg(CREATININE) as CREATININE , avg(MAGNESIUM) as MAGNESIUM , avg(CALCIUM) as CALCIUM , avg(ionizedcalcium) ionizedcalcium
	 , avg(CARBONDIOXIDE) as CARBONDIOXIDE , avg(SGOT) as SGOT , avg(SGPT) as SGPT, avg(BILIRUBIN) as BILIRUBIN , avg(ALBUMIN) as ALBUMIN 
	 , avg(HEMOGLOBIN) as HEMOGLOBIN , avg(WBC) as WBC , avg(PLATELET) as PLATELET , avg(PTT) as PTT
     , avg(PT) as PT , avg(INR) as INR , avg(PH) as PH , avg(PaO2) as PaO2 , avg(PaCO2) as PaCO2
     , avg(BASE_EXCESS) as BASE_EXCESS , avg(BICARBONATE) as BICARBONATE , avg(LACTATE) as LACTATE 
	 ,avg(pao2fio2ratio) as pao2fio2ratio, avg(BANDS) as BANDS -- this is only included in order to calculate SIRS score
	 --ventilation parameters
	 , (avg(mechvent)>0)::integer as MechVent --as long as at least one flag is 1 at the timepoint make overall as 1
	 , avg(FiO2) as FiO2
	 --urine output
	 , sum(urineoutput) as urineoutput
	 -- vasopressors
	 , max(rate_norepinephrine) as rate_norepinephrine , max(rate_epinephrine) as rate_epinephrine 
	 , max(rate_phenylephrine) as rate_phenylephrine , max(rate_vasopressin) as rate_vasopressin 
	 , max(rate_dopamine) as rate_dopamine , max(vaso_total) as vaso_total
	 -- intravenous fluids
	 , sum(iv_total) as iv_total
	 -- cumulative fluid balance
	 , avg(cum_fluid_balance) as cum_fluid_balance
	 -- ventilation parameters
	 , max(PEEP) as PEEP, max(tidal_volume) as tidal_volume, max(plateau_pressure) as plateau_pressure
FROM grid g
LEFT JOIN overalltable_withoutlab_withventparams ot ON ot.charttime >= g.start_time
				   AND ot.charttime <  g.start_time + '4 hours'
				   AND ot.icustay_id=g.icustay_id
				   AND ot.subject_id=g.subject_id
				   AND ot.hadm_id=g.hadm_id

GROUP  BY ot.icustay_id,ot.subject_id, ot.hadm_id, start_time
ORDER  BY icustay_id,subject_id, hadm_id, start_time
