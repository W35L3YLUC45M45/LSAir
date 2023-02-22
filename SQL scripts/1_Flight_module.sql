-- 1.1 

(SELECT 'Most anticipating', c.name AS 'Coutry name', AVG(datediff(flight.date, f.date_of_purchase ))*24 AS 'difference in hours',  AVG(f.price) 
FROM flighttickets AS f 
JOIN person AS pe ON pe.personID = f.passengerID
JOIN country AS c ON pe.countryID = c.countryID
JOIN flight ON flight.flightID = f.flightID
GROUP BY c.countryID
HAVING COUNT(f.passengerID) > 300
ORDER BY AVG(datediff(flight.date, f.date_of_purchase )) DESC
LIMIT 1)
UNION

(SELECT 'Less anticipating', c.name AS 'Coutry name', AVG(datediff(flight.date, f.date_of_purchase ))*24 AS 'difference in hours', AVG(f.price)
FROM flighttickets AS f 
JOIN person AS pe ON pe.personID = f.passengerID
JOIN country AS c ON pe.countryID = c.countryID
JOIN flight ON flight.flightID = f.flightID
GROUP BY c.countryID
HAVING COUNT(f.passengerID) > 300
ORDER BY AVG(datediff(flight.date, f.date_of_purchase ))/*(flight.date) - f.date_of_purchase*/ ASC
LIMIT 1);

-- 1.2 _____________________________________________________________________________________________________________________________________________________________________________

SELECT person.personID, person.name, person.surname, person.born_date
FROM flight 
JOIN flighttickets AS f ON flight.flightID = f.flightID
JOIN passenger AS p ON f.passengerID = p.passengerID
JOIN person ON p.passengerID = person.personId
JOIN status ON flight.statusID = status.statusID
WHERE status.status LIKE "Strong turbulences" AND
	  person.personID NOT IN (SELECT person2.personID
							  FROM flight AS fl
							  JOIN flighttickets AS ft ON fl.flightID = ft.flightID
							  JOIN passenger AS pas ON ft.passengerID = pas.passengerID
							  JOIN person AS person2 ON pas.passengerID = person2.personId
							  WHERE fl.date > flight.date) 
	 AND person.personID NOT IN (SELECT flt.passengerID -- , COUNT(sta.status)
								FROM flight AS fli
								JOIN flighttickets AS flt ON fli.flightID = flt.flightID
								JOIN status AS sta ON fli.statusID = sta.statusID
								WHERE sta.status LIKE "Strong turbulences"
								GROUP BY flt.passengerID
								HAVING COUNT(sta.status) > 1
								ORDER BY passengerID)
                              
;

-- 1.3 _____________________________________________________________________________________________________________________________________________________________________________

(SELECT pilot.flying_license, COUNT(flight.flightID) AS "times she/he was pilot" , pilot.grade
FROM pilot 
JOIN flight ON flight.pilotID = pilot.pilotID 
WHERE pilot.grade >= (SELECT 2+AVG(p.grade) FROM pilot AS p)
GROUP BY pilot.pilotID
HAVING COUNT(flight.flightID) < (SELECT COUNT(copilot.pilotID)
								FROM pilot AS copilot
                                WHERE pilot.pilotID = copilot.copilotID
								GROUP BY copilotID)

ORDER BY pilot.pilotID); 

-- 1.4 _____________________________________________________________________________________________________________________________________________________________________________

SELECT DISTINCT oldperson.name, oldperson.surname, oldperson.born_date
FROM passenger 
JOIN person AS oldperson ON passenger.passengerID = oldperson.personID
JOIN flighttickets ON flighttickets.passengerID = oldperson.personID
WHERE  (DATE_FORMAT(NOW(),'%Y') - DATE_FORMAT(oldperson.born_date, '%Y' )) >= 100 AND
	  NOT EXISTS (SELECT l.languageID FROM languageperson AS l 
				  WHERE l.personID = oldperson.personID AND 
                  EXISTS (SELECT DISTINCT languageID
					      FROM flight_attendant 
					      JOIN person ON person.personID = flight_attendant.flightattendantID
					      JOIN languageperson AS lp ON lp.personID = person.personID
					      JOIN flight_flightattendant AS ff ON ff.flightattendantID = flight_attendant.flightattendantID
					      WHERE ff.flightID = flighttickets.flightID))
;

-- 1.5 _______________________________________________________________________________________________________________________________________________________________________________

SELECT DISTINCT person.name, person.surname
FROM flighttickets 
JOIN person ON personID = flighttickets.passengerID
JOIN checkin ON checkin.flightTicketID = flighttickets.flightTicketID
WHERE  flighttickets.business = 1 AND
	personID NOT IN (SELECT person2.personID 
					 FROM person AS person2
                     JOIN flighttickets AS ft ON ft.passengerID = person2.personID
                     JOIN checkin AS checkin2 ON checkin2.flightticketID = ft.flightticketID
                     WHERE (checkin2.seat NOT LIKE 'A') AND (checkin2.seat NOT LIKE 'F'))
	
ORDER BY person.personID;

-- 1.6 _______________________________________________________________________________________________________________________________________________________________________________

DROP TABLE IF EXISTS TicketError;
CREATE TABLE TicketError (
	ticketErrorID SERIAL,
	personId INTEGER,
    name VARCHAR(255),
    surname VARCHAR(255),
    flightID INTEGER, 
    dateOfFlight DATE,
    dateOfTheTicketPurchase DATE,
    PRIMARY KEY (ticketErrorID)
); 

DROP TABLE IF EXISTS FlightticketsDelete;
CREATE TABLE FlightticketsDelete (
	 flightticketID INTEGER
);


DELIMITER $$
DROP TRIGGER IF EXISTS lsair.invalid_tickets $$
CREATE TRIGGER invalid_tickets AFTER INSERT ON flighttickets

FOR EACH ROW BEGIN

	IF NEW.date_of_purchase > (SELECT flight.date FROM flight WHERE flight.flightID = NEW.flightID) THEN 
    
		INSERT INTO TicketError (personID, name, surname, flightID, dateOfFlight, dateOfTheTicketPurchase)
        SELECT NEW.passengerID, person.name, person.surname, NEW.flightID, flight.date, NEW.date_of_purchase
        FROM person JOIN flighttickets ON person.personID = flighttickets.passengerID
        JOIN flight ON flight.flightID = flighttickets.flightID
        WHERE person.personID = NEW.passengerID AND
			  flight.flightID = NEW.flightID; 
              
	    INSERT INTO  FlightticketsDelete(flightticketID)
        VALUES (NEW.flightticketID);
        
	END IF ; 

 END $$
DELIMITER ;

DELIMITER $$
DROP EVENT IF EXISTS DeleteandoFlighttickets $$
CREATE EVENT  DeleteandoFlighttickets
ON SCHEDULE EVERY 30 SECOND 
DO BEGIN

	DELETE flighttickets
    FROM flighttickets
    JOIN flightticketsDelete ON FlightticketsDelete.flightTicketID = flighttickets.flightTicketID;
                            	
    
END $$

-- 1.7 _______________________________________________________________________________________________________________________________________________________________________________

DROP TABLE IF EXISTS CrimeSuspect;
CREATE TABLE CrimeSuspect (
	crimeSuspectID SERIAL,
	passengerId INTEGER,
    name VARCHAR(255),
    surname VARCHAR(255), 
    passport VARCHAR(11),
    phone VARCHAR (20),
    PRIMARY KEY (crimeSuspectID)
);

DELIMITER $$
DROP TRIGGER IF EXISTS possible_criminal $$
CREATE TRIGGER possible_ciminal AFTER INSERT ON passenger
FOR EACH ROW BEGIN

	IF NEW.creditCard IN (SELECT creditCard FROM passenger WHERE NEW.passengerID <> passengerID) THEN
    
		INSERT INTO CrimeSuspect (passengerId, name, surname, passport, phone)
        SELECT personID, name, surname, passport, phone_number
        FROM person WHERE personID = NEW.passengerId;
    
    END IF; 

END $$
DELIMITER ;

-- 1.8 _______________________________________________________________________________________________________________________________________________________________________________

DROP TABLE IF EXISTS CancelledFlightsMails;
CREATE TABLE CancelledFlightsMails(
	cancelledFlightsMailsID SERIAL,
	flightID DOUBLE,
	personId INTEGER,
	namePerson VARCHAR(255),
	emailPerson VARCHAR(255),
	priceOfTicket FLOAT,
	isBusinessTicket INTEGER, 
	comission FLOAT,
	PRIMARY KEY (cancelledflightsMailsID)
);

DROP TABLE IF EXISTS CancellationCost;
CREATE TABLE CancellationCost(
	cancellationCostID SERIAL,
	flightID DOUBLE,
	refund FLOAT,
    PRIMARY KEY (cancellationCostID)
    
);

-- ALTER TABLE CancellationCost ADD FOREIGN KEY (cancelledFlightsMailsID) REFERENCES CancelledFlightsMails(cancelledFlightsMailsId);


DELIMITER $$
DROP TRIGGER IF EXISTS CancelledFlights $$
CREATE TRIGGER CancelledFlights BEFORE DELETE ON flight
FOR EACH ROW BEGIN

	IF OLD.date > NOW() THEN

		INSERT INTO CancelledFlightsMails (flightID, personId, namePerson, emailPerson, priceOfTicket, isBusinessTicket, comission)
		SELECT OLD.flightID, flighttickets.passengerID, person.name, person.email, flighttickets.price, flighttickets.business, DATEDIFF(flight.date, NOW())
		FROM flighttickets JOIN person ON person.personID = flighttickets.passengerID 
		JOIN flight ON flight.flightID = flighttickets.flightID
		WHERE flighttickets.flightID = OLD.flightID;
		
		INSERT INTO CancellationCost (flightID, refund)
		SELECT OLD.flightID, SUM(POW(c.priceOfTicket,2)*(c.comission+1))
		FROM CancelledFlightsMails AS c WHERE c.flightID = OLD.flightID
        GROUP BY c.flightID; 

	END IF; 
    
END $$
DELIMITER ;

-- 1.9 ________________________________________________________________________________________________________________________________________________________________________________

DROP TABLE IF EXISTS DailyFlights;
CREATE TABLE DailyFlights (
	dailyFlightsID SERIAL,
    date DATE, 
    numFlights INTEGER,
    PRIMARY KEY (dailyFlightsID)

);
DROP TABLE IF EXISTS MonthlyFlights;

CREATE TABLE MonthlyFlights (
	monthlyFlightsID SERIAL,
    month INTEGER,
    year INTEGER,
    avg_numFlights INTEGER,
    PRIMARY KEY (monthlyFlightsID)

);

DELIMITER $$
DROP EVENT IF EXISTS NumFlightsDay $$ 
CREATE EVENT  NumFlightsDay
ON SCHEDULE EVERY 1 DAY
STARTS '2021-05-02 23:50:00:00'
COMMENT 'Afegir quants avions han volat en aquest dia'
DO BEGIN

	INSERT INTO DailyFlights(date, numFlights)
    SELECT CURDATE(), COUNT(DISTINCT flight_trigger.flightID)
    FROM flight WHERE flight.date = CURDATE();
    
END $$
DELIMITER ;

DELIMITER $$
DROP EVENT IF EXISTS averageFlightsMonth $$
CREATE EVENT  averageFlightsMonth
ON SCHEDULE EVERY 1 MONTH 
STARTS '2021-05-29 23:59:00'
COMMENT 'Afegir la mitjana d\'avions que han volat en aquest mes'
DO BEGIN

	INSERT INTO MonthlyFlights(month, year, avg_numFlights)
    SELECT DATE_FORMAT(CURDATE(), '%m') , DATE_FORMAT(CURDATE(), '%Y') , AVG(d.numFlights)
    FROM DailyFlights as d 
    WHERE DATE_FORMAT(CURDATE(), '%m') = DATE_FORMAT(d.date, '%m') AND
		  DATE_FORMAT(CURDATE(), '%Y') = DATE_FORMAT(d.date, '%Y');
    
END $$
DELIMITER ;


