--- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

--- Meziroční změny mezd podle odvětví, bez agregace 

SELECT
    odvetvi,
    rok,
    prumerna_mzda,
    prumerna_mzda - LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok) AS mezirocni_zmena,
    ROUND(
        ((prumerna_mzda - LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok))
        / LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok)) * 100, 2
    ) AS mezirocni_zmena_procenta
FROM v_prumerne_mzdy_odvetvi
ORDER BY odvetvi, rok;

--- Přehled vývoje průměrných mezd podle odvětví.

WITH 
mezirocni_zmeny AS (
    SELECT
        odvetvi,
        rok,
        prumerna_mzda,
        prumerna_mzda - LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok) AS mezirocni_zmena,
        ROUND(
            ((prumerna_mzda - LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok))
            / LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok)) * 100, 2
        ) AS mezirocni_zmena_procenta,
        FIRST_VALUE(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok) AS mzda_2000,
        LAST_VALUE(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS mzda_2021
    FROM v_prumerne_mzdy_odvetvi
),
agg AS (
    SELECT
        odvetvi,
        MAX(mezirocni_zmena_procenta) AS max_mezirocni_zmena,
        MIN(mezirocni_zmena_procenta) AS min_mezirocni_zmena,
        ROUND(AVG(mezirocni_zmena_procenta), 2) AS prumerna_mezirocni_zmena,
        MAX(mzda_2021) AS mzda_2021,
        MAX(mzda_2000) AS mzda_2000
    FROM mezirocni_zmeny
    GROUP BY odvetvi
),
roky_max_min AS (
    SELECT
        odvetvi,
        MAX(CASE WHEN mezirocni_zmena_procenta = max_mezirocni_zmena THEN rok END) AS rok_max_mezirocni_zmena,
        MAX(CASE WHEN mezirocni_zmena_procenta = min_mezirocni_zmena THEN rok END) AS rok_min_mezirocni_zmena
    FROM mezirocni_zmeny
    JOIN agg USING (odvetvi)
    GROUP BY odvetvi
)
SELECT
    a.odvetvi,  
    a.max_mezirocni_zmena,
    r.rok_max_mezirocni_zmena,
    a.min_mezirocni_zmena,
    r.rok_min_mezirocni_zmena,
    a.prumerna_mezirocni_zmena,
    a.mzda_2000,
    a.mzda_2021,
    ROUND(((a.mzda_2021 - a.mzda_2000)::numeric / a.mzda_2000) * 100, 2) AS procentni_narust --- procentní nárůst mezi 2000 a 2021
FROM agg a
JOIN roky_max_min r USING (odvetvi)
ORDER BY procentni_narust  DESC;