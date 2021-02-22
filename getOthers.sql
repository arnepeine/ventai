-- This code is retrieved from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/pivot/pivoted-lab.sql

--The parts about Glucose has been commented in the code. Since in the Nature paper it has been treated as a lab value instead of a vital sign 

DROP MATERIALIZED VIEW IF EXISTS getOthers ;
CREATE MATERIALIZED VIEW getOthers as

with ce as
(
  select ce.icustay_id
	, ce.subject_id
	, ce.hadm_id
    , ce.charttime
    , (case when itemid in (3801)  then valuenum else null end) as SGOT
    , (case when itemid in (3802)  then valuenum else null end) as SGPT
    , (case when itemid in (816,1350,3766,8177,8325,225667)  then valuenum else null end) as IonizedCalcium
  from mimiciii.chartevents ce
  where ce.error IS DISTINCT FROM 1
  and ce.itemid in
  (
  -- SGOT/SGPT
  3801, --"SGOT"
  3802, --"SGPT"
	  
  -- Ionized Calcium

  816,1350,3766,8177,8325,225667

	 ) 
	)
  
select
  	subject_id
  , hadm_id	
  , ce.icustay_id
  , ce.charttime
  , avg(SGOT) as SGOT
  , avg(SGPT) as SGPT
  , avg(IonizedCalcium) as IonizedCalcium
  from ce
  group by ce.subject_id,ce.hadm_id,ce.icustay_id, ce.charttime
