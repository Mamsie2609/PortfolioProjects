/* COVID 19 DATA EXPLORATION*/

SELECT *
FROM CovidDeaths 
ORDER BY 3,4;

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;


SELECT *
FROM CovidVaccinations
ORDER BY 3,4;


--SELECT DATA THAT WE ARE GOING TO BEGIN WITH

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 1,2;


--LOOKING AT THE TOTAL CASES VS TOTAL DEATHS
--Shows the probability of death upon contracting COVID-19 

SELECT location, date, total_cases, total_deaths, 
    ((CAST(total_deaths AS decimal)) / (CAST(total_cases AS decimal))) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;


--Retrieves data that includes the likelihood of dying after contracting COVID-19 in the United Kingdom.

SELECT location, date, total_cases, total_deaths, 
    ((CAST(total_deaths AS decimal)) / (CAST(total_cases AS decimal))) * 100 AS DeathPercentage
FROM CovidDeaths 
WHERE [location] LIKE '%kingdom%'
ORDER BY 1,2;


--Looking at Total Cases vs Population
--Shows the percentage of the population in the United Kingdom that has been infected with Covid.

SELECT location, date, population, total_cases, 
    ((CAST(total_cases AS decimal)) / (CAST(population AS decimal))) * 100 AS PercentPopulationInfected
FROM CovidDeaths 
WHERE [location] LIKE '%kingdom%'
AND continent IS NOT NULL
ORDER BY 1,2;


--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,
   MAX(((CAST(total_cases AS decimal)) / (CAST(population AS decimal))))* 100 AS PercentPopulationInfected
FROM CovidDeaths 
WHERE continent IS NOT NULL
--WHERE [location] LIKE '%kingdom%'
GROUP BY Location,Population
ORDER BY PercentPopulationInfected desc;


-- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths 
--WHERE [location] LIKE '%kingdom%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount desc;


--GROUPING DATA BY CONTINENT
--Showing continents with highest death count per population

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths 
--WHERE [location] LIKE '%kingdom%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc;


--GLOBAL 
--Shows the total cases, total deaths, and death percentage per day for all locations 

SELECT Date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS decimal)) AS total_deaths, (SUM(cast(new_deaths AS decimal))/SUM(new_cases)) * 100 AS DeathPercentage
FROM CovidDeaths
--WHERE Location LIKE 'kingdom'
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY 1, 2;


--Shows the total cases, total deaths, and death percentage across the world.

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS decimal)) AS total_deaths, (SUM(cast(new_deaths AS decimal))/SUM(new_cases)) * 100 AS DeathPercentage
FROM CovidDeaths
--WHERE Location LIKE 'kingdom'
WHERE continent IS NOT NULL
--GROUP BY Date
ORDER BY 1, 2;

--ASSESSING VACCINATION DATA

SELECT *
FROM CovidVaccinations;


--JOINING THE TWO TABLES

SELECT *
FROM CovidDeaths death 
JOIN CovidVaccinations vac 
     ON death.location = vac.location
     AND death.date = vac.date;


--LOOKING AT THE TOTAL POPULATION VS VACCINATIONS

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(INT,vac.new_vaccinations)) OVER 
(PARTITION BY death.location 
ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3;


-- GETTING THE PERCENTAGE OF ROLLINGPEOPLEVACCINATED FOR EACH LOCATION USING CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CONVERT(INT,vac.new_vaccinations)) OVER 
(PARTITION BY death.location 
ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, ((CAST(RollingPeopleVaccinated AS DECIMAL))/ (CAST (Population AS DECIMAL))) * 100 AS RollingPeopleVaccinatedPercentage
FROM PopvsVac;


-- USING TEMP TABLE TO PERFORM CALCULATION ON PARTITION BY IN PREVIOUS QUERY

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CONVERT(INT,vac.new_vaccinations)) OVER 
(PARTITION BY death.location 
ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, ((CAST(RollingPeopleVaccinated AS DECIMAL))/ (CAST (Population AS DECIMAL))) * 100 AS RollingPeopleVaccinatedPercentage
FROM #PercentPopulationVaccinated;




-- CREATING VIEW TO STORE DATA FOR DATA VISUALISATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	 ON death.location = vac.location
	 AND death.date = vac.date
WHERE death.continent IS NOT NULL



SELECT *
FROM PercentPopulationVaccinated;