use lsair;

-- Querie para mostrarnos todos los idiomas distintos
 
select  language.languageID, language.name
from language
where language.languageID in (select lang.languageID
							from pilot 
							join employee as emp on emp.employeeID = pilot.pilotID
							join person as pers on emp.employeeID = pers.personID
							join languageperson as langpers on langpers.personID = pers.personID 
							join language as lang on langpers.languageID = lang.languageID
							where emp.retirement_date < now()
							and emp.salary > 100000
							and  pers.personID  in   ( select person.personID
													from person
													join languageperson as langpers2 on langpers2.personID = person.personID
													join language on langpers2.languageID = language.languageID
													-- where person.personID = pers.personID
													group by person.personID 
													having count(distinct language.languageID) > 3 )
							group by lang.languageID
							)
or language.languageID in (select lang.languageID
							from flight_flightAttendant as fl_attend 
							join employee as emp on emp.employeeID = fl_attend.flightAttendantID
							join person as pers on emp.employeeID = pers.personID
							join languageperson as langpers on langpers.personID = pers.personID 
							join language as lang on langpers.languageID = lang.languageID
							join flight on flight.flightID = fl_attend.flightID
							join pilot on flight.pilotID = pilot.pilotID
							where pilot.pilotID in (
													select  pilot2.pilotid
													from pilot as pilot2
													join employee as emp2 on emp2.employeeID = pilot2.pilotID
													join person as pers2 on emp2.employeeID = pers2.personID
													join languageperson as langpers2 on langpers2.personID = pers2.personID 
													join language as lang2 on langpers2.languageID = lang2.languageID
													where emp2.retirement_date < now()
													and emp2.salary > 100000
													and  pers2.personID  in   ( select pers3.personID
																			from person as pers3
																			join languageperson as langpers3 on langpers3.personID = pers3.personID
																			join language as lang3 on langpers3.languageID = lang3.languageID
																			-- where person.personID = pers.personID
																			group by pers3.personID 
																			having count(distinct lang3.languageID) > 3 )
													)
							group by lang.languageID
)
group by language.languageID;


-- ara mostrem nomes els pilots
select pilot.pilotid, pers.name, pers.surname, pers.email, pers.sex, emp.salary, emp.years_working
from pilot 
join employee as emp on emp.employeeID = pilot.pilotID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
where emp.retirement_date < now()
and emp.salary > 100000
and  pers.personID  in   ( select person.personID
					    from person
					    join languageperson as langpers2 on langpers2.personID = person.personID
						join language on langpers2.languageID = language.languageID
					    -- where person.personID = pers.personID
					    group by person.personID 
                        having count(distinct language.languageID) > 3 )
 group by pilot.pilotID
;

-- ara mostrem les fligthattendants

select distinct fl_attend.flightAttendantID , pers.name, pers.surname, pers.email, pers.sex, emp.salary, emp.years_working
from flight_flightAttendant as fl_attend 
join employee as emp on emp.employeeID = fl_attend.flightAttendantID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
join flight on flight.flightID = fl_attend.flightID
join pilot on flight.pilotID = pilot.pilotID
where pilot.pilotID in (
						select  pilot2.pilotid
						from pilot as pilot2
						join employee as emp2 on emp2.employeeID = pilot2.pilotID
						join person as pers2 on emp2.employeeID = pers2.personID
						join languageperson as langpers2 on langpers2.personID = pers2.personID 
						join language as lang2 on langpers2.languageID = lang2.languageID
						where emp2.retirement_date < now()
						and emp2.salary > 100000
						and  pers2.personID  in   ( select pers3.personID
												from person as pers3
												join languageperson as langpers3 on langpers3.personID = pers3.personID
												join language as lang3 on langpers3.languageID = lang3.languageID
												-- where person.personID = pers.personID
												group by pers3.personID 
												having count(distinct lang3.languageID) > 3 )
						)
;


-- relacions vols i persones


select distinct flight.flightID, pilot.pilotID, fl_attend.flightAttendantID
from flight_flightAttendant as fl_attend 
join employee as emp on emp.employeeID = fl_attend.flightAttendantID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
join flight on flight.flightID = fl_attend.flightID
join pilot on flight.pilotID = pilot.pilotID
join route on flight.routeID = route.routeID
where pilot.pilotID in (
						select  pilot2.pilotid
						from pilot as pilot2
						join employee as emp2 on emp2.employeeID = pilot2.pilotID
						join person as pers2 on emp2.employeeID = pers2.personID
						join languageperson as langpers2 on langpers2.personID = pers2.personID 
						join language as lang2 on langpers2.languageID = lang2.languageID
						where emp2.retirement_date < now()
						and emp2.salary > 100000
						and  pers2.personID  in   ( select pers3.personID
												from person as pers3
												join languageperson as langpers3 on langpers3.personID = pers3.personID
												join language as lang3 on langpers3.languageID = lang3.languageID
												-- where person.personID = pers.personID
												group by pers3.personID 
												having count(distinct lang3.languageID) > 3 )
						)
-- group by flight.flightID
;


-- flight attendant language

select fl_attend.flightAttendantID, lang.languageID
from flight_flightAttendant as fl_attend 
join employee as emp on emp.employeeID = fl_attend.flightAttendantID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
join flight on flight.flightID = fl_attend.flightID
join pilot on flight.pilotID = pilot.pilotID
where pilot.pilotID in (
						select  pilot2.pilotid
						from pilot as pilot2
						join employee as emp2 on emp2.employeeID = pilot2.pilotID
						join person as pers2 on emp2.employeeID = pers2.personID
						join languageperson as langpers2 on langpers2.personID = pers2.personID 
						join language as lang2 on langpers2.languageID = lang2.languageID
						where emp2.retirement_date < now()
						and emp2.salary > 100000
						and  pers2.personID  in   ( select pers3.personID
												from person as pers3
												join languageperson as langpers3 on langpers3.personID = pers3.personID
												join language as lang3 on langpers3.languageID = lang3.languageID
												-- where person.personID = pers.personID
												group by pers3.personID 
												having count(distinct lang3.languageID) > 3 )
						)
;

-- Pilot language
select pilot.pilotid, lang.languageID
from pilot 
join employee as emp on emp.employeeID = pilot.pilotID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
where emp.retirement_date < now()
and emp.salary > 100000
and  pers.personID  in   ( select person.personID
					    from person
					    join languageperson as langpers2 on langpers2.personID = person.personID
						join language on langpers2.languageID = language.languageID
					    -- where person.personID = pers.personID
					    group by person.personID 
                        having count(distinct language.languageID) > 3 )
--  group by pilot.pilotID
;

-- flights

select flight.flightID, flight.date, route.destination_airportID, route.departure_airportID
from flight_flightAttendant as fl_attend 
join employee as emp on emp.employeeID = fl_attend.flightAttendantID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
join flight on flight.flightID = fl_attend.flightID
join pilot on flight.pilotID = pilot.pilotID
join route on flight.routeID = route.routeID
where pilot.pilotID in (
						select  pilot2.pilotid
						from pilot as pilot2
						join employee as emp2 on emp2.employeeID = pilot2.pilotID
						join person as pers2 on emp2.employeeID = pers2.personID
						join languageperson as langpers2 on langpers2.personID = pers2.personID 
						join language as lang2 on langpers2.languageID = lang2.languageID
						where emp2.retirement_date < now()
						and emp2.salary > 100000
						and  pers2.personID  in   ( select pers3.personID
												from person as pers3
												join languageperson as langpers3 on langpers3.personID = pers3.personID
												join language as lang3 on langpers3.languageID = lang3.languageID
												-- where person.personID = pers.personID
												group by pers3.personID 
												having count(distinct lang3.languageID) > 3 )
						)
group by flight.flightID
;


-- airports:


(select route.destination_airportID
from flight_flightAttendant as fl_attend 
join employee as emp on emp.employeeID = fl_attend.flightAttendantID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
join flight on flight.flightID = fl_attend.flightID
join pilot on flight.pilotID = pilot.pilotID
join route on flight.routeID = route.routeID
where pilot.pilotID in (
						select  pilot2.pilotid
						from pilot as pilot2
						join employee as emp2 on emp2.employeeID = pilot2.pilotID
						join person as pers2 on emp2.employeeID = pers2.personID
						join languageperson as langpers2 on langpers2.personID = pers2.personID 
						join language as lang2 on langpers2.languageID = lang2.languageID
						where emp2.retirement_date < now()
						and emp2.salary > 100000
						and  pers2.personID  in   ( select pers3.personID
												from person as pers3
												join languageperson as langpers3 on langpers3.personID = pers3.personID
												join language as lang3 on langpers3.languageID = lang3.languageID
												-- where person.personID = pers.personID
												group by pers3.personID 
												having count(distinct lang3.languageID) > 3 )
						)
group by flight.flightID
)

UNION 

(
select route.departure_airportID
from flight_flightAttendant as fl_attend 
join employee as emp on emp.employeeID = fl_attend.flightAttendantID
join person as pers on emp.employeeID = pers.personID
join languageperson as langpers on langpers.personID = pers.personID 
join language as lang on langpers.languageID = lang.languageID
join flight on flight.flightID = fl_attend.flightID
join pilot on flight.pilotID = pilot.pilotID
join route on flight.routeID = route.routeID
where pilot.pilotID in (
						select  pilot2.pilotid
						from pilot as pilot2
						join employee as emp2 on emp2.employeeID = pilot2.pilotID
						join person as pers2 on emp2.employeeID = pers2.personID
						join languageperson as langpers2 on langpers2.personID = pers2.personID 
						join language as lang2 on langpers2.languageID = lang2.languageID
						where emp2.retirement_date < now()
						and emp2.salary > 100000
						and  pers2.personID  in   ( select pers3.personID
												from person as pers3
												join languageperson as langpers3 on langpers3.personID = pers3.personID
												join language as lang3 on langpers3.languageID = lang3.languageID
												-- where person.personID = pers.personID
												group by pers3.personID 
												having count(distinct lang3.languageID) > 3 )
						)
group by flight.flightID
)
;




