create or replace function elbaza.t27468_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;
	_parent int; 
	
begin
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27468 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;	
		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t27468 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
			if _rc.type = 'item_klient_yurlico' or _rc.type = 'item_klient_fizlico' then
				update t27468_data_klient set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_klient (idkart) values (_rc.idkart);
				end if;
            
			elseif _rc.type = 'item_kontaktnoe_lico' then
				update t27468_data_kontaktnoe_lico set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_kontaktnoe_lico (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_telefon' then
				update t27468_data_telefon set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_telefon (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_pochta' then
				update t27468_data_pochta set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_pochta(idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_rebenok' then
				update t27468_data_rebenok set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_rebenok (idkart) values (_rc.idkart);
				end if;
			
			end if;
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t27468 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t27468_data_klient where idkart = OLD.idkart;
	delete from t27468_data_kontaktnoe_lico where idkart = OLD.idkart;
	delete from t27468_data_telefon where idkart = OLD.idkart;
	delete from t27468_data_pochta where idkart = OLD.idkart;
	delete from t27468_data_rebenok where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t27468_iud() owner to site;

