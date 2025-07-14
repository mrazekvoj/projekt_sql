---Otázka 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT 
    pc.kategorie,
    pm.rok,
    pm.prumerna_mzda,
    pc.prumerna_cena AS prumerna_cena_jednotka,
    ROUND(pm.prumerna_mzda / pc.prumerna_cena) AS moznost_koupit_jednotek,
    cpc.price_unit AS jednotka
FROM v_prumerne_mzdy_celkem pm
JOIN v_prumerne_ceny_potravin pc 
	ON pm.rok = pc.rok
JOIN czechia_price_category cpc 
	ON pc.kategorie = cpc.name
WHERE pc.kategorie IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
  AND pm.rok IN (
    (SELECT MIN(rok) FROM v_prumerne_ceny_potravin),
    (SELECT MAX(rok) FROM v_prumerne_ceny_potravin)
)
ORDER BY pc.kategorie, pm.rok;