/* This project takes global Covid-19 infection, death, and vaccination rates from https://ourworldindata.org/covid-deaths .
SQl Server Managemnet Studio application was used to run the SQL queries. The Data set is from Jan.22,2020 to May 28,2021.
The file was downloaded and split into two in MS Excel format files which were uploaded into SQl Server database using SQL Import and Export Wizard.
Two tables ([dbo].['coviddeaths'] and [dbo].['covidvaccinations'] ) were created in the data base  (Projects). 
In total 7 SQL sriptss were run to generate insights from Covid-19 data, these resulting new tables are then visualised in Tableau https://public.tableau.com/app/profile/aditya.bist/viz/Covid19VaccinationGlobalRates/Sheet1  */


-- **Initialiazing the database where the Tables are stored.** 
use Projects
go

--** Exploring the two tables**
SELECT *
From ['coviddeaths']

SELECT *
From ['covidvaccinations']

--Running different scripts (1-7) to generate insights

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
SELECT *, (RollingCountVac/population) *100 AS VaccinationPercentage
from Populationpvac


--6 Showing Countires with Highest Case count and % per Poulation

select Location,population,date, max(total_cases) as HighestInfectionCount,Max((total_cases/population))*100 AS 'Total_Case_ as_%_ Population'
From ['coviddeaths']
--Where Location = 'India'
Group by Location,population,date
order by 5 desc

--7 Showing Countires with Highest Death count and % per Poulation

select Location,population, max(cast(total_deaths as int)) as HighestDeathCount,Max((cast(total_deaths as int)/population))*100 AS 'Total_Death_ as_%_ Population'
From ['coviddeaths']
Where continent is not null
Group by Location,population
order by 3 desc



--END--





