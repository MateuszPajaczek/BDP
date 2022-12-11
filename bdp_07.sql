-- Database: cw_07

-- DROP DATABASE IF EXISTS cw_07;

CREATE DATABASE cw_07
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;


--2.Załaduj te dane do tabeli o nazwie uk_250k

SELECT *
FROM uk_250k;

--a.Dodanie serial primary key

ALTER TABLE uk_250k
ADD COLUMN rid SERIAL PRIMARY KEY;

--b.Utworzenie indeksu przestrzennego

CREATE INDEX idx_uk_250k ON uk_250k
USING gist (ST_ConvexHull(rast));

--c.Dodanie raster constraints

SELECT AddRasterConstraints('public'::name,'uk_250k'::name,'rast'::name);


--3.Połącz te dane (wszystkie kafle) w mozaikę, a następnie wyeksportuj jako GeoTIFF. 

CREATE TABLE uk_250k_mosaic AS
SELECT ST_Union(r.rast)
FROM uk_250k AS r

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM uk_250k_mosaic;

--Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'C:/Users/mpaja/Desktop/studia/bazy/cw_07/dane/uk_250k_mosaic.tif')
FROM tmp_out;

--Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;


-- 5. Załaduj do bazy danych tabelę reprezentującą granice parków narodowych. (Wczytanie danych GeoPackage do QGIS - Wyeksportowanie sqldump dla National Parks - Wczytanie do Postgres)

SELECT * FROM national_parks;


-- 6. Utwórz nową tabelę o nazwie uk_lake_district, do której zaimportujesz mapy rastrowe z punktu 1., które zostaną przycięte do granic parku narodowego Lake District. 

CREATE TABLE uk_lake_district AS
SELECT r.rid, ST_Clip(r.rast, u.geom, true) AS rast, u.id
FROM uk_250k AS r, national_parks AS u
WHERE ST_Intersects(r.rast, u.geom) AND u.id = 1;

SELECT UpdateRasterSRID('public','uk_lake_district','rast',27700);

DROP TABLE uk_lake_district


-- 7. Wyeksportuj wyniki do pliku GeoTIFF.

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM uk_lake_district;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'C:/bazy/lake_district.tif')
FROM tmp_out;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;


-- 8. Pobierz dane z satelity Sentinel-2 wykorzystując portal: https://scihub.copernicus.eu. Wybierz dowolne zobrazowanie, które pokryje teren parku Lake District oraz gdzie parametr cloud coverage będzie poniżej 20%. 
-- 9. Załaduj dane z Sentinela-2 do bazy danych. (raster2pgsql)

SELECT * 
FROM uk_sentinel;

DROP TABLE uk_sentinel;

-- a. Dodanie serial primary key

ALTER TABLE uk_sentinel
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_uk_sentinel ON uk_sentinel
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('public'::name,'uk_sentinel'::name,'rast'::name);

--Połączenie rastrów

CREATE TABLE uk_sentinel_mosaic AS
SELECT ST_Union(r.rast)
FROM uk_sentinel AS r;

CREATE TABLE tmp_out_2 AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM uk_sentinel_mosaic;


CREATE TABLE uk_sentinel_clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM uk_sentinel_mosaic AS a, uk_lake_district AS b;


-- 10. Policz indeks NDWI oraz przytnij wyniki do granic Lake District

DROP TABLE uk_sentinel_ndwi;

SELECT * 
FROM uk_sentinel_ndwi;

CREATE TABLE uk_sentinel_ndwi AS
WITH r AS (
	SELECT r.rid, r.rast AS rast
	FROM uk_sentinel_mosaic AS r
)
SELECT
	r.rid, ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
	) AS rast
FROM r;

-- a. Dodanie serial primary key

ALTER TABLE uk_sentinel_ndwi
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_uk_sentinel_ndwi ON uk_sentinel_ndwi
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('public'::name,'uk_sentinel_ndvi'::name,'rast'::name);


-- 11. Wyeksportuj obliczony i przycięty wskaźnik NDWI do GeoTIFF.

CREATE TABLE tmp_out_3 AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM uk_sentinel_ndwi;

--Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'C:/Users/mpaja/Desktop/studia/bazy/cw_07/dane/lake_district_ndwi.tif')
FROM tmp_out_3;

--Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_out_3;

DROP TABLE tmp_out_3;

