create or replace function elbaza.t27468_data_kontaktnoe_lico_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27468 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27468 as a
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
		upper(left(a.name, 1)),
		a.property_data ->> 'id26011',
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29222_list'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29061'),
		(a.property_data ->> 'user_position')::int,
		a.property_data ->> 'user_birthday',
		(a.property_data ->> 'user_sex')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
		NEW.starts_with,
		NEW.id26011,
		NEW.id29222_list,
		NEW.id29061,
		NEW.user_position,
		NEW.user_birthday,
		NEW.user_sex
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27468_data_kontaktnoe_lico_iu_bef() owner to site;

