create or replace function elbaza.t19697_data_status_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE
-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19697 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19697 as a
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
		(a.property_data ->> 'status_code')::int,
		(a.property_data ->> 'ur1_status')::int,
		(a.property_data ->> 'ur2_status')::int,
		(a.property_data ->> 'ur3_status')::int,
		(a.property_data ->> 'ur3_men_check')::int,
		(a.property_data ->> 'ur3_men')::int,
		(a.property_data ->> 'ur4_status')::int,
		(a.property_data ->> 'ur4_men_check')::int,
		(a.property_data ->> 'ur4_men')::int,
		(a.property_data ->> 'ur4_close')::int,
		(a.property_data ->> 'ur5_status')::int,
		(a.property_data ->> 'ur5_men_check')::int,
		(a.property_data ->> 'ur5_men')::int,
		(a.property_data ->> 'ur5_close')::int,
		a.property_data ->> 'date_caption',
		(a.property_data ->> 'is_date_close')::int,
		(a.property_data ->> 'day_work')::int,
		(a.property_data ->> 'is_manager')::int,
		(a.property_data ->> 'nadpis')::int,
		(a.property_data ->> 'is_sale')::boolean,
		(a.property_data ->> 'is_answer')::boolean,
		(a.property_data ->> 'is_num_docum')::boolean,
		(a.property_data ->> 'is_event')::boolean,
		(a.property_data ->> 'is_subscription')::boolean,
		(a.property_data ->> 'is_client')::boolean,
		(a.property_data ->> 'is_sum')::boolean,
		(a.property_data ->> 'del_history_phone')::boolean,
		(a.property_data ->> 'action_on')::boolean,
		(a.property_data ->> 'action_list')::int,
		(a.property_data ->> 'result_on')::boolean,
		(a.property_data ->> 'result_list')::int,
		(a.property_data ->> 'state')::int,
		(a.property_data ->> 'state_list')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.status_code,
		NEW.ur1_status,
		NEW.ur2_status,
		NEW.ur3_status,
		NEW.ur3_men_check,
		NEW.ur3_men,
		NEW.ur4_status,
		NEW.ur4_men_check,
		NEW.ur4_men,
		NEW.ur4_close,
		NEW.ur5_status,
		NEW.ur5_men_check,
		NEW.ur5_men,
		NEW.ur5_close,
		NEW.date_caption,
		NEW.is_date_close,
		NEW.day_work,
		NEW.is_manager,
		NEW.nadpis,
		NEW.is_sale,
		NEW.is_answer,
		NEW.is_num_docum,
		NEW.is_event,
		NEW.is_subscription,
		NEW.is_client,
		NEW.is_sum,
		NEW.del_history_phone,
		NEW.action_on,
		NEW.action_list,
		NEW.result_on,
		NEW.result_list,
		NEW.state,
		NEW.state_list
	from t19697 as a
	left join t19697 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

alter function elbaza.t19697_data_status_iu_bef() owner to site;

