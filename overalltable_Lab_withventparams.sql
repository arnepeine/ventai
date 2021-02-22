--Took almost 21 seconds for querying.

-- Querying lab values directly with other parameters returned with a memeory error. So they are queried separately here. And after the sampling they will be merged. Two tables are used for this query: 'getlabvalues2' which contains lab values found directly in LABEVENTS and 'getOthers' which contains lab values found in CHARTEVENTS.

DROP MATERIALIZED VIEW IF EXISTS overalltable_Lab_withventparams;
CREATE MATERIALIZED VIEW overalltable_Lab_withventparams AS

SELECT merged.subject_id, hadm_id, icustay_id, charttime 
     --demographics
	 --, avg(age) as age, /*string_agg(gender,',') ,*/ gender , avg(weight) as weight--, null::integer as hospmort90day
     --vital signs
	 , avg(gcs) as gcs, avg(HeartRate) as HeartRate , avg(SysBP) as SysBP
     , avg(DiasBP) as DiasBP , avg(MeanBP) as MeanBP , avg(SysBP)/avg(HeartRate) as shockindex, avg(RespRate) as RespRate
     , avg(TempC) as TempC , avg(SpO2) as SpO2 
	 --lab values
	 , avg(POTASSIUM) as POTASSIUM , avg(SODIUM) as SODIUM , avg(CHLORIDE) as CHLORIDE , avg(GLUCOSE) as GLUCOSE
	 , avg(BUN) as BUN , avg(CREATININE) as CREATININE , avg(MAGNESIUM) as MAGNESIUM , avg(CALCIUM) as CALCIUM , avg(ionizedcalcium) ionizedcalcium
	 , avg(CARBONDIOXIDE) as CARBONDIOXIDE , avg(SGOT) as SGOT , avg(SGPT) as SGPT , avg(BILIRUBIN) as BILIRUBIN , avg(ALBUMIN) as ALBUMIN 
	 , avg(HEMOGLOBIN) as HEMOGLOBIN , avg(WBC) as WBC , avg(PLATELET) as PLATELET , avg(PTT) as PTT
     , avg(PT) as PT , avg(INR) as INR , avg(PH) as PH , avg(PaO2) as PaO2 , avg(PaCO2) as PaCO2
     , avg(BASE_EXCESS) as BASE_EXCESS , avg(BICARBONATE) as BICARBONATE , avg(LACTATE) as LACTATE 
	 -- multiply by 100 because FiO2 is in a % but should be a fraction. This idea is retrieved from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/firstday/blood-gas-first-day-arterial.sql
	 , avg(PaO2)/avg(Fio2)*100 as PaO2FiO2ratio 
	 , avg(BANDS) as BANDS 
	 --ventilation parameters
	 , (avg(mechvent)>0)::integer as MechVent --as long as at least one flag is 1 at the timepoint make overall as 1
	 , avg(FiO2) as FiO2
	 --urine output
	 , avg(urineoutput) as urineoutput
	 -- vasopressors
	 , avg(rate_norepinephrine) as rate_norepinephrine , avg(rate_epinephrine) as rate_epinephrine 
	 , avg(rate_phenylephrine) as rate_phenylephrine , avg(rate_vasopressin) as rate_vasopressin 
	 , avg(rate_dopamine) as rate_dopamine , avg(vaso_total) as vaso_total
	 -- intravenous fluids
	 , avg(iv_total) as iv_total
	 -- cumulated fluid balance
	 , avg(cum_fluid_balance) as cum_fluid_balance
	 -- ventilation parameters
	 , max(PEEP) as PEEP, max(tidal_volume) as tidal_volume, max(plateau_pressure) as plateau_pressure

FROM
(
SELECT lab.subject_id, lab.hadm_id, lab.icustay_id, lab.charttime
	-- vital signs
	 , null::double precision as gcs, null::double precision as heartrate, null::double precision as sysbp, null::double precision as diasbp, null::double precision as meanbp,  null::double precision as resprate, null::double precision as tempc, null::double precision as spo2 
	--lab values 
	 , POTASSIUM , SODIUM , CHLORIDE , GLUCOSE , BUN , CREATININE , MAGNESIUM , CALCIUM , CARBONDIOXIDE 
	 , BILIRUBIN , ALBUMIN , HEMOGLOBIN , WBC , PLATELET , PTT , PT , INR , PH , PaO2 , PaCO2
     , BASE_EXCESS , BICARBONATE , LACTATE , BANDS
	 ,null::double precision as SGOT , null::double precision as SGPT , null::double precision as IONIZEDCALCIUM
	--ventilation parameters
	 , null::integer as MechVent , null::double precision as FiO2
	--urine output
	 , null::double precision as urineoutput
	-- vasopressors
	 , null::double precision as rate_norepinephrine , null::double precision as rate_epinephrine 
	 , null::double precision as rate_phenylephrine , null::double precision as rate_vasopressin 
	 , null::double precision as rate_dopamine , null::double precision as vaso_total
	-- intravenous fluids
	 , null::double precision as iv_total
	-- cumulative fluid balance
	 , null::double precision as cum_fluid_balance
	-- ventilation parameters
	 , null::double precision as PEEP, null::double precision as tidal_volume, null::double precision as plateau_pressure
	FROM getLabvalues2 lab 
	--GROUP BY lab.subject_id, lab.hadm_id, lab.charttime
UNION ALL
	
SELECT ot.subject_id, ot.hadm_id, ot.icustay_id, ot.charttime
	-- vital signs
	 , null::double precision as gcs, null::double precision as heartrate, null::double precision as sysbp, null::double precision as diasbp, null::double precision as meanbp,  null::double precision as resprate, null::double precision as tempc, null::double precision as spo2 
	--lab values 
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
	 , SGOT , SGPT , IONIZEDCALCIUM
	--ventilation parameters
	 , null::integer as MechVent , null::double precision as FiO2
	--urine output
	 , null::double precision as urineoutput
	-- vasopressors
	 , null::double precision as rate_norepinephrine , null::double precision as rate_epinephrine 
	 , null::double precision as rate_phenylephrine , null::double precision as rate_vasopressin 
	 , null::double precision as rate_dopamine , null::double precision as vaso_total
	-- intravenous fluids
	 , null::double precision as iv_total
	-- cumulative fluid balance
	 , null::double precision as cum_fluid_balance
	-- ventilation parameters
	 , null::double precision as PEEP, null::double precision as tidal_volume, null::double precision as plateau_pressure
	FROM  getOthers ot
	
) merged 


group by subject_id, hadm_id, icustay_id, charttime	
order by subject_id, hadm_id, icustay_id, charttime

