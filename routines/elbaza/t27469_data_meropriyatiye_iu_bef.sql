create or replace function elbaza.t27469_data_meropriyatiye_iu_bef() returns trigger
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
		a.property_data -> 'files2',
		(a.property_data ->> 'add_slider')::int,
		(a.property_data ->> 'id17429')::int,
		a.property_data ->> 'code_event',
		a.property_data ->> 'topic_event',
		a.property_data ->> 'name_event',
		a.property_data ->> 'official_event',
		a.property_data ->> 'description_event',
		pdb_sys_jsonb_to_int_array( a.property_data -> 'id19067_list' ),
		pdb_sys_jsonb_to_int_array( a.property_data -> 'id18888_list' ),
		pdb_sys_jsonb_to_int_array( a.property_data -> 'id18311_list' ),
		a.property_data ->> 'meta_keywords',
		a.property_data ->> 'meta_description'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.files2,
		NEW.add_slider,
		NEW.id17429,
		NEW.code_event,
		NEW.topic_event,
		NEW.name_event,
		NEW.official_event,
		NEW.description_event,
		NEW.id19067_list,
		NEW.id18888_list,
		NEW.id18311_list,
		NEW.meta_keywords,
		NEW.meta_description
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27469_data_meropriyatiye_iu_bef() owner to site;

