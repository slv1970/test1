create or replace function elbaza.t27469_data_raspisaniye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
		inner join temp1 as t on t.parent = a.idkart
		where a.dttmcl is null 
			and t.on = 1
	)
	select t.on into NEW.on
	from temp1 as t
	order by t.lv desc
	limit 1;

	select 
		a.dttmcr,
		a.dttmup,
		a.dttmcl,
		a.userid,
		a."name",
		b."name",
		a.description,
		(a.property_data ->> 'corporate')::boolean,
		a.property_data ->> 'slug',
		a.property_data ->> 'registr_event',
		a.property_data ->> 'date_event_end',
		a.property_data ->> 'date_event',
		(a.property_data ->> 'id28104')::int,
		(a.property_data ->> 'doc_blank')::int,
		a.property_data ->> 'cost_event',
		(a.property_data ->> 'id29071')::int,
		(a.property_data ->> 'id21307')::int,
		(a.property_data ->> 'type_registr')::int,
		pdb_sys_jsonb_to_int_array(a.property_data -> 'promocodes'),
		a.property_data ->> 'description_event'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.corporate,
		NEW.slug,
		NEW.registr_event,
		NEW.date_event_end,
		NEW.date_event,
		NEW.id28104,
		NEW.doc_blank,
		NEW.cost_event,
		NEW.id29071,
		NEW.id21307,
		NEW.type_registr,
		NEW.promocodes,
		NEW.description_event
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27469_data_raspisaniye_iu_bef() owner to site;

