--query script to merge the sampled data with the corresponding scores and demographic information

DROP MATERIALIZED VIEW IF EXISTS sampled_with_scdem_withventparams;
CREATE MATERIALIZED VIEW sampled_with_scdem_withventparams AS

SELECT   --samp.* , sf.sofa , sr.sirs, dem.*, weig.*

		-- the above code also works but it has been given like that in order to preserve the position of sirs and sofa scores
		-- as given in the paper. With above syntax they will be at the end of the table.
		samp.icustay_id, ic.subject_id , ic.hadm_id, samp.start_time , dem.first_admit_age,
		dem.gender, weig.weight, dem.icu_readm, dem.elixhauser_score, sf.sofa , sr.sirs ,
		samp.gcs , samp.heartrate , samp.sysbp, samp.diasbp, samp.meanbp,
		samp.shockindex, samp.resprate, samp.tempc, samp.spo2, samp.potassium,
		samp.sodium, samp.chloride, samp.glucose, samp.bun, samp.creatinine, samp.magnesium,
		samp.calcium, samp.ionizedcalcium, samp.carbondioxide, samp.sgot, samp.sgpt, samp.bilirubin, samp.albumin, samp.hemoglobin,
		samp.wbc, samp.platelet, samp.ptt, samp.pt, samp.inr, samp.ph, samp.pao2, samp.paco2, samp.base_excess,
		samp.bicarbonate, samp.lactate, samp.pao2fio2ratio, samp.mechvent, samp.fio2, samp.urineoutput,
		samp.vaso_total, samp.iv_total, samp.cum_fluid_balance, samp.peep, samp.tidal_volume, samp.plateau_pressure,
		dem.hospmort90day, dem.dischtime, dem.deathtime

FROM sampled_all_withventparams samp

LEFT JOIN getsirs_sampled_withventparams sr
ON samp.icustay_id=sr.icustay_id AND samp.start_time=sr.start_time

LEFT JOIN getsofa_sampled_withventparams sf
ON samp.icustay_id=sf.icustay_id AND samp.start_time=sf.start_time

LEFT JOIN demographics2 dem
ON samp.icustay_id=dem.icustay_id 

LEFT JOIN getweight2 weig
ON samp.icustay_id=weig.icustay_id

INNER JOIN mimiciii.icustays ic
ON samp.icustay_id=ic.icustay_id


ORDER BY samp.icustay_id, samp.subject_id, samp.hadm_id, samp.start_time
--LIMIT 1000000

