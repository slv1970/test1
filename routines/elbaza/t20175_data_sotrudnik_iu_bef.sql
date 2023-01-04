create or replace function elbaza.t20175_data_sotrudnik_iu_bef() returns trigger
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
		(a.property_data ->> 'fio')::int,
		(a.property_data ->> 'log_sip')::boolean,
		(a.property_data ->> 'log_client')::boolean,
		a.property_data ->> 'num_group_phone_ext',
		a.property_data ->> 'num_group_phone',
		(a.property_data ->> 'int_phone')::int,
		(a.property_data ->> 'ats_host')::int,
		a.property_data ->> 'email_work',
		a.property_data ->> 'email_pass',
		a.property_data ->> 'email_server_imap',
		a.property_data ->> 'email_server_smtp',
		a.property_data ->> 'department',
		a.property_data ->> 'num_manager',
		(a.property_data ->> 'id_user_accounts')::int,
		a.property_data ->> 'time_zone',
		a.property_data ->> 'dolzhnost'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.id20455,
		NEW.log_sip,
		NEW.log_client,
		NEW.num_group_phone_ext,
		NEW.num_group_phone,
		NEW.int_phone,
		NEW.ats_host,
		NEW.email_work,
		NEW.email_pass,
		NEW.email_server_imap,
		NEW.email_server_smtp,
		NEW.department,
		NEW.num_manager,
		NEW.id_user_accounts,
		NEW.time_zone,
		NEW.dolzhnost
	from t20175 as a
	left join t20175 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t20175_data_sotrudnik_iu_bef() owner to developer;

