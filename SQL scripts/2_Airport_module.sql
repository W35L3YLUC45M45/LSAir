-- 2.1 Airlines and petrol capacity
-- We want to find the airlines and the number of routes 
-- they operate where the minimum petrol
-- fly the route is greater than the capacity of the aircraft 
-- assigned to the route. We only need 
-- to consider routes between airports in different countries. 
-- The data to retrieve is:
-- Airline name | Routes

SELECT airl.name AS 'airline name', COUNT(r.routeID) AS '# routes'/*, pt.capacity AS 'Aircraft capacity', r.minimum_petrol AS 'Minimum petrol' , r.departure_airportID AS 'Route departure', r.destination_airportID AS 'Route destination'*/
FROM Airline AS airl
JOIN Plane AS pl ON airl.airlineID = pl.airlineID
JOIN Planetype AS pt ON pl.planetypeID = pt.planetypeID
JOIN Routeairline AS rairl ON airl.airlineID = rairl.airlineID
JOIN Route AS r ON rairl.routeID = r.routeID
JOIN Airport AS airp ON r.destination_airportID = airp.airportID
JOIN Airport AS airp2 ON r.departure_airportID = airp2.airportID
JOIN City AS city1 ON airp.cityID = city1.cityID
JOIN City AS city2 ON airp2.cityID = city2.cityID
JOIN Country AS c1 ON city1.countryID = c1.countryID
JOIN Country AS c2 ON city2.countryID = c2.countryID
WHERE 	pt.capacity < r.minimum_petrol AND c1.countryID <> c2.countryID
/*
		AND NOT c.countryID IN (SELECT c2.countryID FROM Country AS c2 WHERE c.countryID <> c2.countryID)
		AND rairl.planetypeID = pt.planetypeID
*/
-- GROUP BY airl.airlineID;
GROUP BY airl.airlineID /*, r.departure_airportID*/;

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.2 Mechanic grades
-- We want to make a study to relate the grade a mechanic 
-- has and the duration of the maintenance s/he usually does. 
-- Therefore, list the ranges of marks (i.e., 0-1, 1-2... 9-10) 
-- and the average duration of the maintenance carried out by 
-- the mechanics who fall into each of the ranges. 
-- Only maintenance where less than 10 pieces have been 
-- replaced should be taken into account. The data to retrieve 
-- is:
-- Grade range | Duration average | num_pieces (validation)

SELECT CONCAT(FLOOR(mech.grade), '-', FLOOR(mech.grade) + 1) AS 'grade range' , AVG(maint.duration) AS 'duration average'
FROM mechanic AS mech
JOIN Maintenance AS maint ON mech.mechanicID = maint.mechanicID
JOIN Piecemaintenance AS pmaint ON maint.maintenanceID = pmaint.maintenanceID
JOIN Piece AS p ON pmaint.pieceID = p.pieceID
WHERE (SELECT COUNT(DISTINCT pmaint2.pieceID) FROM 
		Maintenance AS maint2
        JOIN piecemaintenance AS pmaint2 ON maint2.maintenanceID = pmaint2.maintenanceID
        WHERE maint2.maintenanceID = maint.maintenanceID
        GROUP BY pmaint2.maintenanceID) < 10
GROUP BY FLOOR(mech.grade)
ORDER BY FLOOR(mech.grade) ASC;

-- Verification Query
/*
SELECT maint.maintenanceID AS 'Maintenance ID', AVG(maint.duration) AS 'duration average', mech.grade AS 'Mechanic grade'
        , (SELECT COUNT(DISTINCT pmaint2.pieceID) 
        FROM Maintenance AS maint2
        JOIN piecemaintenance AS pmaint2 ON maint2.maintenanceID = pmaint2.maintenanceID
        WHERE maint2.maintenanceID = maint.maintenanceID
        GROUP BY pmaint2.maintenanceID) AS 'Number of pieces'
FROM mechanic AS mech
JOIN Maintenance AS maint ON mech.mechanicID = maint.mechanicID
JOIN Piecemaintenance AS pmaint ON maint.maintenanceID = pmaint.maintenanceID
JOIN Piece AS p ON pmaint.pieceID = p.pieceID
WHERE (SELECT COUNT(DISTINCT pmaint2.pieceID) FROM 
		Maintenance AS maint2
        JOIN piecemaintenance AS pmaint2 ON maint2.maintenanceID = pmaint2.maintenanceID
        WHERE maint2.maintenanceID = maint.maintenanceID
        GROUP BY pmaint2.maintenanceID) < 10
GROUP BY maint.maintenanceID
ORDER BY mech.grade ASC;
*/

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.3 Airports and mean distance routes
-- We want to know which airports have the average distance 
-- of routes departing from them greater than the average 
-- distance of routes departing from airports in the same 
-- country. The data to retrieve is:
-- Airport id | Country id | Average distance

SELECT airp.airportID AS 'airport id', c.countryID AS 'country id', AVG(r.distance) AS 'average distance'
FROM airport AS airp 
JOIN Route AS r ON airp.airportID = r.departure_airportID
JOIN City ON airp.cityID = city.cityID
JOIN Country AS c ON city.countryID = c.countryID
GROUP BY airp.airportID
HAVING AVG(r.distance) > (SELECT AVG(r2.distance)
							FROM airport AS airp2
							JOIN Route AS r2 ON airp2.airportID = r2.departure_airportID
							JOIN City AS city2 ON airp2.cityID = city2.cityID
							JOIN Country AS c2 ON city2.countryID = c2.countryID
                            WHERE c2.countryID = c.countryID
                            GROUP BY c2.name
                            ORDER BY c2.name ASC)
ORDER BY c.countryID;

-- Query de validació
/*
SELECT airp.airportID AS 'airport id', c.countryID AS 'country id', AVG(r.distance) AS 'average distance routes departing from airport', (SELECT AVG(r2.distance)								FROM airport AS airp2
				JOIN Route AS r2 ON airp2.airportID = r2.departure_airportID
				JOIN City AS city2 ON airp2.cityID = city2.cityID
				JOIN Country AS c2 ON city2.countryID = c2.countryID
				WHERE c2.countryID = c.countryID
				GROUP BY c2.name
ORDER BY c2.name ASC) AS average_distance_routes_departing_from_the_same_country
FROM airport AS airp 
JOIN Route AS r ON airp.airportID = r.departure_airportID
JOIN City ON airp.cityID = city.cityID
JOIN Country AS c ON city.countryID = c.countryID
GROUP BY airp.airportID
HAVING AVG(r.distance) > average_distance_routes_departing_from_the_same_country
ORDER BY c.countryID;
*/

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.4 Airlines and routes
-- We want to find active airlines that do not have any routes departing from or entering your 
-- home country sorted by longest route duration. The data to retrieve is:
-- Airline name | Airline id | Country name | Longest route duration

SELECT airl.name AS 'airline name', airl.airlineID AS 'airline id', c3.name AS 'country name' , MAX(r.time) AS 'longest route duration'-- , airl.active AS 'status'
FROM Airline AS airl
JOIN Routeairline AS rairl ON airl.airlineID = rairl.airlineID
JOIN Route AS r ON rairl.routeID = r.routeID
JOIN Airport AS airp ON r.destination_airportID = airp.airportID
JOIN Airport AS airp2 ON r.departure_airportID = airp2.airportID
JOIN City AS city1 ON airp.cityID = city1.cityID
JOIN City AS city2 ON airp2.cityID = city2.cityID
JOIN Country AS c ON city1.countryID = c.countryID
JOIN Country AS c2 ON city2.countryID = c2.countryID
JOIN Country AS c3 ON c3.countryID = airl.countryID
WHERE airl.active LIKE 'Y' AND NOT c.name LIKE 'Spain' AND NOT c2.name LIKE 'Spain' AND r.time IS NOT NULL
GROUP BY airl.airlineID
ORDER BY MAX(r.time) ASC;

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.5 Pieces replaced
-- We want to list planes that have had to replace the same 
-- piece more than once, and that the cost of changing those 
-- pieces was more than half of the cost of all other parts 
-- changed on those planes. The data to retrieve is:
-- Plane id | Piece name | # Pieces replaced

SELECT *, COUNT(piecemaintenance.maintenanceID) 
FROM piecemaintenance 
JOIN maintenance ON piecemaintenance.maintenanceID = maintenance.maintenanceID 
JOIN piece ON piecemaintenance.pieceID = piece.pieceID 
GROUP BY piecemaintenance.pieceID, maintenance.planeID, piece.cost 
HAVING (COUNT(piecemaintenance.maintenanceID)*piece.cost) > (SELECT (SUM(piece.cost)/2) FROM piecemaintenance AS pm  
															JOIN maintenance AS m ON pm.maintenanceID = m.maintenanceID                
															JOIN piece AS p ON pm.pieceID = p.pieceID                                           
															WHERE maintenance.planeID = m.planeID AND                   
															piece.pieceID <> p.pieceID                
															GROUP BY maintenance.planeID) 
		AND COUNT(piecemaintenance.maintenanceID) > 1
ORDER BY COUNT(piecemaintenance.maintenanceID) DESC;

-- LLEGIR MEMÒRIA PER A AQUESTA QUERY, PER COMPLEMENTAR LA EXPLICACIÓ DEL PROCÉS DE DESENVOLUPAMENT DE LA QUERY I LA VALIDACIÓ

-- Aquesta query d'abaix havia de ser la que funcionés en realitat, però degut a raons explicades a la memòria,
-- ens vam veure obligats d'afegir el '*' de tot, perquè no ens deixava mostrar els paràmetres seleccionats
-- desitjats amb la filtració de resultats adient amb JOINs que vam afegir.

/*
SELECT maintenance.planeID, piece.name, COUNT(piecemaintenance.maintenanceID) FROM piecemaintenance
JOIN maintenance ON piecemaintenance.maintenanceID = maintenance.maintenanceID
JOIN piece ON piecemaintenance.pieceID = piece.pieceID
GROUP BY piece.pieceID, maintenance.planeID, piece.cost
HAVING (COUNT(piecemaintenance.maintenanceID))*piece.cost > (SELECT (SUM(p.cost))/2 FROM piecemaintenance AS pm
															JOIN maintenance AS m ON pm.maintenanceID = m.maintenanceID
															JOIN piece AS p ON pm.pieceID = p.pieceID
                                                            WHERE maintenance.planeID = m.planeID AND
																  piece.pieceID <> p.pieceID
															GROUP BY maintenance.planeID
                                                            )
ORDER BY COUNT(piecemaintenance.maintenanceID) DESC;
*/

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.6 Routes cancelled (Trigger)
-- As we all know, this last year has been hard, not only on a psychological level, but also on 
-- an economic level, many companies have been affected by the measures applied by 
-- governments. For example, airlines are constantly affected by the closing of borders in some 
-- countries, which causes them to cancel routes between specific countries. To consider all 
-- these facts we have been asked to store in a table called RoutesCancelled (which will 
-- contain the name of the destination, the name of the origin, the number of airlines that 
-- managed this map and the date on which the route was deleted) the routes that are being 
-- cancelled. In addition, when a route is deleted, we have also been asked to delete the route 
-- from the RouteAirline table.

-- LLEGIR MEMÒRIA PER A AQUESTA QUERY, PER COMPLEMENTAR LA EXPLICACIÓ DEL PROCÉS DE DESENVOLUPAMENT DE LA QUERY I LA VALIDACIÓ

DROP TABLE IF EXISTS RoutesCancelled;
CREATE TABLE RoutesCancelled(
    destination_name VARCHAR(50),    -- JOIN Route, Airport, City
    origin_name VARCHAR(50),        -- JOIN Route, Airport, City
    num_airlines INT,                -- COUNT(airline.airlineID)
    date_route_deletion DATE        -- NOW()
);

DELIMITER $$
DROP TRIGGER IF EXISTS routes_cancelled $$

CREATE TRIGGER routes_cancelled 
    BEFORE DELETE ON Route
    FOR EACH ROW
BEGIN
    INSERT INTO RoutesCancelled(destination_name, origin_name, num_airlines, date_route_deletion)
    SELECT c.name, c1.name, COUNT(airl.airlineID), NOW() FROM Airline AS airl 
    JOIN RouteAirline AS rairl ON airl.airlineID = rairl.airlineID
    JOIN Route AS r ON rairl.routeID = r.routeID
    JOIN Airport AS airp ON r.departure_airportID = airp.airportID
    JOIN Airport AS airp1 ON r.destination_airportID = airp1.airportID
    JOIN City AS c ON c.cityID = airp.cityID
    JOIN City AS c1 ON c1.cityID = airp1.cityID
    WHERE r.routeID = old.routeID;

    DELETE FROM RouteAirline WHERE routeID = old.routeID;
END $$
DELIMITER ;



-- Query de validació del trigger
/*
DROP TABLE IF EXISTS RoutesCancelled;
CREATE TABLE RoutesCancelled(
    destination_name VARCHAR(50),    -- JOIN Route, Airport, City
    origin_name VARCHAR(50),        -- JOIN Route, Airport, City
    num_airlines INT,                -- COUNT(airline.airlineID)
    date_route_deletion DATE        -- NOW()
);

DELIMITER $$
DROP TRIGGER IF EXISTS routes_cancelled $$

CREATE TRIGGER routes_cancelled 
    BEFORE DELETE ON RouteTrigger
    FOR EACH ROW
BEGIN
    INSERT INTO RoutesCancelled(destination_name, origin_name, num_airlines, date_route_deletion)
    SELECT c.name, c1.name, COUNT(airl.airlineID), NOW() FROM Airline AS airl 
    JOIN RouteAirline AS rairl ON airl.airlineID = rairl.airlineID
    JOIN Route AS r ON rairl.routeID = r.routeID
    JOIN Airport AS airp ON r.departure_airportID = airp.airportID
    JOIN Airport AS airp1 ON r.destination_airportID = airp1.airportID
    JOIN City AS c ON c.cityID = airp.cityID
    JOIN City AS c1 ON c1.cityID = airp1.cityID
    WHERE r.routeID = old.routeID;

    DELETE FROM RouteAirlineTrigger WHERE routeID = old.routeID;
END $$
DELIMITER ;

SELECT * FROM RoutesCancelled;

USE lsair;
DELETE FROM RouteTrigger WHERE routeID >= 773 AND routeID <= 777; 

select * from routeAirlineTrigger;

CREATE TABLE routeTrigger
SELECT * FROM Route;

CREATE TABLE routeAirlineTrigger
SELECT * FROM RouteAirline;

DELETE FROM RouteTrigger WHERE routeID >= 1 AND routeID <= 5; 

SELECT * FROM routeTrigger;

DROP TABLE routetrigger;
DROP TABLE routeAirlineTrigger;
DELETE FROM RoutesCancelled;
*/

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.7 Mechanics firings (Trigger)
-- From the mechanics unions, we have been asked to have a history of the reason for each 
-- of the firings of mechanics that have the different airports. The reasons for the dismissals 
-- will be stored in the table MechanicsFirings (id of the mechanic, name, surname, date of 
-- birth of the person and reason for firing). You have to take into account that there can be 3 
-- types of reasons for dismissal: 
-- • Retirement: If the date when the person is deleted from the table is 65 years old or
-- older. 
-- • Not completing the evaluation period: When the sum of repairs that the mechanic has 
-- done does not add up to more than 10 hours. 
-- • Firing without reason: When it does not belong to any of the previous types. 
-- You have also to remove the maintenance and the pieces (PieceMaintenance table) 
-- replaced by them.

-- LLEGIR MEMÒRIA PER A AQUESTA QUERY, PER COMPLEMENTAR LA EXPLICACIÓ DEL PROCÉS DE DESENVOLUPAMENT DE LA QUERY I LA VALIDACIÓ

DROP TABLE IF EXISTS MechanicsFirings;
CREATE TABLE MechanicsFirings(
    mechanic_id INT,    
    name VARCHAR(50),        
    surname VARCHAR(50),            
    birth_date DATE,    
    firing_reason TEXT         
);

DELIMITER $$
DROP TRIGGER IF EXISTS dismissal $$

CREATE TRIGGER dismissal
    BEFORE DELETE ON Mechanic FOR EACH ROW
BEGIN
    -- • Retirement: If the date when the person is deleted from the table is 65 years old or
    -- older. 
    IF (SELECT (YEAR(NOW()) - YEAR(person.born_date)) >= 65 FROM person WHERE person.personID = OLD.mechanicID) THEN 
        INSERT INTO MechanicsFirings(mechanic_id, name, surname, birth_date, firing_reason)
        SELECT p.personID, p.name, p.surname, p.born_date, "Retirement" 
        FROM Person AS p
        JOIN Mechanic AS mech ON mech.mechanicID = p.personID
        JOIN Country AS c ON p.countryID = c.countryID
        JOIN City AS city ON c.countryID = city.cityID
        JOIN Airport AS airp ON city.cityID = airp.cityID
        WHERE mech.mechanicID = old.mechanicID
        GROUP BY mech.mechanicID;
        
    -- • Not completing the evaluation period: When the sum of repairs that the mechanic has 
    -- done does not add up to more than 10 hours. 
    ELSEIF (SELECT SUM(m.duration) <= 10 FROM maintenance as m WHERE m.mechanicid = OLD.mechanicID) THEN
        INSERT INTO MechanicsFirings(mechanic_id, name, surname, birth_date, firing_reason)
        SELECT p.personID, p.name, p.surname, p.born_date, "Not completing the evaluation period" 
        FROM Person AS p
        JOIN Mechanic AS mech ON mech.mechanicID = p.personID
        JOIN Maintenance AS m ON mech.mechanicID = m.mechanicID
		WHERE mech.mechanicID = old.mechanicID
        GROUP BY mech.mechanicID;
        
    -- • Firing without reason: When it does not belong to any of the previous types. 
    ELSE
        INSERT INTO MechanicsFirings(mechanic_id, name, surname, birth_date, firing_reason)
        SELECT p.personID, p.name, p.surname, p.born_date, "Firing without reason" 
        FROM Person AS p
        JOIN Mechanic AS mech ON mech.mechanicID = p.personID
        JOIN Maintenance AS m ON mech.mechanicID = m.mechanicID
		WHERE mech.mechanicID = old.mechanicID
        GROUP BY mech.mechanicID;
    END IF;
    
    DELETE maintenance, piecemaintenance FROM maintenance JOIN piecemaintenance
    WHERE maintenance.mechanicID IN (SELECT mech.mechanicID FROM Mechanic AS mech WHERE mech.mechanicID = old.mechanicID)
	AND piecemaintenance.maintenanceID = maintenance.maintenanceID;
END $$
DELIMITER ;



-- Query de validació del trigger
/*
DROP TABLE IF EXISTS MechanicsFirings;
CREATE TABLE MechanicsFirings(
    mechanic_id INT,    
    name VARCHAR(50),        
    surname VARCHAR(50),            
    birth_date DATE,    
    firing_reason TEXT         
);

CREATE TABLE PiecemaintenanceTrigger
SELECT * FROM Piecemaintenance;
DELETE FROM piecemaintenancetrigger;
INSERT INTO Piecemaintenancetrigger
SELECT * FROM Piecemaintenance;

DROP TABLE IF EXISTS MechanicTrigger;
CREATE TABLE MechanicTrigger
SELECT * FROM Mechanic;
INSERT INTO MechanicTrigger
SELECT * FROM Mechanic;

CREATE TABLE MaintenanceTrigger
SELECT * FROM Maintenance;
DELETE FROM MaintenanceTrigger;
INSERT INTO MaintenanceTrigger
SELECT * FROM Maintenance;

-- • Retirement: If the date when the person is deleted from the table is 65 years old or
-- older. 
DELIMITER $$
DROP TRIGGER IF EXISTS dismissal $$

CREATE TRIGGER dismissal
    BEFORE DELETE ON MechanicTrigger FOR EACH ROW
BEGIN
    -- • Retirement: If the date when the person is deleted from the table is 65 years old or
    -- older. 
    IF (SELECT (YEAR(NOW()) - YEAR(person.born_date)) >= 65 FROM person WHERE person.personID = OLD.mechanicID) THEN 
        INSERT INTO MechanicsFirings(mechanic_id, name, surname, birth_date, firing_reason)
        SELECT p.personID, p.name, p.surname, p.born_date, "Retirement" 
        FROM Person AS p
        JOIN Mechanic AS mech ON mech.mechanicID = p.personID
        JOIN Country AS c ON p.countryID = c.countryID
        JOIN City AS city ON c.countryID = city.cityID
        JOIN Airport AS airp ON city.cityID = airp.cityID
        WHERE mech.mechanicID = old.mechanicID
        GROUP BY mech.mechanicID;
        
    -- • Not completing the evaluation period: When the sum of repairs that the mechanic has 
    -- done does not add up to more than 10 hours. 
    ELSEIF (SELECT SUM(m.duration) <= 10 FROM maintenance as m WHERE m.mechanicid = OLD.mechanicID) THEN
        INSERT INTO MechanicsFirings(mechanic_id, name, surname, birth_date, firing_reason)
        SELECT p.personID, p.name, p.surname, p.born_date, "Not completing the evaluation period" 
        FROM Person AS p
        JOIN Mechanic AS mech ON mech.mechanicID = p.personID
        JOIN Maintenance AS m ON mech.mechanicID = m.mechanicID
		WHERE mech.mechanicID = old.mechanicID
        GROUP BY mech.mechanicID;
        
    -- • Firing without reason: When it does not belong to any of the previous types. 
    ELSE
        INSERT INTO MechanicsFirings(mechanic_id, name, surname, birth_date, firing_reason)
        SELECT p.personID, p.name, p.surname, p.born_date, "Firing without reason" 
        FROM Person AS p
        JOIN Mechanic AS mech ON mech.mechanicID = p.personID
        JOIN Maintenance AS m ON mech.mechanicID = m.mechanicID
		WHERE mech.mechanicID = old.mechanicID
        GROUP BY mech.mechanicID;
    END IF;
    
    DELETE maintenancetrigger, piecemaintenancetrigger FROM maintenancetrigger JOIN piecemaintenancetrigger
    WHERE maintenancetrigger.mechanicID IN (SELECT mech.mechanicID FROM MechanicTrigger AS mech WHERE mech.mechanicID = old.mechanicID)
	AND piecemaintenancetrigger.maintenanceID = maintenancetrigger.maintenanceID;
END $$
DELIMITER ;

SELECT * FROM MechanicTrigger;

select * from piecemaintenance;

SELECT * FROM mechanic;

SELECT * FROM mechanicsFirings
GROUP BY mechanic_id;

SELECT * FROM PiecemaintenanceTrigger;
SELECT * FROM MaintenanceTrigger
ORDER BY mechanicID;

DELETE FROM mechanicTrigger WHERE mechanicID = 103;

SELECT * FROM MechanicTrigger AS mech
RIGHT JOIN Maintenance AS m ON m.mechanicID = mech.mechanicID
JOIN PiecemaintenanceTrigger AS mt ON mt.maintenanceID = m.maintenanceID
JOIN Piece AS p ON p.pieceID = mt.pieceID
WHERE mech.mechanicID = 103
GROUP BY mt.maintenanceID
ORDER BY mech.mechanicID, mt.maintenanceID;
*/

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.8 Petrol updates (Trigger)
-- Every year, technological improvements are made in planes, which makes us a more and 
-- more environmentally sustainable society. For this reason, we want to have a history of the 
-- times that the amount of petrol is updated to carry out a route. Create a historical table called 
-- EnvironmentalReductions in which the route is stored (VARCHAR where the origin + 
-- destination are included in a single value), the difference with respect to the minimum value 
-- prior to the update and the date on which the update occurred. 

-- LLEGIR MEMÒRIA PER A AQUESTA QUERY, PER COMPLEMENTAR LA EXPLICACIÓ DEL PROCÉS DE DESENVOLUPAMENT DE LA QUERY I LA VALIDACIÓ

DROP TABLE IF EXISTS EnvironmentalReductions;
CREATE TABLE EnvironmentalReductions(
	route VARCHAR(100),	
    difference INT,		
    up_date DATE
);

DELIMITER $$
DROP TRIGGER IF EXISTS history_petrol $$
CREATE TRIGGER history_petrol
	BEFORE UPDATE ON Route FOR EACH ROW
BEGIN
	INSERT INTO EnvironmentalReductions(route, difference, up_date)
    SELECT CONCAT('DEPARTURE:', c.name, '(', country.name, ')', ' --> ', 'DESTINATION:', calt.name, '(', countryalt.name, ')') AS route_dest_dep, ABS(NEW.minimum_petrol - old.minimum_petrol) AS diff, NOW() FROM Route AS routealt
    JOIN Airport AS airp ON old.departure_airportID = airp.airportID
    JOIN Airport AS airpalt ON old.destination_airportID = airpalt.airportID
    JOIN City AS c ON c.cityID = airp.cityID
    JOIN City AS calt ON calt.cityID = airpalt.cityID
    JOIN Country AS country ON c.countryID = country.countryID
    JOIN Country AS countryalt ON calt.countryID = countryalt.countryID
    WHERE routealt.routeID = old.routeID;
END $$
DELIMITER ;



-- Query de validació del trigger
/*
DROP TABLE IF EXISTS EnvironmentalReductions;
CREATE TABLE EnvironmentalReductions(
	route VARCHAR(100),	
    difference INT,		
    up_date DATE
);

CREATE TABLE RouteTrigger1
SELECT * FROM Route;
DELETE FROM RouteTrigger1;
INSERT INTO RouteTrigger1
SELECT * FROM Route;

SELECT * FROM RouteTrigger1;
SELECT * FROM EnvironmentalReductions;

DELIMITER $$
DROP TRIGGER IF EXISTS history_petrol $$
CREATE TRIGGER history_petrol
	BEFORE UPDATE ON RouteTrigger1 FOR EACH ROW
BEGIN
	INSERT INTO EnvironmentalReductions(route, difference, up_date)
    SELECT CONCAT('DEPARTURE:', c.name, '(', country.name, ')', ' --> ', 'DESTINATION:', calt.name, '(', countryalt.name, ')') AS route_dest_dep, ABS(NEW.minimum_petrol - old.minimum_petrol) AS diff, NOW() FROM Route AS routealt
    JOIN Airport AS airp ON old.departure_airportID = airp.airportID
    JOIN Airport AS airpalt ON old.destination_airportID = airpalt.airportID
    JOIN City AS c ON c.cityID = airp.cityID
    JOIN City AS calt ON calt.cityID = airpalt.cityID
    JOIN Country AS country ON c.countryID = country.countryID
    JOIN Country AS countryalt ON calt.countryID = countryalt.countryID
    WHERE routealt.routeID = old.routeID;
END $$
DELIMITER ;

UPDATE RouteTrigger1
SET minimum_petrol = 30000
WHERE routeid >= 1 AND routeid <= 10;
*/

-- //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- 2.9 Yearly maintenance costs (Event)
-- We know that the cost of maintaining a plane is high, which is why the airlines, motivated by 
-- all the economic losses they have suffered during the pandemic, want to carry out a study 
-- on those planes that cost them the most to maintain. In order to carry out this study, they 
-- have asked us to write down each year in a table called MaintenanceCost, which will have 
-- the name of the plane and the economic costs of 
-- maintenance that it has meant during the year.

-- LLEGIR MEMÒRIA PER A AQUESTA QUERY, PER COMPLEMENTAR LA EXPLICACIÓ DEL PROCÉS DE DESENVOLUPAMENT DE LA QUERY I LA VALIDACIÓ

DROP TABLE IF EXISTS MaintenanceCost;
CREATE TABLE MaintenanceCost(
year  int,
planeName VARCHAR(255),
price INT
);

DELIMITER $$
DROP EVENT IF EXISTS YearlyMaintenanceCosts $$
CREATE EVENT YearlyMaintenanceCosts
    ON SCHEDULE
        EVERY 1 YEAR
    DO
        BEGIN

        INSERT INTO MaintenanceCost
        SELECT YEAR(CURDATE()), planetype.type_name , sum(cost) FROM
            piece INNER JOIN piecemaintenance ON piece.pieceID = piecemaintenance.pieceid
            INNER JOIN maintenance ON piecemaintenance.maintenanceID = maintenance.maintenanceID
            INNER JOIN plane ON plane.planeID = maintenance.planeID
            INNER JOIN planetype ON planetype.planetypeID = plane.planetypeID
            WHERE YEAR(maintenance.date) = YEAR(CURDATE())
            GROUP BY planetype.planetypeID;

        END $$
DELIMITER ;


-- Query de validació de l'event
/*
UPDATE MaintenanceEvent
SET date = '2021-02-02'
WHERE YEAR(date) < 1970;

CREATE TABLE MaintenanceEvent
SELECT * FROM Maintenance;
DELETE FROM MaintenanceEvent;
INSERT INTO MaintenanceEvent
SELECT * FROM Maintenance;

CREATE TABLE PieceEvent
SELECT * FROM Piece;
DELETE FROM PieceEvent;
INSERT INTO PieceEvent
SELECT * FROM Piece;

SELECT date FROM maintenance;
SELECT * FROM Maintenanceevent
WHERE YEAR(date) = 2021;

SELECT * FROM piecemaintenance
WHERE pieceID = 1;

SELECT * FROM pieceevent
WHERE pieceID = 1;

-- SELECT * FROM piece;
UPDATE pieceevent SET cost = 0 WHERE pieceID = 1;

DROP TABLE IF EXISTS MaintenanceCost;
CREATE TABLE MaintenanceCost(
year  int,
planeName VARCHAR(255),
price INT
);

DELIMITER $$
DROP EVENT IF EXISTS YearlyMaintenanceCosts $$
CREATE EVENT YearlyMaintenanceCosts
    ON SCHEDULE
        EVERY 1 MINUTE
    DO
        BEGIN

        INSERT INTO MaintenanceCost
        SELECT YEAR(CURDATE()), planetype.type_name , sum(cost) FROM
            pieceevent INNER JOIN piecemaintenance ON pieceevent.pieceID = piecemaintenance.pieceid
            INNER JOIN maintenanceevent ON piecemaintenance.maintenanceID = maintenanceevent.maintenanceID
            INNER JOIN plane ON plane.planeID = maintenanceevent.planeID
            INNER JOIN planetype ON planetype.planetypeID = plane.planetypeID
            WHERE YEAR(maintenanceevent.date) = YEAR(CURDATE())
            GROUP BY planetype.planetypeID;

        END $$
DELIMITER ;

SELECT * FROM MaintenanceCost;

SHOW processlist;
SET GLOBAL event_scheduler = OFF;
*/