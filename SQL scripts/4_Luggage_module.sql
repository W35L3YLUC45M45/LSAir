
-- 4.1 (Query)
SELECT person.personId, person.name, person.surname, salary
FROM flightluggagehandler
INNER JOIN person ON flightluggagehandler.luggageHandlerID = personID
INNER JOIN employee ON personID = employeeID
GROUP BY flightluggagehandler.flightID
HAVING count(*) = 1
AND salary < (SELECT avg(salary) 
			  FROM employee, luggagehandler
			  WHERE employeeID = luggageHandlerID);

              
-- 4.2 (Query) Va lenta (70 segundos aprox.).

(
SELECT  person.name AS passenger_name, email, country.name AS country, color, brand, weight,
(size_x * size_y * size_z) AS volume, extra_cost, fragile
FROM person LEFT JOIN luggage ON luggage.passengerID = person.personID
INNER JOIN country ON person.countryID = country.countryID
LEFT JOIN handluggage ON  luggageID = handluggageID
LEFT JOIN checkedluggage ON luggageID = checkedluggageID 
LEFT JOIN specialobjects ON checkedluggageID = specialobjectID
WHERE SUBSTRING(person.name, 1, 4) LIKE SUBSTRING(country.name, 1, 4)
AND luggage.luggageID IS NULL
)
UNION
(
SELECT  person.name AS passenger_name, email, country.name AS country, color, brand, weight,
(size_x * size_y * size_z) AS volume, extra_cost, fragile
FROM person LEFT JOIN luggage ON luggage.passengerID = person.personID
INNER JOIN country ON person.countryID = country.countryID
LEFT JOIN handluggage ON  luggageID = handluggageID
LEFT JOIN checkedluggage ON luggageID = checkedluggageID 
LEFT JOIN specialobjects ON checkedluggageID = specialobjectID
WHERE SUBSTRING(person.name, 1, 4) LIKE SUBSTRING(country.name, 1, 4)
AND luggage.luggageID = (SELECT DP.luggageID FROM luggage AS DP WHERE DP.passengerID = luggage.passengerID ORDER BY DP.weight ASC LIMIT 1)
GROUP BY passengerID
) ORDER BY passenger_name ASC;

-- 4.3 (Query) . Tengo que añadir datos o algo. Preguntar si vale que haya hecho Update.

SELECT lostobject.color, count(*) AS lost_objects, count(distinct passengerID) AS num_passengers, count(*)/count(distinct passengerID) AS ratio
FROM luggage INNER JOIN lostobject ON luggage.luggageID = lostobject.luggageID
GROUP BY lostobject.color
UNION
SELECT luggage.brand, count(*) AS lost_objects, count(distinct passengerID) AS num_passengers, count(*)/count(distinct passengerID) AS ratio
FROM luggage INNER JOIN lostobject ON luggage.luggageID = lostobject.luggageID
GROUP BY luggage.brand;

-- 4.4 (Query)

SELECT (fragile + corrosive + flammable) AS hazardous_level, AVG(extra_cost) AS extra_cost
FROM specialobjects INNER JOIN checkedluggage ON checkedluggageID = specialobjectID
GROUP BY hazardous_level
ORDER BY hazardous_level;

-- 4.5 (Query) 

SELECT claims.passengerID, name, surname, (SELECT count(distinct flightID) FROM luggage WHERE passengerID = claims.passengerID) AS n_flights, (SELECT count(distinct c.claimID) FROM claims AS c WHERE c.passengerID = claims.passengerID) AS n_claims
FROM person INNER JOIN claims ON claims.passengerID = person.personID
INNER JOIN refund ON claims.claimID = refundID
INNER JOIN luggage ON luggage.passengerID = claims.passengerID
WHERE (SELECT count(distinct c.claimID) FROM claims AS c WHERE c.passengerID = claims.passengerID) > (SELECT count(distinct flightID) FROM luggage WHERE passengerID = claims.passengerID)
GROUP BY claims.passengerID
HAVING avg(accepted) = 0
ORDER BY claims.passengerID ;

-- 4.6 (Trigger)

DROP TABLE IF EXISTS RefundsAlterations;
DROP TABLE IF EXISTS refund2;

CREATE TABLE IF NOT EXISTS RefundsAlterations(
			passengerID BIGINT UNSIGNED NOT NULL DEFAULT 0,
            flightTicketID BIGINT UNSIGNED NOT NULL DEFAULT 0,
            comment TEXT );
           
          
CREATE TABLE IF NOT EXISTS refund2(
	refundID	bigint unsigned,
	flightTicketID	bigint unsigned,
	argument	text,
	accepted	tinyint(1),
	amount	bigint unsigned
);

delimiter //
DROP TRIGGER IF EXISTS refunded_tickets//
CREATE TRIGGER refunded_tickets
BEFORE INSERT ON refund2
FOR EACH ROW
	BEGIN
		IF (SELECT count(*) FROM RefundsAlterations WHERE flightTicketID = new.flightTicketID GROUP BY flightTicketID) >= 3 THEN
			INSERT INTO RefundsAlterations(passengerID, flightTicketID, comment)
            SELECT passengerID, new.flightTicketID, "Excessive Attempts"
            FROM  refund2 RIGHT JOIN claims ON claims.claimID = refund2.refundID
			WHERE new.refundID = claims.claimID
            LIMIT 1;
		ELSE IF new.flightTicketID IN (SELECT flightTicketID FROM refund2 WHERE accepted = 1) THEN
			INSERT INTO RefundsAlterations(passengerID, flightTicketID, comment)
            SELECT passengerID, new.flightTicketID, "Refund of a ticket already processed correcty"
            FROM  refund2 RIGHT JOIN claims ON claims.claimID = refund2.refundID
			WHERE new.refundID = claims.claimID
            LIMIT 1;
			END IF;
        END IF;
    END //
    delimiter ;
INSERT INTO refund2 (refundID, flightTicketID, argument, accepted, amount)
VALUES (252, 197, 'Flight Delayed', 1, 264);

SELECT * FROM RefundsAlterations;
 
-- 4.7 (Trigger) 
 
DROP TABLE IF EXISTS LostObjectsDays;

CREATE TABLE IF NOT EXISTS LostObjectsDays(
			lostObjectID BIGINT UNSIGNED,
            days_to_find INT,
            avg_days_type INT
			);


delimiter //
DROP TRIGGER IF EXISTS lost_object_days//
CREATE TRIGGER lost_object_days
AFTER UPDATE ON lostobject
FOR EACH ROW
	BEGIN
		IF new.founded = 1 AND new.founded <> old.founded THEN
			INSERT INTO LostObjectsDays
            SELECT new.lostObjectID, TIMESTAMPDIFF(DAY, flight.date, claims.date), (SELECT AVG(days_to_find) 
																					FROM LostObjectsDays 
                                                                                    INNER JOIN lostobject ON LostObjectsDays.lostObjectID = lostObject.lostObjectID
                                                                                    WHERE LostObjectsDays.lostObjectID = new.lostObjectID
                                                                                    GROUP BY description)
            FROM lostobject INNER JOIN claims ON claimID = lostObjectID 
            INNER JOIN luggage ON luggage.luggageID = lostobject.luggageID 
            INNER JOIN flight ON flight.flightID = luggage.flightID
			WHERE lostobject.lostObjectID = new.lostObjectID;
        END IF;
    END //
    delimiter ;
    
    
	UPDATE lostobject SET founded = 0 WHERE lostObjectID = '9267';
	UPDATE lostobject SET founded = 1 WHERE lostObjectID = '9267';
    
    
    SELECT *, TIMESTAMPDIFF(DAY, flight.date, claims.date) FROM lostobject INNER JOIN claims ON claimID = lostObjectID INNER JOIN luggage ON luggage.luggageID = lostobject.luggageID INNER JOIN flight ON flight.flightID = luggage.flightID WHERE lostobject.luggageId IS NOT NULL;
    SELECT * FROM LostObjectsDays;
    
-- 4.8 (Event) He tenido que desactivar SAFEUPDATE.

DROP TABLE IF EXISTS DailyLuggageStatistics;
DROP TABLE IF EXISTS MonthlyLuggageStatistics;
DROP TABLE IF EXISTS YearlyLuggageStatistics;

-- Esto lo hago para que haya valores en la tabla.
    SET SQL_SAFE_UPDATES = 0;
UPDATE flight
SET date = CURDATE()
WHERE date < '1955-06-29';

UPDATE flight
SET date = DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY)
WHERE date < '1960-04-12';

UPDATE claims
SET date = CURDATE()
WHERE date < '1955-06-29';

UPDATE claims
SET date = DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY)
WHERE date < '1960-04-12';
	SET SQL_SAFE_UPDATES = 1;

CREATE TABLE IF NOT EXISTS DailyLuggageStatistics(
	statisticsdate DATE,
    weight int,
    dangerobjects int,
    acceptedclaims int
);

CREATE TABLE IF NOT EXISTS MonthlyLuggageStatistics(
	year int,
    month int,
    weight int,
    dangerobjects int,
    acceptedclaims int
);

CREATE TABLE IF NOT EXISTS YearlyLuggageStatistics(
	year int,
    weight int,
    dangerobjects int,
    acceptedclaims int
);


delimiter //

DROP EVENT IF EXISTS DailyLuggageStatistics//
CREATE EVENT DailyLuggageStatistics
	ON SCHEDULE
		EVERY 1 DAY
	DO    
		BEGIN
        
			INSERT INTO DailyLuggageStatistics
            SELECT CURDATE(), (SELECT SUM(weight) 
								FROM luggage INNER JOIN flight ON flight.flightID = luggage.flightID 
                                WHERE date between date_sub(CURDATE(), INTERVAL 1 DAY) AND CURDATE()),
                                (SELECT COUNT(*)
								FROM luggage INNER JOIN flight ON flight.flightID = luggage.flightID 
                                INNER JOIN checkedluggage ON checkedluggage.checkedluggageid = luggage.luggageID
                                INNER JOIN specialobjects ON specialobjects.specialobjectID = checkedluggage.checkedluggageid
                                WHERE date between date_sub(CURDATE(), INTERVAL 1 DAY) AND CURDATE()
                                AND (corrosive OR flammable) = 1),
                                (SELECT count(*)
                                FROM claims INNER JOIN refund ON claimID = refundID
								WHERE date between date_sub(CURDATE(), INTERVAL 1 DAY) AND CURDATE()
                                AND accepted = 1);
        END//
        
delimiter ;

delimiter //

DROP EVENT IF EXISTS MonthlyLuggageStatistics//
CREATE EVENT MonthlyLuggageStatistics
	ON SCHEDULE
		EVERY 1 MONTH
	DO    
		BEGIN
        
			INSERT INTO MonthlyLuggageStatistics
            SELECT YEAR(CURDATE()), MONTH(CURDATE()), (SELECT SUM(weight) 
								FROM luggage INNER JOIN flight ON flight.flightID = luggage.flightID 
                                WHERE date between DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY) AND date_add(DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY), INTERVAL 1 MONTH)),
                                (SELECT COUNT(*)
								FROM luggage INNER JOIN flight ON flight.flightID = luggage.flightID 
                                INNER JOIN checkedluggage ON checkedluggage.checkedluggageid = luggage.luggageID
                                INNER JOIN specialobjects ON specialobjects.specialobjectID = checkedluggage.checkedluggageid
                                WHERE date between DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY) AND date_add(DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY), INTERVAL 1 MONTH)
                                AND (corrosive OR flammable) = 1),
                                (SELECT count(*)
                                FROM claims INNER JOIN refund ON claimID = refundID
								WHERE date between DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY) AND date_add(DATE_SUB(CURDATE(),INTERVAL DAYOFMONTH(CURDATE())-1 DAY), INTERVAL 1 MONTH)
                                AND accepted = 1);
        END//
        
delimiter ;

delimiter //

DROP EVENT IF EXISTS YearlyLuggageStatistics//
CREATE EVENT YearlyLuggageStatistics
	ON SCHEDULE
		EVERY 1 YEAR
	DO    
		BEGIN
        
			INSERT INTO YearlyLuggageStatistics
            SELECT YEAR(CURDATE()), (SELECT SUM(weight) 
								FROM luggage INNER JOIN flight ON flight.flightID = luggage.flightID 
                                WHERE YEAR(date) = YEAR(CURDATE())),
                                (SELECT COUNT(*)
								FROM luggage INNER JOIN flight ON flight.flightID = luggage.flightID 
                                INNER JOIN checkedluggage ON checkedluggage.checkedluggageid = luggage.luggageID
                                INNER JOIN specialobjects ON specialobjects.specialobjectID = checkedluggage.checkedluggageid
                                WHERE YEAR(date) = YEAR(CURDATE())
                                AND (corrosive OR flammable) = 1),
                                (SELECT count(*)
                                FROM claims INNER JOIN refund ON claimID = refundID
								WHERE YEAR(date) = YEAR(CURDATE())
                                AND accepted = 1);
        END//
                
delimiter ;

SELECT * FROM DailyLuggageStatistics;
SELECT * FROM MonthlyLuggageStatistics;
SELECT * FROM YearlyLuggageStatistics;