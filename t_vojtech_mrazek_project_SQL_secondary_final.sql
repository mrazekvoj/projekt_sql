--- Tabulka s HDP, GINI koeficientem a populací dalších evropských států ve stejném období, jako primární přehled pro ČR.

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