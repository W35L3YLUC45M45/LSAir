-- 5.1 

SELECT airline.airlineID, airline.name, (SELECT count(distinct flight.flightID)
										FROM flight INNER JOIN plane ON flight.planeID = plane.planeID
										INNER JOIN airline AS al ON plane.airlineID = al.airlineID
										INNER JOIN flighttickets ON flight.flightID = flighttickets.flightID
										LEFT JOIN checkin  ON checkin.flightticketID =  flighttickets.flightticketID
										WHERE checkinID IS NULL AND al.airlineID = airline.airlineID) AS overbooked_flights
FROM flight 
INNER JOIN plane ON flight.planeID = plane.planeID
INNER JOIN airline ON plane.airlineID = airline.airlineID
INNER JOIN flighttickets ON flight.flightID = flighttickets.flightID
LEFT JOIN checkin  ON checkin.flightticketID =  flighttickets.flightticketID
WHERE checkinID IS NULL
GROUP BY airline.airlineID
HAVING count(flighttickets.passengerID) >
                            (SELECT count(flighttickets.passengerID)
							FROM flight INNER JOIN plane ON flight.planeID = plane.planeID
							INNER JOIN airline AS al ON plane.airlineID = al.airlineID
							INNER JOIN flighttickets ON flight.flightID = flighttickets.flightID
							LEFT JOIN checkin ON checkin.flightticketID =  flighttickets.flightticketID
							WHERE al.airlineID = airline.airlineID) * 0.1;                      

                            
/* Esto lo guardo para hacer pruebas
SELECT * 
FROM flight INNER JOIN plane ON flight.planeID = plane.planeID
INNER JOIN airline ON plane.airlineID = airline.airlineID
INNER JOIN flighttickets ON flight.flightID = flighttickets.flightID
LEFT JOIN checkin  ON checkin.flightticketID =  flighttickets.flightticketID
WHERE checkinID IS NULL AND airline.airlineID = 3830;
*/

-- 5.2 (Query) 

SELECT ABS(departure_city.timezone - destination_city.timezone) AS timezone_difference, count(distinct lostObjectID) AS lost_objects
FROM route INNER JOIN airport AS departure ON departure.airportID = route.departure_airportID
INNER JOIN airport AS destination ON destination.airportID = route.destination_airportID
INNER JOIN city AS departure_city ON departure.cityID = departure_city.cityID
INNER JOIN city AS destination_city ON destination.cityID = destination_city.cityID
INNER JOIN flight ON flight.routeId = route.routeID
INNER JOIN flightTickets ON flighttickets.flightID = flight.flightID
INNER JOIN passenger ON flighttickets.passengerID = passenger.passengerID
INNER JOIN claims ON passenger.passengerID = claims.passengerID
INNER JOIN lostobject ON lostobject.lostobjectID = claims.claimID
INNER JOIN luggage ON luggage.luggageID = lostobject.luggageID AND luggage.flightID = flight.flightID
WHERE claims.date < date_add(flight.date, INTERVAL 3 MONTH)
GROUP BY timezone_difference
ORDER BY timezone_difference DESC;

/* Esto lo guardo para hacer pruebas
SELECT lostobject.*, luggage.flightID, departure_city.timezone - destination_city.timezone AS timezone_difference, claims.date, flight.date
FROM route INNER JOIN airport AS departure ON departure.airportID = route.departure_airportID
INNER JOIN airport AS destination ON destination.airportID = route.destination_airportID
INNER JOIN city AS departure_city ON departure.cityID = departure_city.cityID
INNER JOIN city AS destination_city ON destination.cityID = destination_city.cityID
INNER JOIN flight ON flight.routeId = route.routeID
INNER JOIN flightTickets ON flighttickets.flightID = flight.flightID
INNER JOIN passenger ON flighttickets.passengerID = passenger.passengerID
INNER JOIN claims ON passenger.passengerID = claims.passengerID
INNER JOIN lostobject ON lostobject.lostobjectID = claims.claimID
INNER JOIN luggage ON luggage.luggageID = lostobject.luggageID AND luggage.flightID = flight.flightID
WHERE claims.date < date_add(flight.date, INTERVAL 3 MONTH) AND departure_city.timezone - destination_city.timezone = 4
;*/

-- 5.3 (Query) Esta en teoria esta bien, aunque no se si es obligatorio que los pasajeros hayan viajado con Ryanair. Por ahora he puesto que si.

SELECT person.name, person.surname, person.phone_number, (SELECT count(*) FROM languageperson AS lp WHERE lp.personID = languageperson.personID GROUP BY lp.personID) AS lenguages_spoken
FROM route INNER JOIN airport AS departure ON departure.airportID = route.departure_airportID
INNER JOIN airport AS destination ON destination.airportID = route.destination_airportID
INNER JOIN city AS departure_city ON departure.cityID = departure_city.cityID
INNER JOIN city AS destination_city ON destination.cityID = destination_city.cityID
INNER JOIN flight ON flight.routeId = route.routeID
INNER JOIN flightTickets ON flighttickets.flightID = flight.flightID
INNER JOIN passenger ON flighttickets.passengerID = passenger.passengerID
INNER JOIN plane ON flight.planeID = plane.planeID
INNER JOIN airline ON airline.airlineID = plane.airlineID
INNER JOIN person ON person.personID = passenger.passengerID
INNER JOIN languageperson ON languageperson.personID = person.personID
INNER JOIN language ON language.languageID = languageperson.languageID
WHERE ABS(departure_city.timezone - destination_city.timezone) >= 3
/*AND airline.name LIKE 'Ryanair'*/ AND language.name LIKE 'Chavacano'
GROUP BY languageperson.personID
HAVING lenguages_spoken > 1;

-- 5.4 (Query) Esta parece que esta bien.

SELECT departure.name, (SELECT count(*)
						FROM route INNER JOIN airport AS dp ON dp.airportID = route.departure_airportID
						INNER JOIN flight ON flight.routeId = route.routeID
						INNER JOIN flightTickets ON flighttickets.flightID = flight.flightID
						INNER JOIN passenger ON flighttickets.passengerID = passenger.passengerID
                        WHERE dp.airportID = departure.airportID
						GROUP BY dp.airportID) AS total_number_passengers
FROM route INNER JOIN airport AS departure ON departure.airportID = route.departure_airportID
INNER JOIN airport AS destination ON destination.airportID = route.destination_airportID
INNER JOIN city AS destination_city ON destination.cityID = destination_city.cityID
INNER JOIN flight ON flight.routeId = route.routeID
INNER JOIN flightTickets ON flighttickets.flightID = flight.flightID
INNER JOIN passenger ON flighttickets.passengerID = passenger.passengerID
INNER JOIN country ON country.countryID = destination_city.countryID
INNER JOIN forbiddenproducts ON forbiddenproducts.countryID = destination_city.countryID
INNER JOIN luggage ON luggage.flightID = flight.flightID
INNER JOIN handluggage ON handluggage.productID = forbiddenproducts.productID AND handluggageID = luggage.luggageID
GROUP BY departure.airportID;

-- 5.5 (Query) Esta tambien parece estar bien.

SELECT planetype.type_name-- , count(distinct flight.flightID) AS flights, SUM(route.distance), count(distinct airline.airlineID), SUM(status LIKE 'Perfect') 
FROM planetype INNER JOIN plane ON plane.planetypeID = planetype.planetypeID
INNER JOIN flight ON flight.planeID = plane.planeID
INNER JOIN status ON status.statusID = flight.statusId
INNER JOIN route ON flight.routeID = route.routeID
INNER JOIN airline ON airline.airlineID = plane.airlineID
GROUP BY planetype.planetypeID
HAVING SUM(route.distance) > 1000000 AND count(distinct flight.flightID) > 500 
AND count(distinct airline.airlineID) > 70 AND SUM(status LIKE 'Perfect')  >= count(distinct flight.flightID)*0.53
ORDER BY planetype.planetypeID;

-- 5.6 (Query)

(
SELECT 'flight_attendant' AS employee_type, language.name, count(distinct languageperson.personID) AS people_who_speak
FROM employee INNER JOIN flight_attendant ON flight_attendant.flightattendantID = employee.employeeId
INNER JOIN languageperson ON languageperson.personID = employee.employeeID
INNER JOIN language ON language.languageID = languageperson.languageID
GROUP BY languageperson.languageID
)
UNION
(
SELECT 'other_employee', language.name, count(distinct languageperson.personID)
FROM employee INNER JOIN languageperson ON languageperson.personID = employee.employeeID
INNER JOIN language ON language.languageID = languageperson.languageID
WHERE employee.employeeId NOT IN (SELECT flightattendantID FROM flight_attendant)
GROUP BY languageperson.languageID
)
ORDER BY people_who_speak DESC;