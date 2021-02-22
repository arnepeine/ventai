-- ------------------------------------------------------------------
-- Title: Sequential Organ Failure Assessment (SOFA)
-- This query extracts the sequential organ failure assessment (formally: sepsis-related organ failure assessment).
-- This score is a measure of organ failure for patients in the ICU.
-- The score is calculated on the first day of each ICU patients' stay.
-- ------------------------------------------------------------------

-- Reference for SOFA:
--    Jean-Louis Vincent, Rui Moreno, Jukka Takala, Sheila Willatts, Arnaldo De Mendonça,
--    Hajo Bruining, C. K. Reinhart, Peter M Suter, and L. G. Thijs.
--    "The SOFA (Sepsis-related Organ Failure Assessment) score to describe organ dysfunction/failure."
--    Intensive care medicine 22, no. 7 (1996): 707-710.

-- Variables used in SOFA:
--  GCS, MAP, FiO2, Ventilation status (sourced from CHARTEVENTS)
--  Creatinine, Bilirubin, FiO2, PaO2, Platelets (sourced from LABEVENTS)
--  Dobutamine, Epinephrine, Norepinephrine (sourced from INPUTEVENTS_MV and INPUTEVENTS_CV)
--  Urine output (sourced from OUTPUTEVENTS)

-- code inspired from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/severityscores/sofa.sql
-- also this wikipedia article can be used as a cross-check reference https://en.wikipedia.org/wiki/SOFA_score
--NOTE: Took 20 seconds to query.
DROP MATERIALIZED VIEW IF EXISTS getSOFA_sampled_withventparams;
CREATE MATERIALIZED VIEW getSOFA_sampled_withventparams AS

with scorecomp as(

SELECT icustay_id,subject_id , hadm_id, start_time
       --respiration
       , PaO2FiO2ratio , mechvent
	   -- nervous system
       , gcs
	   -- cardiovascular system
	   , meanbp ,  rate_dopamine 
	   , rate_norepinephrine, rate_epinephrine
	   -- liver
       , bilirubin
	   -- coagulation
	   , platelet
	   -- kidneys (renal)
	   , creatinine, urineoutput

FROM sampled_all_withventparams),

scorecalc as
(
SELECT icustay_id, subject_id, hadm_id, start_time , PaO2FiO2ratio , mechvent , gcs, meanbp , rate_dopamine , rate_norepinephrine, rate_epinephrine
       , bilirubin , platelet , creatinine, urineoutput 

	   , case
      when PaO2FiO2ratio < 100 and mechvent=1 then 4
      when PaO2FiO2ratio < 200 and mechvent=1 then 3
      when PaO2FiO2ratio < 300                then 2
      when PaO2FiO2ratio < 400                then 1
      when PaO2FiO2ratio is null then null
      else 0
    end as respiration
	
	  -- Neurological failure (GCS)
  , case
      when (gcs >= 13 and gcs <= 14) then 1
      when (gcs >= 10 and gcs <= 12) then 2
      when (gcs >=  6 and gcs <=  9) then 3
      when  gcs <   6 then 4
      when  gcs is null then null
  else 0 end
    as cns
	
  -- Cardiovascular
  , case
      when rate_dopamine > 15 or rate_epinephrine >  0.1 or rate_norepinephrine >  0.1 then 4
      when rate_dopamine >  5 or rate_epinephrine <= 0.1 or rate_norepinephrine <= 0.1 then 3
      when rate_dopamine <=  5 /*or rate_dobutamine > 0*/ then 2
      when MeanBP < 70 then 1
      when coalesce(MeanBP, rate_dopamine, /*rate_dobutamine,*/ rate_epinephrine, rate_norepinephrine) is null then null
      else 0
    end as cardiovascular
	
	-- Liver
  , case
      -- Bilirubin checks in mg/dL
        when Bilirubin >= 12.0 then 4
        when Bilirubin >= 6.0  then 3
        when Bilirubin >= 2.0  then 2
        when Bilirubin >= 1.2  then 1
        when Bilirubin is null then null
        else 0
      end as liver
	  
	  -- Coagulation
  , case
      when platelet < 20  then 4
      when platelet < 50  then 3
      when platelet < 100 then 2
      when platelet < 150 then 1
      when platelet is null then null
      else 0
    end as coagulation
	
	-- Renal failure - high creatinine or low urine output
  , case
    when (Creatinine >= 5.0) then 4
    when  UrineOutput < 200 then 4
    when (Creatinine >= 3.5 and Creatinine < 5.0) then 3
    when  UrineOutput < 500 then 3
    when (Creatinine >= 2.0 and Creatinine < 3.5) then 2
    when (Creatinine >= 1.2 and Creatinine < 2.0) then 1
    when coalesce(UrineOutput, Creatinine) is null then null
  else 0 end
    as renal
	
	
	
	from scorecomp)
	
SELECT icustay_id, subject_id , hadm_id, start_time
	   -- parameters from scorecomp
       , PaO2FiO2ratio , mechvent , gcs, meanbp , rate_dopamine , rate_norepinephrine, rate_epinephrine
       , bilirubin , platelet , creatinine, urineoutput
	   -- parameters from scorecalc, contains separate scores to estimate the final SOFA score
	   , respiration , cns , cardiovascular , liver , coagulation , renal
	   -- overall SOFA score calculation
       , coalesce(respiration,0) + coalesce(cns,0) 
       + coalesce(cardiovascular,0) + coalesce(liver,0) 
       + coalesce(coagulation,0) + coalesce(renal,0) as SOFA
	   
FROM scorecalc

ORDER BY icustay_id, subject_id , hadm_id, start_time

