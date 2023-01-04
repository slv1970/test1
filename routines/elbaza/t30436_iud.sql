create or replace function elbaza.t30436_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;
    _list_id int; 
    _data_filter jsonb = '{}';
    _item_filter jsonb = '{}';
    _property_data jsonb;
    _filter_type text;
    _select_type text;
    _meaning jsonb;
    _condition jsonb;
    _data_types jsonb	 = p30436_list_types();
    _array int;
    
begin
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t30436 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t30436 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
			if _rc.type = 'item_spisok' then
				update t30436_data_spisok set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t30436_data_spisok( idkart ) values( _rc.idkart );
				end if;
			end if;
		end loop;
        
        return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t30436 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t30436_data_spisok where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t30436_iud() owner to site;

