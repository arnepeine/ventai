-- ------------------------------------------------------------------
-- Title: Systemic inflammatory response syndrome (SIRS) criteria
-- This query extracts the Systemic inflammatory response syndrome (SIRS) criteria
-- The criteria quantify the level of inflammatory response of the body
-- The score is calculated on the first day of each ICU patients' stay.
-- ------------------------------------------------------------------

-- Reference for SIRS:
--    American College of Chest Physicians/Society of Critical Care Medicine Consensus Conference:
--    definitions for sepsis and organ failure and guidelines for the use of innovative therapies in sepsis"
--    Crit. Care Med. 20 (6): 864–74. 1992.
--    doi:10.1097/00003246-199206000-00025. PMID 1597042.

-- Variables used in SIRS:
--  Body temperature (min and max)
--  Heart rate (max)
--  Respiratory rate (max)
--  PaCO2 (min)
--  White blood cell count (min and max)
--  the presence of greater than 10% immature neutrophils (band forms)

-- code inspired from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/severityscores/sirs.sql
--NOTE: Took 12 seconds to query.
DROP MATERIALIZED VIEW IF EXISTS getSIRS_sampled_withventparams;
CREATE MATERIALIZED VIEW getSIRS_sampled_withventparams AS

with scorecomp as(

SELECT icustay_id, subject_id , hadm_id,  start_time
       , tempC , heartrate , resprate , paco2 , wbc , bands

FROM sampled_all_withventparams),

scorecalc as
( SELECT icustay_id, subject_id , hadm_id, start_time
       , tempC , heartrate , resprate , paco2 , wbc , bands
 
 , case
      when Tempc < 36.0 then 1
      when Tempc > 38.0 then 1
      when Tempc is null then null
      else 0
    end as Temp_score


  , case
      when HeartRate > 90.0  then 1
      when HeartRate is null then null
      else 0
    end as HeartRate_score

  , case
      when RespRate > 20.0  then 1
      when PaCO2 < 32.0  then 1
      when coalesce(RespRate, PaCO2) is null then null
      else 0
    end as Resp_score

  , case
      when WBC <  4.0  then 1
      when WBC > 12.0  then 1
      when Bands > 10 then 1-- > 10% immature neurophils (band forms)
      when coalesce(WBC, Bands) is null then null
      else 0
    end as WBC_score
  
 
 from scorecomp
)

select
  icustay_id, subject_id , hadm_id, start_time
  -- Combine all the scores to get SIRS
  -- Impute 0 if the score is missing
  , coalesce(Temp_score,0)
  + coalesce(HeartRate_score,0)
  + coalesce(Resp_score,0)
  + coalesce(WBC_score,0)
    as SIRS
  , Temp_score, HeartRate_score, Resp_score, WBC_score
from scorecalc;