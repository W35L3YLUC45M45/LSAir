-- Queries for the module 3: Shopping

-- 1

select distinct c.name,  co.name
from product as p
join company as c on p.companyID = c.companyID
join food as f on f.foodID = p.productID
join country as co on c.countryID = co.countryID
where  c.countryid = f.countryid 
and  c.companyid in (select co.companyID
					 from company as co
                     join product as pr on co.companyID = pr.companyID
                     join food as fo on pr.productID = fo.foodID
                     group by co.companyID
                     having count(fo.foodID) >= 40 )
;

-- 2 

select ct_vr.name, ct_re.name, count(*) as number_of_vip_rest

from vip_room as vr
join waitingarea as wa_vr on wa_vr.waitingAreaID = vr.vipID
join company as co_vr on wa_vr.companyID = co_vr.companyID
join country as ct_vr on ct_vr.countryID = co_vr.countryID

join waitingarea as wa_re
join restaurant as re on wa_re.waitingAreaID = re.restaurantID
join company as co_re on wa_re.companyID = co_re.companyID
join country as ct_re on ct_re.countryID = co_re.countryID

where ct_vr.countryID <> ct_re.countryID
and vr.restaurantID = re.restaurantID
and ct_vr.countryID in (select co.countryID
						from country as co
                        join forbiddenproducts as fp on co.countryID = fp.countryID
                        join product as pr on pr.productID = fp.productID
                        group by co.countryID
                        having count(pr.productID) <= 80 )
and ct_re.countryID in (select co.countryID
						from country as co
                        join forbiddenproducts as fp on co.countryID = fp.countryID
                        join product as pr on pr.productID = fp.productID
                        group by co.countryID
                        having count(pr.productID) <= 80 )

group by ct_re.countryID, ct_vr.countryID
;

-- 3


select co.name, re.score
from company as co
join waitingarea as wa on co.companyID = wa.companyID
join restaurant as re on wa.waitingAreaID = re.restaurantID
where co.companyID = (select co2.companyID 
					  from company as co2
                      join waitingarea as wa2 on co2.companyID = wa2.companyID	
					  group by co2.companyID
                      order by count(wa2.waitingAreaID) desc
                      limit 1)
ORDER BY re.score DESC
limit 1;

-- 4 


select co.name, co.company_value
from company as co
join product as po on po.companyID = co.companyID
join productstore as ps on po.productID = ps.productID

where co.companyID in (select co3.companyID
					   from company as co3
                       join waitingarea as wa on wa.companyID = co3.companyID
                       join restaurant as re on re.restaurantID = wa.waitingareaID
                       group by co3.companyID
					   having count(distinct re.type)>= 2)

group by ps.storeID, co.companyID
having 0.2 <= (select (count(po.productID)/count(po2.productID)) 
			   from company as co2
			   join product as po2 on po2.companyID = co2.companyID 
               where co2.companyID = co.companyID
               group by co2.companyID) 
;

-- 5 

select distinct co.name, wa.opening_hour, wa.close_hour, wa.airportID,  wa.waitingareaID
from waitingarea as wa
join shopkeeper as sk on sk.waitingAreaID = wa.waitingAreaID
join company as co on wa.companyID = co.companyID
where wa.close_hour between wa.opening_hour and '23:59:59'
and time_to_sec(timediff(wa.close_hour, wa.opening_hour )*7) > (select time_to_sec(sum(sk2.weekly_hours))
																from shopkeeper as sk2
                                                                join waitingarea as wa2 on wa2.waitingareaID = sk2.waitingareaID
                                                                where wa2.waitingareaID = wa.waitingareaID
                                                                group by wa2.waitingareaID)


;

-- 6


drop table if exists EconomicReductions;

create table if not exists EconomicReductions (

	companyName varchar(255),
    waitingAreaName varchar(255),
    annualSavings float,
    annualExpenses float);

delimiter $$

drop trigger if exists trigger1 $$

create trigger trigger1 after delete on waitingarea
for each row
begin 
	
    declare name_waitingArea varchar(255);
    declare annual_savings float;
    declare annual_expenses float;
    declare company_name varchar(255);
    
    if (select OLD.waitingAreaID = vip_room.vipID from vip_room  where vip_room.vipID = OLD.waitingAreaID) then
		select 'vip_room'
        into name_waitingArea;

	else 
		if (select OLD.waitingAreaID = restaurant.restaurantID from restaurant where restaurant.restaurantID = OLD.waitingAreaID) then
		select 'restaurant'
        into name_waitingArea;
		else
			if  (select OLD.waitingAreaID = store.storeID from store where store.storeId = OLD.waitingAreaID) then
			select 'store'
			into name_waitingArea;
			end if;
		end if;
	end if;
    
	select  sum(sk.weekly_hours)* 52 * 10 
    into annual_savings
    from shopkeeper as sk 
    where sk.waitingAreaID = OLD.waitingAreaID
    group by OLD.waitingAreaID;
    
	select sum(sk.weekly_hours) * 52 * 10
    into annual_expenses
    from waitingArea as wa
    join shopkeeper as sk on sk.waitingAreaID = wa.waitingAreaID
    where wa.waitingAreaID <> OLD.waitingAreaID
    and wa.companyID = OLD.companyID
    group by wa.companyID;
    
    select co.name
    into company_name
    from company as co
    where co.companyID = OLD.companyID;

	insert into EconomicReductions (companyName, waitingAreaName, annualSavings, annualExpenses)
	values (company_name, name_waitingArea, annual_savings, annual_expenses);
    
       if annual_expenses = 0 then 
		
			-- fico la relacio compania product a null
			update product
			set companyID = null
			where companyID = OLD.companyID;
			-- elimino la compania
			delete company
			from company
			where companyID = OLD.companyID;
	
	end if;
end $$

delimiter ;

-- 7


drop table if exists PriceUpdates;

create table if not exists PriceUpdates (

	productName varchar(255),
    companyOfProduct varchar(255),
    previousPrice float,
    laterPrice float,
    dateOfChange date,
    comment varchar(255));
    
    
delimiter $$ 

drop trigger if exists trigger2 $$

create trigger trigger2 after update on product 
for each row
begin

	declare product_name varchar(255);
    declare company_name varchar(255);
    declare previous_price float;
    declare later_price float;
	declare date_change date;
    declare comment varchar (255);
    
    if (EXISTS (select PriceUpdates.productName from PriceUpdates where PriceUpdates.productname = OLD.name and PriceUpdates.companyOfProduct = (SELECT comp.name
																																			FROM company as comp
                                                                                                                                            where OLD.companyID = comp.companyID)))
		then
		
        select "This product has been changing over time, it is possible that it is a strategy of the company"
        into comment;
	end if;
    
    select OLD.name, co.name, OLD.price, NEW.price, NOW()
    into product_name, company_name, previous_price, later_price, date_change
    from product as pr
    join company as co on  OLD.companyID = co.companyID
    where old.productID = pr.productID;
    
    insert into PriceUpdates (productName, companyOfProduct, previousPrice, laterPrice, dateOfChange, comment)
	values (product_name, company_name, previous_price, later_price, NOW(), comment);
    
		
            
    end $$
delimiter ;


-- 8


drop table if exists AverageSquareMetreValue;

create table if not exists AverageSquareMetreValue (
	storeId integer,
    valueM2 float
);


delimiter $$ 

drop trigger if exists trigger3 $$

create trigger trigger3 after insert on productstore 
for each row
begin
	
		delete from AverageSquareMetreValue;

		insert into AverageSquareMetreValue (storeId, valueM2)
		select st.storeID, avg(pr.price)/st.surface
		from store as st
		join productstore as prst on prst.storeID = st.storeID
		join product as pr on prst.productID = pr.productID
		group by st.storeID;
		
end $$ 
    
delimiter ;

-- 9


drop table if exists ExpiredProducts;

create table if not exists ExpiredProducts (
	productID integer,
    expireDate date,
    warningDay date
);

delimiter $$

DROP EVENT IF EXISTS daily_control $$

CREATE EVENT IF NOT EXISTS daily_control
ON SCHEDULE EVERY 1 DAY

DO BEGIN
	
    DELETE FROM ExpiredProducts;

	INSERT INTO ExpiredProducts (productID, expireDate, warningDay)
    SELECT fpr.foodID, fpr.expiration_date, NOW()
    FROM food as fpr
    join product as pr on fpr.foodID = pr.productID
    where fpr.foodID in (select f.foodID
							from food as f
                            where f.expiration_date < NOW()
                            )
	;

END $$
DELIMITER ;
