create or replace function elbaza.t27470_data_sayt_iu_bef() returns trigger
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

-- 	-- связь с таблицей сайтов
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

	select 
		a.dttmcr,
		a.dttmup,
		a.dttmcl,
		a.userid,
		a."name",
		b."name",
		a.description,
		a.property_data -> 'all_banner',
		a.property_data -> 'link_img_otzyvy',
		a.property_data -> 'image_pay',
		a.property_data -> 'image_gift',
		a.property_data ->> 'link_edu',
		a.property_data -> 'files2_ob_polozhenie',
		a.property_data ->> 'main_video',
		a.property_data ->> 'template_counters',
		a.property_data ->> 'print_info',
		a.property_data ->> 'contact_work',
		a.property_data ->> 'contact_trace',
		a.property_data ->> 'contact_phone',
		a.property_data ->> 'contact_long',
		a.property_data ->> 'contact_lat',
		a.property_data ->> 'contact_email',
		a.property_data ->> 'contact_address',
		a.property_data -> 'files2_about_image',
		a.property_data ->> 'about_content',
		a.property_data -> 'files2_footer_logo',
		a.property_data ->> 'footer_link_in',
		a.property_data ->> 'footer_link_tg',
		a.property_data ->> 'footer_link_vk',
		a.property_data ->> 'footer_link_fb',
		a.property_data ->> 'footer_phone_href',
		a.property_data ->> 'footer_phone',
		a.property_data ->> 'footer_mail',
		a.property_data ->> 'footer_address',
		a.property_data ->> 'footer_copyright',
		a.property_data ->> 'header_phone',
		a.property_data ->> 'header_phone_code',
		a.property_data ->> 'header_phone_href',
		a.property_data -> 'files2_header_logo'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
		NEW.all_banner,
		NEW.link_img_otzyvy,
		NEW.image_pay,
		NEW.image_gift,
		NEW.link_edu,
		NEW.files2_ob_polozhenie,
		NEW.main_video,
		NEW.template_counters,
		NEW.print_info,
		NEW.contact_work,
		NEW.contact_trace,
		NEW.contact_phone,
		NEW.contact_long,
		NEW.contact_lat,
		NEW.contact_email,
		NEW.contact_address,
		NEW.files2_about_image,
		NEW.about_content,
		NEW.files2_footer_logo,
		NEW.footer_link_in,
		NEW.footer_link_tg,
		NEW.footer_link_vk,
		NEW.footer_link_fb,
		NEW.footer_phone_href,
		NEW.footer_phone,
		NEW.footer_mail,
		NEW.footer_address,
		NEW.footer_copyright,
		NEW.header_phone,
		NEW.header_phone_code,
		NEW.header_phone_href,
		NEW.files2_header_logo
	from t27470 as a
	left join t27470 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27470_data_sayt_iu_bef() owner to site;

