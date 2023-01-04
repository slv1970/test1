create or replace function elbaza.t19008_iud() returns trigger
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
			if (select count(*) from t19008 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19008 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
		
			if _rc.type = 'item_geopozitsiya' then
				update t19008_data_geopozitsiya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19008_data_geopozitsiya( idkart ) values( _rc.idkart );
				end if;
			end if;
			
			if _rc.type = 'item_adres' then
				update t19008_data_adres set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19008_data_adres( idkart ) values( _rc.idkart );
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t19008 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t19008_children where idkart = OLD.idkart;
	delete from t19008_data_geopozitsiya where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t19008_iud() owner to developer;

