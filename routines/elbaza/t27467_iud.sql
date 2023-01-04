create or replace function elbaza.t27467_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP = 'INSERT' or TG_OP = 'UPDATE' ) then
		-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27467 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- 		raise '%', NEW;
		-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t27467 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_dokument' then
				update t27467_data_dokument set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_dokument (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_peremennaya' then
			
				update t27467_data_peremennaya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_peremennaya (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_pismo' then
			
				update t27467_data_pismo set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_pismo (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_sms' then
			
				update t27467_data_sms set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_sms (idkart) values (_rc.idkart);
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
	
	-- проверка на удаление записи
	if (select count(*) from t27467 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
	
	-- удаление связей
	delete from t27467_children where idkart = OLD.idkart;
	delete from t27467_data_dokument where idkart = OLD.idkart;
	delete from t27467_data_peremennaya where idkart = OLD.idkart;
	delete from t27467_data_pismo where idkart = OLD.idkart;
	delete from t27467_data_sms where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t27467_iud() owner to site;

