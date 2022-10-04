EXPLORATORY DATA ANALYSIS USING SQL

Actual dataset used for this project can be found here https://ourworldindata.org/covid-deaths

-- First step:  current covid datasets was imported as an xslx file.
-- I divided the datasets into two tables (1) covid_deaths (2) covid_vaccinations
-- Created database(PortfoloDB) in Microsoft SQL Server Management studio and imported the 2 tables into the database.

-- check the first table
SELECT *
FROM PortfolioDB..covid_death$
where continent is not null
order by 3,4

-- check second table
--SELECT *
--FROM PortfolioDB..covid_vacination$
--order by 3,4



select location, date, total_cases, new_cases, total_deaths, population
from PortfolioDB..covid_death$
where continent is not null
order by 1,2


-- Look at the total cases vs total deaths
-- shows the likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioDB..covid_death$
where location like '%States%'
order by 1,2

'''result shows that as at 10/02/2022, there are 1059605 deaths from covid and an approximate
1.099% chance for a person with covid in the United state to die of covid'''


-- Calculating the total cases vs the population
-- shows what percentage of population got covid
select location, date, total_cases, population, (total_cases/population)*100 as CasesPercentage
from PortfolioDB..covid_death$
location like '%States%'
and  continent is not null

order by 1,2


-- Calculating countries with highiest infection rate compare to population

select location, population, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 as CasesPercentage
from PortfolioDB..covid_death$
where continent is not null
-- where location like '%States%'
group by population, location
order by CasesPercentage desc


-- Calculate countries with the highest death count per population

select location, MAX(CAST(total_deaths as int))  as TotalDeathCounts
from PortfolioDB..covid_death$
-- where location like '%States%'
where continent is not null -- adding this clause makes it eliminates some metrics not needed
group by location
order by TotalDeathCounts desc


-- Breaking things  down by continent

select continent, MAX(CAST(total_deaths as int))  as TotalDeathCounts
from PortfolioDB..covid_death$
-- where location like '%States%'
where continent is not null
group by continent
order by TotalDeathCounts desc


-- Showing the continent with the highest death count per population
select continent, MAX(CAST(total_deaths as int))  as TotalDeathCounts
from PortfolioDB..covid_death$
-- where location like '%States%'
where continent is not null
group by continent
order by TotalDeathCounts desc

-- Global Numbers

select date, sum(new_cases) as Total_Cases, sum(cast(new_deaths as int))as Total_Deaths, sum(cast(new_deaths as int))/sum(new_cases) *100 as DeathPercentage
from PortfolioDB..covid_death$
-- where location like '%States%'
where continent is not null
group by date
order by 1,2

-- Global breakdowns

select sum(new_cases) as Total_Cases, sum(cast(new_deaths as int))as Total_Deaths, sum(cast(new_deaths as int))/sum(new_cases) *100 as DeathPercentage
from PortfolioDB..covid_death$
-- where location like '%States%'
where continent is not null
-- group by date
order by 1,2


-- Join tables 

select * 
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date

-- Look at Total Population vs Vaccinations
select Da.continent, Da.location,Da.date, Da.population, Va.new_vaccinations
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date
where Da.continent is not null
order by 2,3

-- doing Total Population vs Vaccinations using a different apprroach
select Da.continent, Da.location,Da.date, Da.population, Va.new_vaccinations
,sum(convert(int,Va.new_vaccinations)) OVER(Partition by Da.location) -- Break it down by lcation 
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date
where Da.continent is not null
order by 2,3


-- doing Total Population vs Vaccinations using a different apprroach
select Da.continent, Da.location,Da.date, Da.population, Va.new_vaccinations
,sum(convert(int,Va.new_vaccinations)) OVER(Partition by Da.location order by Da.Location, Da.date) as RollingPeopleVaccinated -- Break it down by location 
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date
where Da.continent is not null
order by 2,3



-- doing Total Population vs Vaccinations using a different apprroach
select Da.continent, Da.location,Da.date, Da.population, Va.new_vaccinations
,sum(convert(int,Va.new_vaccinations)) OVER(Partition by Da.location order by Da.Location, Da.date) as RollingPeopleVaccinated -- Break it down by location 
-- , (RollingPeopleVaccinated/population)*100 -- shows error cause you cannot use as alias as a metric of measurement in same querry
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date
where Da.continent is not null
order by 2,3

-- USE CTE Instead for the querry above to calculate RollingPercent

with PopVsVac (continent, location,date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select Da.continent,Da.location, Da.date, Da.population,Va.new_vaccinations
, sum(convert(int,Va.new_vaccinations)) OVER (Partition by Da.location order by Da.Location, Da.date) as RollingPeopleVaccinated -- Break it down by location 
-- , (RollingPeopleVaccinated/population)*100 -- shows error cause you cannot use as alias as a metric of measurement in same querry
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date
where Da.continent is not null
-- order by 2,3
)
select * ,(RollingPeopleVaccinated/population)*100 as RollingPercent
from PopVsVac



-- TEMP TABLE
drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
new_vacinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
select Da.continent,Da.location, Da.date, Da.population,Va.new_vaccinations
, sum(convert(int,Va.new_vaccinations)) OVER (Partition by Da.location order by Da.Location, Da.date) as RollingPeopleVaccinated -- Break it down by location 
-- , (RollingPeopleVaccinated/population)*100 -- shows error cause you cannot use as alias as a metric of measurement in same querry
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date
where Da.continent is not null
-- order by 2,3
select * ,(RollingPeopleVaccinated/population)*100 as RollingPercent
from #PercentPopulationVaccinated


-- Creating views to store data later for visualization

Create view PercentPopulationVaccinated AS
select Da.continent,Da.location, Da.date, Da.population,Va.new_vaccinations
, sum(convert(int,Va.new_vaccinations)) OVER (Partition by Da.location order by Da.Location, Da.date) as RollingPeopleVaccinated -- Break it down by location 
-- , (RollingPeopleVaccinated/population)*100 -- shows error cause you cannot use as alias as a metric of measurement in same querry
from PortfolioDB..covid_death$ Da
join  PortfolioDB..covid_vacination$ Va
	on Da.location = Va.location
	and Da.date = Va.date
where Da.continent is not null
-- order by 2,3

select *
from PercentPopulationVaccinated
