--This code is retrieved from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/pivot/pivoted-uo.sql

DROP MATERIALIZED VIEW IF EXISTS getUrineoutput2;
CREATE MATERIALIZED VIEW getUrineoutput2 AS
select
  subject_id , hadm_id , icustay_id
  , charttime
  , sum(UrineOutput) as UrineOutput
from
(
  select
  -- patient identifiers
	oe.subject_id , oe.hadm_id ,
    oe.icustay_id
  , oe.charttime
  -- volumes associated with urine output ITEMIDs
  -- note we consider input of GU irrigant as a negative volume
  , case
      when oe.itemid = 227488 and oe.value > 0 then -1*oe.value
      else oe.value
    end as UrineOutput
  from mimiciii.outputevents oe
  -- exclude rows marked as error
  where oe.iserror IS DISTINCT FROM 1
  and itemid in
  (
  -- these are the most frequently occurring urine output observations in CareVue
  40055, -- "Urine Out Foley"
  43175, -- "Urine ."
  40069, -- "Urine Out Void"
  40094, -- "Urine Out Condom Cath"
  40715, -- "Urine Out Suprapubic"
  40473, -- "Urine Out IleoConduit"
  40085, -- "Urine Out Incontinent"
  40057, -- "Urine Out Rt Nephrostomy"
  40056, -- "Urine Out Lt Nephrostomy"
  40405, -- "Urine Out Other"
  40428, -- "Urine Out Straight Cath"
  40086,--	Urine Out Incontinent
  40096, -- "Urine Out Ureteral Stent #1"
  40651, -- "Urine Out Ureteral Stent #2"

  -- these are the most frequently occurring urine output observations in MetaVision
  226559, -- "Foley"
  226560, -- "Void"
  226561, -- "Condom Cath"
  226584, -- "Ileoconduit"
  226563, -- "Suprapubic"
  226564, -- "R Nephrostomy"
  226565, -- "L Nephrostomy"
  226567, --	Straight Cath
  226557, -- R Ureteral Stent
  226558, -- L Ureteral Stent
  227488, -- GU Irrigant Volume In
  227489  -- GU Irrigant/Urine Volume Out
  )
) t1
group by t1.subject_id, t1.hadm_id , t1.icustay_id, t1.charttime
order by t1.subject_id, t1.hadm_id , t1.icustay_id, t1.charttime;