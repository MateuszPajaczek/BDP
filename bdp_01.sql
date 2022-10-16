-- Database: bdp_01

-- DROP DATABASE IF EXISTS bdp_01;

CREATE DATABASE bdp_01
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
CREATE EXTENSION postgis;

CREATE TABLE roads (id INT PRIMARY KEY NOT NULL, name VARCHAR(50), geom GEOMETRY);

INSERT INTO roads VALUES (1, 'RoadX', ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0));
INSERT INTO roads VALUES (2, 'RoadY', ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)', 0));

SELECT * FROM roads;

--1. Wyznacz całkowitą długość dróg w analizowanym mieście.

SELECT SUM(ST_Length(geom)) 
FROM roads;

-----

CREATE TABLE buildings (id INT PRIMARY KEY NOT NULL, name VARCHAR(50), height INT, geom GEOMETRY);

--2. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego BuildingA.

INSERT INTO buildings VALUES (1, 'BuildingA', 65, ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))',0));

SELECT name, ST_AsText(geom) AS WKT, ST_AREA(geom) AS area, ST_PERIMETER(geom) AS perimeter
FROM buildings
WHERE name LIKE '%A';

-----

INSERT INTO buildings VALUES (2, 'BuildingB', 21, ST_GeomFromText('POLYGON((4 5,6 5, 6 7, 4 7, 4 5))',0));
INSERT INTO buildings VALUES (3, 'BuildingC', 22, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))',0));
INSERT INTO buildings VALUES (4, 'BuildingD', 3, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))',0));
INSERT INTO buildings VALUES (5, 'BuildingF', 1, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))',0));

--3. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.

SELECT name, ST_AREA(geom) AS area
FROM buildings
ORDER BY name;

-----

--4. Wypisz nazwy i obwody 2 budynków o największej powierzchni.

SELECT name, ST_AREA(geom) AS area
FROM buildings
ORDER BY ST_AREA(geom) DESC
LIMIT 2;

-----

CREATE TABLE points (id INT PRIMARY KEY NOT NULL, name VARCHAR(50), number INT, geom GEOMETRY);

INSERT INTO points VALUES (1, 'G', 35, ST_GeomFromText('POINT(1 3.5)',0));

--5. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.

SELECT ST_Distance(buildings.geom, points.geom) AS shortest_distance -- ST_Length(ST_ShortestLine(buildings.geom, points.geom)) as a
FROM buildings, points 
WHERE buildings.name='BuildingC' AND points.name='G';

-----

--6. Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB.

SELECT ST_Area(ST_Difference((SELECT geom
							  FROM buildings 
							  WHERE name = 'BuildingC'), ST_Buffer((SELECT geom
																	FROM buildings 
																	WHERE name = 'BuildingB'), 0.5))) AS area;
		
-----

--7. Wybierz te budynki, których centroid(ST_Centroid) znajduje się powyżej drogi RoadX.

SELECT buildings.name
FROM buildings, roads
WHERE roads.name = 'RoadX' AND ST_Y(ST_Centroid(buildings.geom)) > ST_Y(ST_Centroid(roads.geom));

-----

--8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

SELECT ST_Area(ST_SymDifference(geom, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')))
	FROM buildings
	WHERE name = 'BuildingC';
