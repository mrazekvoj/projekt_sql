 ## Final SQL project for ENGETO Data Academy 
Wages, Food Prices, and Economic Indicators in Czechia and Europe


## Project Overview
Tento projekt se věnuje dostupnosti potravin na základě průměrných příjmů za určité časové období. Jeho cílem je vytvořit dvě robustní tabulky, ve kterých je možné porovnávat relevantní data, a také odpovědět na pět výzkumných otázek.

V souladu se zadáním byly vytvořeny dvě robustní tabulky:
- [`t_vojtech_mrazek_project_SQL_primary_final.sql`](./t_vojtech_mrazek_project_SQL_primary_final.sql) – Mzdy a ceny potravin za Českou republiku sjednocené na totožné porovnatelné období – společné roky
- [`t_vojtech_mrazek_project_SQL_secondary_final.sql`](./t_vojtech_mrazek_project_SQL_secondary_final.sql) – Tabulka s HDP, GINI koeficientem a populací dalších evropských států ve stejném období jako primární přehled pro ČR

## Views Used in the Project
Projekt využívá několika views, které zpřehledňují zápis a zamezují zbytečnému opakování některých částí kódu:

- `v_prumerne_mzdy_celkem`
- `v_prumerne_ceny_potravin`
- `v_mezirocni_zmena_mzdy_celkem`
- `v_mezirocni_zmeny_ceny_potravin`
- `v_mezirocni_zmeny_HDP`
- `v_prumerne_mzdy_odvetvi`

Kompletní zápis je k dispozici ve [`views.sql`](./views.sql).

## Questions Answered
Každá z otázek je zodpovězena v odděleném SQL skriptu:

1. [📈 Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?](./otazka_1.sql)

 Z tabulky Meziroční změny mezd podle odvětví, bez agregace je patrné, že v některých letech mzdy v určitých odvětvích klesaly. Tabulka Přehled vývoje průměrných mezd podle odvětví nám pak dává přehlednější souhrnná data, včetně let, kdy došlo k největšímu růstu a největšímu poklesu. Existují odvětví, u kterých mzdy nikdy meziročně nepoklesly, např. zdravotní a         sociální péče, zpracovatelský průmysl. Činnosti v oblasti nemovitostí např. rekordně poklesly v prvním covidovém roce, většina ostatních odvětví pak rekordně poklesla v roce 2013, kdy vrcholila úsporná opatření Nečasovy vlády.

2. [🍞 Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?](./otazka_2.sql)

 V roce 2006 bylo možné za průměrnou mzdu koupit ročně 1 292 kg chleba (chléb konzumní kmínový), v roce 2018 pak 1 354 kg. Za průměrnou mzdu bylo v roce 2006 možné pořídit 
 1 477 litrů mléka (mléko polotučné pasterované), v roce 2018 to bylo 1 624 litrů.

3. [📉 Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?](./otazka_3.sql)

 Nejpomaleji zdražoval cukr krystalový – jeho cena v porovnávaných letech průměrně meziročně klesala o dvě procenta. Podobně průměrně meziročně klesala i cena rajčat (-0,83 %).

4. [💰 Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?](./otazka_4.sql)

 Podle dat neexistuje. Nejvyšší rozdíl byl v roce 2013, a to 7,15 %.

5. [🌍 Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?](./otazka_5.sql) 

 Vypočítaná korelace mezi HDP na obyvatele a průměrnými cenami potravin v ČR v letech 2000–2021 je 0,85 (Pearsonův korelační koeficient). S růstem HDP na obyvatele obvykle rostly i ceny potravin. Korelace mezi HDP na obyvatele a průměrnými mzdami ve stejném období je 0,44, což značí středně silný vztah – růst HDP tedy nebyl vždy provázen stejně výrazným růstem mezd.    Údaje za jednotlivé roky jsou dostupné v podrobné tabulce níže.
