-- Database: testdb

-- DROP DATABASE IF EXISTS testdb;

CREATE DATABASE testdb
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
	
CREATE EXTENSION postgis;
	
--4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) 
--położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające 
--to kryterium zapisz do osobnej tabeli tableB.

SELECT COUNT(popp)
FROM popp, majrivers
WHERE ST_Distance(popp.geom, majrivers.geom) < 1000 AND popp.f_codedesc LIKE 'Building';

SELECT popp.* INTO tableB
FROM popp, majrivers
WHERE ST_Distance(popp.geom, majrivers.geom) < 1000 AND popp.f_codedesc LIKE 'Building';

SELECT * FROM tableB;

-----

--5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports zaimportuj nazwy lotnisk, 
--ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.  

SELECT name, elev, geom INTO airportsNew 
FROM airports;

-----

--5a. Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.  

SELECT name as west_airport, ST_X(geom) 
FROM airportsNew
ORDER BY ST_X(geom) DESC
LIMIT 1;

SELECT name as east_airport, ST_X(geom) 
FROM airportsNew
ORDER BY ST_X(geom) ASC
LIMIT 1;

--5b. Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone
--jest w punkcie środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. 
--Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.

INSERT INTO airportsNew(name,elev,geom) VALUES
(
	'airportB',
	1234,
	(SELECT ST_Centroid(
		ST_ShortestLine(
			(SELECT geom FROM airportsNew WHERE name LIKE 'ANNETTE ISLAND'), 
			(SELECT geom FROM airportsNew WHERE name LIKE 'ATKA'))))
);

-----
	
--6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek
--od najkrótszej linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer(ST_ShortestLine(lakes.geom, airportsNew.geom), 1000))
	FROM lakes, airportsNew
	WHERE lakes.names LIKE 'Iliamna Lake' AND airportsNew.name LIKE 'AMBLER';
	
-----
	
--7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących 
--poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).  

SELECT SUM(ST_Area(trees.geom)), trees.vegdesc
	FROM trees, tundra, swamp
	WHERE ST_Within(trees.geom, tundra.geom) OR ST_Within(trees.geom, swamp.geom)
	GROUP BY trees.vegdesc;
	

	

	