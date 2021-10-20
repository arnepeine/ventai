DROP MATERIALIZED VIEW IF EXISTS getIntravenous2;
CREATE MATERIALIZED VIEW getIntravenous2 AS

WITH intra_cv AS
(SELECT * 
FROM mimiciii.inputevents_cv
WHERE originalroute in('Intravenous','Intravenous Infusion','Intravenous Push','IV Drip','IV Piggyback')
), intra_mv AS
(
	SELECT * 
FROM mimiciii.inputevents_mv
WHERE ordercategoryname IN ('03-IV Fluid Bolus','02-Fluids (Crystalloids)','04-Fluids (Colloids)','07-Blood Products')
	OR secondaryordercategoryname IN ('03-IV Fluid Bolus','02-Fluids (Crystalloids)','04-Fluids (Colloids)','07-Blood Products')
 )
 
 SELECT subject_id, hadm_id , icustay_id, charttime
	 , (case when amountuom in ('ml','cc') then amount /*else null*/ end) as amount
FROM intra_cv

UNION ALL

SELECT subject_id, hadm_id , icustay_id, storetime as charttime
	 , avg(totalamount) as amount
FROM intra_mv

group by subject_id, hadm_id  , icustay_id, charttime
order by subject_id, hadm_id , icustay_id, charttime