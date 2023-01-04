create or replace function elbaza.t17430_filtr_iu() returns trigger
    language plpgsql
as
$$
declare
	_link_table text;
	_ids_polzovateley integer[];
	_date_b date; 
	_date_e date; 
	_limit_obyekt_logirovaniya integer;
	_ids_obyekt_logirovaniya integer[];
begin
 
	if NEW.type = 'item_filtr' and NEW.dttmcl is null then
	
-- взять имя таблицы
		select a.link_table into _link_table
		from t17430 as a where a.idkart = NEW.parent;
-- получение данных по условию	
		-- пользователи
		_ids_polzovateley = pdb_sys_jsonb_to_int_array( NEW.property_data -> 'ids_polzovateley' );
		-- записи		
		_ids_obyekt_logirovaniya = pdb_sys_jsonb_to_int_array( NEW.property_data -> 'ids_obyekt_logirovaniya' );
		-- даты
		_date_b = NEW.property_data #>> '{period,0}';
		_date_e = NEW.property_data #>> '{period,1}';
		-- лимит
		_limit_obyekt_logirovaniya =  NEW.property_data ->> 'limit_obyekt_logirovaniya';
		_limit_obyekt_logirovaniya = COALESCE( _limit_obyekt_logirovaniya, 100 );
		
		if _ids_polzovateley is null and _ids_obyekt_logirovaniya is null and _date_b is null and _date_e is null then
			return NEW;
		end if;
		
		create local temp table _tmp_t17430_filtr_iu on commit drop as
			select _link_table as link_table, a.link_idkart
			from t17430_log as a
			where a.link_table = _link_table
				and (_ids_polzovateley is null or a.userid = any( _ids_polzovateley ) )
				and (_ids_obyekt_logirovaniya is null or a.link_idkart = any ( _ids_obyekt_logirovaniya) )
				and (_date_b is null or a.dttmcr >= _date_b)
				and (_date_e is null or a.dttmcr <= _date_e)
			group by a.link_idkart
			limit _limit_obyekt_logirovaniya;
-- закрыть звписи		
		update t17430 set dttmcl = now()
		where t17430.dttmcl is null
			and t17430.parent = NEW.idkart
			and not EXISTS (
				select a.link_idkart
				from _tmp_t17430_filtr_iu as a
				where t17430.link_table = a.link_table
					and t17430.link_idkart = a.link_idkart
			);
-- востановить закрытые если есть
		update t17430 set dttmcl = null, dttmup = now()
		from (
			select a.link_table, a.link_idkart, max( a.idkart ) as idkart
			from t17430 as a
			inner join _tmp_t17430_filtr_iu as b on
				a.link_table = b.link_table
				and a.link_idkart = b.link_idkart
			where a.parent = NEW.idkart
			group by a.link_table, a.link_idkart		
		) as a
		where t17430.dttmcl is not null
			and t17430.idkart = a.idkart;			
-- добавить записи 
		insert into t17430( parent, type, "on", name, link_table, link_idkart )
		select 
			NEW.idkart, 'item_obyekt_logirovaniya' as "type", 1 as "on", 
			concat( a.link_table, ' - ', a.link_idkart ) as "name", a.link_table, a.link_idkart
		from _tmp_t17430_filtr_iu as a
		left join t17430 as b on
			b.dttmcl is null
			and b.parent = NEW.idkart
			and b.link_table = a.link_table
			and b.link_idkart = a.link_idkart
		where b.idkart is null
		order by a.link_idkart desc;
		
		drop table _tmp_t17430_filtr_iu;
		
	end if;

	return NEW;

end;
$$;

alter function elbaza.t17430_filtr_iu() owner to developer;

