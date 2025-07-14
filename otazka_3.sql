--- Otázka 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?


WITH ceny_s_predchozi AS (
    SELECT
        kategorie,
        rok,	
        prumerna_cena,
        LAG(prumerna_cena) OVER (PARTITION BY kategorie ORDER BY rok) AS predchozi_cena
    FROM v_prumerne_ceny_potravin
),
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
prumerne_rusty AS (
    SELECT
        kategorie,
        ROUND(AVG(mezirocni_zmena_procenta)::numeric, 2) AS prumerny_mezirocni_rust_cen
    FROM mezirocni_zmeny_cen
    WHERE mezirocni_zmena_procenta IS NOT NULL
    GROUP BY kategorie
)
--Finální select, seřazeno od nejpomalejšího růstu cen (ve skutečnosti pokles ceny)
SELECT 
    kategorie, 
    prumerny_mezirocni_rust_cen
FROM prumerne_rusty
ORDER BY prumerny_mezirocni_rust_cen ASC
;