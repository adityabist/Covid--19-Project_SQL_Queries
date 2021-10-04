/* This project takes global Covid-19 infection, death and vaccination rates from https://ourworldindata.org/covid-deaths . 
The file was downloaded in MS Excel format and then uploaded into SQl Server database using SQL Import and Export Wizard.
There are two tables ([dbo].['coviddeaths'] and [dbo].['covidvaccinations'] ) in the data base  (PortfolioProject) 
that are used to generate into global Covid-19 data. Various queries are run in SQl Server Managemnet Studion to aggregated data, these resulting new tables are then visualised in Tableau  */

-- Initialiazing the database where the Tables are stored. 
use PortfolioProject
go

Alter Database PortfolioProject Modify Name =Projects
-- Exploring the two tables
SELECT *
From ['coviddeaths']

SELECT *
From ['covidvaccinations']

--Running different scripts to aggregate data

--1 Total cases vs Total deaths %
SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 AS 'Death%'
From ['coviddeaths']
where continent is not null

--2 Analysis by Continent

SELECT location, max(cast(total_deaths as int)) as HighestDeathCount
From ['coviddeaths']
Where continent is null
and location not in ('World','European Union','International')
Group by location
order by 2 desc

--3 Looking counties with highest infection rates

select Location,population,date, max(total_cases) as HighestInfectionCount,Max((total_cases/population))*100 AS 'Total_Case_ as_%_ Population'
From ['coviddeaths']
--Where Location = 'India'
Group by Location,population,date
order by 5 desc

--4 Total Cases, Deaths, Vaccination counts by joining tables  used for Tableau visualisation

SELECT death.continent,death.location,death.date,death.population,death.total_cases,cast(death.total_deaths as int) As total_deaths,vac.new_vaccinations,
sum(Cast(vac.new_vaccinations as int)) over (Partition by death.location order by death.location,death.date) as RollingCountVac
from ['coviddeaths']death 
join ['covidvaccinations'] vac
   on death.location=vac.location
   and death.date=vac.date
where death.continent is not null
order by 2,3

--convert(varchar,death.date,102)
--5 Storing the above created joined Table query and using three different methods i.e. creating Table, View, & CTE

--a) CREATING A TABLE

DROP table if exists #PercentagePopulationVaccinated
CREATE Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
total_cases numeric,
total_deaths numeric,
new_vaccinations numeric,
RollingCountVac numeric
)

INSERT into #PercentagePopulationVaccinated
SELECT death.continent,death.location,death.date,death.population,death.total_cases,cast(death.total_deaths as int) As total_deaths,vac.new_vaccinations,
sum(Cast(vac.new_vaccinations as int)) over (Partition by death.location order by death.location,death.date) as RollingCountVac
from ['coviddeaths']death 
join ['covidvaccinations'] vac
   on death.location=vac.location
   and death.date=vac.date
where death.continent is not null

SELECT *, (RollingCountVac/population) *100 As PecentageVaccinated
from #PercentagePopulationVaccinated

update #PercentagePopulationVaccinated
	set  total_deaths = 0
	WHERE total_deaths is null;
	--set  new_vaccinations = 0
	--WHERE new_vaccinations is null
	--set  RollingCountVac = 0
	--WHERE RollingCountVac is null
	--set  total_CASES = 0,
	--WHERE total_CASES is null;

	
	--case when total_cases is null then 0 end,
		--total_deaths case when total_deaths is null then 0 end,
		--RollingCountVac case when RollingCountVac is null then 0 end,
		--new_vaccinations case when new_vaccinations is null then 0 end
	--where null in (total_cases,total_deaths,RollingCountVac,new_vaccinations)


SELECT *, (RollingCountVac/population) *100 As PecentageVaccinated
from #PercentagePopulationVaccinated

--b) CREATING A VIEW
	
drop view if exists PercentagePopulationVaccinated

CREATE View PercentagePopulationVaccinated as
SELECT death.continent,death.location,death.date,death.population,death.total_cases,cast(death.total_deaths as int) As total_deaths,vac.new_vaccinations,
sum(Cast(vac.new_vaccinations as int)) over (Partition by death.location order by death.location,death.date) as RollingCountVac
from ['coviddeaths']death 
join ['covidvaccinations'] vac
   on death.location=vac.location
   and death.date=vac.date
where death.continent is not null

SELECT *
from 
PercentagePopulationVaccinated

--c) CREATING A CTE
	
WITH Populationpvac (continent, location,  date,population,total_cases,total_deaths, new_vaccinations,RollingCountVac)
as 
(
SELECT death.continent,death.location,death.date,death.population,death.total_cases,cast(death.total_deaths as int) As total_deaths,vac.new_vaccinations,
sum(Cast(vac.new_vaccinations as int)) over (Partition by death.location order by death.location,death.date) as RollingCountVac
from ['coviddeaths']death 
join ['covidvaccinations'] vac
   on death.location=vac.location
   and death.date=vac.date
where death.continent is not null
)
SELECT *, (RollingCountVac/population) *100
from Populationpvac

--Using CTE--arrange columns in with statement as they are within as ()
--order by 2,3 can't have order by in a CTE ---run CTE along with select statement


--5 Other Adhoc insights 
select Location,population,date, max(total_cases) as HighestInfectionCount,Max((total_cases/population))*100 AS 'Total_Case_ as_%_ Population'
From ['coviddeaths']
--Where Location = 'India'
Group by Location,population,date
order by 5 desc

--6

--Looking death  % for India
select Location,population, date,total_cases, new_cases, cast(total_deaths as int),(cast(total_deaths as int)/total_cases)*100 AS 'Death%'
From ['coviddeaths']
Where Location = 'Canada'
order by 6 desc

--Looking Total Cases vs Poulation %
select Location, date,population,total_cases, new_cases, total_deaths,(total_cases/population)*100 AS 'Total_Case_ as_%_ Population'
From ['coviddeaths']
Where Location = 'India'
order by 7 desc

--Showing Contires with Highest Death count per Poulation

select Location,population, max(cast(total_deaths as int)) as HighestDeathCount,Max((total_deaths/population))*100 AS 'Total_Death_ as_%_ Population'
From ['coviddeaths']
Where continent is not null
Group by Location,population
order by 3 desc



select location, max(cast(total_deaths as int)) as HighestDeathCount
From ['coviddeaths']
Where continent is not null
Group by location
order by 2 desc

--Global numbers Continent death rate as %

select location,population, max(cast(total_deaths as int)) as HighestDeathCount,max(cast(total_deaths as int)/population)*100 AS ContinentDeathPercen
From ['coviddeaths']
Where continent is null
Group by location,population
order by 2 desc

--Global Rate by Country

select location, population, max(cast(total_deaths as int)) as HighestDeathCount,max(cast(total_deaths as int)/population)*100 AS CountryDeathPercen
From ['coviddeaths']
Where continent is not null
Group by location,population
order by 4 desc

--






