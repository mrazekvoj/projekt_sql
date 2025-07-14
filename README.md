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

1. [📈 Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?](./q1_wages_by_industry.sql)


2. 
3. [🍞 How many units of selected food items could be bought for the average wage?](./q2_food_units_per_wage.sql)
4. [📉 Which food items increased in price the slowest (or decreased)?](./q3_slowest_rising_foods.sql)
5. [💰 Did wages grow faster than food prices?](./q4_wage_vs_food_growth.sql)
6. [🌍 Correlation between GDP, wages, and prices](./q5_correlation_macro.sql)
