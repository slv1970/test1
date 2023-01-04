create or replace function elbaza.t27469_data_dokument_iu_bef() returns trigger
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
		(a.property_data ->> 'templ_doc')::int,
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id20175_podrazdelenie'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id20175_gruppa'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id20175_sotrudnik'),
		a.property_data ->> 'date_end',
		a.property_data ->> 'date_begin'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.templ_doc,
		NEW.id20175_podrazdelenie,
		NEW.id20175_gruppa,
		NEW.id20175_sotrudnik,
		NEW.date_end,
		NEW.date_begin
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27469_data_dokument_iu_bef() owner to site;

