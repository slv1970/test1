create or replace function elbaza.t20175_data_podrazdeleniye_iu_bef() returns trigger
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
		(a.property_data ->> 'zadaniye')::int,
		a.property_data ->> 'num_group_phone_ext',
		a.property_data ->> 'num_group_phone',
		a.property_data ->> 'sms_password',
		a.property_data ->> 'sms_login',
		a.property_data ->> 'sms_sender',
		a.property_data ->> 'email_pass',
		a.property_data ->> 'email',
		a.property_data ->> 'email_server_smtp',
		a.property_data ->> 'email_server_imap',
		(a.property_data ->> 'rits')::int,
		(a.property_data ->> 'napravleniye')::int,
		(a.property_data ->> 'adres')::int,
		(a.property_data ->> 'subdivision_code')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.zadaniye,
		NEW.num_group_phone_ext,
		NEW.num_group_phone,
		NEW.sms_password,
		NEW.sms_login,
		NEW.sms_sender,
		NEW.email_pass,
		NEW.email,
		NEW.email_server_smtp,
		NEW.email_server_imap,
		NEW.rits,
		NEW.napravleniye,
		NEW.adres,
		NEW.subdivision_code
	from t20175 as a
	left join t20175 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t20175_data_podrazdeleniye_iu_bef() owner to developer;

