DROP MATERIALIZED VIEW IF EXISTS getVasopressors2;
CREATE MATERIALIZED VIEW getVasopressors2 as

WITH vaso_union AS
(SELECT icustay_id, starttime, 
	vaso_rate as rate_norepinephrine,
	null::double precision as rate_epinephrine,
	null::double precision as rate_phenylephrine,
	null::double precision as rate_dopamine,
	null::double precision as rate_vasopressin

FROM norepinephrine_dose 

UNION ALL 

SELECT icustay_id, starttime, 
	null::double precision as rate_norepinephrine,
	vaso_rate as rate_epinephrine,
	null::double precision as rate_phenylephrine,
	null::double precision as rate_dopamine,
	null::double precision as rate_vasopressin

FROM epinephrine_dose 

UNION ALL 

SELECT icustay_id, starttime, 
	null::double precision as rate_norepinephrine,
	null::double precision as rate_epinephrine,
	vaso_rate as rate_phenylephrine,
	null::double precision as rate_dopamine,
	null::double precision as rate_vasopressin

FROM phenylephrine_dose 

UNION ALL 

SELECT icustay_id, starttime, 
	null::double precision as rate_norepinephrine,
	null::double precision as rate_epinephrine,
	null::double precision as rate_phenylephrine,
	vaso_rate as rate_dopamine,
	null::double precision as rate_vasopressin

FROM dopamine_dose 

UNION ALL 

SELECT icustay_id, starttime, 
	null::double precision as rate_norepinephrine,
	null::double precision as rate_epinephrine,
	null::double precision as rate_phenylephrine,
	null::double precision as rate_dopamine,
	vaso_rate as rate_vasopressin

FROM vasopressin_dose 
), vaso as
(SELECT icustay_id,starttime, 
  --max command is used to merge different vasopressors taken at the same time into a single row.
	max(rate_norepinephrine) as rate_norepinephrine,
	max(rate_epinephrine) as rate_epinephrine,
	max(rate_phenylephrine) as rate_phenylephrine,
	max(rate_dopamine) as rate_dopamine,
	max(rate_vasopressin) as rate_vasopressin
	
FROM vaso_union

GROUP BY icustay_id, starttime
 )
 SELECT *,
    coalesce(rate_norepinephrine,0) + coalesce(rate_epinephrine,0) +
	coalesce(rate_phenylephrine/2.2,0) + coalesce(rate_dopamine/100,0) +
	coalesce(rate_vasopressin*8.33,0) as vaso_total
	
FROM vaso

ORDER BY icustay_id, starttime