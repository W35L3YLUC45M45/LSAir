/* FITXERO CON TODAS LAS QUERIES PARA GENERAR LOS DATASETS O CSV DEL CASE STUDY 1*/

-- Planes (Dataset 1)

SELECT DISTINCT plane.planeID, plane.retirement_year, planetype.type_name 'Plane_type_name', airline.name AS 'Airline_name', country.name AS 'Country_name', COUNT(maintenance.maintenanceID) AS 'Times_maintained', COUNT(DISTINCT piecemaintenance.pieceID) AS 'Diferent_pieces_changed', SUM(piece.cost) AS 'Cost_changing_pieces'
FROM plane
JOIN airline ON plane.airlineID = airline.airlineID
JOIN country ON airline.countryID = country.countryID
JOIN planetype ON planetype.planetypeID = plane.planetypeID
LEFT JOIN maintenance ON maintenance.planeID = plane.planeID
LEFT JOIN piecemaintenance ON maintenance.maintenanceID = piecemaintenance.maintenanceID
LEFT JOIN piece ON piece.pieceID = piecemaintenance.pieceID
-- belongs to airlines from countries whose name starts by S.
WHERE country.name LIKE 'S%'
AND plane.retirement_year > YEAR(now()) - 3
GROUP BY plane.planeID, airline.airlineID; 

-- airports, city and their relations with country (Dataset 2)

SELECT DISTINCT airport.airportID, airport.name AS 'Airport_name', airport.altitude, airport.cityID, city.name AS 'City_name', city.timezone ,country.countryID AS "Country_ID", country.name AS 'Country_name' FROM airport 
JOIN route ON (airport.airportID = route.destination_airportID OR airport.airportID = route.departure_airportID)
JOIN routeairline ON route.routeID = routeairline.routeID 
JOIN airline ON routeairline.airlineID = airline.airlineID
JOIN city ON airport.cityID = city.cityID
JOIN country ON country.countryID = city.countryID
WHERE airline.airlineID IN (SELECT DISTINCT airline.airlineID
							FROM plane
							JOIN airline ON plane.airlineID = airline.airlineID
							JOIN country ON airline.countryID = country.countryID
							JOIN planetype ON planetype.planetypeID = plane.planetypeID
							-- belongs to airlines from countries whose name starts by S.
							WHERE country.name LIKE 'S%'
							AND plane.retirement_year > YEAR(now()) - 3)
;

-- Country

SELECT DISTINCT country.countryID AS "Country_ID", country.name AS 'Country_name' FROM airport 
JOIN route ON (airport.airportID = route.destination_airportID OR airport.airportID = route.departure_airportID)
JOIN routeairline ON route.routeID = routeairline.routeID 
JOIN airline ON routeairline.airlineID = airline.airlineID
JOIN city ON airport.cityID = city.cityID
JOIN country ON country.countryID = city.countryID
WHERE airline.airlineID IN (SELECT DISTINCT airline.airlineID
							FROM plane
							JOIN airline ON plane.airlineID = airline.airlineID
							JOIN country ON airline.countryID = country.countryID
							JOIN planetype ON planetype.planetypeID = plane.planetypeID
							-- belongs to airlines from countries whose name starts by S.
							WHERE country.name LIKE 'S%'
							AND plane.retirement_year > YEAR(now()) - 3)
;

-- ______________relacion dataset 1 i 2

SELECT '103' AS planeID, '3125' AS departure_airportID, '5195' AS destination_airportID
UNION
SELECT DISTINCT plane.planeID, route.departure_airportID, route.destination_airportID
FROM plane 
JOIN airline ON airline.airlineID = plane.airlineID
JOIN routeairline ON routeairline.airlineID = airline.airlineID
LEFT JOIN route ON route.routeID = routeairline.routeID
WHERE plane.planeID IN (SELECT pl.planeID
						FROM plane AS pl
						JOIN airline ON pl.airlineID = airline.airlineID
						JOIN country ON airline.countryID = country.countryID
						JOIN planetype ON planetype.planetypeID = pl.planetypeID
						-- belongs to airlines from countries whose name starts by S.
						WHERE country.name LIKE 'S%'
						AND plane.retirement_year > YEAR(now()) - 3)
                        GROUP BY route.routeID;
                        


