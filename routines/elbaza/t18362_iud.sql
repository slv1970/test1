create or replace function elbaza.t18362_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t18362 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t18362 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type in ('item_razdel_okved', 'item_podrazdel_okved', 'item_okved_uroven_1', 
				'item_okved_uroven_2', 'item_okved_uroven_3', 'item_okved_uroven_4' )
			then
				update t18362_data_okved set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18362_data_okved( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_gruppa_okved' then
				update t18362_data_gruppa_okved set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18362_data_gruppa_okved( idkart ) values( _rc.idkart );
				end if;
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t18362 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t18362_children where idkart = OLD.idkart;
	delete from t18362_data_okved where idkart = OLD.idkart;
	delete from t18362_data_gruppa_okved where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t18362_iud() owner to developer;

