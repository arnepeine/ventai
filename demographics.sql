DROP MATERIALIZED VIEW IF EXISTS demographics2 ;
CREATE MATERIALIZED VIEW demographics2 as

WITH first_admission_time AS
(
  SELECT
      p.subject_id, a.hadm_id, i.icustay_id, p.dob, p.gender, p.dod
      , MIN (a.admittime) AS first_admittime
      , MIN( ROUND( (cast(admittime as date) - cast(dob as date)) / 365.242,2) ) --dob:date of birth
          AS first_admit_age
	  -- This part is retrieved from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/cookbook/mortality.sql
	  ,(CASE WHEN p.dod > i.intime AND p.dod < i.outtime THEN 1 ELSE 0 END) AS ICUMort
	  , hospital_expire_flag AS HospMort
	  , (CASE WHEN dod < admittime + interval '28' day THEN 1 ELSE 0 END)  AS HospMort28day
	  , (CASE WHEN dod < admittime + interval '90' day THEN 1 ELSE 0 END)  AS HospMort90day
	  , a.dischtime , a.deathtime
	
  FROM mimiciii.icustays i --, mimiciii.chartevents ce
 
  INNER JOIN mimiciii.admissions a
  ON a.hadm_id = i.hadm_id
  INNER JOIN mimiciii.patients p
  ON p.subject_id = i.subject_id
  GROUP BY p.subject_id, p.dob, p.gender, p.dod, a.admittime, /*ce.itemid, ce.valuenum,*/a.hadm_id , a.dischtime, a.deathtime,a.hospital_expire_flag,i.icustay_id,i.intime, i.outtime
  ORDER BY p.subject_id
),
hos_admissions as
(SELECT DISTINCT(subject_id)
 , (CASE WHEN COUNT(icustay_id)>1 then 1 else 0 end) as ICU_readm
FROM first_admission_time
GROUP By subject_id)
SELECT
    f.subject_id , f.hadm_id, f.icustay_id, 
	-- For patients older than 89, MIMIC-3 records the ages as 300 so the below modification is done. Retrieved from https://github.com/alistairewj/sepsis3-mimic/blob/master/query/tbls/cohort.sql
	-- Set de-identified ages to median of 91.4 . The median info can be found under https://mimic.physionet.org/mimictables/patients/ under 'Important Considerations' title.
	case when f.first_admit_age>89 then 91.4 else f.first_admit_age end as first_admit_age, 
	f.gender, /*admit_weight_kg,*/  h.ICU_readm
	,eli.elixhauser_vanwalraven as elixhauser_score
	, f.ICUMort, f.HospMort, f.HospMort28day, f.HospMort90day, f.dischtime, f.deathtime
	
FROM first_admission_time f
INNER JOIN hos_admissions h
ON f.subject_id=h.subject_id
INNER JOIN getelixhauser_score2 eli
ON f.subject_id=eli.subject_id AND  f.hadm_id=eli.hadm_id
ORDER BY subject_id, hadm_id