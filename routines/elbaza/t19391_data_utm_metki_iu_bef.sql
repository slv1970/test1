create or replace function elbaza.t19391_data_utm_metki_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19391 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19391 as a
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
		a."on",
		'UTM',
		a.description,
		a.property_data ->> 'utm_result_short',
		a.property_data ->> 'utm_result',
		(a.property_data ->> 'utm_term')::int,
		(a.property_data ->> 'utm_campaign')::int,
		(a.property_data ->> 'utm_content')::int,
		(a.property_data ->> 'utm_medium')::int,
		(a.property_data ->> 'utm_source')::int,
		a.property_data ->> 'utm_link'		
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."on",
		NEW."group",
		NEW.description,
		NEW.utm_result_short,
		NEW.utm_result,
		NEW.utm_term,
		NEW.utm_campaign,
		NEW.utm_content,
		NEW.utm_medium,
		NEW.utm_source,
		NEW.utm_link
	from t19391 as a
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t19391_data_utm_metki_iu_bef() owner to developer;

