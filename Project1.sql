-- Memilih Tabel untuk ditampilkan
SELECT *
FROM coviddeaths

SELECT *
FROM covidvaccinations

-- Mengurutkan A-Z kolom location dan date
SELECT *
FROM coviddeaths
ORDER BY 3,4

SELECT *
FROM covidvaccinations
ORDER BY 3,4

-- Mengurutkan Data yang akan digunakan dalam Tabel Covid Deaths untuk kolom location dan date
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1,2

-- Perbandingan Total Cases VS Total Deaths di Indonesia
SELECT location, date, total_cases , total_deaths, cast(total_deaths as float)/cast(total_cases as float)*100 PresentaseKematian
FROM coviddeaths
WHERE location like 'Indonesia' and total_cases is not NULL
ORDER BY 2 DESC

-- Perbandingan Total Cases VS Populations di Indonesia
SELECT location, date, population, total_cases, cast(total_cases as float)/cast(population as float) as PresentasePopuliasiTerinfeksi
FROM coviddeaths
WHERE location like 'Indonesia' and total_cases is not NULL
ORDER BY 2 DESC

-- Lokasi dengan Total Penduduk Terinfeksi Terbanyak
SELECT location, population, MAX(total_cases) as BanyaknyaTerinfeksi, MAX(cast(total_cases as float)/cast(population as float)) as PresentasiPopulasiTerinfeksi
FROM coviddeaths
WHERE continent is NULL
GROUP BY location, population
ORDER BY PresentasiPopulasiTerinfeksi DESC


-- Lokasi dengan kasus kematian covid terbanyak
SELECT location, MAX(cast(total_deaths as float)) as BanyaknyaKematian_lokasi
FROM coviddeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY BanyaknyaKematian_lokasi DESC

-- Benua dengan kasus Kematian Covid terbanyak
SELECT continent, MAX(cast(total_deaths as float)) as BanyaknyaKematian_benua
FROM coviddeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY BanyaknyaKematian_benua DESC

-- Presentase kematian di seluruh Dunia
Select SUM(cast(new_cases as float)) as BanyaknyaKasus, SUM(cast(new_deaths as float)) as BanyaknyaKematian, 
SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as PresentaseKematian
FROM coviddeaths
ORDER BY 1,2

-- Menggabungkan Table coviddeaths dan Table covidvaccinations
SELECT *
FROM coviddeaths as death
	join covidvaccinations as vaccine
	on death.location = vaccine.location
	and death.date = vaccine.date

-- Melihat Banyaknya Vaksin di seluruh Dunia
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
FROM coviddeaths as death
	join covidvaccinations as vaccine
	on death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL
ORDER BY location, date

-- Melihat banyaknya Orang yang sudah Vaksin
SELECT death.continent, death.location, death.date, death.population, vaccine.[new_vaccinations]
, SUM(cast(vaccine.[new_vaccinations]as float)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as BanyakOrangVaksin 
FROM coviddeaths as death
	join covidvaccinations as vaccine
	on death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL
ORDER BY location, date DESC

-- Melihat Perbandingan Banyaknya orang yang sudah Vaksin

WITH X ([continent], [location], [date], [population], [new_vaccinations], BanyakOrangVaksin)
AS

(
SELECT death.continent, death.location, death.date, death.population, vaccine.[new_vaccinations]
, SUM(cast(vaccine.[new_vaccinations]as float)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as BanyakOrangVaksin 
FROM coviddeaths as death
	join covidvaccinations as vaccine
	on death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL 
)
SELECT *, (BanyakOrangVaksin/(CONVERT(numeric, population))) as ProbabilitasTervaksin
FROM X


-- Membuat Tam Table

DROP TABLE IF exists #PerbandinganVaksinVSPopulasi

CREATE TABLE #PerbandinganVaksinVSPopulasi
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population float,
new_vaccinations float,
BanyakOrangVaksin float
)

INSERT INTO #PerbandinganVaksinVSPopulasi
SELECT death.continent, death.location, death.date, death.population, vaccine.[new_vaccinations]
, SUM(cast(vaccine.[new_vaccinations]as float)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as BanyakOrangVaksin 
FROM coviddeaths as death
	join covidvaccinations as vaccine
	on death.location = vaccine.location
	and death.date = vaccine.date
--WHERE death.continent is not NULL 

SELECT *, (BanyakOrangVaksin/population)
FROM #PerbandinganVaksinVSPopulasi

-- Membuat View

CREATE VIEW PerbandinganVaksinVSPopulasi AS
SELECT death.continent, death.location, death.date, death.population, vaccine.[new_vaccinations]
, SUM(cast(vaccine.[new_vaccinations]as float)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as BanyakOrangVaksin 
FROM coviddeaths as death
	join covidvaccinations as vaccine
	on death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL
