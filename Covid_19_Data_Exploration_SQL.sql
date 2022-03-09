select *
from CovidDataAnalysis..coviddeaths
where continent is not NULL
order by 3,4

-- Select data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
from CovidDataAnalysis..coviddeaths
where continent is not NULL
order by 1,2 

-- calculating the death percentage -- total cases vs total deaths
-- it shows the chances of dying if you contact with covid

select location, population , max(cast(total_deaths as int)) as deaths, max((total_deaths/population))*100 as death_percentage
from CovidDataAnalysis..coviddeaths
where continent is not NULL
group by location, population
order by 4 desc

-- Death count by continents


select location, Max(cast(total_deaths as int)) as TotalDeathCount
from CovidDataAnalysis..coviddeaths
where continent is null
and location not in ('World', 'European Union', 'International')
and location not like '%income%'
group by location
order by TotalDeathCount desc

-- showing continents with highest death count per population

select location, population, Max(cast(total_deaths as int)) as TotalDeathCount, max((total_deaths/population))*100 as death_percentage
from CovidDataAnalysis..coviddeaths
where continent is null
and location not in ('World', 'European Union', 'International')
and location not like '%income%'
group by location, population
order by TotalDeathCount desc

-- Cases by date

select cast(date as DATE) as date, sum(cast(new_cases as int)) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths
from CovidDataAnalysis..coviddeaths
where continent is not null
and new_cases is not null
group by date
order by date


-- total population vs vaccination


select d.location, cast(d.date as DATE) as date, d.population, v.new_vaccinations
From CovidDataAnalysis..coviddeaths d
join CovidDataAnalysis..covidvaccination v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
and v.new_vaccinations is not null
--and d.location like '%states%'
order by 2,3

-- total population vs vaccinations partitiion by location and date


select d.continent, d.location, cast(d.date as DATE) as date, d.population, v.new_vaccinations
, sum(cast(v.new_vaccinations as int))  over (partition by d.location order by d.location, d.date) as total_vaccinations
From CovidDataAnalysis..coviddeaths d
join CovidDataAnalysis..covidvaccination v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
and d.location like '%states%'
order by 2,3 


-- USING CTE(common table expressions) population vs vaccinations

with PopulationVsVaccination (continent, location, date, population, new_vaccinations, total_vaccinations_as_of_date)
as 
(
select d.continent, d.location, cast(d.date as DATE) as date, d.population, v.new_vaccinations
, sum(cast(v.new_vaccinations as int))  over (partition by d.location order by d.location, d.date) as total_vaccinations_as_of_date
From CovidDataAnalysis..coviddeaths d
join CovidDataAnalysis..covidvaccination v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
and d.location like '%states%'
)
select *, (total_vaccinations_as_of_date/population)*100 as vaccination_percentage
from PopulationVsVaccination
order by 2,3 


-- create a table with vaccination counts


drop table if exists #PercentVaccinated
create table #PercentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date Date,
population numeric,
new_vaccinations numeric,
total_vaccinations_as_of_date numeric
)

insert into #PercentVaccinated
select d.continent, d.location, cast(d.date as DATE) as date, d.population, v.new_vaccinations
, sum(cast(v.new_vaccinations as int))  over (partition by d.location order by d.location, d.date) as total_vaccinations_as_of_date
From CovidDataAnalysis..coviddeaths d
join CovidDataAnalysis..covidvaccination v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
and d.location like '%states%'
select *, (total_vaccinations_as_of_date/population)*100 as vaccination_percentage
from #PercentVaccinated
--order by 2,3 



-- Creating view to store data for later visualizations

create view PercentPopulationVaccinated as
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as total_vaccinations_as_of_date
--, (RollingPeopleVaccinated/population)*100
From CovidDataAnalysis..coviddeaths d
Join CovidDataAnalysis..covidvaccination v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null

select *
from PercentPopulationVaccinated