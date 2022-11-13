-- Database: bdp_05

-- DROP DATABASE IF EXISTS bdp_05;

CREATE DATABASE bdp_05
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
CREATE EXTENSION postgis; 


--1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia
--ustal jako niezdefiniowany. Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT.

CREATE TABLE obiekty (id INT PRIMARY KEY, name VARCHAR(20), geometry GEOMETRY); 

--obiekt1
INSERT INTO obiekty(id, name, geometry)  VALUES
	(1, 'obiekt1', ST_GeomFromText('MULTICURVE( (0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'));

--obiekt2
INSERT INTO obiekty(id, name, geometry)  VALUES
	(2, 'obiekt2', ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE(CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6, 14 6)), CIRCULARSTRING(11 2, 13 2, 11 2))'));

--obiekt3
INSERT INTO obiekty(id, name, geometry)  VALUES
	(3, 'obiekt3', ST_GeomFromText('POLYGON((7 15, 12 13, 10 17, 7 15))'));

--obiekt4
INSERT INTO obiekty(id, name, geometry)  VALUES
	(4, 'obiekt4', ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'));

--obiekt5
INSERT INTO obiekty(id, name, geometry)  VALUES
	(5, 'obiekt5', ST_GeomFromText('MULTIPOINT(30 30 59, 38 32 234)'));
	
--obiekt6
INSERT INTO obiekty(id, name, geometry)  VALUES
	(6, 'obiekt5', ST_GeomFromText('GEOMETRYCOLLECTION(POINT(4 2),LINESTRING(1 1,3 2))'));
	
SELECT * FROM obiekty;


--1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
--obiekt 3 i 4.

SELECT ST_Area(
	 ST_Buffer(
		 ST_ShortestLine(
			(SELECT geometry 
			 FROM obiekty 
			 WHERE name = 'obiekt3'), 
			  (SELECT geometry 
			   FROM obiekty 
			   WHERE name = 'obiekt4')), 5));
	
	
--2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te
--warunki.

UPDATE obiekty 
SET GEOMETRY = ST_MakePolygon(ST_AddPoint(geometry, 'POINT(20 20)')) 
WHERE name = 'obiekt4';


--3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty(id, name, geometry)  
VALUES(7, 'obiekt7', ST_Collect((SELECT geometry 
							   FROM obiekty 
							   WHERE name = 'obiekt3'), (SELECT geometry 
														 FROM obiekty 
														 WHERE name = 'obiekt4')));


--4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie
--zawierających łuków.

SELECT ST_Area(ST_Buffer(geometry, 5))
	FROM obiekty
	WHERE NOT ST_HasArc(geometry);
	
SELECT SUM(ST_Area(ST_Buffer(geometry, 5)))
	FROM obiekty
	WHERE NOT ST_HasArc(geometry);



