DROP MATERIALIZED VIEW IF EXISTS getVentilationparams2 ;
CREATE MATERIALIZED VIEW getVentilationparams2 as

--Code retrieved from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/firstday/blood-gas-first-day-arterial.sql for Fio2.

select SUBJECT_ID, HADM_ID, ICUSTAY_ID, CHARTTIME
    -- pre-process the FiO2s to ensure they are between 21-100%
    , max(
        case
          when itemid = 223835
            then case
              when valuenum > 0 and valuenum <= 1
                then valuenum * 100
              -- improperly input data - looks like O2 flow in litres
              when valuenum > 1 and valuenum < 21
                then null
              when valuenum >= 21 and valuenum <= 100
                then valuenum
              else null end -- unphysiological
        when itemid in (3420, 3422)
        -- all these values are well formatted
            then valuenum
        when itemid = 190 and valuenum > 0.20 and valuenum < 1
        -- well formatted but not in %
            then valuenum * 100
      else null end
    ) as fio2_chartevents
--Code retrieved from https://github.com/MIT-LCP/mimic-code/blob/1754d925ba4e96e376dc29858e8df301fcb69a20/concepts/durations/ventilation-durations.sql for mechanical ventilation.
  , max(
    case
      when itemid is null or value is null then 0 -- can't have null values
      when itemid = 720 and value != 'Other/Remarks' THEN 1  -- VentTypeRecorded
      when itemid = 223848 and value != 'Other' THEN 1
      when itemid = 223849 then 1 -- ventilator mode
      when itemid = 467 and value = 'Ventilator' THEN 1 -- O2 delivery device == ventilator
      when itemid in
        (
        445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
        , 639, 654, 681, 682, 683, 684,224685,224684,224686 -- tidal volume
        , 218,436,535,444,459,224697,224695,224696,224746,224747 -- High/Low/Peak/Mean/Neg insp force ("RespPressure")
        , 221,1,1211,1655,2000,226873,224738,224419,224750,227187 -- Insp pressure
        , 543 -- PlateauPressure
        , 5865,5866,224707,224709,224705,224706 -- APRV pressure
        , 60,437,505,506,686,220339,224700 -- PEEP
        , 3459 -- high pressure relief
        , 501,502,503,224702 -- PCV
        , 223,667,668,669,670,671,672 -- TCPCV
        , 224701 -- PSVlevel
        )
        THEN 1
      else 0
    end
    ) as MechVent
  from mimiciii.CHARTEVENTS ce
  where ce.value is not null
  -- exclude rows marked as error
  and ce.error IS DISTINCT FROM 1
  group by subject_id, hadm_id, icustay_id, charttime