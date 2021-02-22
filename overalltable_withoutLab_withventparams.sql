--Took almost 10 minutes for querying.

DROP MATERIALIZED VIEW IF EXISTS overalltable_withoutLab_withventparams;
CREATE MATERIALIZED VIEW overalltable_withoutLab_withventparams AS

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
SELECT subject_id, hadm_id, icustay_id, charttime
	 -- vital signs
	 , gcs, heartrate, sysbp, diasbp, meanbp, resprate, tempc, spo2 
	 --lab values
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as IONIZEDCALCIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as SGOT , null::double precision as SGPT , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
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
		
FROM getVitalsigns2 vit
/*UNION ALL
SELECT lab.subject_id, lab.hadm_id, lab.icustay_id, lab.charttime
	-- vital signs
	 , null as gcs, null as heartrate, null as sysbp, null as diasbp, null as meanbp,  null as resprate, null as tempc, null as spo2 
	--lab values 
	 , POTASSIUM , SODIUM , CHLORIDE , GLUCOSE , BUN , CREATININE , MAGNESIUM , CALCIUM /*, IONIZEDCALCIUM*/ , CARBONDIOXIDE 
	 /*, SGOT , SGPT*/ , BILIRUBIN , ALBUMIN , HEMOGLOBIN , WBC , PLATELET , PTT , PT , INR , PH , PaO2 , PaCO2
     , BASE_EXCESS , BICARBONATE , LACTATE , BANDS
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
	FROM getLabvalues2 lab , getOthers
	--GROUP BY lab.subject_id, lab.hadm_id, lab.charttime*/
UNION ALL
SELECT subject_id, hadm_id, icustay_id, charttime
	-- vital signs
	 , null as gcs, null as heartrate, null as sysbp, null as diasbp, null as meanbp,  null as resprate, null as tempc, null as spo2 
	--lab values
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as IONIZEDCALCIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as SGOT , null::double precision as SGPT , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
	--ventilation parameters
	 , MechVent , fio2_chartevents as FiO2
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
	
	FROM getVentilationparams2 vent 

UNION ALL
SELECT subject_id, hadm_id, icustay_id, charttime
	-- vital signs
	 , null as gcs, null as heartrate, null as sysbp, null as diasbp, null as meanbp,  null as resprate, null as tempc, null as spo2 
     --lab values
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as IONIZEDCALCIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as SGOT , null::double precision as SGPT , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
	--ventilation parameters
	 , null::integer as MechVent , null::double precision as FiO2
	--urine output
	 , urineoutput
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
	
	FROM getUrineoutput2 uo 
	
UNION ALL
SELECT ic.subject_id, ic.hadm_id, ic.icustay_id, starttime as charttime
	-- vital signs
	 , null as gcs, null as heartrate, null as sysbp, null as diasbp, null as meanbp, null as resprate, null as tempc, null as spo2 
	--lab values
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as IONIZEDCALCIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as SGOT , null::double precision as SGPT , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
	--ventilation parameters
	 , null::integer as MechVent , null::double precision as FiO2
	--urine output
	 , null::double precision as urineoutput
	-- vasopressors
	 , rate_norepinephrine , rate_epinephrine , rate_phenylephrine 
	 , rate_vasopressin , rate_dopamine , vaso_total
	-- intravenous fluids
	 , null::double precision as iv_total
	-- cumulative fluid balance
	 , null::double precision as cum_fluid_balance
	-- ventilation parameters
	 , null::double precision as PEEP, null::double precision as tidal_volume, null::double precision as plateau_pressure
	
FROM getVasopressors2
INNER JOIN mimiciii.icustays ic
ON getVasopressors2.icustay_id=ic.icustay_id
	
UNION ALL
SELECT subject_id, hadm_id, icustay_id, charttime
	-- vital signs
	 , null as gcs, null as heartrate, null as sysbp, null as diasbp, null as meanbp, null as resprate, null as tempc, null as spo2 
	--lab values
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as IONIZEDCALCIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as SGOT , null::double precision as SGPT , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
	--ventilation parameters
	 , null::integer as MechVent , null::double precision as FiO2
	--urine output
	 , null::double precision as urineoutput
	-- vasopressors
	 , null::double precision as rate_norepinephrine , null::double precision as rate_epinephrine 
	 , null::double precision as rate_phenylephrine , null::double precision as rate_vasopressin 
	 , null::double precision as rate_dopamine , null::double precision as vaso_total
	-- intravenous fluids
	 , amount as iv_total
	-- cumulative fluid balance
	 , null::double precision as cum_fluid_balance
	-- ventilation parameters
	 , null::double precision as PEEP, null::double precision as tidal_volume, null::double precision as plateau_pressure
	
FROM getIntravenous2
	
UNION ALL
SELECT subject_id, hadm_id, icustay_id, charttime
	 -- vital signs
	 , null as gcs, null as heartrate, null as sysbp, null as diasbp, null as meanbp, null as resprate, null as tempc, null as spo2 
	 --lab values
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as IONIZEDCALCIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as SGOT , null::double precision as SGPT , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
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
	 , cum_fluid_balance as cum_fluid_balance
	-- ventilation parameters
	 , null::double precision as PEEP, null::double precision as tidal_volume, null::double precision as plateau_pressure
	
FROM getCumFluid cumflu
	
UNION ALL
SELECT subject_id, hadm_id, icustay_id, charttime
	 -- vital signs
	 , null as gcs, null as heartrate, null as sysbp, null as diasbp, null as meanbp, null as resprate, null as tempc, null as spo2 
	 --lab values
	 , null::double precision as POTASSIUM , null::double precision as SODIUM , null::double precision as CHLORIDE , null::double precision as GLUCOSE , null::double precision as BUN , null::double precision as CREATININE , null::double precision as MAGNESIUM , null::double precision as IONIZEDCALCIUM , null::double precision as CALCIUM , null::double precision as CARBONDIOXIDE 
	 , null::double precision as SGOT , null::double precision as SGPT , null::double precision as BILIRUBIN , null::double precision as ALBUMIN , null::double precision as HEMOGLOBIN , null::double precision as WBC , null::double precision as PLATELET , null::double precision as PTT , null::double precision as PT , null::double precision as INR , null::double precision as PH , null::double precision as PaO2 , null::double precision as PaCO2
     , null::double precision as BASE_EXCESS , null::double precision as BICARBONATE , null::double precision as LACTATE , null::double precision as BANDS
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
	 , PEEP as PEEP, tidal_volume as tidal_volume, plateau_pressure as plateau_pressure
	
FROM ventparameters cumflu
	
) merged 


group by subject_id, hadm_id, icustay_id, charttime	
order by subject_id, hadm_id, icustay_id, charttime
--limit 1000
