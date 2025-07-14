--- Otázka 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?


WITH prumerne_ceny AS (
    SELECT 
        EXTRACT(YEAR FROM cp.date_to)::int AS rok,
        ROUND(AVG(value)) AS prumerna_cena
    FROM czechia_price cp
    GROUP BY EXTRACT(YEAR FROM cp.date_to)
),
ceny_s_rustem AS (
    SELECT 
        rok,
        prumerna_cena,
        ROUND(
            (
                100.0 * (prumerna_cena - LAG(prumerna_cena) OVER (ORDER BY rok))
                / NULLIF(LAG(prumerna_cena) OVER (ORDER BY rok), 0)
            )::numeric, 2
        ) AS rust_cen_potravin_procenta
    FROM prumerne_ceny
),
porovnani AS (
    SELECT 
        c.rok,
        c.rust_cen_potravin_procenta,
        m.mezirocni_zmena_mzdy_procenta AS rust_mezd_procenta,
        ROUND((c.rust_cen_potravin_procenta - m.mezirocni_zmena_mzdy_procenta)::numeric, 2) AS rozdil_procenta
    FROM ceny_s_rustem c
    JOIN v_mezirocni_zmena_mzdy_celkem m 
    	ON c.rok = m.rok
)
SELECT *
FROM porovnani
WHERE rozdil_procenta IS NOT NULL
ORDER BY rozdil_procenta DESC;