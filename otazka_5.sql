--- Otázka 5: Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

SELECT 
    h.rok,
    h.mezirocni_zmena_hdp_procenta,
    m.mezirocni_zmena_mzdy_procenta,
    c.mezirocni_zmena_cen_procenta,
   ROUND(h.mezirocni_zmena_hdp_procenta - c.mezirocni_zmena_cen_procenta, 2) AS rozdil_hdp_vs_ceny,
ROUND(m.mezirocni_zmena_mzdy_procenta - h.mezirocni_zmena_hdp_procenta, 2) AS rozdil_mzdy_vs_hdp,
ROUND(m.mezirocni_zmena_mzdy_procenta - c.mezirocni_zmena_cen_procenta, 2) AS rozdil_mzdy_vs_ceny,
-- Porovnání HDP vs. ceny
CASE 
    WHEN h.mezirocni_zmena_hdp_procenta > c.mezirocni_zmena_cen_procenta 
        THEN 'HDP rostl rychleji než ceny'
    WHEN h.mezirocni_zmena_hdp_procenta < c.mezirocni_zmena_cen_procenta 
        THEN 'Ceny rostly rychleji než HDP'
    WHEN h.mezirocni_zmena_hdp_procenta = c.mezirocni_zmena_cen_procenta 
        THEN 'Stejný růst'
    ELSE 'Nelze srovnávat'
END AS porovnani_hdp_vs_ceny,
-- Porovnání mzdy vs. HDP
CASE 
    WHEN m.mezirocni_zmena_mzdy_procenta > h.mezirocni_zmena_hdp_procenta 
        THEN 'Mzdy rostly rychleji než HDP'
    WHEN m.mezirocni_zmena_mzdy_procenta < h.mezirocni_zmena_hdp_procenta 
        THEN 'HDP rostl rychleji než mzdy'
    WHEN m.mezirocni_zmena_mzdy_procenta = h.mezirocni_zmena_hdp_procenta 
        THEN 'Stejný růst'
    ELSE 'Nelze srovnávat'
END AS porovnani_mzdy_vs_hdp,
-- Porovnání mzdy vs. ceny
CASE 
    WHEN m.mezirocni_zmena_mzdy_procenta > c.mezirocni_zmena_cen_procenta 
        THEN 'Mzdy rostly rychleji než ceny'
    WHEN m.mezirocni_zmena_mzdy_procenta < c.mezirocni_zmena_cen_procenta 
        THEN 'Ceny rostly rychleji než mzdy'
    WHEN m.mezirocni_zmena_mzdy_procenta = c.mezirocni_zmena_cen_procenta 
        THEN 'Stejný růst'
    ELSE 'Nelze srovnávat'
END AS porovnani_mzdy_vs_ceny
FROM v_mezirocni_zmeny_HDP h
JOIN v_mezirocni_zmena_mzdy_celkem m USING (rok)
JOIN v_mezirocni_zmeny_ceny_potravin c USING (rok)
ORDER BY h.rok;

-- korelace HDP vs. prumerne ceny
SELECT 
    corr(h.hdp_per_capita_nominalni, c.prumerna_cena) AS korelace_hdp_vs_ceny
FROM v_mezirocni_zmeny_HDP h
JOIN v_mezirocni_zmeny_ceny_potravin c 
    ON h.rok = c.rok
WHERE h.hdp_per_capita_nominalni IS NOT NULL
  AND c.prumerna_cena IS NOT NULL;

-- korelace HDP vs. mzdy
SELECT 
    corr(h.mezirocni_zmena_hdp_procenta, m.mezirocni_zmena_mzdy_procenta) AS korelace_hdp_vs_mzdy
FROM v_mezirocni_zmeny_HDP h
JOIN v_mezirocni_zmena_mzdy_celkem m 
	ON h.rok = m.rok
WHERE h.mezirocni_zmena_hdp_procenta IS NOT NULL
  AND m.mezirocni_zmena_mzdy_procenta IS NOT NULL;