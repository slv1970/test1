create or replace function elbaza.t27468_data_klient_yurlico_iu_bef() returns trigger
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
		(a.property_data ->> 'kd')::int,
		(a.property_data ->> 'id21324')::int,
		(a.property_data ->> 'id26011')::int,
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29222_list'),
		a.property_data ->> 'site',
		a.property_data ->> 'email',
		a.property_data ->> 'phone',
		a.property_data ->> 'base_work',
		a.property_data -> 'dt_address_legal',
		a.property_data -> 'dt_address',
		a.property_data ->> 'nm_full',
		a.property_data -> 'find_client',
		a.property_data ->> 'inn',
		a.property_data ->> 'kpp',
		a.property_data ->> 'ogrn',
		a.property_data ->> 'nm',
		a.property_data ->> 'bank_name',
		a.property_data ->> 'bank_cor_account',
		a.property_data ->> 'bank_bic',
		a.property_data ->> 'bank_account',
		a.property_data -> 'find_bic',
		a.property_data ->> 'bush_comment',
		(a.property_data ->> 'id24001_brush')::int,
		a.property_data ->> 'dir_position',
		a.property_data ->> 'dir_email',
		a.property_data ->> 'dir_phone',
		a.property_data ->> 'dir_name_rp',
		a.property_data ->> 'dir_position_rp',
		a.property_data -> 'dir_name',
		a.property_data ->> 'acc_email',
		a.property_data ->> 'acc_phone',
		a.property_data -> 'acc_name_rp',
		a.property_data ->> 'acc_position_rp',
		a.property_data -> 'acc_name',
		a.property_data ->> 'acc_position'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
		NEW.kd,
		NEW.id21324,
		NEW.id26011,
		NEW.id29222_list,
		NEW.site,
		NEW.email,
		NEW.phone,
		NEW.base_work,
		NEW.dt_address_legal,
		NEW.dt_address,
		NEW.nm_full,
		NEW.find_client,
		NEW.inn,
		NEW.kpp,
		NEW.ogrn,
		NEW.nm,
		NEW.bank_name,
		NEW.bank_cor_account,
		NEW.bank_bic,
		NEW.bank_account,
		NEW.find_bic,
		NEW.bush_comment,
		NEW.id24001_brush,
		NEW.dir_position,
		NEW.dir_email,
		NEW.dir_phone,
		NEW.dir_name_rp,
		NEW.dir_position_rp,
		NEW.dir_name,
		NEW.acc_email,
		NEW.acc_phone,
		NEW.acc_name_rp,
		NEW.acc_position_rp,
		NEW.acc_name,
		NEW.acc_position
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t27468_data_klient_yurlico_iu_bef() owner to site;

