create or replace function elbaza.t20092_data_zadanye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t20092 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t20092 as a
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
		(a.property_data ->> 'num_inquirer')::int,
		(a.property_data ->> 'tip')::int,
		(a.property_data ->> 'status')::int,
		(a.property_data ->> 'rits')::int,
		(a.property_data ->> 'napravleniye')::int,
		(a.property_data ->> 'on_lk')::boolean,
		(a.property_data ->> 'on_type_mail')::boolean,
		(a.property_data ->> 'on_manager')::boolean,
		(a.property_data ->> 'on_source')::boolean,
		(a.property_data ->> 'on_childs')::boolean,
		(a.property_data ->> 'on_date')::boolean,
		(a.property_data ->> 'on_view')::boolean
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.num_inquirer,
		NEW.tip,
		NEW.status,
		NEW.rits,
		NEW.napravleniye,
		NEW.on_lk,
		NEW.on_type_mail,
		NEW.on_manager,
		NEW.on_source,
		NEW.on_childs,
		NEW.on_date,
		NEW.on_view
	from t20092 as a
	left join t20092 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t20092_data_zadanye_iu_bef() owner to site;

