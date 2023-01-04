create or replace function elbaza.t20175_iud() returns trigger
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
			if (select count(*) from t20175 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t20175 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_sotrudnik' then
				update t20175_data_sotrudnik set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20175_data_sotrudnik( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_gruppa' then
				update t20175_data_gruppa set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20175_data_gruppa( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_podrazdeleniye' then
				update t20175_data_podrazdeleniye set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20175_data_podrazdeleniye( idkart ) values( _rc.idkart );
				end if;

			end if;		
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t20175 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t20175_children where idkart = OLD.idkart;
	delete from t20175_data_sotrudnik where idkart = OLD.idkart;
	delete from t20175_data_podrazdeleniye where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t20175_iud() owner to developer;

