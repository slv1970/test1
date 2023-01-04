create or replace function elbaza.t20175_data_gruppa_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t20175 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t20175 as a
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
		(a.property_data ->> 'sotrudnik')::int,
		(a.property_data ->> 'group_code')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.sotrudnik,
		NEW.group_code
	from t20175 as a
	left join t20175 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t20175_data_gruppa_iu_bef() owner to developer;

