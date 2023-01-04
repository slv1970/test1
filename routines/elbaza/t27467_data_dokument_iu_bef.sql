create or replace function elbaza.t27467_data_dokument_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27467 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27467 as a
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
		a.property_data ->> 'margin_bottom',
		a.property_data ->> 'margin_right',
		a.property_data ->> 'margin_top',
		a.property_data ->> 'margin_left',
		(a.property_data ->> 'info_pages')::int,
		a.property_data ->> 'orientation',
		a.property_data ->> 'format',
		a.property_data ->> 'barcode',
		a.property_data ->> 'body',
		a.property_data ->> 'discount',
		(a.property_data ->> 'id25324')::int,
		a.property_data ->> 'blank_code',
		(a.property_data ->> 'counterparty')::int,
		(a.property_data ->> 'type')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.margin_bottom,
		NEW.margin_right,
		NEW.margin_top,
		NEW.margin_left,
		NEW.info_pages,
		NEW.orientation,
		NEW.format,
		NEW.barcode,
		NEW.body,
		NEW.discount,
		NEW.id25324,
		NEW.blank_code,
		NEW.counterparty,
		NEW.type
	from t27467 as a
	left join t27467 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27467_data_dokument_iu_bef() owner to site;

