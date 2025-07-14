--- Tabulka pro data mezd a cen potravin za Českou republiku sjednocených na totožné porovnatelné období – společné roky

CREATE TABLE t_vojtech_mrazek_project_SQL_primary_final AS
WITH ceny AS (
    SELECT 
        EXTRACT(YEAR FROM cp.date_to) AS rok,
        cpc.name AS kategorie_potraviny,
        ROUND(AVG(cp.value)::numeric, 2) AS prumerna_cena,
        cpc.price_unit AS jednotka,
        NULL::text AS odvetvi,
        NULL::numeric AS prumerna_mzda,
        'cena_potravin' AS zdroj
    FROM czechia_price cp
    JOIN czechia_price_category cpc 
    	ON cp.category_code = cpc.code
    WHERE cp.value IS NOT NULL
    GROUP BY rok, cpc.name, cpc.price_unit
),
mzdy_odvetvi AS (
    SELECT 
        cp.payroll_year AS rok,
        NULL::text AS kategorie_potraviny,
        NULL::numeric AS prumerna_cena,
        NULL::text AS jednotka,
        cpib.name AS odvetvi,
        ROUND(AVG(cp.value)::numeric, 2) AS prumerna_mzda,
        'mzda_odvetvi' AS zdroj
    FROM czechia_payroll cp
    JOIN czechia_payroll_industry_branch cpib 
    	ON cp.industry_branch_code = cpib.code
    WHERE cp.value IS NOT NULL AND cp.value_type_code = 5958
    GROUP BY rok, cpib.name
)
SELECT * FROM ceny
UNION ALL
SELECT * FROM mzdy_odvetvi
ORDER BY rok, zdroj, kategorie_potraviny, odvetvi;
