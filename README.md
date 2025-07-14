## Final SQL project for ENGETO Data Academy 
Wages, Food Prices, and Economic Indicators in Czechia and Europe


## Project Overview
Tento projekt se věnuje dostupnosti potravin na základě průměrných příjmů za určité časové období. Jeho cílem je vytvořit dvě robustní tabulky, ve kterých je možné porovnávat relevantní data, a také odpovědět na pět výzkumných otázek.

Dvě robustní taublky byly vytvořeny:
- [`t_vojtech_mrazek_project_SQL_primary_final.sql`](./t_vojtech_mrazek_project_SQL_primary_final.sql) – Mzdy a ceny potravin za Českou republiku sjednocené na totožné porovnatelné období – společné roky
- [`t_vojtech_mrazek_project_SQL_secondary_final.sql`](./t_vojtech_mrazek_project_SQL_secondary_final.sql) – Tabulka s HDP, GINI koeficientem a populací dalších evropských států ve stejném období jako primární přehled pro ČR

## Views Used in the Project
Projekt využívá několika views, které zpřehledňují zápis a zamezují opakování:

- `v_prumerne_mzdy_celkem`
- `v_prumerne_ceny_potravin`
- `v_mezirocni_zmena_mzdy_celkem`
- `v_mezirocni_zmeny_ceny_potravin`
- `v_mezirocni_zmeny_HDP`
- `v_prumerne_mzdy_odvetvi`

Kompletní zápis views je k dispozici ve [`views.sql`](./views.sql).

## Questions Answered
Každá z otázek je zodpovězena v odděleném SQL skriptu:

1. [📈 Evolution of average wages by industry](./q1_wages_by_industry.sql)
2. [🍞 How many units of selected food items could be bought for the average wage?](./q2_food_units_per_wage.sql)
3. [📉 Which food items increased in price the slowest (or decreased)?](./q3_slowest_rising_foods.sql)
4. [💰 Did wages grow faster than food prices?](./q4_wage_vs_food_growth.sql)
5. [🌍 Correlation between GDP, wages, and prices](./q5_correlation_macro.sql)

## 🗃 Final Output Tables
SQL definitions for final unified data tables:

- [`final_primary_table.sql`](./final_primary_table.sql)
- [`final_secondary_table.sql`](./final_secondary_table.sql)




t_vojtech_mrazek_project_SQL_primary_final

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
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code
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
    JOIN czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code
    WHERE cp.value IS NOT NULL AND cp.value_type_code = 5958
    GROUP BY rok, cpib.name
)
SELECT * FROM ceny
UNION ALL
SELECT * FROM mzdy_odvetvi
ORDER BY rok, zdroj, kategorie_potraviny, odvetvi;

---

t_vojtech_mrazek_project_SQL_secondary_final

CREATE TABLE t_vojtech_mrazek_project_SQL_secondary_final AS
SELECT 
    c.country,
    e.year AS rok,
    ROUND(e.gdp)::numeric AS hdp,
    e.gini,
    e.population,
    ROUND((e.gdp / NULLIF(e.population, 0))::numeric) AS hdp_per_capita_nominalni
FROM countries c
JOIN economies e 
    ON c.country = e.country
WHERE c.continent = 'Europe'
  AND e.year BETWEEN 2000 AND 2021
ORDER BY c.country, e.year;

-- Uvahy k t_vojtech_mrazek_project_SQL_secondary_final:

SELECT DISTINCT e.country, c.region_in_world, c.country
FROM countries c
LEFT JOIN economies e ON e.country = c.country --- LEFT JOIN je zbytečný, země, které nejsou v tabulce economies, nejsou relevantní
WHERE c.continent = 'Europe' --- je relevantní srvonávat v rámci Evropy
ORDER BY e.country;

---

--- 1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají? Z tabulky 1 je patrné, že v některých letech mzdy v určitých odvětvích klesaly. Tabulka 2 nám pak dává přehlednější souhrnná data, včetně let, kdy došlo k největšímu růstu a největšímu poklesu. Existují odvětví, u kterých mzdy nikdy meziročně nepoklesly, např. zdravotní a sociální péče, zpracovatelský průmysl. Činnosti v oblasti nemovitostí např. rekordně poklesly v prvním covidovém roce, většina ostatních odvětví pak rekordně poklesla v roce 2013, kdy vrcholila úsporná opatření Nečasovy vlády.


-- Tabulka 1: Meziroční změna, bez agregace. 

WITH prumerne_mzdy AS (
    SELECT 
        cpib.name AS odvetvi,
        cp.payroll_year AS rok,
    round(AVG(cp.value)) AS prumerna_mzda
    FROM czechia_payroll cp 
    JOIN czechia_payroll_industry_branch cpib
        ON cp.industry_branch_code = cpib.code
    WHERE cp.value_type_code = 5958
        AND cp.value IS NOT NULL
    GROUP BY cpib.name, cp.payroll_year
)
SELECT
    odvetvi,
    rok,
    prumerna_mzda,
    prumerna_mzda - LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok) AS mezirocni_zmena,
    ROUND(
        ((prumerna_mzda - LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok))
        / LAG(prumerna_mzda) OVER (PARTITION BY odvetvi ORDER BY rok)) * 100, 2
    ) AS mezirocni_zmena_procenta
FROM prumerne_mzdy
ORDER BY odvetvi, rok;

-- Tabulka 2: Přehled vývoje průměrných mezd podle odvětví s agregacemi

-- Průměrně roční mzda podle odvětví:
WITH prumerne_mzdy AS (
    SELECT 
        cpib.name AS odvetvi,
        cp.payroll_year AS rok,
        ROUND(AVG(cp.value)) AS prumerna_mzda
    FROM czechia_payroll cp 
    JOIN czechia_payroll_industry_branch cpib
        ON cp.industry_branch_code = cpib.code
    WHERE cp.value_type_code = 5958
        AND cp.value IS NOT NULL
    GROUP BY cpib.name, cp.payroll_year
),
-- Procentní meziroční změny, mzda v roce 2000, mzda v roce 2021 (začátek a konec sběru dat)
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
    FROM prumerne_mzdy
),
-- Agregační funkce
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
--Roky, kdy byl nejvyšší meziroční růst mezd, případně nejvyšší pokles/nejnižší růst
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

---

--- 2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd? V roce 2006 bylo možné za průměrnou mzdu koupit ročně 1 292 kg chleba (chléb konzumní kmínový), v roce 2018 pak 1 354 kg. Za průměrnou mzdu bylo v roce 2006 možné pořídit 1 477 litrů mléka (mléko polotučné pasterované), v roce 2018 to bylo 1 624 litrů.

--Prumerne mzdy podle roku
WITH prumerne_mzdy AS (
    SELECT 
        payroll_year AS rok,
        ROUND(AVG(value), 2) AS prumerna_mzda
    FROM czechia_payroll
    WHERE value_type_code = 5958
        AND value IS NOT NULL
    GROUP BY payroll_year
),
--Prumerne ceny potravin podle roku (mléko a chléb)
prumerne_ceny AS (
   SELECT 
    cpc.name AS kategorie,
    EXTRACT(YEAR FROM cp.date_to) AS rok,
    ROUND(AVG(value)) AS prumerna_cena
FROM czechia_price cp
JOIN czechia_price_category cpc
    ON cp.category_code = cpc.code
WHERE cpc.name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
GROUP BY cpc.name, rok
ORDER BY kategorie, rok
)
--Výpočet množství zboží, které bylo možné koupit za průměrnou mzdu v daném roce (první a poslední srovnatelné období)
SELECT 
    pc.kategorie,
    pm.rok,
    pm.prumerna_mzda,
    pc.prumerna_cena AS prumerna_cena_jednotka,
    round(pm.prumerna_mzda / pc.prumerna_cena) AS moznost_koupit_jednotek,
    cpc.price_unit AS jednotka
FROM prumerne_mzdy pm
JOIN prumerne_ceny pc ON pm.rok = pc.rok
JOIN czechia_price_category cpc ON pc.kategorie = cpc.name -- připojeny jednotky (kg a l)
WHERE pm.rok IN (
    (SELECT MIN(rok) FROM prumerne_ceny),
    (SELECT MAX(rok) FROM prumerne_ceny) --filtr min. a max. srovnatelného roku
)
ORDER BY pc.kategorie, pm.rok;

 ---

--- 3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? Nejpomaleji zdražoval cukr krystalový – jeho cena v porovnávaných letech průměrně meziročně klesala o dvě procenta. Podobně průměrně meziročně klesala i cena rajčat (–0,83 %).

--prumerne ceny potravin podle roku a katergorie
WITH prumerne_ceny AS (
    SELECT 
        cpc.name AS kategorie,
        EXTRACT(YEAR FROM cp.date_to) AS rok,
        ROUND(AVG(value)) AS prumerna_cena
    FROM czechia_price cp
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    GROUP BY cpc.name, EXTRACT(YEAR FROM cp.date_to)
),
--ceny za predchozi rok
ceny_s_predchozi AS (
    SELECT
        kategorie,
        rok,
        prumerna_cena,
        LAG(prumerna_cena) OVER (PARTITION BY kategorie ORDER BY rok) AS predchozi_cena
    FROM prumerne_ceny
),
--procentuální změny cen mezi roky
mezirocni_zmeny_cen AS (
SELECT
    kategorie,
    rok,
    prumerna_cena,
    predchozi_cena,
        round(100.0 * (prumerna_cena - predchozi_cena) / NULLIF(predchozi_cena, 0))
      AS mezirocni_zmena_procenta
FROM ceny_s_predchozi
ORDER BY kategorie, rok
),
--průměr meziročního růstu
prumerne_rusty AS (
    SELECT
        kategorie,
        ROUND(AVG(mezirocni_zmena_procenta)::numeric, 2) AS prumerny_mezirocni_rust_cen
    FROM mezirocni_zmeny_cen
    WHERE mezirocni_zmena_procenta IS NOT NULL
    GROUP BY kategorie
)
--finální select, seřazení od nejpomalejšího růstu cen (ve skutečnosti pokles ceny)
SELECT 
    kategorie, 
    prumerny_mezirocni_rust_cen
FROM prumerne_rusty
ORDER BY prumerny_mezirocni_rust_cen ASC
;

---


--- 4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)? Podle dat neexistuje. Nejvyšší rozdíl byl v roce 2013, a to 7,15 %.

--prumerne ceny potravin podle roku
WITH prumerne_ceny AS (
    SELECT 
        EXTRACT(YEAR FROM cp.date_to)::int AS rok,
        ROUND(AVG(value)) AS prumerna_cena
    FROM czechia_price cp
    GROUP BY EXTRACT(YEAR FROM cp.date_to)
),
--Průměrné mzdy podle roku
Prumerne_mzdy AS (
    SELECT 
        payroll_year AS rok,
        ROUND(AVG(value)) AS prumerna_mzda
    FROM czechia_payroll
    WHERE value_type_code = 5958
        AND value IS NOT NULL
    GROUP BY payroll_year
),
--Meziroční růst cen potravin
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
--Meziroční růst mezd
mzdy_s_rustem AS (
    SELECT 
        rok,
        prumerna_mzda,
        ROUND(
            (
                100.0 * (prumerna_mzda - LAG(prumerna_mzda) OVER (ORDER BY rok))
                / NULLIF(LAG(prumerna_mzda) OVER (ORDER BY rok), 0)
            )::numeric, 2
        ) AS rust_mezd_procenta
    FROM prumerne_mzdy
),
--Rozdíl meziročního růstu cen a mezd
porovnani AS (
    SELECT 
        c.rok,
        c.rust_cen_potravin_procenta,
        m.rust_mezd_procenta,
        ROUND((c.rust_cen_potravin_procenta - m.rust_mezd_procenta)::numeric, 2) AS rozdil_procenta
    FROM ceny_s_rustem c
    JOIN mzdy_s_rustem m ON c.rok = m.rok
)
--Finální selekt, seřazeno podle rozdílu mezi růstem mezd a potravin, řádný srovnatelný rok to nebylo více než 10 %
SELECT *
FROM porovnani
WHERE rozdil_procenta IS NOT NULL
ORDER BY rozdil_procenta DESC;

---

--- 5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem? Vypočítaná korelace mezi HDP na obyvatele a průměrnými cenami potravin v ČR v letech 2000–2021 je 0,85 (Pearsonův korelační koeficient). S růstem HDP na obyvatele obvykle rostly i ceny potravin. Korelace mezi HDP na obyvatele a průměrnými mzdami ve stejném období je 0,44, což značí středně silný vztah – růst HDP tedy nebyl vždy provázen stejně výrazným růstem mezd. Údaje za jednotlivé roky jsou dostupné v podrobné tabulce níže.


-- Srovnání meziročního růstu HDP, mezd a cen – podrobná tabulka
WITH hdp AS (
    SELECT 
        year AS rok,
        ROUND((gdp / population)::numeric) AS hdp_per_capita_nominalni,
        LAG(ROUND((gdp / population)::numeric)) OVER (ORDER BY year) AS predchozi_hdp_per_capita
    FROM economies
    WHERE country = 'Czech Republic'
      AND year BETWEEN 2000 AND 2021
),
hdp_zmeny AS (
    SELECT
        rok,
        hdp_per_capita_nominalni,
        ROUND(
            100.0 * (hdp_per_capita_nominalni::numeric - predchozi_hdp_per_capita::numeric)
            / NULLIF(predchozi_hdp_per_capita::numeric, 0),
            2
        ) AS mezirocni_zmena_hdp_procenta
    FROM hdp
),
mzdy AS (
    SELECT 
        payroll_year AS rok,
        ROUND(AVG(value)::numeric) AS prumerna_mzda
    FROM czechia_payroll
    WHERE value_type_code = 5958
        AND value IS NOT NULL
    GROUP BY payroll_year
),
mzdy_zmeny AS (
    SELECT
        rok,
        prumerna_mzda,
        ROUND(
            100.0 * (prumerna_mzda - LAG(prumerna_mzda) OVER (ORDER BY rok))
            / NULLIF(LAG(prumerna_mzda) OVER (ORDER BY rok), 0),
            2
        ) AS mezirocni_zmena_mzdy_procenta
    FROM mzdy
),
ceny AS (
    SELECT 
        EXTRACT(YEAR FROM cp.date_to)::int AS rok,
        ROUND(AVG(cp.value)::numeric, 2) AS prumerna_cena
    FROM czechia_price cp
    WHERE cp.value IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM cp.date_to)
),
ceny_zmeny AS (
    SELECT
        rok,
        prumerna_cena,
        ROUND(
            100.0 * (prumerna_cena - LAG(prumerna_cena) OVER (ORDER BY rok))
            / NULLIF(LAG(prumerna_cena) OVER (ORDER BY rok), 0),
            2
        ) AS mezirocni_zmena_cen_procenta
    FROM ceny
)
SELECT 
    h.rok,
    h.mezirocni_zmena_hdp_procenta,
    m.mezirocni_zmena_mzdy_procenta,
    c.mezirocni_zmena_cen_procenta,
   ROUND(h.mezirocni_zmena_hdp_procenta - c.mezirocni_zmena_cen_procenta, 2) AS rozdil_hdp_vs_ceny,
ROUND(m.mezirocni_zmena_mzdy_procenta - h.mezirocni_zmena_hdp_procenta, 2) AS rozdil_mzdy_vs_hdp,
ROUND(m.mezirocni_zmena_mzdy_procenta - c.mezirocni_zmena_cen_procenta, 2) AS rozdil_mzdy_vs_ceny,
--Porovnání HDP vs. ceny
CASE 
    WHEN h.mezirocni_zmena_hdp_procenta > c.mezirocni_zmena_cen_procenta 
        THEN 'HDP rostl rychleji než ceny'
    WHEN h.mezirocni_zmena_hdp_procenta < c.mezirocni_zmena_cen_procenta 
        THEN 'Ceny rostly rychleji než HDP'
    WHEN h.mezirocni_zmena_hdp_procenta = c.mezirocni_zmena_cen_procenta 
        THEN 'Stejný růst'
    ELSE 'Nelze srovnávat'
END AS porovnani_hdp_vs_ceny,
--Porovnání mzdy vs. HDP
CASE 
    WHEN m.mezirocni_zmena_mzdy_procenta > h.mezirocni_zmena_hdp_procenta 
        THEN 'Mzdy rostly rychleji než HDP'
    WHEN m.mezirocni_zmena_mzdy_procenta < h.mezirocni_zmena_hdp_procenta 
        THEN 'HDP rostl rychleji než mzdy'
    WHEN m.mezirocni_zmena_mzdy_procenta = h.mezirocni_zmena_hdp_procenta 
        THEN 'Stejný růst'
    ELSE 'Nelze srovnávat'
END AS porovnani_mzdy_vs_hdp,
--Porovnání mzdy vs. ceny
CASE 
    WHEN m.mezirocni_zmena_mzdy_procenta > c.mezirocni_zmena_cen_procenta 
        THEN 'Mzdy rostly rychleji než ceny'
    WHEN m.mezirocni_zmena_mzdy_procenta < c.mezirocni_zmena_cen_procenta 
        THEN 'Ceny rostly rychleji než mzdy'
    WHEN m.mezirocni_zmena_mzdy_procenta = c.mezirocni_zmena_cen_procenta 
        THEN 'Stejný růst'
    ELSE 'Nelze srovnávat'
END AS porovnani_mzdy_vs_ceny
FROM hdp_zmeny h
JOIN mzdy_zmeny m USING (rok)
JOIN ceny_zmeny c USING (rok)
ORDER BY h.rok;

-- Korelace HDP vs. prumerne ceny

SELECT 
    corr(h.hdp_per_capita_nominalni, c.prumerna_cena) AS korelace_hdp_vs_ceny
FROM (
    SELECT 
        year AS rok,
        ROUND((gdp / population)::numeric) AS hdp_per_capita_nominalni
    FROM economies
    WHERE country = 'Czech Republic'
      AND year BETWEEN 2000 AND 2021
) h
JOIN (
    SELECT 
        EXTRACT(YEAR FROM cp.date_to) AS rok,
        ROUND(AVG(cp.value)::numeric) AS prumerna_cena
    FROM czechia_price cp
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code
    GROUP BY EXTRACT(YEAR FROM cp.date_to)
) c ON h.rok = c.rok;


--- korelace HDP vs. mzdy

WITH hdp AS (
    SELECT 
        year AS rok,
        ROUND((gdp / population)::numeric) AS hdp_per_capita_nominalni,
        LAG(ROUND((gdp / population)::numeric)) OVER (ORDER BY year) AS predchozi_hdp_per_capita
    FROM economies
    WHERE country = 'Czech Republic'
      AND year BETWEEN 2000 AND 2021
),
hdp_zmeny AS (
    SELECT
        rok,
        hdp_per_capita_nominalni,
        ROUND(
            100.0 * (hdp_per_capita_nominalni - predchozi_hdp_per_capita)
            / NULLIF(predchozi_hdp_per_capita, 0),
            2
        ) AS mezirocni_zmena_hdp_procenta
    FROM hdp
),
mzdy AS (
    SELECT 
        payroll_year AS rok,
        ROUND(AVG(value)::numeric) AS prumerna_mzda
    FROM czechia_payroll
    WHERE value_type_code = 5958
        AND value IS NOT NULL
        AND payroll_year BETWEEN 2000 AND 2021
    GROUP BY payroll_year
),
mzdy_zmeny AS (
    SELECT
        rok,
        prumerna_mzda,
        ROUND(
            100.0 * (prumerna_mzda - LAG(prumerna_mzda) OVER (ORDER BY rok))
            / NULLIF(LAG(prumerna_mzda) OVER (ORDER BY rok), 0),
            2
        ) AS mezirocni_zmena_mzdy_procenta
    FROM mzdy
)
SELECT 
    corr(h.mezirocni_zmena_hdp_procenta, m.mezirocni_zmena_mzdy_procenta) AS korelace_hdp_vs_mzdy
FROM hdp_zmeny h
JOIN mzdy_zmeny m ON h.rok = m.rok
WHERE h.mezirocni_zmena_hdp_procenta IS NOT NULL
  AND m.mezirocni_zmena_mzdy_procenta IS NOT NULL;
