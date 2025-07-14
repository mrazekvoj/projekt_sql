CREATE VIEW v_prumerne_mzdy_celkem AS
SELECT 
    payroll_year AS rok,
    ROUND(AVG(value)::numeric, 2) AS prumerna_mzda
FROM czechia_payroll
WHERE value_type_code = 5958
    AND value IS NOT NULL
GROUP BY payroll_year;
---
CREATE VIEW v_prumerne_ceny_potravin AS
SELECT 
    cpc.name AS kategorie,
    EXTRACT(YEAR FROM cp.date_to)::int AS rok,
    ROUND(AVG(cp.value)::numeric, 2) AS prumerna_cena
FROM czechia_price cp
JOIN czechia_price_category cpc 
	ON cp.category_code = cpc.code
WHERE cp.value IS NOT NULL
GROUP BY cpc.name, EXTRACT(YEAR FROM cp.date_to);
---
CREATE VIEW v_mezirocni_zmena_mzdy_celkem AS
SELECT 
    rok,
    prumerna_mzda,
    ROUND(
        (
            100.0 * (prumerna_mzda - LAG(prumerna_mzda) OVER (ORDER BY rok))
            / NULLIF(LAG(prumerna_mzda) OVER (ORDER BY rok), 0)
        )::numeric, 2
    ) AS mezirocni_zmena_mzdy_procenta
FROM v_prumerne_mzdy_celkem;
---
CREATE VIEW v_mezirocni_zmeny_ceny_potravin AS
WITH
ceny AS (
    SELECT 
        EXTRACT(YEAR FROM cp.date_to)::int AS rok,
        ROUND(AVG(cp.value)::numeric, 2) AS prumerna_cena
    FROM czechia_price cp
    WHERE cp.value IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM cp.date_to)
    )
    SELECT
        rok,
        prumerna_cena,
        ROUND(
            100.0 * (prumerna_cena - LAG(prumerna_cena) OVER (ORDER BY rok))
            / NULLIF(LAG(prumerna_cena) OVER (ORDER BY rok), 0),
            2
        ) AS mezirocni_zmena_cen_procenta
    FROM ceny
 ;
---
CREATE VIEW v_mezirocni_zmeny_HDP AS
WITH hdp AS (
    SELECT 
        year AS rok,
        ROUND((gdp / population)::numeric) AS hdp_per_capita_nominalni,
        LAG(ROUND((gdp / population)::numeric)) OVER (ORDER BY year) AS predchozi_hdp_per_capita
    FROM economies
    WHERE country = 'Czech Republic'
      AND year BETWEEN 2000 AND 2021
)    SELECT
        rok,
        hdp_per_capita_nominalni,
        ROUND(
            100.0 * (hdp_per_capita_nominalni::numeric - predchozi_hdp_per_capita::numeric)
            / NULLIF(predchozi_hdp_per_capita::numeric, 0),
            2
        ) AS mezirocni_zmena_hdp_procenta
    FROM hdp
;
