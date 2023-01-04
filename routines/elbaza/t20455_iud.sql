create or replace function elbaza.t20455_iud() returns trigger
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
			if (select count(*) from t20455 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart ) as 
			(
				select NEW.idkart
				union all
				select a.idkart from t20455 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart
			from temp1 as t
		loop

			update t20455_data set idkart = idkart where idkart = _rc.idkart
			returning idkart into _iddata;

			if _iddata is null then
				insert into t20455_data( idkart ) values( _rc.idkart );
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t20455 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t20455_children where idkart = OLD.idkart;
	delete from t20455_data where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t20455_iud() owner to developer;

