create or replace function elbaza.t27470_data_aktsiya_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27470 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27470 as a
		inner join temp1 as t on t.parent = a.idkart
		where a.dttmcl is null 
			and t.on = 1
	)
	select t.on into NEW.on
	from temp1 as t
	order by t.lv desc
	limit 1;

-- -- связь с таблицей сайтов
-- 	with recursive temp1 ( idkart, parent, type) as 
-- 	(
-- 		select idkart, parent, type
-- 		from t27470 as a
-- 		where a.idkart = NEW.idkart
-- 		union all
-- 		select a.idkart, a.parent, a.type
-- 		from t27470 as a
-- 		inner join temp1 as t on t.parent = a.idkart
-- 	)
-- 	select t.idkart into NEW.site_id
-- 	from temp1 as t
-- 	where t.type = 'item_sayt';

-- добавление остальных полей
	select 
		a.dttmcr,
		a.dttmup,
		a.dttmcl,
		a.userid,
		a."name",
		b."name",
		a.description,
		a.parent,
		a.property_data -> 'banner_image',
		(a.property_data ->> 'banner_on')::boolean,
		a.property_data ->> 'shares_date_end',
		a.property_data ->> 'shares_date_start',
		a.property_data ->> 'shares_description',
		a.property_data -> 'shares_image',
		a.property_data ->> 'shares_view',
		a.property_data ->> 'meta_description',
		a.property_data ->> 'meta_keywords',
		a.property_data -> 'meta_image',
		a.property_data ->> 'meta_title',
		a.property_data ->> 'slug',
		a.property_data ->> 'h1'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.parent,
		NEW.banner_image,
		NEW.banner_on,
		NEW.shares_date_end,
		NEW.shares_date_start,
		NEW.shares_description,
		NEW.shares_image,
		NEW.shares_view,
		NEW.meta_description,
		NEW.meta_keywords,
		NEW.meta_image,
		NEW.meta_title,
		NEW.slug,
		NEW.h1
	from t27470 as a
	left join t27470 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27470_data_aktsiya_iu_bef() owner to site;

