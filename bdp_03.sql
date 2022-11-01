-- Database: bdp_03

-- DROP DATABASE IF EXISTS bdp_03;

CREATE DATABASE bdp_03
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
	CREATE EXTENSION postgis;
	
--1. Zaimportuj następujące pliki shapefile do bazy, przyjmij wszędzie układ WGS84:
--T2018_KAR_BUILDINGS
--T2019_KAR_BUILDINGS
--Pliki te przedstawiają zabudowę miasta Karlsruhe w latach 2018 i 2019.

--Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana
--pomiędzy 2018 a 2019).

CREATE TABLE new_buildings AS
(
	SELECT * 
	FROM T2019_KAR_BUILDINGS AS bud_2019
	WHERE bud_2019.gid NOT IN (
		SELECT DISTINCT(bud_2019.gid) 
		FROM T2019_KAR_BUILDINGS AS bud_2019, T2018_KAR_BUILDINGS AS bud_2018
		WHERE ST_Equals(bud_2019.geom, bud_2018.geom)
));

SELECT * FROM new_buildings;

--2. Zaimportuj dane dotyczące POIs (Points of Interest) z obu lat:
--T2018_KAR_POI_TABLE
--T2019_KAR_POI_TABLE

--Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
--wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.

SELECT COUNT(DISTINCT(poi_2019.geom)) 
FROM T2019_KAR_POI_TABLE as poi_2019, new_buildings as n_b
WHERE poi_2019.poi_id NOT IN(
	SELECT poi_2018.poi_id 
	FROM T2018_KAR_POI_TABLE AS poi_2018
) 
AND ST_DWithin(poi_2019.geom, n_b.geom, 500);

--3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
--T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.

CREATE TABLE streets_reprojected AS (
	SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel, ST_Transform(geom, 3068) as geom
	FROM T2019_KAR_STREETS
);

SELECT * FROM streets_reprojected;

--4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
--Użyj następujących współrzędnych:
--X Y
--8.36093 49.03174
--8.39876 49.00644
--Przyjmij układ współrzędnych GPS.

CREATE TABLE input_points (
	p_id INT PRIMARY KEY,
	geom GEOMETRY
);


INSERT INTO input_points(p_id, geom)
VALUES
	(1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326)),
	(2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));
	
SELECT * FROM input_points;
DROP TABLE input_points;

--5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
--DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText().

UPDATE input_points 
SET geom = ST_Transform(ST_SetSRID(geom, 4326), 3068);

ALTER TABLE input_points 
ALTER COLUMN geom TYPE geometry(POINT, 3068);

SELECT p_id, ST_AsText(geom)
FROM input_points;

--6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
--z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
--reprojekcji geometrii, aby była zgodna z resztą tabel.

SELECT * FROM t2019_kar_street_node AS s
WHERE ST_DWithin(ST_Transform(s.geom, 3068), 
(SELECT ST_MakeLine(p.geom) FROM input_points AS p), 200) 
AND s.intersect = 'Y';

--7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
--w odległości 300 m od parków (LAND_USE_A).

SELECT COUNT(DISTINCT(poi.gid))
FROM t2019_kar_poi_table as poi, t2019_kar_land_use_a as parki
WHERE poi.type = 'Sporting Goods Store' 
AND ST_DWithin(poi.geom, parki.geom, 300) 
AND parki.type = 'Park (City/County)';

--8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
--znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.
	
CREATE TABLE T2019_KAR_BRIDGES AS (
	SELECT DISTINCT(ST_Intersection(tory.geom, cieki.geom))
	FROM t2019_kar_railways AS tory, t2019_kar_water_lines AS cieki
);

SELECT * FROM T2019_KAR_BRIDGES;
	