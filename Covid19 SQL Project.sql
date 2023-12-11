--COVIDDEATHS DATA

SELECT *
FROM Covid19Project..CovidDeaths;


-- COVIDVACCINATIONS DATA

SELECT *
FROM Covid19Project..CovidVaccinations;


-- SELECTING THE DATASET INTENDED FOR THE COVIDDEATHS ANALYSIS

SELECT continent, location, date, population, new_cases, total_cases, total_deaths, new_deaths
FROM Covid19Project..CovidDeaths;


-- SELECTING THE DATASET INTENDED FOR THE COVIDVACCINATIONS ANALYSIS

SELECT continent, location, date, new_vaccinations, total_vaccinations
FROM Covid19Project..CovidVaccinations


-- JOINING COVIDDEATHS AND COVIDVACCINATIONS, SELECTING THE INTENDED COLUMNS FOR ANALYSIS

SELECT death.continent, death.location, death.date, death.population, death.new_cases, death.total_cases, 
		death.new_deaths, death.total_deaths, vacc.new_vaccinations, vacc.total_vaccinations
FROM Covid19Project..CovidDeaths death
JOIN Covid19Project..CovidVaccinations vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT NULL;


-- HIGHEST INFECTION RATE BY CONTINENT (IN %) FROM HIGHEST TO LOWEST

SELECT continent, SUM (population) AS population, SUM (new_cases) AS TotalCases,
		(SUM (new_cases)/SUM (population))*100 AS CasesPerPopulationPercent 
FROM Covid19Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 4 DESC;


-- LIKELIHOOD OF DEATH IN COVID CASES BY CONTINENT (IN %) FROM HIGHEST TO LOWEST

SELECT continent, SUM (population) AS population, SUM (new_cases) AS total_cases, SUM (CAST(new_deaths as int)) AS total_deaths,
		(SUM (CAST(new_deaths as int))/SUM (new_cases))*100 AS DeathPerCasePercentage
FROM Covid19Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 5 DESC;


-- COVIDVACCINATIONS PER POPULATION BY CONTINENT (IN %) FROM HIGHEST TO LOWEST

SELECT vacc.continent, SUM (death.Population) AS Population, SUM (CAST(vacc.new_vaccinations as int)) AS TotalVaccinations,
		(SUM (CAST(vacc.new_vaccinations as int))/SUM (death.Population))*100 AS VaccinationPerPopulationPercent
FROM Covid19Project..CovidVaccinations vacc
JOIN Covid19Project..CovidDeaths death
ON vacc.continent = death.continent AND death.location = vacc.location AND death.date = vacc.date
WHERE vacc.continent IS NOT NULL
GROUP BY vacc.continent
ORDER BY 4 DESC;


-- WORLD'S COVID DATA SHOWING COUNT OF TOTAL CASES, TOTAL DEATHS, TOTAL VACCINATIONS BY CONTINENT

SELECT death.continent, SUM (death.population) AS population, SUM (death.new_cases) AS TotalCases,
		SUM (CAST(death.new_deaths as bigint)) AS TotalDeaths, SUM (CAST(vacc.new_vaccinations as int)) AS TotalVaccinations
FROM Covid19Project..CovidDeaths death
JOIN Covid19Project..CovidVaccinations vacc
ON death.continent = vacc.continent AND death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT NULL
GROUP BY death.continent
ORDER BY 1;


-- AFRICA'S COVID DEATHS AND VACCINATIONS

SELECT death.continent, death.location, SUM (death.population) AS population, SUM (death.new_cases) AS TotalCases,
		SUM (CAST(death.new_deaths as bigint)) AS TotalDeaths,
		COALESCE (SUM (CAST(vacc.new_vaccinations as int)), 0) AS TotalVaccinations
FROM Covid19Project..CovidDeaths death
JOIN Covid19Project..CovidVaccinations vacc
ON death.continent = vacc.continent AND death.location = vacc.location AND death.date = vacc.date
WHERE death.continent LIKE '%Africa%'
GROUP BY death.continent, death.location;


-- COUNTRIES IN AFRICA WITH THE HIGHEST TO LOWEST INFECTION RATE (IN %)

SELECT continent, location, SUM (population) AS population, COALESCE (SUM (new_cases), 0) AS TotalCases,
		(COALESCE (SUM (new_cases), 0)/SUM (population))*100 AS CasePerPopulationPercent
FROM Covid19Project..CovidDeaths
WHERE continent LIKE '%Africa%'
GROUP BY continent, location
ORDER BY 4 DESC;


-- LIKELIHOOD OF COVID DEATHS (IN %) IN AFRICAN COUNTRIES FROM HIGHEST TO LOWEST

SELECT continent, location, SUM (population) AS population, SUM (new_cases) AS TotalCases,
		SUM (CAST (new_deaths as int)) AS TotalDeaths, (SUM (CAST (new_deaths as int))/SUM (new_cases))*100 AS DeathPerCasePercent
FROM Covid19Project..CovidDeaths
WHERE continent LIKE '%Africa%'
GROUP BY continent, location
ORDER BY 6 DESC;


-- COUNTRIES IN AFRICA WITH THE HIGHEST TO LOWEST VACCINATION RATE PER POPULATION (IN %)

SELECT vacc.continent, vacc.location, SUM (death.Population) AS Population,
		COALESCE (SUM (CAST(vacc.new_vaccinations as int)), 0) AS TotalVaccinations,
		COALESCE ((SUM (CAST(vacc.new_vaccinations as int))/SUM (death.Population))*100, 0.0) AS VaccinationPerPopulationPercent
FROM Covid19Project..CovidVaccinations vacc
JOIN Covid19Project..CovidDeaths death
ON vacc.continent = death.continent AND death.location = vacc.location AND death.date = vacc.date
WHERE vacc.continent LIKE '%Africa%'
GROUP BY vacc.continent, vacc.location
ORDER BY 5 DESC;


-- NIGERIA'S ROLLING INFECTION RATE PER POPULATION (IN %) USING CTE

WITH Q1 AS (SELECT location, date, population, SUM (COALESCE (new_cases, 0)) AS NewCases
			FROM Covid19Project..CovidDeaths
			WHERE location LIKE 'Nigeria'
			GROUP BY location, date, population),

	Q2 AS (SELECT *, SUM (NewCases) OVER (PARTITION BY location ORDER BY date) AS RollingTotalCases
			FROM Q1)

SELECT *, (RollingTotalCases/population)*100 AS CasePerPopulationPercent
FROM Q2;


-- LIKELIHOOD OF COVID DEATHS (IN %) IN NIGERIA USING CTE

WITH Q1 AS (SELECT location, date, population, total_cases, SUM (COALESCE (new_deaths, 0)) AS NewDeaths
			FROM Covid19Project..CovidDeaths
			WHERE location LIKE 'Nigeria'
			GROUP BY location, date, population, total_cases),

	Q2 AS (SELECT *, SUM (NewDeaths) OVER (PARTITION BY location ORDER BY date) AS RollingTotalDeaths
			FROM Q1)

SELECT *, (RollingTotalDeaths/total_cases)*100 AS DeathPerCasesPercent
FROM Q2;


-- NIGERIA'S ROLLING VACCINATION PER POPULATION (IN %) USING CTE

WITH Q1 AS (SELECT vacc.location, vacc.date, death.population, COALESCE (CAST(vacc.new_vaccinations as int), 0) AS NewVaccinations,
					COALESCE (vacc.total_vaccinations, 0) AS TotalVaccinations--COALESCE (SUM (CAST(vacc.new_vaccinations as int)), 0) AS NewVaccinations
			FROM Covid19Project..CovidVaccinations vacc
			JOIN Covid19Project..CovidDeaths death
			ON death.location = vacc.location AND death.date = vacc.date
			WHERE vacc.location LIKE '%Nigeria%';

	 Q2 AS (SELECT *, SUM (NewVaccinations) OVER (PARTITION BY location ORDER BY date) AS RollingTotalVaccinations
			FROM Q1)

SELECT *, (RollingTotalVaccinations/population)*100 AS RollingVaccinationPerPopulationPercent
FROM Q2;


-- COMBINING RELEVANT DATA FOR NIGERIA USING CTE

WITH Q1 AS (SELECT death.location, death.date, death.population, death.new_cases AS NewCases, death.total_cases AS TotalCases, 
					COALESCE (death.new_deaths, 0) AS NewDeaths, COALESCE (death.total_deaths, 0) AS TotalDeaths, 
					COALESCE (vacc.new_vaccinations, 0) AS NewVaccinations, COALESCE (vacc.total_vaccinations, 0) AS TotalVaccinations
			FROM Covid19Project..CovidDeaths death
			JOIN Covid19Project..CovidVaccinations vacc
			ON death.location = vacc.location AND death.date = vacc.date
			WHERE death.location LIKE '%Nigeria%')
			
SELECT *, (TotalCases/population)*100 AS CasesPerPopulationPercent, (TotalDeaths/TotalCases)*100 AS DeathsPerCasesPercent,
		(TotalVaccinations/population)*100 AS VaccinationsPerPopulationPercent
FROM Q1
ORDER BY 2;


-- CREATING TEMP TABLE

DROP TABLE IF EXISTS #NigeriaCovidData
CREATE TABLE #NigeriaCovidData
(Location NVARCHAR (255),
Date DATETIME,
Population NUMERIC,
NewCases NUMERIC,
TotalCases NUMERIC,
NewDeaths NUMERIC,
TotalDeaths NUMERIC,
NewVaccinations NUMERIC,
TotalVaccinations NUMERIC)

INSERT INTO #NigeriaCovidData

SELECT death.location, death.date, death.population, death.new_cases AS NewCases, death.total_cases AS TotalCases, 
		COALESCE (death.new_deaths, 0) AS NewDeaths, COALESCE (death.total_deaths, 0) AS TotalDeaths, 
		COALESCE (vacc.new_vaccinations, 0) AS NewVaccinations, COALESCE (vacc.total_vaccinations, 0) AS TotalVaccinations
FROM Covid19Project..CovidDeaths death
JOIN Covid19Project..CovidVaccinations vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.location LIKE '%Nigeria%'
			
SELECT *, (TotalCases/population)*100 AS CasesPerPopulationPercent, (TotalDeaths/TotalCases)*100 AS DeathsPerCasesPercent,
		(TotalVaccinations/population)*100 AS VaccinationsPerPopulationPercent
FROM #NigeriaCovidData
ORDER BY 2;


-- CREATING VIEW TO STORE NIGERIA COVID DATA FOR VISUALISATIONS

USE Covid19Project
GO
CREATE VIEW NigeriaCovidData AS 
SELECT death.location, death.date, death.population, death.new_cases AS NewCases, death.total_cases AS TotalCases, 
		COALESCE (death.new_deaths, 0) AS NewDeaths, COALESCE (death.total_deaths, 0) AS TotalDeaths, 
		COALESCE (vacc.new_vaccinations, 0) AS NewVaccinations, COALESCE (vacc.total_vaccinations, 0) AS TotalVaccinations
FROM Covid19Project..CovidDeaths death
JOIN Covid19Project..CovidVaccinations vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.location LIKE '%Nigeria%'


SELECT *
FROM NigeriaCovidData


-- CREATING VIEW TO STORE AFRICA COVID DATA FOR VISUALISATIONS

USE Covid19Project
GO
CREATE VIEW AfricaCovidData AS
SELECT death.continent, death.location, SUM (death.population) AS population, SUM (death.new_cases) AS TotalCases,
		SUM (CAST(death.new_deaths as bigint)) AS TotalDeaths,
		COALESCE (SUM (CAST(vacc.new_vaccinations as int)), 0) AS TotalVaccinations
FROM Covid19Project..CovidDeaths death
JOIN Covid19Project..CovidVaccinations vacc
ON death.continent = vacc.continent AND death.location = vacc.location AND death.date = vacc.date
WHERE death.continent LIKE '%Africa%'
GROUP BY death.continent, death.location;

SELECT *
FROM AfricaCovidData


-- CREATING VIEW TO STORE WORLD COVID DATA FOR VISUALISATIONS

USE Covid19Project
GO
CREATE VIEW WorldCovidData AS
SELECT death.continent, SUM (death.population) AS population, SUM (death.new_cases) AS TotalCases,
		SUM (CAST(death.new_deaths as bigint)) AS TotalDeaths, SUM (CAST(vacc.new_vaccinations as int)) AS TotalVaccinations
FROM Covid19Project..CovidDeaths death
JOIN Covid19Project..CovidVaccinations vacc
ON death.continent = vacc.continent AND death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT NULL
GROUP BY death.continent
--ORDER BY 1;

SELECT *
FROM WorldCovidData