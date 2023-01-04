create function elbaza.__t20455_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	NEW.cache_data = md5(
		concat( 
			NEW.idkart, NEW.dttmcr, NEW.dttmup, NEW.dttmcl, NEW.userid, NEW.parent, NEW.type, NEW.on, NEW.name, NEW.description, NEW.property_data
		)
	);
	return NEW;
	
end;
$$;

create function elbaza.click(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 

--	объявляем переменные
	_idkart integer		= pdb_val_api_text(_value, '{get,short}');
	_post jsonb			= pdb_val_api(_value, null);
	_utm text;

begin

--	получаем данные из GET
	select property_data ->> 'utm_result'
	into _utm
	from t19391
	where idkart = _idkart;
	
	if _idkart is not null and _utm is not null then
		insert into link_transitions (utm_idkart, headers_data)
		values (_idkart, _post);
	else
		return pdb_return( _value, 301, 'https://grant.respectrb.ru');
	end if;
		
-- end показать info
	return pdb_return( _value, 302, _utm);

end;
$$;

create function elbaza.load_users(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
begin

-- добавление новых пользователей
	insert into t20455( uuid_pdb, idkart, dttmcr, dttmup, dttmcl, access_owner, "on", 
        name, description, property_data, data_hash, contract_data )
    select a.uuid_pdb, a.idkart, a.dttmcr, a.dttmup, a.dttmcl, a.access_owner, a.on, 
        concat( a.user_code, ' - ', a.user_name ), a.user_description, a.user_data, 
        a.data_hash, a.contract_data
	from pdb2_user_list() as a
	left join t20455 as b on a.idkart = b.idkart
	where b.idkart is null;
-- изменение данных пользователя
	update t20455 set
        uuid_pdb = a.uuid_pdb,
		dttmcr = a.dttmcr, 
		dttmup = a.dttmup,
		dttmcl = a.dttmcl,
		access_owner = a.access_owner,
		"on" = a.on,
		name = concat( a.user_code, ' - ', a.user_name ),
		description = a.user_description,
		property_data = a.user_data,
		data_hash = a.data_hash,
        contract_data = a.contract_data
	from pdb2_user_list() as a
	where a.idkart = t20455.idkart
		and a.data_hash <> t20455.data_hash;
		
	return null;
	
end;
$$;

create function elbaza.log_iud() returns trigger
    language plpgsql
as
$$
declare
	_idkart bigint;
	
begin

	if TG_OP='INSERT' then
-- запись 	
		insert into t17430_log( userid, link_table, link_idkart, iud_type )
		values ( pdb_current_userid(), TG_TABLE_NAME, NEW.idkart, 1 )
		returning idkart into _idkart;
-- поля
		insert into t17430_log_fields( id_17430_log, name, data_new )
		select _idkart, a.key, a.value
		from json_each( row_to_json( NEW ) ) as a;
		
		return NEW;
		
	elsif TG_OP='UPDATE' then
-- запись 	
		insert into t17430_log( userid, link_table, link_idkart, iud_type )
		values ( pdb_current_userid(), TG_TABLE_NAME, NEW.idkart, 2 )
		returning idkart into _idkart;
-- поля
		insert into t17430_log_fields( id_17430_log, name, data_new, data_old )
		select _idkart, a.key, a.value, b.value
		from json_each( row_to_json( NEW ) ) as a
		inner join json_each( row_to_json( OLD ) ) as b on a.key = b.key
		where concat( '-', a.value ) <> concat( '-', b.value );

		return NEW;

	end if;
	
-- запись 	
	insert into t17430_log( userid, link_table, link_idkart, iud_type )
	values ( pdb_current_userid(), TG_TABLE_NAME, OLD.idkart, 3 )
	returning idkart into _idkart;
-- поля
	insert into t17430_log_fields( id_17430_log, name, data_old )
	select _idkart, a.key, a.value
	from json_each( row_to_json( OLD ) ) as a;

	return OLD;
end;
$$;

comment on function elbaza.log_iud() is 'Логирование таблиц';

create function elbaza.m29567_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare

	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_b_submit int 		= pdb2_val_include_text( _name_mod, 'b_submit', '{value}' );  	-- id кнопки
	_MOD_TABLE text 	= 'p27472_table';  												-- таблица, с которой работаем
	_filter jsonb;  																	-- json для фильтров
    _filter_val text 	= pdb2_val_include_text( _MOD_TABLE, 'filter', '{value}' );  	-- id определенного фильтра
begin
	-- Добавить
	if _b_submit = '1' and _event = 'submit' then
		
		insert into t29567 (idispl, filter_name, date_start, date_end, phone_address_to, phone_address_from, time_start, time_end, id21311, id21301, group_id, page)
		values (_pdb_userid, 
				pdb2_val_include_text( _name_mod, 'list_name', '{value}' ),									 -- навзание фильтра
				pdb2_val_include_text( _name_mod, 'date_start', '{value}' )::date, 							 -- дата "От"
				pdb2_val_include_text( _name_mod, 'date_end', '{value}' )::date,							 -- дата "До"
				pdb2_val_include_text( _name_mod, 'phone_address_to', '{value}' ),							
				pdb2_val_include_text( _name_mod, 'phone_address_from', '{value}' ),						
				pdb2_val_include_text( _name_mod, 'time_start', '{value}' )::int,
                pdb2_val_include_text( _name_mod, 'time_end', '{value}' )::int,
				pdb2_val_include_text( _name_mod, 'id21311', '{value}' )::int,								 -- пользователь, создавший фильтр
				pdb2_val_include_text( _name_mod, 'id21301', '{value}' )::int,								 -- подразделение, откуда пользователь
				1,
			   	1);
		perform pdb_func_alert( _value, 'success', 'Фильтр создан' );
		
	-- Изменить			
	elsif _b_submit = '2' and _event = 'submit' then
	
		if _filter_val is not null then
			update t29567
			set idispl = _pdb_userid,
			filter_name = pdb2_val_include_text( _name_mod, 'list_name', '{value}' ),						 -- навзание фильтра
			date_start = pdb2_val_include_text( _name_mod, 'date_start', '{value}' )::date,					 -- дата "От"
			date_end = pdb2_val_include_text( _name_mod, 'date_end', '{value}' )::date,						 -- дата "До"
			phone_address_to = pdb2_val_include_text( _name_mod, 'phone_address_to', '{value}' ),							 
			phone_address_from = pdb2_val_include_text( _name_mod, 'phone_address_from', '{value}' ),					 
			time_start = pdb2_val_include_text( _name_mod, 'time_start', '{value}' )::int,				    
			time_end = pdb2_val_include_text( _name_mod, 'time_end', '{value}' )::int,
			id21311 = pdb2_val_include_text( _name_mod, 'id21311', '{value}' )::int,						 -- пользователь, создавший фильтр
			id21301 = pdb2_val_include_text( _name_mod, 'id21301', '{value}' )::int							 -- подразделение, откуда пользователь
			where idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр изменён' );
		else
			raise 'Фильтр не выбран';
		end if;
	
	-- Продублировать
	elsif _b_submit = '4' and _event = 'submit' then
	
		if _filter_val is not null then
			insert into t29567 (idispl, filter_name, date_start, date_end, phone_address_to, phone_address_from, time_start, time_end, id21311, id21301, group_id, page)
			select 
				_pdb_userid, 						-- пользователь
				concat(a.filter_name,' - копия'),   -- название
				a.date_start, 						-- дата "От"
				a.date_end, 						-- дата "До"
				a.phone_address_to, 				-- телефон
				a.phone_address_from, 				
				a.time_start, 							
				a.time_end, 							
				a.id21311, 							-- пользователи
				a.id21301, 							-- подразделения
				a.group_id,							-- группа фильтров
				a.page								-- страница
			from t29567 as a
			where a.idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр продублирован' );
		else
			raise 'Фильтр не выбран';
		end if;
	
	-- Удалить
	elsif _b_submit = '3' and _event = 'submit' then
	
		if _filter_val is not null then
		
			update t29567 
			set dttmcl = now()
			where idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр удален' );
			
			perform pdb2_val_include( _MOD_TABLE, 'filter', '{value}', null );  -- испраление бага, с отображением id в списке фильтров
		else
			raise 'Фильтр не выбран';
		end if;
		
	end if;
	
	perform pdb2_mdl_before( _name_mod );
	
	-- Получение данных для определенного фильтра
	if _filter_val is not null then
		select jsonb_build_object(
			'list_name', a.filter_name,								-- название фильтра
			'date_start', to_char(a.date_start, 'dd.mm.yyyy'),		-- дата "От"
			'date_end', to_char(a.date_end, 'dd.mm.yyyy'),			-- дата "До"
            'phone_address_to', a.phone_address_to,							-- телефон
			'phone_address_from', a.phone_address_from,							-- телефон
			'time_start', a.time_start,								
 			'time_end', a.time_end,																		
			'id21311', a.id21311,									-- пользователь
			'id21301', a.id21301,									-- подразделение
            'group', a.group_id
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
	
	end if;
	
	-- При добавлении нового фильтра, поля должны быть пустыми
	if _b_submit = 1 or (_filter ->> 'group')::int = 3 then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', null);
		perform pdb2_val_include( _name_mod, 'date_start', '{value}', null);
		perform pdb2_val_include( _name_mod, 'date_end', '{value}', null);
		perform pdb2_val_include( _name_mod, 'phone_address_to', '{value}', null);
		perform pdb2_val_include( _name_mod, 'phone_address_from', '{value}', null);
		perform pdb2_val_include( _name_mod, 'time_start', '{value}', null);
		perform pdb2_val_include( _name_mod, 'time_end', '{value}', null);
		perform pdb2_val_include( _name_mod, 'id21311', '{value}', null);
		perform pdb2_val_include( _name_mod, 'id21301', '{value}', null);
        
--         perform pdb2_val_include( _name_mod, 'list_name', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'date_start', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'date_end', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'phone', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'sms_message', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'status', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'gateway', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'id21311', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'id21301', '{disabled}', 1);
	-- При изменении, дублировании, удалении поля должны быть заполнены
	elsif _b_submit IN ('2', '3', '4') then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', _filter ->> 'list_name');
		perform pdb2_val_include( _name_mod, 'date_start', '{value}', _filter ->> 'date_start');
		perform pdb2_val_include( _name_mod, 'date_end', '{value}', _filter ->> 'date_end');
		perform pdb2_val_include( _name_mod, 'phone_address_to', '{value}', _filter ->> 'phone_address_to');
		perform pdb2_val_include( _name_mod, 'phone_address_from', '{value}', _filter ->> 'phone_address_from');
		perform pdb2_val_include( _name_mod, 'time_start', '{value}', _filter ->> 'time_start' );
		perform pdb2_val_include( _name_mod, 'time_end', '{value}', _filter ->> 'time_end');
		perform pdb2_val_include( _name_mod, 'id21311', '{value}', _filter ->> 'id21311');
		perform pdb2_val_include( _name_mod, 'id21301', '{value}', _filter ->> 'id21301');
	end if;

	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.m29568_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare

	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_MOD_TABLE text 	= 'p27472_table';												-- текущая таблица с которой работаем
	_filter_val text 	= pdb2_val_include_text( _MOD_TABLE, 'filter', '{value}' );		-- id фильтра					
	_b_submit int 		= pdb2_val_include_text( _name_mod, 'b_submit', '{value}' );	-- id кнопки
	_filter jsonb;																		-- json данных фильтра
	_id21311 jsonb 		= pdb2_val_include_text( _name_mod, 'id21311s', '{value}' );	-- json пользователей
	_id21311s int[]     = (select array_agg( a.value::integer ) 
						   from jsonb_array_elements_text( _id21311 ) as a);			-- массив пользователей
begin
	-- Кнопка Поделиться
	if _b_submit = '1' and _event = 'submit' then
		
		if _filter_val is not null then
			insert into t29567 (idispl, filter_name, date_start, date_end, phone_address_from, phone_address_to, time_start, 
								time_end, id21311, id21301, group_id, page)
			select 
				t20175_data_sotrudnik.id20455,	-- сотрудник, указанный в форме
				-- если поле для нового названия заполнено
				case when pdb2_val_include_text( _name_mod, 'list_new_name', '{value}' ) is not null then
					-- в таблицу вносим новое значений
					pdb2_val_include_text( _name_mod, 'list_new_name', '{value}' )
				-- иначе
				else
					-- оставляем старое
					pdb2_val_include_text( _name_mod, 'list_name', '{value}' )
				end as name,
				a.date_start, -- дата от
				a.date_end, -- дата до
				a.phone_address_from, -- откуда
				a.phone_address_to, -- куда
                a.time_start,
				a.time_end, -- сообщение
				a.id21311, -- пользователь
				a.id21301, -- подразделение
				a.group_id, -- группа фильтров
				a.page -- страница 
			from t29567 as a
			left join t20175_data_sotrudnik on t20175_data_sotrudnik.id20455 = any (_id21311s)
			where a.idkart::text = _filter_val
			and a.dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр создан' );
		else
			raise 'Фильтр не выбран';
		end if;
	end if;
	
	perform pdb2_mdl_before( _name_mod );
	
	-- Получение значений из таблицы для определенного фильтра
	if _filter_val is not null then
		select jsonb_build_object(
			'list_name', a.filter_name,		-- название фильтра
			'id21311', a.id21311,			-- пользователь
			'id21301', a.id21301			-- подразделение
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
	
	end if;
	
	-- Зполнение полей формы Поделиться
	if _b_submit = 1 then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', _filter ->> 'list_name' ); 
		perform pdb2_val_include( _name_mod, 'list_new_name', '{value}', null );
		perform pdb2_val_include( _name_mod, 'id21311s', '{value}', null );
	end if;
		

	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.m30288_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare

	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_b_submit int 		= pdb2_val_include_text( _name_mod, 'b_submit', '{value}' );  	-- id кнопки
	_MOD_TABLE text 	= 'p27473_table';  												    -- таблица, с которой работаем
	_filter jsonb;  																	-- json для фильтров
    _filter_val text 	= pdb2_val_include_text( _MOD_TABLE, 'filter', '{value}' );  	-- id определенного фильтра
	_status_s int[];  																	-- массив для статусов
begin
	-- Добавить
	if _b_submit = '1' and _event = 'submit' then
		
		insert into t29567 (idispl, filter_name, date_start, date_end, email_from, email_to, message, email_files, gateway, status, id21311, id21301, group_id, page)
		values (_pdb_userid, 
				pdb2_val_include_text( _name_mod, 'list_name', '{value}' ),									 -- навзание фильтра
				pdb2_val_include_text( _name_mod, 'date_start', '{value}' )::date, 							 -- дата "От"
				pdb2_val_include_text( _name_mod, 'date_end', '{value}' )::date,							 -- дата "До"
                pdb2_val_include_text( _name_mod, 'email_from', '{value}' ),								 -- От
                pdb2_val_include_text( _name_mod, 'email_to', '{value}' ),								     -- Кому
				pdb2_val_include_text( _name_mod, 'email_subject', '{value}' ),								 -- смс сообщение
				pdb2_val_include_text( _name_mod, 'email_files', '{value}' )::boolean,						     -- вложение
				pdb2_val_include_text( _name_mod, 'gateway', '{value}' )::int,								 -- смс шлюз
				(select 
				 	array_agg( a.value::integer ) 															 -- статусы
				 from jsonb_array_elements_text( pdb2_val_include( _name_mod, 'status', '{value}' ) ) as a), -- несколько значений в массив
				pdb2_val_include_text( _name_mod, 'id21311', '{value}' )::int,								 -- пользователь, создавший фильтр
				pdb2_val_include_text( _name_mod, 'id21301', '{value}' )::int,								 -- подразделение, откуда пользователь
				1,
			   	3);
		perform pdb_func_alert( _value, 'success', 'Фильтр создан' );
		
	-- Изменить			
	elsif _b_submit = '2' and _event = 'submit' then
	
		if _filter_val is not null then
			update t29567
			set idispl = _pdb_userid,
			filter_name = pdb2_val_include_text( _name_mod, 'list_name', '{value}' ),						 -- навзание фильтра
			date_start = pdb2_val_include_text( _name_mod, 'date_start', '{value}' )::date,					 -- дата "От"
			date_end = pdb2_val_include_text( _name_mod, 'date_end', '{value}' )::date,						 -- дата "До"
            email_from = pdb2_val_include_text( _name_mod, 'email_from', '{value}' ),								 -- От
            email_to = pdb2_val_include_text( _name_mod, 'email_to', '{value}' ),								     -- Кому
			message = pdb2_val_include_text( _name_mod, 'email_subject', '{value}' ),							 -- смс сообщение
			email_files = pdb2_val_include_text( _name_mod, 'email_files', '{value}' ),					 -- телефон
			gateway = pdb2_val_include_text( _name_mod, 'gateway', '{value}' )::int,						 -- смс шлюз
			status = (select 
					  array_agg( a.value::integer ) 															   -- статусы
					  from jsonb_array_elements_text( pdb2_val_include( _name_mod, 'status', '{value}' ) ) as a),  -- несколько значений в массив
			id21311 = pdb2_val_include_text( _name_mod, 'id21311', '{value}' )::int,						 -- пользователь, создавший фильтр
			id21301 = pdb2_val_include_text( _name_mod, 'id21301', '{value}' )::int							 -- подразделение, откуда пользователь
			where idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр изменён' );
		else
			raise 'Фильтр не выбран';
		end if;
	
	-- Продублировать
	elsif _b_submit = '4' and _event = 'submit' then
	
		if _filter_val is not null then
			insert into t29567 (idispl, filter_name, date_start, date_end, email_from, email_to, email_files, message, gateway, status, id21311, id21301, group_id, page)
			select 
				_pdb_userid, 						-- пользователь
				concat(a.filter_name,' - копия'),   -- название
				a.date_start, 						-- дата "От"
				a.date_end, 						-- дата "До"
                a.email_from,
                a.email_to,
				a.email_files, 				        -- телефон
				a.message, 							-- смс сообщение
				a.gateway, 							-- смс шлюз
				a.status, 							-- статусы
				a.id21311, 							-- пользователи
				a.id21301, 							-- подразделения
				a.group_id,							-- группа фильтров
				a.page								-- страница
			from t29567 as a
			where a.idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр продублирован' );
		else
			raise 'Фильтр не выбран';
		end if;
	
	-- Удалить
	elsif _b_submit = '3' and _event = 'submit' then
	
		if _filter_val is not null then
		
			update t29567 
			set dttmcl = now()
			where idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр удален' );
			
			perform pdb2_val_include( _MOD_TABLE, 'filter', '{value}', null );  -- испраление бага, с отображением id в списке фильтров
		else
			raise 'Фильтр не выбран';
		end if;
		
	end if;
	
	perform pdb2_mdl_before( _name_mod );
	
	-- Получение данных для определенного фильтра
	if _filter_val is not null then
		select jsonb_build_object(
			'list_name', a.filter_name,								-- название фильтра
			'date_start', to_char(a.date_start, 'dd.mm.yyyy'),		-- дата "От"
			'date_end', to_char(a.date_end, 'dd.mm.yyyy'),			-- дата "До"
            'email_from', a.email_from,
            'email_to', a.email_to,
			'email_files', a.email_files,							-- телефон
			'email_subject', a.message,								-- смс сообщение
 			'status', a.status,										-- статусы
			'gateway', a.gateway,									-- смс шлюз
			'id21311', a.id21311,									-- пользователь
			'id21301', a.id21301,									-- подразделение
            'group', a.group_id
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
	
	end if;
	
	-- массив статусов
	_status_s = (select array_agg( a.value::integer ) from jsonb_array_elements_text( (_filter ->> 'status')::jsonb ) as a);
	
	-- При добавлении нового фильтра, поля должны быть пустыми
	if _b_submit = 1 or (_filter ->> 'group')::int = 3 then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', null);
		perform pdb2_val_include( _name_mod, 'date_start', '{value}', null);
		perform pdb2_val_include( _name_mod, 'date_end', '{value}', null);
        perform pdb2_val_include( _name_mod, 'email_from', '{value}', null);
        perform pdb2_val_include( _name_mod, 'email_to', '{value}', null);
		perform pdb2_val_include( _name_mod, 'email_files', '{value}', null);
		perform pdb2_val_include( _name_mod, 'email_subject', '{value}', null);
		perform pdb2_val_include( _name_mod, 'status', '{value}', null);
		perform pdb2_val_include( _name_mod, 'gateway', '{value}', null);
		perform pdb2_val_include( _name_mod, 'id21311', '{value}', null);
		perform pdb2_val_include( _name_mod, 'id21301', '{value}', null);
        
--         perform pdb2_val_include( _name_mod, 'list_name', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'date_start', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'date_end', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'phone', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'sms_message', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'status', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'gateway', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'id21311', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'id21301', '{disabled}', 1);
	-- При изменении, дублировании, удалении поля должны быть заполнены
	elsif _b_submit IN ('2', '3', '4') then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', _filter ->> 'list_name');
		perform pdb2_val_include( _name_mod, 'date_start', '{value}', _filter ->> 'date_start');
		perform pdb2_val_include( _name_mod, 'date_end', '{value}', _filter ->> 'date_end');
        perform pdb2_val_include( _name_mod, 'email_from', '{value}', _filter ->> 'email_from');
        perform pdb2_val_include( _name_mod, 'email_to', '{value}', _filter ->> 'email_to');
		perform pdb2_val_include( _name_mod, 'email_files', '{value}', _filter ->> 'email_files');
		perform pdb2_val_include( _name_mod, 'email_subject', '{value}', _filter ->> 'email_subject');
		perform pdb2_val_include( _name_mod, 'status', '{value}', _status_s::int[]);
		perform pdb2_val_include( _name_mod, 'gateway', '{value}', _filter ->> 'gateway');
		perform pdb2_val_include( _name_mod, 'id21311', '{value}', _filter ->> 'id21311');
		perform pdb2_val_include( _name_mod, 'id21301', '{value}', _filter ->> 'id21301');
	end if;

	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.m30305_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare

	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_MOD_TABLE text 	= 'p27473_table';												-- текущая таблица с которой работаем
	_filter_val text 	= pdb2_val_include_text( _MOD_TABLE, 'filter', '{value}' );		-- id фильтра					
	_b_submit int 		= pdb2_val_include_text( _name_mod, 'b_submit', '{value}' );	-- id кнопки
	_filter jsonb;																		-- json данных фильтра
	_id21311 jsonb 		= pdb2_val_include_text( _name_mod, 'id21311s', '{value}' );	-- json пользователей
	_id21311s int[]     = (select array_agg( a.value::integer ) 
						   from jsonb_array_elements_text( _id21311 ) as a);			-- массив пользователей
begin
	-- Кнопка Поделиться
	if _b_submit = '1' and _event = 'submit' then
		
		if _filter_val is not null then
			insert into t29567 (idispl, filter_name, date_start, date_end, email_from, email_to, email_files, 
								message, gateway, status, id21311, id21301, group_id, page)
			select 
				t20175_data_sotrudnik.id20455,	-- сотрудник, указанный в форме
				-- если поле для нового названия заполнено
				case when pdb2_val_include_text( _name_mod, 'list_new_name', '{value}' ) is not null then
					-- в таблицу вносим новое значений
					pdb2_val_include_text( _name_mod, 'list_new_name', '{value}' )
				-- иначе
				else
					-- оставляем старое
					pdb2_val_include_text( _name_mod, 'list_name', '{value}' )
				end as name,
				a.date_start, -- дата от
				a.date_end, -- дата до
				a.email_from, -- откуда
				a.email_to, -- куда
                a.email_files,
				a.message, -- сообщение
				a.gateway, -- смс шлюз
				a.status, -- статус
				a.id21311, -- пользователь
				a.id21301, -- подразделение
				a.group_id, -- группа фильтров
				a.page -- страница 
			from t29567 as a
			left join t20175_data_sotrudnik on t20175_data_sotrudnik.id20455 = any (_id21311s)
			where a.idkart::text = _filter_val
			and a.dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр создан' );
		else
			raise 'Фильтр не выбран';
		end if;
	end if;
	
	perform pdb2_mdl_before( _name_mod );
	
	-- Получение значений из таблицы для определенного фильтра
	if _filter_val is not null then
		select jsonb_build_object(
			'list_name', a.filter_name,		-- название фильтра
			'id21311', a.id21311,			-- пользователь
			'id21301', a.id21301			-- подразделение
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
	
	end if;
	
	-- Зполнение полей формы Поделиться
	if _b_submit = 1 then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', _filter ->> 'list_name' ); 
		perform pdb2_val_include( _name_mod, 'list_new_name', '{value}', null );
		perform pdb2_val_include( _name_mod, 'id21311s', '{value}', null );
	end if;
		

	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.m30386_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare

	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_b_submit int 		= pdb2_val_include_text( _name_mod, 'b_submit', '{value}' );  	-- id кнопки
    _button int         = pdb2_val_include_text( _name_mod, 'button', '{value}' );
	_MOD_TABLE text 	= 'p27474_table';  												-- таблица, с которой работаем
	_filter jsonb;  																	-- json для фильтров
    _filter_val text 	= pdb2_val_include_text( _MOD_TABLE, 'filter', '{value}' );  	-- id определенного фильтра
	_status_s int[];  																	-- массив для статусов
begin
    --raise '%', _button;
	-- Добавить
	if _b_submit = '1' and _event = 'submit' then
		
		insert into t29567 (idispl, filter_name, date_start, date_end, message, phone_address_from, gateway, status, id21311, id21301, group_id, page)
		values (_pdb_userid, 
				pdb2_val_include_text( _name_mod, 'list_name', '{value}' ),									 -- навзание фильтра
				pdb2_val_include_text( _name_mod, 'date_start', '{value}' )::date, 							 -- дата "От"
				pdb2_val_include_text( _name_mod, 'date_end', '{value}' )::date,							 -- дата "До"
				pdb2_val_include_text( _name_mod, 'sms_message', '{value}' ),								 -- смс сообщение
				pdb2_val_include_text( _name_mod, 'phone', '{value}' ),										 -- телефон
				pdb2_val_include_text( _name_mod, 'gateway', '{value}' )::int,								 -- смс шлюз
				(select 
				 	array_agg( a.value::integer ) 															 -- статусы
				 from jsonb_array_elements_text( pdb2_val_include( _name_mod, 'status', '{value}' ) ) as a), -- несколько значений в массив
				pdb2_val_include_text( _name_mod, 'id21311', '{value}' )::int,								 -- пользователь, создавший фильтр
				pdb2_val_include_text( _name_mod, 'id21301', '{value}' )::int,								 -- подразделение, откуда пользователь
				1,
			   	2);
		perform pdb_func_alert( _value, 'success', 'Фильтр создан' );
		
	-- Изменить			
	elsif _b_submit = '2' and _event = 'submit' then
	
		if _filter_val is not null then
			update t29567
			set idispl = _pdb_userid,
			filter_name = pdb2_val_include_text( _name_mod, 'list_name', '{value}' ),						 -- навзание фильтра
			date_start = pdb2_val_include_text( _name_mod, 'date_start', '{value}' )::date,					 -- дата "От"
			date_end = pdb2_val_include_text( _name_mod, 'date_end', '{value}' )::date,						 -- дата "До"
			message = pdb2_val_include_text( _name_mod, 'sms_message', '{value}' ),							 -- смс сообщение
			phone_address_from = pdb2_val_include_text( _name_mod, 'phone', '{value}' ),					 -- телефон
			gateway = pdb2_val_include_text( _name_mod, 'gateway', '{value}' )::int,						 -- смс шлюз
			status = (select 
					  array_agg( a.value::integer ) 															   -- статусы
					  from jsonb_array_elements_text( pdb2_val_include( _name_mod, 'status', '{value}' ) ) as a),  -- несколько значений в массив
			id21311 = pdb2_val_include_text( _name_mod, 'id21311', '{value}' )::int,						 -- пользователь, создавший фильтр
			id21301 = pdb2_val_include_text( _name_mod, 'id21301', '{value}' )::int							 -- подразделение, откуда пользователь
			where idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр изменён' );
		else
			raise 'Фильтр не выбран';
		end if;
	
	-- Продублировать
	elsif _b_submit = '4' and _event = 'submit' then
	
		if _filter_val is not null then
			insert into t29567 (idispl, filter_name, date_start, date_end, phone_address_from, message, gateway, status, id21311, id21301, group_id, page)
			select 
				_pdb_userid, 						-- пользователь
				concat(a.filter_name,' - копия'),   -- название
				a.date_start, 						-- дата "От"
				a.date_end, 						-- дата "До"
				a.phone_address_from, 				-- телефон
				a.message, 							-- смс сообщение
				a.gateway, 							-- смс шлюз
				a.status, 							-- статусы
				a.id21311, 							-- пользователи
				a.id21301, 							-- подразделения
				a.group_id,							-- группа фильтров
				a.page								-- страница
			from t29567 as a
			where a.idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр продублирован' );
		else
			raise 'Фильтр не выбран';
		end if;
	
	-- Удалить
	elsif _b_submit = '3' and _event = 'submit' then
	
		if _filter_val is not null then
		
			update t29567 
			set dttmcl = now()
			where idkart::text = _filter_val
			and dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр удален' );
			
			perform pdb2_val_include( _MOD_TABLE, 'filter', '{value}', null );  -- испраление бага, с отображением id в списке фильтров
		else
			raise 'Фильтр не выбран';
		end if;
		
	end if;
	
	perform pdb2_mdl_before( _name_mod );
	
	-- Получение данных для определенного фильтра
	if _filter_val is not null then
		select jsonb_build_object(
			'list_name', a.filter_name,								-- название фильтра
			'date_start', to_char(a.date_start, 'dd.mm.yyyy'),		-- дата "От"
			'date_end', to_char(a.date_end, 'dd.mm.yyyy'),			-- дата "До"
			'phone', a.phone_address_from,							-- телефон
			'sms_message', a.message,								-- смс сообщение
 			'status', a.status,										-- статусы
			'gateway', a.gateway,									-- смс шлюз
			'id21311', a.id21311,									-- пользователь
			'id21301', a.id21301,									-- подразделение
            'group', a.group_id
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
	
	end if;
	
	-- массив статусов
	_status_s = (select array_agg( a.value::integer ) from jsonb_array_elements_text( (_filter ->> 'status')::jsonb ) as a);
	
	-- При добавлении нового фильтра, поля должны быть пустыми
	if _b_submit = 1 or (_filter ->> 'group')::int = 3 then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', null);
		perform pdb2_val_include( _name_mod, 'date_start', '{value}', null);
		perform pdb2_val_include( _name_mod, 'date_end', '{value}', null);
		perform pdb2_val_include( _name_mod, 'phone', '{value}', null);
		perform pdb2_val_include( _name_mod, 'sms_message', '{value}', null);
		perform pdb2_val_include( _name_mod, 'status', '{value}', null);
		perform pdb2_val_include( _name_mod, 'gateway', '{value}', null);
		perform pdb2_val_include( _name_mod, 'id21311', '{value}', null);
		perform pdb2_val_include( _name_mod, 'id21301', '{value}', null);
        
--         perform pdb2_val_include( _name_mod, 'list_name', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'date_start', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'date_end', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'phone', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'sms_message', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'status', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'gateway', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'id21311', '{disabled}', 1);
-- 		perform pdb2_val_include( _name_mod, 'id21301', '{disabled}', 1);
	-- При изменении, дублировании, удалении поля должны быть заполнены
	elsif _b_submit IN ('2', '3', '4') then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', _filter ->> 'list_name');
		perform pdb2_val_include( _name_mod, 'date_start', '{value}', _filter ->> 'date_start');
		perform pdb2_val_include( _name_mod, 'date_end', '{value}', _filter ->> 'date_end');
		perform pdb2_val_include( _name_mod, 'phone', '{value}', _filter ->> 'phone');
		perform pdb2_val_include( _name_mod, 'sms_message', '{value}', _filter ->> 'sms_message');
		perform pdb2_val_include( _name_mod, 'status', '{value}', _status_s::int[]);
		perform pdb2_val_include( _name_mod, 'gateway', '{value}', _filter ->> 'gateway');
		perform pdb2_val_include( _name_mod, 'id21311', '{value}', _filter ->> 'id21311');
		perform pdb2_val_include( _name_mod, 'id21301', '{value}', _filter ->> 'id21301');
	end if;

	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.m30405_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare

	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_MOD_TABLE text 	= 'p27474_table';												-- текущая таблица с которой работаем
	_filter_val text 	= pdb2_val_include_text( _MOD_TABLE, 'filter', '{value}' );		-- id фильтра					
	_b_submit int 		= pdb2_val_include_text( _name_mod, 'b_submit', '{value}' );	-- id кнопки
	_filter jsonb;																		-- json данных фильтра
	_id21311 jsonb 		= pdb2_val_include_text( _name_mod, 'id21311s', '{value}' );	-- json пользователей
	_id21311s int[]     = (select array_agg( a.value::integer ) 
						   from jsonb_array_elements_text( _id21311 ) as a);			-- массив пользователей
begin
	-- Кнопка Поделиться
	if _b_submit = '1' and _event = 'submit' then
		
		if _filter_val is not null then
			insert into t29567 (idispl, filter_name, date_start, date_end, phone_address_from, 
								phone_address_to, time_start, time_end, message, gateway, status, id21311, id21301, group_id, page)
			select 
				t20175_data_sotrudnik.id20455,	-- сотрудник, указанный в форме
				-- если поле для нового названия заполнено
				case when pdb2_val_include_text( _name_mod, 'list_new_name', '{value}' ) is not null then
					-- в таблицу вносим новое значений
					pdb2_val_include_text( _name_mod, 'list_new_name', '{value}' )
				-- иначе
				else
					-- оставляем старое
					pdb2_val_include_text( _name_mod, 'list_name', '{value}' )
				end as name,
				a.date_start, -- дата от
				a.date_end, -- дата до
				a.phone_address_from, -- телефон откуда
				a.phone_address_to, -- телефон куда
				a.time_start,  -- время начала
				a.time_end,  -- время конца
				a.message, -- сообщение
				a.gateway, -- смс шлюз
				a.status, -- статус
				a.id21311, -- пользователь
				a.id21301, -- подразделение
				a.group_id, -- группа фильтров
				a.page -- страница 
			from t29567 as a
			left join t20175_data_sotrudnik on t20175_data_sotrudnik.id20455 = any (_id21311s)
			where a.idkart::text = _filter_val
			and a.dttmcl is null;
			perform pdb_func_alert( _value, 'success', 'Фильтр создан' );
		else
			raise 'Фильтр не выбран';
		end if;
	end if;
	
	perform pdb2_mdl_before( _name_mod );
	
	-- Получение значений из таблицы для определенного фильтра
	if _filter_val is not null then
		select jsonb_build_object(
			'list_name', a.filter_name,		-- название фильтра
			'id21311', a.id21311,			-- пользователь
			'id21301', a.id21301			-- подразделение
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
	
	end if;
	
	-- Зполнение полей формы Поделиться
	if _b_submit = 1 then
		perform pdb2_val_include( _name_mod, 'list_name', '{value}', _filter ->> 'list_name' ); 
		perform pdb2_val_include( _name_mod, 'list_new_name', '{value}', null );
		perform pdb2_val_include( _name_mod, 'id21311s', '{value}', null );
	end if;
		

	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.p140031_info(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
-- система	
  	_id text	    = pdb2_val_api_text( '{post,idkart}' );
	_idkart text     = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, '{data, idkart}');
  	_table text		= pdb2_val_api_text( '{post,table}' );
	_json jsonb;
	_dt timestamp with time zone;
	_user_name text;
	
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );

	execute format( 'select row_to_json(a) from %I as a where a.idkart = %L', _table, _idkart )
	into _json;
	
	select a.text into _user_name
--	from v20455_select as a
	from v20455_data_select as a
	where a.id = (_json->> 'userid')::integer;
	
	perform pdb2_val_include( _name_mod, 'idkart', '{value}', _idkart );
	perform pdb2_val_include( _name_mod, 'table', '{value}', _table );
	_dt = _json->> 'dttmcr';	
	perform pdb2_val_include( _name_mod, 'dttmcr', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmup';	
	perform pdb2_val_include( _name_mod, 'dttmup', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmcl';	
	perform pdb2_val_include( _name_mod, 'dttmcl', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	perform pdb2_val_include( _name_mod, 'ispl', '{value}', _user_name );

	perform pdb2_val_include( _name_mod, 'json', '{value}', jsonb_pretty( _json, 4, 0 ) );

	perform pdb2_mdl_after( _name_mod );
	return null;

	
end;
$$;

create function elbaza.p17430_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_name_tree text		= 'tree';
-- система	
  	_event text			= pdb2_event_name( _name_mod );
-- поле поиска
  	_find_text text;

  	_placeholder jsonb;
 	_parent integer;
	
	_name_table text;
	_name_table_children text;
	_idtree integer;
	_cmd_socket jsonb;
	
begin

	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;

  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );

-- обработка событий
	
	if pdb2_event_name() = 'websocket' then
-- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p17430_tree_view( null, null, a.value::integer, _name_table, _name_table_children )
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a;		
		if _cmd_socket is not null then
-- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
-- установить информацию по бланкам - НЕ ПРОРАБОТАНО
--			perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		end if;

	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );

-- добавить корень дерева	
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
		execute format( '
			insert into %I( parent, type, name, "on" )
			select 0, a.value ->> ''type'', a.value ->> ''text'', 1
			from jsonb_array_elements( $1 ) as a
			left join %I as b on (a.value ->> ''type'') = b.type
			where (a.value ->> ''type'') like ''root_%%'' and b.idkart is null;', _name_table, _name_table )
		using _placeholder;
		
-- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );

	elsif _event in ( 'selected', 'opened' ) then

-- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		return null;
		
	elsif _event = 'refresh' then
	
-- получить переменые
		_parent = pdb2_val_api_text( '{post,id}' );
-- список веток		
		_placeholder = p17430_tree_view( null, null, _parent, _name_table, _name_table_children );
-- ветки
		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'children' then
	
-- получить переменые
		_parent = pdb2_val_api_text( '{post,parent}' );
-- список веток		
		_placeholder = p17430_tree_view( _parent, _find_text, null, _name_table, _name_table_children );
-- ветки
		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'create' then

-- добавить ветку
		perform pdb2_tpl_tree_create( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
		
	elsif _event = 'move' then

-- перемешение ветки
		perform pdb2_tpl_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then

-- переименование ветки
		perform pdb2_tpl_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'duplicate' then

-- дублировать ветку
		perform pdb2_tpl_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then

-- удаление ветки
		perform pdb2_tpl_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'values' then
	
-- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
-- собрать root
	_placeholder = p17430_tree_view( 0, _find_text, null, _name_table, _name_table_children );
-- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
-- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
-- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
-- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
-- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
-- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;
							
	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

create function elbaza.p17430_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );

	_tree_mod text;
	_tree_inc text;
	_tree_view text;
	_tree_idkart integer;
	_tree_b_submit integer;
	_name_table text;
	_name_table_children text;

	_from text;
	_fields jsonb;
	_where text[];
	_link_table text;
	_link_idkart integer;

begin

	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );

	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_tree_idkart = pdb2_val_session_text( _tree_mod, '{idkart}' );
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
-- установить таблицу на изменение
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
-- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
-- если модуль скрыт - выход
		return null;
	end if;

-- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _tree_idkart );

-- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then
	
-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
-- обновить дерево
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', p17430_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
									]
							);
-- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _tree_idkart );	
						
		_tree_b_submit = 0;

	end if;

	if _tree_b_submit = 0 then
		
-- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
-- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );

	else
-- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
-- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );

-- ===================================================
-- обработка данных
	if _tree_b_submit <> 0 then
		perform pdb2_val_include( _name_mod, 'limit_obyekt_logirovaniya', '{value}', 
					pdb2_val_include( _name_mod, 'limit_obyekt_logirovaniya', '{placeholder}' ) 
								);
	end if;

	if _name_mod = 'p17430_property_obyekt_logirovaniya' then
-- условия
		select 
			a.link_table, a.link_idkart
		into 
			_link_table, _link_idkart
		from t17430 as a
		where a.idkart = _tree_idkart;
		_where = _where || format( 'link_table = %L', _link_table );
		_where = _where || format( 'link_idkart = %L', _link_idkart );
-- формирование запроса
		_from = format('select 
							a.idkart,
							a.dttmcr,
							to_char( a.dttmcr, ''dd.mm.yyyy hh24:mi:ss tz'' ) as dttmcr_fmt,
							b.text as user_name,
					   		a.iud_type,
					   		case 
					   			when a.iud_type = 1 then ''Добавление'' 
					   			when a.iud_type = 2 then ''Изменение'' 
					   			when a.iud_type = 3 then ''Удаление''
					   		else 
					   			''-'' 
					   		end as iud_type_fmf
						from t17430_log as a
					   	left join t20455_select as b on a.userid = b.id
					   ' );
-- подготовка список полей
	_fields = jsonb_build_array(
			jsonb_build_object( 'text', 'idkart', 'sort', 'idkart' ),
			jsonb_build_object( 'text', 'dttmcr_fmt', 'sort', 'dttmcr' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'iud_type_fmf', 'sort', 'iud_type' ),
			jsonb_build_object( 'align', '''center''', 'includes', array['dropdown'] )
		);
-- инициализация таблицы
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,query,from}', _from );
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,query,where}', _where );
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,table,fields}', _fields );
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,query,order_by}', 'idkart desc' );

	end if;
-- ===================================================

	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

create function elbaza.p17430_tree_view(_parent integer, _name_find text, _idkart integer, _name_table text, _name_table_children text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb_current_userid();
	_rc record;
	_placeholder jsonb[];
	_cn_all integer;
	_cn_catalog integer;
	
begin
-- item_filtr - показывает только текущего пользователя

	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;

	execute format( '
		insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
		select a.idkart, a.name, a.type, a.parent, a.on
		from %I as a
		left join %I as mn on a.parent = mn.idkart
		left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
		where a.dttmcl is null 
			and (
				$1 is null and ( a.parent = $2 or $2 = 0 and a.parent = 0 )
				or a.idkart = $1 
			)
			and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
		order by srt.sort NULLS FIRST, a.idkart desc', _name_table, _name_table_children, _pdb_userid )
	using _idkart, _parent;
	
	for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
		
	loop
-- условие поиска
		execute format( '
			with recursive temp1( idkart, ok ) as 
			(
				select a.idkart,
					case when 
						$2 is null or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				where a.dttmcl is null and a.idkart = $1
				union
				select a.idkart,
					case when 
						temp1.ok = true or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				inner join temp1 on temp1.idkart = a.parent
				where a.dttmcl is null
					and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
			)
			select count(*), max( case when a.idkart <> $1 then 1 end )
			from temp1 as a 
			inner join %I as b on a.idkart = b.idkart
			where a.ok = true
					   ;', _name_table, _name_table, _pdb_userid, _name_table )
		using _rc.idkart, _name_find
		into _cn_all, _cn_catalog;
-- ветка по условию поиска не подходит
		continue when _cn_all = 0;
-- добавить ветку		
		_placeholder = _placeholder || 
				jsonb_build_object(
					'id', _rc.idkart,
 					'parent', _rc.parent,
 					'text', _rc.name,
 					'type', _rc.type,
					'children', _cn_catalog,
					'theme', case when _rc.on = 1 then null else 5 end
				);

	end loop;
	
	drop table _tmp_pdb2_tpl_tree_view;
					
	return to_jsonb( _placeholder );

end;
$$;

create function elbaza.p18133_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
-- система	
  	_idkart integer	= pdb2_val_api_text( '{post,idkart}' );
	_json jsonb;
	
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
-- данные из таблице t17430_log
	select row_to_json(a)
	into _json
	from (
		select 
			a.link_table,
			a.link_idkart,
			to_char( a.dttmcr, 'dd.mm.yyyy hh24:mi:ss tz' ) as dttmcr,
			b.text as ispl,
			case 
				when a.iud_type = 1 then 'Добавление'
				when a.iud_type = 2 then 'Изменение' 
				when a.iud_type = 3 then 'Удаление'
			end as iud_type
		from t17430_log as a
		left join t20455_select as b on a.userid = b.id
		where a.idkart = _idkart
	) as a;
-- установить
	perform pdb2_val_include_set( _name_mod, '{value}', _json, 'dttmcr', 'iud_type', 'ispl' );
-- данные из таблице лога
	execute format( '
		select row_to_json(a) 
		from (
			select 
				a.idkart as link_idkart,
				''%s'' as link_table,
				to_char( a.dttmcr, ''dd.mm.yyyy hh24:mi:ss tz'' ) as link_dttmcr,
				to_char( a.dttmup, ''dd.mm.yyyy hh24:mi:ss tz'' ) as link_dttmup,
				to_char( a.dttmcl, ''dd.mm.yyyy hh24:mi:ss tz'' ) as link_dttmcl,
				b.text as link_ispl
			from %I as a 
			left join t20455_select as b on a.userid = b.id
			where a.idkart = %s
		) as a
		', _json ->> 'link_table', _json ->> 'link_table', _json ->> 'link_idkart' )
	into _json;
-- установить
	perform pdb2_val_include_set( _name_mod, '{value}', _json, 
			'link_idkart', 'link_table', 'link_dttmcr', 'link_dttmup', 'link_dttmcl', 'link_ispl'
								);
-- данные из таблице t17430_log_fields
	select row_to_json(a)
	into _json
	from (
		select
			jsonb_pretty( a.data_old, 3, 0 ) as json_before,
			jsonb_pretty( a.data_new, 3, 0 ) as json_after
		from (
			select 
				jsonb_object_agg( a.name, a.data_new ) as data_new,
				jsonb_object_agg( a.name, a.data_old ) as data_old
			from t17430_log_fields as a
			where a.id_17430_log = _idkart
		) as a
	) as a;
-- установить
	perform pdb2_val_include_set( _name_mod, '{value}', _json, 'json_before', 'json_after' );

	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

create function elbaza.p18170_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
-- система	
  	_idkart text	= pdb2_val_api_text( '{post,idkart}' );
  	_table text		= pdb2_val_api_text( '{post,table}' );
	_json jsonb;
	_dt timestamp with time zone;
	_user_name text;
	elem text[];
	
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
	elem = pdb2_val_api_text('{post, id}')::text[];
	
	if length(_idkart) > 10 then
		_idkart = pdb2_tree_placeholder( elem[3], 'tree', _idkart, 0, '{data, idkart}');
	else 
		_idkart = _idkart::int;
	end if;

	execute format( 'select row_to_json(a) from %I as a where a.idkart = %L', _table, _idkart )
	into _json;
	
	select a.text into _user_name
--	from v20455_select as a
	from v20455_data_select as a
	where a.id = (_json->> 'userid')::integer;
	
	perform pdb2_val_include( _name_mod, 'idkart', '{value}', _idkart );
	perform pdb2_val_include( _name_mod, 'table', '{value}', _table );
	_dt = _json->> 'dttmcr';	
	perform pdb2_val_include( _name_mod, 'dttmcr', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmup';	
	perform pdb2_val_include( _name_mod, 'dttmup', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmcl';	
	perform pdb2_val_include( _name_mod, 'dttmcl', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	perform pdb2_val_include( _name_mod, 'ispl', '{value}', _user_name );

	perform pdb2_val_include( _name_mod, 'json', '{value}', jsonb_pretty( _json, 4, 0 ) );

	perform pdb2_mdl_after( _name_mod );
	return null;

	
end;
$$;

create function elbaza.p19391_property_utm_metki(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );
	_idkart integer			= pdb2_val_include_text( _name_mod, 'idkart', '{var}' );
	
	_utm_link text;
	_utm_source text;
	_utm_medium text;
	_utm_campaign text;
	_utm_content text;
	_utm_term text;
	_utm_term_cond text;
	_utm_content_cond text;
	_symbol text = '?';
	_result text;
	_result_short text;
	_tree_inc text;
	_name_table text;
	_name_table_children text;
	_tree_view text;
	_tree_idkart integer;
	_tree_mod text;
	_tree_b_submit integer;
	
begin
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );
	
	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_tree_idkart = pdb2_val_session_text( _tree_mod, '{idkart}' );
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
	
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
-- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
-- если модуль скрыт - выход
		return null;
	end if;

-- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _tree_idkart );

-- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then
	
        -- собираем данные инклудов
		_utm_link = pdb2_val_include_text( _name_mod, 'utm_link', '{value}' );
		_utm_source = pdb2_val_include_text( _name_mod, 'utm_source', '{value}' );
		_utm_medium = pdb2_val_include_text( _name_mod, 'utm_medium', '{value}' );
		_utm_campaign = pdb2_val_include_text( _name_mod, 'utm_campaign', '{value}' );
		_utm_content = pdb2_val_include_text( _name_mod, 'utm_content', '{value}' );
		_utm_term = pdb2_val_include_text( _name_mod, 'utm_term', '{value}' );

        -- Проверяем, есть ли в ссылке вхождение - маркер модалки
		if substring( _utm_link from 'dynamic-box'::text ) is not null then
 		    _symbol = '&';
 		end if;

        -- Обработка необяз-го параметра utm_content
		if _utm_term = '' or _utm_content is null then
			_utm_content_cond = null;
		else
			_utm_content_cond = concat('&utm_content=', _utm_content);
		end if;
		
		-- Обработка необяз-го параметра utm_term
		if _utm_term = '' or _utm_term is null then
			_utm_term_cond = null;
		else
			_utm_term_cond = concat('&utm_term=', _utm_term);
		end if;
		
		_result = concat(
			_utm_link, 
			_symbol, 
			'utm_source=', _utm_source, 
			'&utm_medium=', _utm_medium, 
			'&utm_campaign=', _utm_campaign, 
			_utm_content_cond, 
			_utm_term_cond 
		);
		
		perform pdb2_val_include( _name_mod, 'utm_result', '{value}', _result );
		
		-- Получение сокращённой ссылки
		_result_short = concat('https://grant.respectrb.ru/click/?short=', _idkart);
		perform pdb2_val_include( _name_mod, 'utm_result_short', '{value}', _result_short);

	
-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
		
-- обновить дерево
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', pdb2_tpl_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
									]
							);
		perform pdb2_val_page( '{pdb,socket_data,ids}', _tree_idkart );	
		_tree_b_submit = 0;
		
	end if;

	if _tree_b_submit = 0 then
		
-- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
-- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );

	else
-- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
-- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );
	
	perform pdb2_mdl_after( _name_mod );

	return null;

end;
$$;

create function elbaza.p20455_tab(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_from text;
	_fields jsonb;
	_where text[];
	_tabs text;
			
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
-- формирование условий
	_where = _where || format( 'a.dttmcl is null' );

	_tabs = pdb2_val_include_text( _name_mod, 'tabs', '{value}' );
	if _tabs = '3' then
		_where = _where || format( 'a.on is null' );
	else
		_where = _where || format( 'a.on = 1' );
	end if;

-- формирование запроса
	_from = format('select 
						a.idkart,
				   		a.user_name
					from t20455_data as a
					' );
-- подготовка список полей
	_fields = jsonb_build_array(
			jsonb_build_object( 'html', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'html', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'align', '''right''', 'includes', array['dropdown'] )
		);
			
-- инициализация таблицы
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,from}', _from );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,where}', _where );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,table,fields}', _fields );

	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

create function elbaza.p27467_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_name_tree text		= 'tree';	
  	_event text			= pdb2_event_name( _name_mod );
	-- поле поиска
  	_find_text text;

  	_placeholder jsonb;
 	_parent integer;
	
	_name_table text;
	_name_table_children text;
	_idtree integer;
	_cmd_socket jsonb;
	
begin

	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;

  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );

	-- обработка событий
	if pdb2_event_name() = 'websocket' then
	-- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p27467_tree_view( null, null, a.value::integer, _name_table, _name_table_children )
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a;		
		
		if _cmd_socket is not null then
			-- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
			-- установить информацию по бланкам - НЕ ПРОРАБОТАНО
			--	perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		end if;

	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );

		-- добавить корень дерева	
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
		execute format( '
			insert into %I( parent, type, name, "on" )
			select 0, a.value ->> ''type'', a.value ->> ''text'', 1
			from jsonb_array_elements( $1 ) as a
			left join %I as b on (a.value ->> ''type'') = b.type
			where (a.value ->> ''type'') like ''root_%%'' and b.idkart is null;', _name_table, _name_table )
		using _placeholder;
		
		-- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );

	elsif _event in ( 'selected', 'opened' ) then

		-- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		return null;
		
	elsif _event = 'refresh' then
	
		-- получить переменые
		_parent = pdb2_val_api_text( '{post,id}' );
		-- список веток		
		_placeholder = p27467_tree_view( null, null, _parent, _name_table, _name_table_children );
		-- ветки
		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'children' then
	
		-- получить переменые
		_parent = pdb2_val_api_text( '{post,parent}' );
		-- список веток		
		_placeholder = p27467_tree_view( _parent, _find_text, null, _name_table, _name_table_children );
		-- ветки
		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'create' then

		-- добавить ветку
		perform pdb2_tpl_tree_create( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
		
	elsif _event = 'move' then

		-- перемешение ветки
		perform pdb2_tpl_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then

		-- переименование ветки
		perform pdb2_tpl_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'duplicate' then

		-- дублировать ветку
		perform pdb2_tpl_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then

		-- удаление ветки
		perform pdb2_tpl_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'values' then
	
		-- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;

	-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
	-- собрать root
	_placeholder = p27467_tree_view( 0, _find_text, null, _name_table, _name_table_children );
	-- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
	-- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
	-- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
		-- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
		-- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
		-- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;
							
	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

create function elbaza.p27467_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );

	_tree_mod text;
	_tree_inc text;
	_tree_view text;
	_tree_idkart integer;
	_tree_b_submit integer;
	_name_table text;
	_name_table_children text;

begin

	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );

	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_tree_idkart = pdb2_val_session_text( _tree_mod, '{idkart}' );
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
	-- установить таблицу на изменение
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
	-- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
		-- если модуль скрыт - выход
		return null;
	end if;
	-- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _tree_idkart );
	-- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then
		-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
		-- обновить дерево
 		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', pdb2_tpl_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
									]
							);
		-- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _tree_idkart );	
						
		_tree_b_submit = 0;

	end if;

	if _tree_b_submit = 0 then
		
		-- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
		-- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );

	else
		-- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
	-- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );
	
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

create function elbaza.p27467_tree_view(_parent integer, _name_find text, _idkart integer, _name_table text, _name_table_children text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb_current_userid();
	_rc record;
	_placeholder jsonb[];
	_cn_all integer;
	_cn_catalog integer;
	
begin
	-- item_filtr - показывает только текущего пользователя

	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;

	execute format( '
		insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
		select a.idkart, a.name, a.type, a.parent, a.on
		from %I as a
		left join %I as mn on a.parent = mn.idkart
		left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
		where a.dttmcl is null 
			and (
				$1 is null and ( a.parent = $2 or $2 = 0 and a.parent = 0 )
				or a.idkart = $1 
			)
			and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
		order by srt.sort NULLS FIRST, a.idkart desc', _name_table, _name_table_children, _pdb_userid )
	using _idkart, _parent;
	
	for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
		
	loop
	-- условие поиска
		execute format( '
			with recursive temp1( idkart, ok ) as 
			(
				select a.idkart,
					case when 
						$2 is null or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				where a.dttmcl is null and a.idkart = $1
				union
				select a.idkart,
					case when 
						temp1.ok = true or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				inner join temp1 on temp1.idkart = a.parent
				where a.dttmcl is null
					and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
			)
			select count(*), max( case when a.idkart <> $1 then 1 end )
			from temp1 as a 
			inner join %I as b on a.idkart = b.idkart
			where a.ok = true
					   ;', _name_table, _name_table, _pdb_userid, _name_table )
		using _rc.idkart, _name_find
		into _cn_all, _cn_catalog;
		-- ветка по условию поиска не подходит
		continue when _cn_all = 0;
		-- добавить ветку		
		_placeholder = _placeholder || 
				jsonb_build_object(
					'id', _rc.idkart,
 					'parent', _rc.parent,
 					'text', _rc.name,
 					'type', _rc.type,
					'children', _cn_catalog,
					'theme', case when _rc.on = 1 then null else 5 end
				);

	end loop;
	
	drop table _tmp_pdb2_tpl_tree_view;
					
	return to_jsonb( _placeholder );

end;
$$;

create function elbaza.p27468_filter_data(_client_id integer, _filter_data jsonb) returns boolean
    language plpgsql
as
$$
declare
	_kd text;
	
	_ddt_client_json jsonb	= _filter_data -> 'ddt_client_json';
	_ddt_adr_json jsonb		= _filter_data -> 'ddt_adr_json';
	
-- поля в таблице
	_type text;
	_opf text;
	_state text;
	_okved text;
	_okveds text[];
	_employee integer;
	_tax text;
	_founders text[];
	_managers text[];
	_capital numeric;
	_income numeric;
	_expense numeric;
	_debt numeric;
	_penalty numeric;
	_smb text;
	_id21324 integer;
	_adr text[];
	_id202_find integer;
	_id24001_brush integer;
	_client_id_find int;
    
begin
	
	_type = _ddt_client_json #>> '{type}';
	if _type is not null then 
		select a.kd into _kd from t_klient_type as a
		where a.kd = _type;
		if _kd is null then
			insert into t_klient_type( kd, nm )
			values( _type, 
					case
				   		when _type = 'LEGAL' 		then 'юридическое лицо'
						when _type = 'INDIVIDUAL'	then 'индивидуальный предприниматель'
				   end );
		end if;
	end if;
    
	_opf = _ddt_client_json #>> '{opf,code}';
	if _opf is not null then
		select a.kd into _kd from t_klient_okpf as a
		where a.kd = _opf;
		if _kd is null then
			insert into t_klient_okpf( kd, nm )
			values( _opf, _ddt_client_json #>> '{opf,full}' );
		end if;
	end if;
    
	_state = _ddt_client_json #>> '{state,status}';
	if _state is not null then
		select a.kd into _kd from t_klient_state as a
		where a.kd = _state;
		if _kd is null then
			insert into t_klient_state( kd, nm )
			values( _state, 
						case
						when _state = 'ACTIVE' 			then 'действующая'
						when _state = 'LIQUIDATING'		then 'ликвидируется'
						when _state = 'LIQUIDATED'		then 'ликвидирована'
						when _state = 'REORGANIZING'	then 'в процессе присоединения к другому юрлицу, с последующей ликвидацией'
						end
				  );
		end if;
	end if;
    
	if jsonb_typeof( _ddt_client_json #> '{okveds}' ) = 'array' then 
		insert into t_klient_okveds( kd, nm ) 
        select a.kd, a.nm
		from (
			select a.value ->> 'code' as kd, a.value ->> 'name' as nm
			from jsonb_array_elements( _ddt_client_json #> '{okveds}' ) as a
		) as a 
		left join t_klient_okveds as b on a.kd = b.kd
		where b.kd is null;
	end if;
	
	if jsonb_typeof( _ddt_client_json #> '{okveds}' ) = 'array' then 
		select array_agg(a.value ->> 'code') into _okveds
		from jsonb_array_elements( _ddt_client_json #> '{okveds}' ) as a;
	end if;	
    
	_okved = _ddt_client_json #>> '{okved}';
	_employee = _ddt_client_json #>> '{employee_count}';
	_tax = COALESCE( (_ddt_client_json #>> '{finance,tax_system}'), 'OSN' );
    
	if _tax is not null then 
		select a.kd into _kd from t_klient_tax as a where a.kd = _tax;		
		if _kd is null then
			insert into t_klient_tax( kd, nm )
			values( _tax, 
					case
						when _tax = 'ENVD' then 'единый налог на вмененный доход'
						when _tax = 'ESHN' then 'единый сельскохозяйственный налог'
						when _tax = 'SRP'  then 'система налогообложения при выполнении соглашений о разделе продукции'
						when _tax = 'USN'  then 'упрощенная система налогообложения'
						when _tax = 'OSN'  then 'не указана (общая система налогообложения)'			   		
					end
				  );
		end if;
	end if;
    
	if jsonb_typeof( _ddt_client_json #> '{founders}' ) = 'array' then 
		select array_agg( concat( a.value #>> '{fio,source}', a.value ->> 'inn' ) ) into _founders
		from jsonb_array_elements( _ddt_client_json #> '{founders}' ) as a;
	end if;
    
	if jsonb_typeof( _ddt_client_json #> '{managers}' ) = 'array' then 
		select array_agg( concat( a.value #>> '{fio,source}', a.value ->> 'inn' ) ) into _managers
		from jsonb_array_elements( _ddt_client_json #> '{managers}' ) as a;
	end if;
    
	_capital = _ddt_client_json #>> '{capital,value}';
	_income = _ddt_client_json #>> '{finance,income}';
	_expense = _ddt_client_json #>> '{finance,expense}';
	_debt = _ddt_client_json #>> '{finance,debt}';
	_penalty = _ddt_client_json #>> '{finance,penalty}';
	_smb = _ddt_client_json #>> '{documents,smb,category}';
    
	if _smb is not null then 
		select a.kd into _kd from t_klient_smb as a
		where a.kd = _smb;
		if _kd is null then
			insert into t_klient_smb( kd, nm )
			values( _smb, _ddt_client_json #>> '{documents,smb,type}' );
		end if;
	end if;
	
    -- адреса
	_adr = array[ 
				_ddt_adr_json #>> '{data,region_fias_id}',		-- регион
				_ddt_adr_json #>> '{data,area_fias_id}',		-- район в регоне
				_ddt_adr_json #>> '{data,city_fias_id}',		-- город
				_ddt_adr_json #>> '{data,city_district_fias_id}',-- район города
				_ddt_adr_json #>> '{data,settlement_fias_id}',	-- населенный пункт
				_ddt_adr_json #>> '{data,street_fias_id}'		-- улица
				];
				
	_okveds = array_remove( _okveds, null ); 
	_founders = array_remove( _founders, null ); 
	_managers = array_remove( _managers, null ); 
	_adr = array_remove( _adr, null ); 
    
	update t27468_data_klient_filter set
		vr_type = _type,
		vr_opf = _opf,
		vr_state = _state,
		vr_okveds = _okveds,
		vr_tax = _tax,
		vr_founders = _founders,
		vr_managers = _managers,
		vr_capital = _capital,
		vr_income = _income,
		vr_expense = _expense,
		vr_debt = _debt,
		vr_penalty = _penalty,
		vr_smb = _smb,
		vr_adr = _adr,
		vr_okved = _okved,
		vr_check = (_filter_data ->> 'vr_check')::integer
	where client_id = _client_id
	returning client_id into _client_id_find;
	
	if _client_id_find is null then 
		insert into t27468_data_klient_filter(
				client_id, vr_type, vr_opf, vr_state, vr_okveds, vr_employee, vr_tax, vr_founders, vr_managers, vr_capital,
				vr_income, vr_expense, vr_debt, vr_penalty, vr_smb,  vr_adr, vr_okved, vr_check )
		values (
				_client_id, _type, _opf, _state, _okveds, _employee, _tax, _founders, _managers, _capital,
				_income, _expense, _debt, _penalty, _smb,  _adr, _okved,  (_filter_data ->> 'vr_check')::integer );
	end if;
	
	return true;
	
end;
$$;

create function elbaza.p27468_query_all(_name_mod text, _name_find text, OUT _client_ids_out integer[], OUT _cn_all_out integer, OUT _cn_ric_out integer, OUT _cn_metki_out integer) returns record
    language plpgsql
as
$$
--=================================================================================================
-- Собирает массив idkart клиентов с учетом фильтра по названию и возвращает эти данные  
--=================================================================================================

declare 
    _where text;            -- условия where сформированные из фильтра списка
    _cn_all int;            -- всего клиентов
    _cn_ric int;            -- всего клиентов по РИЦам
    _cn_metki int;          -- всего клиентов по меткам
    _cn_kusty int;          -- всего клиентов по кустам
    _find_or text[];        -- массив условий соединяемых через оператор OR
    _find_and text[];       -- массив условий, соединяемых через оператор AND
    _find_text text;        -- условие для WHERE соединенные оператором AND или OR

begin 
    -- сформировать условия для поиска по названию
    _find_or = string_to_array( _name_find, ',' );
    _find_and = string_to_array( _name_find, ' ' );
    
    -- если больше одного слова через запятую
    if array_length( _find_or, 1 ) > 1 then
    
        select string_agg( format( ' a.name ~* %L', trim(a) ), ' or ' ) into _find_text
        from unnest( _find_or ) as a;
        
    -- если больше одного слова через пробел или всего 1 слово
    elsif array_length( _find_and, 1 ) > 0 then

        select string_agg( format( ' a.name ~* %L', trim(a) ), ' and ' ) into _find_text
        from unnest( _find_and ) as a;
    else 
        _find_text = null; 
    end if;
    
    if _find_text is null then
        execute 'select count(*), 
               count(case when a.id21324 is not null then a.id21324 end), 
               count(case when a.id29222_list is not null then a.id29222_list end)
        from t27468_data_klient as a
        where dttmcl is null'
        into _cn_all_out, _cn_ric_out, _cn_metki_out;
    else
        execute format('select array_agg(idkart),
               count(*), 
               count(case when a.id21324 is not null then a.id21324 end), 
               count(case when a.id29222_list is not null then a.id29222_list end)
        from t27468_data_klient as a
        where dttmcl is null and %s', _find_text)
        into _client_ids_out, _cn_all_out, _cn_ric_out, _cn_metki_out;
    end if; 
end;
$$;

create function elbaza.p27468_query_list(_name_mod text, _list_id integer, _name_find text, OUT _client_ids_out integer[], OUT _cn_all_out integer, OUT _cn_ric_out integer, OUT _cn_metki_out integer) returns record
    language plpgsql
as
$$
--=================================================================================================
-- Собирает массив idkart клиентов, с учетом фильтра по списку и по названию и возвращает эти данные
--=================================================================================================

declare 
    _data_filter jsonb;     -- фильтр списка
    _where text;            -- условия where сформированные из фильтра списка
    _find_or text[];
    _find_and text[];
    _find_text text;

begin 
    -- сформировать условия для поиска по названию
    _find_or = string_to_array( _name_find, ',' ); -- перечислены через запятую (ИЛИ)
    _find_and = string_to_array( _name_find, ' ' ); -- перечислены через пробел (И)
    
    -- если больше одного слова через запятую
    if array_length( _find_or, 1 ) > 1 then

        select string_agg( format( ' client_data.name ~* %L', trim(a) ), ' or ' ) into _find_text
        from unnest( _find_or ) as a;
        
    -- если больше одного слова через пробел или всего 1 слово
    elsif array_length( _find_and, 1 ) > 0 then

        select string_agg( format( ' client_data.name ~* %L', trim(a) ), ' and ' ) into _find_text
        from unnest( _find_and ) as a;
    else 
        _find_text = null; 
    end if;
    
    -- получить фильтр по id списка
    select a.data_filter into _data_filter 
	from t30436_data_spisok as a
	where a.idkart = _list_id;
    
    -- сформировать условия where для списка
    _where = p30436_tool_filter_table( _data_filter, null );
    
    -- если есть условия по списку
    if _where is not null then
        if _find_text is not null then 
            _where = _where || ' and client_data.dttmcl is null and ' ||  _find_text; 
        else
            _where = _where || ' and client_data.dttmcl is null';
        end if;
        
        execute format( '
            select array_agg( a.client_id ), 
                   count(*), 
                   count(case when a.id21324 is not null then a.id21324 end), 
                   count(case when a.id29222_list is not null then a.id29222_list end)
            from (
                select client.client_id, client_data.id21324, client_data.id29222_list, client_data.id24001_brush
                from t27468_data_klient_filter as client
                inner join t27468_data_klient as client_data on client_data.idkart = client.client_id 
                where %s
                order by client.client_id
            ) as a', _where )
		into _client_ids_out,  _cn_all_out, _cn_ric_out, _cn_metki_out;
    else    
        -- если нет условий по списку
        if _find_text is not null then
            _where = format('client_data.dttmcl is null and %s', _find_text); 
        else
            _where = 'client_data.dttmcl is null';
        end if;
            
        execute format( '
            select array_agg( a.client_id ), 
                       count(*),
                       count(case when a.id21324 is not null then a.id21324 end), 
                       count(case when a.id29222_list is not null then a.id29222_list end)
            from (
                select client.client_id, client_data.id21324, client_data.id29222_list, client_data.id24001_brush
                from t27468_data_klient_filter as client
                inner join t27468_data_klient as client_data on client_data.idkart = client.client_id 
                where %s
                order by client.client_id
            ) as a', _where )
		into _client_ids_out,  _cn_all_out, _cn_ric_out, _cn_metki_out;
    end if;
    
end;
$$;

create function elbaza.p27468_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_name_tree text		= 'tree';
-- система	
  	_event text			= pdb2_event_name( _name_mod );
-- поле поиска
  	_find_text text;
    _parent text; 
  	_placeholder jsonb;
	_parent_id text; 
	_id text; 
	_name_table text;
	_name_table_children text;
	_idtree integer;
	_cmd_socket jsonb;
	_idkart text; 
	_data jsonb;
	
begin
	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;
  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );
	
-- обработка событий
	if pdb2_event_name() = 'websocket' then
-- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
        
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p27468_tree_view( _name_mod, _name_tree, null, null, a.value )
                    
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a; 
        
		if _cmd_socket is not null then
-- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
-- установить информацию по бланкам - НЕ ПРОРАБОТАНО
			perform p27468_tree_set( _name_mod, _name_tree, _name_table);

		end if;
		
	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );
-- добавить корень дерева				
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
        
        insert into t27468( parent, type, name, "on" )
        select 0, a.value ->> 'type', a.value ->> 'text', 1
        from jsonb_array_elements( _placeholder ) as a
        left join t27468 as b on (a.value ->> 'type') = b.type
        where (a.value ->> 'type') = 'root_klienti' and b.idkart is null;
        
-- установить информацию по бланкам
		perform p27468_tree_set( _name_mod, _name_tree, _name_table);

	elsif _event in ( 'selected', 'opened' ) then

-- установить информацию по бланкам
		perform p27468_tree_set( _name_mod, _name_tree, _name_table);

		return null;
		
	elsif _event = 'refresh' then
-- получить переменые
		_id = pdb2_val_api_text( '{post,id}' );
        _placeholder = p27468_tree_view( _name_mod, _name_tree, null, null, _id );

-- 		_parent_id = pdb2_tree_placeholder_text( _name_mod, 'tree', _id, 1, '{item, id}' );
        
-- -- список веток	 
-- 		_placeholder = p27468_tree_view( _parent_id, null, null );
-- -- ветки
-- 		select jsonb_agg( a.value ) into _placeholder
-- 		from jsonb_array_elements( _placeholder ) as a
-- 		where a.value ->> 'id' = _id;
--         -- получить переменые
-- -- ветки
		perform pdb2_return( _placeholder );
		return null;

	elsif _event = 'children' then
	
-- получить переменые
		_parent_id = pdb2_val_api_text( '{post,parent}' );

		_placeholder = p27468_tree_view( _name_mod, _name_tree, _parent_id, _find_text, null );
        
-- ветки
		perform pdb2_return( _placeholder );
		
--         _value = pdb_func_alert(_value, 'success',  EXTRACT(EPOCH from clock_timestamp() - TRANSACTION_TIMESTAMP())::text);

		return null;
		
	elsif _event = 'create' then

-- добавить ветку
		perform p27468_tree_create( _name_mod, _name_tree, _name_table, _name_table_children );

		return null; 
		
	elsif _event = 'move' then

-- перемешение ветки
		perform p27468_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then
-- переименование ветки
        
		perform p27468_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
        

		return null;

	elsif _event = 'duplicate' then

-- дублировать ветку
		perform p27468_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then

-- удаление ветки
		perform p27468_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );

		return null;

	elsif _event = 'values' then
	
-- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;
    
-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
-- собрать root

	_placeholder = p27468_tree_view( _name_mod, _name_tree, '0', _find_text, null );

-- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
-- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
-- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
-- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
-- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
-- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

create function elbaza.p27468_tree_create(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Создает элемент дерева клиентов, обновляет таблицу сортировки дерева
--=================================================================================================
declare 
-- система	
 	_pdb_userid	integer	= pdb_current_userid(); -- текущий пользователь

  	_placeholder jsonb = '[]';                  -- placeholder для нового элемента дерева
 	_after text;                                

	_type text;         -- тип элемента в дереве
	_name text;         -- имя элемента в дереве
 	_types jsonb;       -- типа элементов дерева и их данные    
	_cn integer;        -- count, для проверки наличия элемента
	_id text;			-- ID элемента в дереве (в виде ключа)
	_parent_id text;	-- ID родителя в дереве (в виде ключа)
    _idkart int; 		-- idkart созданного элемента в таблице дерева
	_parent_idkart int; -- idkart родителя в таблице дерева
 	_children jsonb;     -- массив ID дочерних элементов папки, в которой создается элемент
	_children_arr int[]; -- массив idkart дочерних элементов в виде int[]

begin
    -- информация по дереву
	_types = pdb2_val_include( _name_mod, _name_tree, '{data,types}' );	
    -- ID родителя в дереве (в виде уникального ключа)
	_parent_id = pdb2_val_api_text( '{post, parent}' ); 
    -- idkart родителя в таблице дерева 
	_parent_idkart = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' ) ;
	-- тип элемента в дереве
	_type = pdb2_val_api_text( '{post, type}' ); 
    -- дочерние элементы папки, в которой создается новый элемент
    _children = pdb2_val_api( '{post,children}' );
	_after = pdb2_val_api_text( '{post, after}' );
    
    -- установить имя по умолчанию		
	_name = pdb_val_text( _types, array[_type,'text'] );
    
    -- добавить ветку
	execute format('insert into %I( parent, type, name, userid ) values( $1, $2, $3, $4 ) returning idkart;', _name_table)
	using _parent_idkart, _type, _name, _pdb_userid
	into _idkart;
    
    -- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    
    -- клиенты и контактные лица упорядочиваются автоматически
    if _type not in ('item_klient_fizlico', 'item_klient_yurlico', 'item_kontaktnoe_lico') then
        
        -- превращает jsonb-массив из id в дереве в int-массив из idkart в таблице дерева
        select array_agg(pdb2_tree_placeholder_text( _name_mod, _name_tree, a.value, 0,  '{data, idkart}' )::int )
        from jsonb_array_elements_text(_children) as a
        into _children_arr;
        
        execute format('select count(*) from %I as a where a.idkart = $1', _name_table_children) 
        using _parent_idkart into _cn;  

        if _cn > 0 then
            -- изменить позцию позиции
            execute format( 'update %I set children = $1 where idkart = $2;', _name_table_children )
		    using _children_arr, _parent_idkart;
        else
            -- установить позицию
            execute format( 'insert into %I( idkart, children ) values ( $1, $2 );', _name_table_children )
		    using _parent_idkart, _children_arr;
        end if;
    end if;
    
    -- получить новую ветку	 
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', _type,
                  'text', _name,
				  'idkart', _idkart
				),
				'text', _name,
				'type', _type,
				'parent', _parent_id,
				'children', case when _type in ('item_klient_fizlico', 'item_klient_yurlico') then 1 end,
				'theme', 5);
                
	-- преобразовать id и сохранить данные в сессии
	_placeholder = pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
    
 	-- получить id в дереве
    _id = _placeholder #>> '{0, id}';
    
	-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _id );
	
    -- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table); 
    
    -- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );
    
    -- новая ветка
	perform pdb2_return( _placeholder );

end;
$$;

create function elbaza.p27468_tree_duplicate(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Дублирует элемент дерева и всю ветку данного элемента. 
--=================================================================================================
declare
  	_idkart integer;	    -- ID нового элемента (копии) из таблицы дерева
 	_after_idkart integer;  -- ID дублируемого элемента из таблицы дерева 
	_parent_idkart integer; -- parent дублируемого элемента из таблицы дерева
	_id text; 		 		-- ID нового элемента в дереве
	_after_id text;	 		-- ID дублируемого элемента в дереве
	_parent_id text; 		-- parent дублируемого элемента в дереве
	_children jsonb; 		-- children элементы внутри папки _parent_id
  	_placeholder jsonb = '[]';	-- placeholder для новой записи
	_cn integer;			-- count для проверки наличия записи
	_name text;				-- название нового элемента
	_type text; 			-- тип нового элемента
	_after text;			
	_children_arr int[];
    
begin
	
	-- получить переменые
	_parent_id = pdb2_val_api_text( '{post,parent}' ); 
	_children = pdb2_val_api( '{post,children}' );		
	_after_id = pdb2_val_api_text( '{post,id}' );
	
	_parent_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
	_after_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _after_id, 0, '{data, idkart}' );
	-- создает дубликат записи в таблице и возвращает его idkart
	_idkart = p27468_tree_duplicate_copy( _after_idkart, null ); 
	-- получает название и тип нового элемента
	select type, name from t27468 where idkart = _idkart into _type, _name;
	-- формирует ветку для нового элемента
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', _type,
                  'text', _name,
				  'idkart', _idkart
				),
				'text', _name,
				'type', _type,
				'parent', _parent_id,
				'theme', 5);
	-- преобразует id placeholderа и сохраняет его данные 			
	_placeholder = pdb2_tree_placeholder( 'p27468_tree', 'tree', _placeholder );
 	-- получает преобразованный id - уникальный id в дереве
	_id = _placeholder #>> '{0, id}';
    -- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected, 0}', _id );

	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    
    
	-- превращает массив ключей children в дереве, в массив idkart 
    select array_agg(pdb2_tree_placeholder_text( _name_mod, _name_tree, a.value, 0,  '{data, idkart}' )::int )
    from jsonb_array_elements_text(_children) as a
    into _children_arr;

	-- проверка записи
	execute format ('select count(*) from %I as a where a.idkart = $1', _name_table_children)
    using _parent_idkart into _cn; 
    
	if _cn > 0 then
	-- изменить позцию позиции
        execute format( 'update %I set children = $1 where idkart = $2;', _name_table_children )
		using _children_arr, _parent_idkart;
	else
	-- установить позицию
        execute format( 'insert into %I( idkart, children ) values ( $1, $2 );', _name_table_children )
		using _parent_idkart, _children_arr;
	end if;
    
	-- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table);
	-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );	
	-- новая ветка
	perform pdb2_return( _placeholder );
	
end;
$$;

create function elbaza.p27468_tree_duplicate_copy(_idkart integer, _parent integer) returns integer
    language plpgsql
as
$$
--=================================================================================================
-- Вставляет в таблицу копию исходного элемента и всех дочерних элементов
--=================================================================================================
declare
 	_pdb_userid	integer	= pdb_current_userid(); -- ID текущего пользователя

	_new_parent integer;            -- idkart копии после вставки в таблицу 
	_all_parent integer[];          -- массив idkart всех копий, вложенных в текущего родителя
	
begin
    -- вставить копию текущей записи в таблицу и вернуть idkart
	insert into t27468( userid, parent, type, name, description, property_data )
	select _pdb_userid, COALESCE( _parent, a.parent ), a.type, concat( a.name, ' - копия' ),
		a.description, a.property_data
	from t27468 as a where a.idkart = _idkart
	returning idkart
	into _new_parent;

    -- повторить действие для всех дочерних элементов
	select array_agg( a.new_parent )
	from (
		select p27468_tree_duplicate_copy( a.idkart, _new_parent ) as new_parent
		from t27468 as a
		left join t27468_children as mn on a.parent = mn.idkart
		left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
		where a.dttmcl is null and a.parent = _idkart
		order by srt.sort NULLS FIRST, a.idkart desc
	) as a
	into _all_parent;
	
    -- вернуть idkart копии исходного элемента
	return _new_parent;

end;
$$;

create function elbaza.p27468_tree_move(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Перемещает элемент в дереве
--=================================================================================================
declare 
  	_idkart integer; 			-- idkart перемещаемого элемента из таблицы t27468
	_parent_idkart_new integer; -- parent перемещаемого элемента из таблицы t27468 после перемещения
	_parent_idkart_old integer; -- parent перемещаемого элемента из таблицы t27468 до перемещения
	_parent_id_new text; 		-- ID папки, в который перемещается элемент
	_parent_id_old text;        -- ID папки, из которой перемещается элемент
    _cn integer;                -- count, для проверки наличия записи
	_id text; 					-- ID перемещаемого элемента в дереве
 	_children jsonb;			-- массив id children-элементов для parent
-- 	select * from elbaza.t27468 where idkart =  74045;
begin
	-- получает ID перемещаемого элемента в дереве
	_id = pdb2_val_api_text( '{post,id}' );
	-- получает ID родителя в дереве, куда перемещается элемент  
	_parent_id_new = pdb2_val_api_text( '{post,parent}' );
    -- получает ID родителя в дереве, из которого перемещается элемент
 	_parent_id_old = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _id, 0, '{item, parent}' );
	-- получает jsonb-массив из children элементов, куда перемещается элемент 
	_children = pdb2_val_api( '{post,children}' );
	-- получает idkart перемещаемого элемента
	_idkart = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _id, 0, '{data, idkart}' );
	-- получает idkart родителя, куда перемещается элемент
	_parent_idkart_new = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _parent_id_new, 0, '{data, idkart}' );
	-- получает jsonb-массив idkart для children элементов
	select jsonb_agg(pdb2_tree_placeholder_text( 'p27468_tree', 'tree', a.value, 0, '{data, idkart}' )) 
	from jsonb_array_elements_text(_children) as a
	into _children;
	-- получает idkart родителя, откуда перемещается элемент
	select a.parent from t27468 as a where a.idkart = _idkart 
	into _parent_idkart_old; 

	-- смена родителя
	update t27468 set dttmup = now(), parent = _parent_idkart_new where idkart = _idkart;
	
	-- проверка записи
	select count(*) from t27468_children as a where a.idkart =_parent_idkart_new 
	into _cn;
	if _cn > 0 then
    -- изменить позцию позиции
		update t27468_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_idkart_new;
	else
    -- установить позицию
		insert into t27468_children( idkart, children ) values ( _parent_idkart_new, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
    -- подготвить данные для сокета - обновить родителя	
	if _parent_idkart_new = _parent_idkart_old then
		perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_new );	
	else
    -- проверка вложенности _parent_idkart_old в _parent_idkart_new
			with recursive temp1 ( parent ) as 
			(	
				select a.parent
				from t27468 as a
				where a.idkart = _parent_idkart_new
				union all
				select a.parent
				from t27468 as a
				inner join temp1 as t on a.idkart = t.parent
			)
			select count(*) from temp1 as a
			where a.parent = _parent_idkart_old
			into _cn;
			
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_old );
			return;
		end if;
        -- проверка вложенности _parent_idkart_new в _parent_idkart_old
			with recursive temp1 ( parent ) as 
			(	
				select a.parent
				from t27468 as a
				where a.idkart = _parent_idkart_old
				union all
				select a.parent
				from t27468 as a
				inner join temp1 as t on a.idkart = t.parent
			)
			select count(*) from temp1 as a
			where a.parent = _parent_idkart_new
			into _cn;
			
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_new );
			return;
		end if;
        -- обновить оба родителя 
		perform pdb2_val_page( '{pdb,socket_data,ids}', array[ _parent_id_new, _parent_id_old ] );
			
	end if;
	
end;
$$;

create function elbaza.p27468_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
--=================================================================================================
-- Отображает модуль "Свойства объекта" для выделенного элемента дерева
--=================================================================================================
declare 
	_include text			= pdb2_event_include( _name_mod ); -- название инклюда, вызвавшего событие
	_event text				= pdb2_event_name( _name_mod ); -- название события

	_tree_mod text;     -- название модуля дерева
	_tree_inc text;     -- название инклюда дерева
	_tree_view text;    -- название модуля свойства
	_idkart integer;    -- idkart выделенного элемента в таблице дерева
	_tree_b_submit integer; -- значение кнопки b_submit
	_name_table text;   -- название таблицы дерева
	_name_table_children text; -- название таблицы сортировки дерева
	_id text;           -- ID выделенного элемента в дереве (в виде ключа)
	_parent_id text;    -- ID родителя выделенного элемента в дереве
	_tmp_arr text[];
    _data jsonb;
    
begin
    -- получить данные по дереву
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );
    
    -- получить данные по свойству
	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_id = pdb2_val_session_text( _tree_mod, '{id}' );
	_idkart = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _id, 0, '{data, idkart}');
    
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
    -- установить таблицу на изменение
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
    -- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
    -- если модуль скрыт - выход
		return null;
	end if;
    -- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _idkart );
	
    -- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
        
	elsif _event = 'submit' then
		_id = pdb2_val_include_text( _tree_mod, _tree_inc, '{selected,0}' );
    -- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
    -- обновить дерево
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', p27468_tree_view( _tree_mod, _tree_inc, null, null, _id ) ),
                                        jsonb_build_object( 
									  		'cmd', 'reload_parent',
									  		'data', array[_id] )
									]
							);
    -- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	
						
		_tree_b_submit = 0;

	elseif _event = 'values' then
        _tree_b_submit = 2;
    end if;
    
	if _tree_b_submit = 0 then
        -- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
        
        -- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );
	else
        -- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
    -- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );
	
    perform p27468_tree_property_select(_value, _name_mod); 
        
    if _name_mod in ('p27468_property_klient_yurlico', 'p27468_property_klient_fizlico') then
        
        _data = pdb2_val_include( _name_mod, 'find_client','{value,json,data}' );
        if _data is not null then	
            perform pdb2_val_include( _name_mod, 'inn','{value}', _data -> 'inn' );
            perform pdb2_val_include( _name_mod, 'kpp','{value}', _data -> 'kpp' );
            perform pdb2_val_include( _name_mod, 'ogrn','{value}', _data -> 'ogrn' );
            perform pdb2_val_include( _name_mod, 'nm','{value}', _data #> '{name,short_with_opf}' );
            perform pdb2_val_include( _name_mod, 'nm_full','{value}', _data #> '{name,full_with_opf}' );
            perform pdb2_val_include( _name_mod, 'dir_position', '{value}', _data #> '{management,post}' );
            perform pdb2_val_include( _name_mod, 'dir_name','{value,text}', _data #> '{management,name}' );
            perform pdb2_val_include( _name_mod, 'dt_address_legal','{value}', 
                        jsonb_build_object( 'json', _data #> '{address}', 'text', _data #>> '{address,value}' ));
        end if;

        _data = pdb_val_include( _value, _name_mod, 'find_bic', '{value,json}' );
        
        if _data is not null then
            perform pdb2_val_include( _name_mod, 'bank_bic','{value}', _data #> '{data,bic}' );
            perform pdb2_val_include( _name_mod, 'bank_cor_account','{value}', _data #> '{data,correspondent_account}' );
            perform pdb2_val_include( _name_mod, 'bank_name','{value}', _data -> 'unrestricted_value' );
        end if;
    end if;
    
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

create function elbaza.p27468_tree_property_select(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
    
begin
    if _name_mod in ('p27468_property_klient_fizlico', 'p27468_property_klient_yurlico')  then
        perform pdb2_val_include( _name_mod, 'id26011', '{pdb,query,where}',
                format( 'id in (select idkart from t19697_data_status as a where a.dttmcl is null and a.ur1_status = 1)' ));
    elseif _name_mod = 'p27468_property_kontaktnoe_lico' then
        perform pdb2_val_include( _name_mod, 'id26011', '{pdb,query,where}',
                format( 'id in (select idkart from t19697_data_status as a where a.dttmcl is null and a.ur2_status = 1)' ));
    end if;
    
	return null;
	
end;
$$;

create function elbaza.p27468_tree_remove(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_idkart integer;
	_id text;
  	_parent integer;
  	_idkart_old integer;
	_id_old text;
	_parent_id text;
	_placeholder_data jsonb;
    
begin

-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
    _placeholder_data = pdb2_tree_placeholder( 'p27468_tree', 'tree', _id, 0, null);
	_idkart = _placeholder_data #>> '{data, idkart}';
	_parent_id = _placeholder_data #>> '{item, parent}';
    
-- удаление ветки
    execute format( 'update %I set dttmcl = now() where idkart = $1;', _name_table)
	using _idkart;

	_id_old = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
    
	if _id = _id_old then
-- убрать позицию
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
	end if;
-- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table );
-- подготвить данные для сокета - обновить родителя	
-- 	perform pdb2_val_page( '{pdb,socket_data,ids}',_parent_id );	
		
end;
$$;

create function elbaza.p27468_tree_rename(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_id text;       -- ID элемента в дереве
	_idkart int;    -- idkart в таблице дерева
	_name text;     -- новое название элемента
    
begin

-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
	_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _id, 0, '{data, idkart}' );
 	_name = pdb2_val_api_text( '{post,text}' );
-- смена текста
	execute format( 'update %I set dttmup = now(), name = $1 where idkart = $2 returning name;', _name_table )
	using _name, _idkart into _name;

-- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table );		
-- новое имя ветки 	
    perform pdb2_return( to_jsonb( _name ) );
-- подготвить данные для сокета - обновить id	
    perform pdb2_val_include( _name_mod, _name_tree, '{task}',
                          array[ 
                                jsonb_build_object( 
                                    'cmd', 'reload_parent',
                                    'data', array[_id] )
                            ]
                    );

    perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	

end;
$$;

create function elbaza.p27468_tree_set(_name_mod text, _name_tree text, _name_table text) returns void
    language plpgsql
as
$$
declare 
	_id text;       -- уникальный ID выделенного элемента в дереве
	_id_old text;   -- уникальный ID предыдущего элемента, хранящийся в сессии
	_type text;     -- тип выделенного элемента в дереве
	_mod_property text; -- название модуля, выделенного элемента в дереве
    
begin
-- установить информацию по выделенной ветки
	_id = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	_type = pdb2_tree_placeholder_text( _name_mod,_name_tree, _id, 0, '{data, type}' );
    
 	if _type is not null then
		_mod_property = pdb2_val_include_text( _name_mod, _name_tree, array[ 'pdb','action','visible_module', _type] );
	end if;
	if _mod_property is null then
		_mod_property = pdb2_val_include_text( _name_mod, _name_tree, array[ 'pdb','action','visible_module',''] );
	end if;
    
    -- обработка бланка
	if _mod_property is not null then
        -- убрать автомат	
		perform pdb2_val_include( _name_mod, _name_tree, array[ 'pdb','action','visible_module'], null );
        
        -- запомнитьв сессии данные для бланка
		perform pdb2_val_module( _mod_property, '{hide}', null );
		perform pdb2_val_session( _name_mod, '{view}', _mod_property );
		
        _id_old = pdb2_val_session_text( _name_mod, '{id}' );
		
        if _id = _id_old then
		else
			perform pdb2_val_session( _name_mod, '{id}', _id );
			perform pdb2_val_session( _name_mod, '{b_submit}', 0 );
		end if;
		
	end if;
end;
$$;

create function elbaza.p27468_tree_view(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Определяет тип элемента и вызывает соответствующую функцию -- 
-- Иерархия типов элементов дерева:
-- root_klienti(по Алфавиту) -> folder_klienti(А, Б..) -> item_klient_fizlico/yurlico(Клиент) -> folder_klient(Конт.лица) -> folder_klient(по Алфавиту) -> folder_klient (А, Б..) ->item_kontaktnoe_lico(по Алфавиту) -> folder_kontaktnoe_lico/item_telefon/item_pochta/item_rebenok
-- root_filter_klienti(по РИЦам) -> folder_filter_klienti(РИЦ_X) -> folder_filter_klienti(А,Б..) -> item_klient_fizlico/yurlico(Клиент)
-- root_filter_klienti(по Меткам) -> folder_filter_klienti(Метка_X) -> folder_filter_klienti(А,Б..) -> item_klient_fizlico/yurlico(Клиент)
-- root_filter_klienti(по Кустам) -> folder_filter_klienti(Основные) -> folder_filter_klienti(А,Б..) -> item_klient_fizlico/yurlico(Клиент)
--=======================================================================================--

	_type text;
    
begin	
    
    _type = pdb2_tree_placeholder_text(_name_mod, _name_tree, coalesce(_id, _parent_id), 0, '{data, type}'); 
    
    if  _type is null then 
    -- корневые элементы дерева (папки по Алфавиту, по РИЦам, по Меткам, по Кустам)
        return p27468_tree_view_root(_name_mod, _name_tree, _parent_id, _name_find, null); 
    elseif _type = 'root_klienti' then
    -- вложения папки "по Алфавиту"
        return p27468_tree_view_root_klienti(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'item_klient_yurlico' then
    -- вложения элемента - Клиент юр. лицо
        return p27468_tree_view_klient_yurlico(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'item_klient_fizlico' then 
    -- вложения элемента - Клиент физ.лицо
        return p27468_tree_view_klient_fizlico(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'folder_klienti' then 
    -- вложения папки с первой буквой наименования клиента 
        return p27468_tree_view_folder_klienti(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'folder_klient' then
    -- вложения папки "Контактные лица", по Алфавиту" и буквы алфавита для контактных лиц
        return p27468_tree_view_folder_klient(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif  _type = 'root_filter_klienti' then  
    -- вложения корневого фильтра "по РИЦам", "по Меткам", "по Кустам" и папок "Филиалы", "Кусты"
        return p27468_tree_view_root_filter(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif  _type = 'folder_filter_klienti' then  
    -- вложения папок для РИЦ, Меток
        return p27468_tree_view_folder_filter_klienti(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'folder_filter_klient' then 
    -- вложения для фильтр контактных лиц "по Состоянию", "по Меткам"
        return p27468_tree_view_folder_filter_klient(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    else
    -- контактные лица, телефон, email и др. папки, вложенные в контактное лицо
        return p27468_tree_view_kontaktnie_lica(_name_mod, _name_tree, _parent_id, _name_find, _id);
    end if;
    
	return null;
    
--     реализация через таблицу связей (не оптимально из-за слишком большого количества записей)    
--     if _id is not null then
--         select jsonb_agg( a ) into _placeholder
--         from (
--             select 
--                 a.idkart as id,
--                 b.idkart as parent, 
--                 c.name as "text", 
--                 c.type as "type",
--                 case when (select count(*) from t27468_structure as d where d.parent_id = a.child_id) > 0 then 1 end as children
--             from t27468_structure as a
--             inner join t27468_structure as b on a.parent_id = b.child_id
--             inner join t27468 as c on a.child_id = c.idkart
--             where c.dttmcl is null and a.idkart = _id::int 
--         ) as a;
--     elseif _name_find is null then
--         for _rc in 
--             select b.idkart as id, 
--                    a.idkart as parent, 
--                    c.idkart as idkart, 
--                    c.name as "text", 
--                    c.type as "type", 
--                    count(*) as count 
--             from t27468_structure as a
--             inner join t27468_structure as b on a.child_id = b.parent_id
--             inner join t27468 as c on b.child_id = c.idkart
--             left join t27468 as d on d.parent = b.child_id
--             where c.dttmcl is null 
--             and a.idkart = _parent_id::int
--             group by c.idkart, b.idkart, a.idkart
--             order by c.name
--         loop
--             if  _rc.type = 'root_klienti' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по РИЦам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_ric || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по Меткам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_metki || '</span>' );
--             elseif _rc.type  = 'root_filter_klienti' and _rc.text = 'по Кустам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_kusty || '</span>' );
--             end if;

--             _placeholder = _placeholder || 
--                   jsonb_build_object(
--                       'id', _rc.id,
--                       'parent', _rc.parent,
--                       'text', _rc.text,
--                       'type', _rc.type,
--                       'text_pref', _text_pref,
--                       'children', case when _rc.count > 0 or _rc.type ~* 'root%' then 1 end);
--         end loop;
--     else
--         for _rc in 
--             select b.idkart as id, 
--                    a.idkart as parent, 
--                    c.idkart as idkart, 
--                    c.name as "text", 
--                    c.type as "type", 
--                    count(*) as count 
--             from t27468_structure as a
--             inner join t27468_structure as b on a.child_id = b.parent_id
--             inner join t27468 as c on b.child_id = c.idkart
--             left join t27468_structure as d on d.parent_id = b.child_id
--             where c.dttmcl is null 
--             and a.idkart = _parent_id::int
--             and case when c.type in ('item_klient_fizlico', 'item_klient_yurlico') then c.idkart = any(_client_ids) 
--                      when c.type in ('folder_klienti', 'folder_klient') then c.name = left(upper(_name_find),1) 
--                      else true end
--             group by c.idkart, b.idkart, a.idkart
--             order by c.name
--         loop
--             if  _rc.type = 'root_klienti' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по РИЦам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_ric || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по Меткам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_metki || '</span>' );
--             elseif _rc.type  = 'root_filter_klienti' and _rc.text = 'по Кустам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_kusty || '</span>' );
--             end if;

--             _placeholder = _placeholder || 
--                   jsonb_build_object(
--                       'id', _rc.id,
--                       'parent', _rc.parent,
--                       'text', _rc.text,
--                       'type', _rc.type,
--                       'text_pref', _text_pref,
--                       'children', case when _rc.count > 0 or _rc.type ~* 'root%' then 1 end);
--         end loop;
--     end if;
    
--     return _placeholder; 

end;
$$;

create function elbaza.p27468_tree_view_folder_filter_klient(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder контактных лиц, отфильтрованных по статусу или по меткам
--=======================================================================================--
	_text text; 
	_placeholder jsonb = '[]';
	_client_id int;
	_status_id int; 
	_metka_id int; 
    _inn text;
    _id24001_brush int;
    _placeholder_data jsonb;
    _type text;
    _folder text;
    _cn int;
    
begin
    if _id is not null then 
		-- если передан _id возвращает placeholder с данной буквой
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
        _parent_id = _placeholder_data #>>  '{item, parent}'; 
        -- добавить подсчет количества
        if _text = 'Филиалы' then
            _client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _id, 1, '{data, idkart}' );

            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null and idkart <> _client_id
            and inn = (select inn from t27468_data_klient where dttmcl is null and idkart = _client_id);

        elseif _text = 'Кусты' then
            _client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _id, 1, '{data, idkart}' );
            
            select count(*) into _cn from t27468_data_klient as a 
            where a.dttmcl is null and a.id24001_brush = _client_id;
            
        end if;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
                case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end as text_pref,
				case when _cn is null or _cn > 0 then 1 end as children
        ) as a; 
        
        return _placeholder;
    end if;
    
    _text = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' ) ;

	if _text = 'по Состоянию' then
		-- Собирает placeholder для папки "по Состоянию" (фильтр контактных лиц)
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 2, '{data, idkart}' );
		
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_klient',
                  'text', a.text, 
				  'idkart', a.id,
				  'folder', 'status'
				) as id,
				a.text as "text", 
				'folder_klient' as "type",
				_parent_id as parent,
                case when a.count > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || a.count || '</span>' ) end as text_pref,
				case when a.count > 0 then 1 end as children 
			from (
				select c.id, COALESCE( c.text, '- нет -' ) as text, count(*) as count
				from t27468_data_kontaktnoe_lico as a 
 				inner join t27468 as b on b.idkart = a.idkart
                left join v19697_status_select as c on a.id26011 = c.id
				where a.dttmcl is null and b.dttmcl is null and c.dttmcl is null
				and b.parent = _client_id
				group by c.id, c.text 
			) as a
        ) as a;
			
	elseif _text = 'по Меткам' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 2, '{data, idkart}' );
        
        
        select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_klient',
                  'text', a.text, 
				  'idkart', a.id,
				  'folder', 'metka'
				) as id,
				a.text as "text", 
				'folder_klient' as "type",
				_parent_id as parent,
                case when a.count > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || a.count || '</span>' ) end as text_pref,
				case when a.count > 0 then 1 end as children 
			from (
				select c.id, COALESCE( c.text, '- нет -' ) as text, count(*) as count
				from (
					select unnest( COALESCE( a.id29222_list, array[-1] )) as id29222
					from t27468_data_kontaktnoe_lico as a
					inner join t27468 as b on a.idkart = b.idkart
					where a.dttmcl is null and b.dttmcl is null and b.parent = _client_id
                ) as a
				left join v19638_data_metka_select as c on c.id = a.id29222
				where c.dttmcl is null
				group by c.id, c.text
                order by c.text
            )  as a
        ) as a;  
    elseif _text = 'Филиалы' then
        _client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 1, '{data, idkart}' );
        select inn into _inn from t27468_data_klient where idkart = _client_id; 

        select jsonb_agg( a )  into _placeholder
        from (
            select 
                jsonb_build_object(
                  'type', b.type,
                  'text', b.name,
                  'idkart', b.idkart
                ) as id,
                b.name as "text", 
                b.type as "type",
                _parent_id as parent,
                concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) as text_pref,
                1 as children,
               case when b.on = 1 then null else 5 end as theme
            from t27468_data_klient a
            inner join t27468 as b on a.idkart = b.idkart
            where a.dttmcl is null and b.dttmcl is null
            and a.inn = _inn and a.idkart <> _client_id
        ) as a;
            
	elseif _text = 'Кусты' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 1, '{data, idkart}' );
        
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', b.type,
                  'text', b.name,
				  'idkart', b.idkart
				) as id,
				b.name as "text", 
				b.type as "type",
				_parent_id as parent,
                concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) as text_pref,
				1 as children,
               case when b.on = 1 then null else 5 end as theme
			from t27468_data_klient a
			inner join t27468 as b on a.idkart = b.idkart
			where a.dttmcl is null and b.dttmcl is null
			and a.id24001_brush = _client_id
        ) as a;  
    
    end if;
	
	return pdb2_tree_placeholder( 'p27468_tree', 'tree', _placeholder );

end;
$$;

create function elbaza.p27468_tree_view_folder_filter_klienti(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder клиентов, подпадающих под выбранный РИЦ или Метку или Куст --
--=======================================================================================--
	_placeholder jsonb = '[]';  -- результат функции 
	_placeholder_data jsonb;    -- данные placeholderа
    _folder text;
	_ric_id int;            -- ID РИЦа
	_metka_id int;          -- ID метки
	_letter text;           -- начало названия (1 буква) для фильтра
	_double_letter text;    -- начало названия (2 буквы) для фильтра
	_client_ids int[];      -- ID клиентов, отфильтрованных по списку или по полю для поиска
    _parent_folder text;    -- папка-родитель
    _kust_main boolean;     -- кусты-основные 
    _kust_related boolean;  -- кусты-связанные
    _cn int;                -- count
    _type text;
    _text text;
    _text_pref text;
    
begin
    _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
    
    if _id is not null then 
		-- если передан _id возвращает placeholder с данной буквой
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		_folder = _placeholder_data #>> '{data, folder}';
        
        -- сформировать условия для запроса
        if _folder = 'ric' then
            _ric_id = _placeholder_data #>> '{data, idkart}';
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null 
            and (_ric_id is null and id21324 is null or id21324 = _ric_id) 
            and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        elseif _folder = 'metka' then 
            _metka_id = _placeholder_data #>> '{data, idkart}';
            select count(*) into _cn from t27468_data_klient where dttmcl is null 
            and (_metka_id is null and id29222_list is null or _metka_id = any(id29222_list)) 
            and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        elseif _folder = 'kust_main' then
            _kust_main = true;
            select count(*) into _cn from t27468_data_klient where dttmcl is null and id24001_brush is null and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        elseif _folder = 'kust_related' then
            _kust_related = true;
            select count(*) into _cn from t27468_data_klient where dttmcl is null and id24001_brush is not null and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        end if;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
				case when _cn is null or _cn > 0 then 1 end as children,
                case when _cn > 0 then _text_pref end as text_pref
        ) as a; 
        
        return _placeholder;
    end if;
    
    _placeholder_data = pdb2_tree_placeholder(_name_mod, 'tree', _parent_id, 0, null); 
    _folder = _placeholder_data #>> '{data, folder}';

	-- папка для отдельного РИЦа. Собирает начало названий всех клиентов, соответствующих данному РИЦ 
	if _folder = 'ric' then
		_ric_id = _placeholder_data #>> '{data, idkart}' ;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id)
				order by a.letter
			) as a
        ) as a;
	-- папка для отдельной метки. Собирает начало названий всех клиентов, соответствующих данной метке 
	elseif _folder = 'metka' then
		_metka_id = _placeholder_data #>> '{data, idkart}' ;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list))
				order by a.letter
			) as a
        ) as a;
	-- папка "Основные" для куста. Собирает начало названий всех клиентов, являющихся основными 
	elseif _folder = 'kust_main' then
    
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and a.id24001_brush is null
				order by a.letter
			) as a
        ) as a;
    -- папка "Связанные" для куста. Собирает начало названий всех клиентов, являющихся связанными
	elseif _folder = 'kust_related' then
    
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and a.id24001_brush is not null
				order by a.letter
			) as a
        ) as a;		
    -- папка с 1 буквой. Собирает всех клиентов соответствющего РИЦ, метки или куста названия которых начинаются с выбранной буквы 
	elseif _folder = 'letter'  then
        -- получить название буквы для фильтрации
        _letter = _placeholder_data #>> '{data, text}';
        
        -- получить данные по ближайшему фильтру
        _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 1, '{data}' );
        
        -- определить тип папки родителя (РИЦ, Метка, Основной или Связанный куст)
        _parent_folder = _placeholder_data ->> 'folder';
        
        -- сформировать условия для запроса
        if _parent_folder = 'ric' then
            _ric_id = _placeholder_data ->> 'idkart';
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null 
            and (_ric_id is null and id21324 is null or id21324 = _ric_id);
        elseif _parent_folder = 'metka' then 
            _metka_id = _placeholder_data ->> 'idkart';
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null 
            and (_metka_id is null and id29222_list is null or _metka_id = any(id29222_list)); 
        elseif _parent_folder = 'kust_main' then
            _kust_main = true;
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null and id24001_brush is null; 
        elseif _parent_folder = 'kust_related' then
            _kust_related = true;
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null and id24001_brush is not null; 
        end if;
        
        -- если записей больше 300, добавить фильтр по 2 букве. Иначе вывести клиентов
        if _cn <= 300 then  
            -- сформировать jsonb-массив из клиентов
            select jsonb_agg( a ) into _placeholder
            from (
                select 
                    jsonb_build_object(
                        'type', a.type,
                        'text', a.name,
                        'idkart', a.idkart
                    ) as id,
                    a.name as "text", 
                    a.type as "type",
                    _parent_id as parent,
                    1 as children,
                    case when a.on = 1 then null else 5 end as theme
                from t27468_data_klient as a
                where a.dttmcl is null
                and a.letter = _letter
                and (_client_ids is null or a.idkart = any(_client_ids))
                and (_parent_folder <> 'ric' or (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id))
                and (_parent_folder <> 'metka' or (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list)))
                and (_kust_main is null or a.id24001_brush is null)
                and (_kust_related is null or a.id24001_brush is not null)
                order by a.name
            ) as a;
        else
            -- сформировать jsonb-массив из папок с 2 буквами
            select jsonb_agg( a ) into _placeholder
            from (
                select 
                    jsonb_build_object(
                        'type', 'folder_filter_klienti',
                        'text', a.double_letter,
                        'folder', 'double_letter'
                    ) as id,
                    a.double_letter as "text", 
                    'folder_klienti' as "type",
                    _parent_id as parent,
                    1 as children 
                from (
                    select distinct double_letter
                    from t27468_data_klient as a
                    where a.dttmcl is null
                    and a.letter = _letter
                    and (_client_ids is null or idkart = any(_client_ids))
                    and (_parent_folder <> 'ric' or (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id))
                    and (_parent_folder <> 'metka' or (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list)))
                    and (_kust_main is null or a.id24001_brush is null)
                    and (_kust_related is null or a.id24001_brush is not null)
                    order by double_letter
                ) as a
            ) as a;
        end if;
    -- папка с 2 буквами. Собирает всех клиентов соответствющего РИЦ, метки или куста названия которых начинаются с выбранных букв
    elseif _folder = 'double_letter' then
        -- получить название буквы для фильтрации
        _double_letter = _placeholder_data #>> '{data, text}';
        -- получить данные по ближайшему фильтру
        _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 2, '{data}' );
        -- определить тип папки родителя (РИЦ, Метка, Основной или Связанный куст)
        _parent_folder = _placeholder_data ->> 'folder';
        -- сформировать условия для запроса
        if _parent_folder = 'ric' then
            _ric_id = _placeholder_data ->> 'idkart';
        elseif _parent_folder = 'metka' then 
            _metka_id = _placeholder_data ->> 'idkart';
        elseif _parent_folder = 'kust_main' then
            _kust_main = true;
        elseif _parent_folder = 'kust_related' then
            _kust_related = true;
        end if;
        
        -- сформировать jsonb-массив из клиентов
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                jsonb_build_object(
                    'type', a.type,
                    'text', a.name,
                    'idkart', a.idkart
                ) as id,
                a.name as "text", 
                a.type as "type",
                _parent_id as parent,
                1 as children,
                case when a.on = 1 then null else 5 end as theme
            from t27468_data_klient as a
            where a.dttmcl is null 
            and a.double_letter = _double_letter
            and (_client_ids is null or a.idkart = any(_client_ids))
            and (_parent_folder <> 'ric' or (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id))
            and (_parent_folder <> 'metka' or (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list)))
            and (_kust_main is null or a.id24001_brush is null)
            and (_kust_related is null or a.id24001_brush is not null)
            order by a.name
        ) as a;
	end if;
	
    -- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

create function elbaza.p27468_tree_view_folder_klient(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder для папок "Контактные лица", по Алфавиту" и буквы алфавита внутри клиента
--=======================================================================================--
	_placeholder jsonb = '[]';
	_placeholder_data jsonb; 
	_text text;          -- папка в дереве
    _folder text;        -- папка в дереве
    _type text;	        -- тип элемента в дереве
	_starts_with text;	-- начало имени контактного лица
	_client_id int;     -- ID клиента
	_metka_id int;      -- ID метки
	_status_id int;     -- ID статуса
	_inn text; 
    _id24001_brush int;
    _cn int;
    _text_pref text;
    _cn_catalog int;
    
begin
    -- если передан ID элемента дерева, сформировать placeholder для этой папки
	if _id is not null then 
		_placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
		_folder = _placeholder_data #>> '{data, folder}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
        
        if _text = 'Контактные лица' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 1, '{data, idkart}'); 
            select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
        
        elseif _text = 'по Алфавиту' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 2, '{data, idkart}'); 
            select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
        
        elseif _folder = 'metka' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 3, '{data, idkart}'); 
            _metka_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, '{data, idkart}'); 
            select count(*) into _cn 
            from t27468_data_kontaktnoe_lico as a
            inner join t27468 as b on a.idkart = b.idkart
            where a.dttmcl is null and b.dttmcl is null and b.parent = _client_id
            and (_metka_id is null or _metka_id = any(a.id29222_list));
        
        elseif _folder = 'status' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 3, '{data, idkart}'); 
            _status_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, '{data, idkart}'); 
            select count(*) into _cn 
            from t27468_data_kontaktnoe_lico as a
            inner join t27468 as b on a.idkart = b.idkart
            where a.dttmcl is null and b.dttmcl is null and b.parent = _client_id
            and (_status_id is null or _status_id = _status_id);
        
        elseif _folder = 'letter' then
            select count(*) into _cn 
            from t27468_data_kontaktnoe_lico as a where a.starts_with = _text; 
        end if;
        
        if _cn > 0 and (_folder is null or _folder <> 'letter') then
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        end if;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
                _text_pref as text_pref,
				case when _cn > 0 then 1 end as children
        ) as a; 
        
    	return _placeholder;
    end if;
    
    _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 0, null); 
    _text = _placeholder_data #>> '{data, text}';
    _folder = _placeholder_data #>> '{data, folder}'; 

	-- Папка "Контактные лица" клиента
	if _text = 'Контактные лица' then
        _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 1, '{data, idkart}'); 
		select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
        _placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'folder_klient', 
				  'text', 'по Алфавиту'
				),
				'text', 'по Алфавиту',
				'type', 'folder_klient',
				'parent', _parent_id,
                'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
				'children', case when _cn > 0 then 1 end);
				
		_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'folder_filter_klient',
				  'text', 'по Состоянию'
				),
				'text', 'по Состоянию',
				'type', 'folder_filter_klient',
				'parent', _parent_id,
				'children', case when _cn > 0 then 1 end);
            
		_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'folder_filter_klient',
				  'text', 'по Меткам'
				),
				'text', 'по Меткам',
				'type', 'folder_filter_klient',
				'parent', _parent_id,
				'children', case when _cn > 0 then 1 end);
    	
	-- Папка "по Алфавиту" для отображения списка контактных лиц 
	elseif _text = 'по Алфавиту' then
		-- Получает ID клиента
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 2, '{data, idkart}' );
        -- Собирает placeholder для папки "по Алфавиту" 
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_klient',
				  'text', a.starts_with,
                  'folder', 'letter'
				) as id,
				a.starts_with as "text", 
				'folder_klient' as "type",
				_parent_id as parent,
				1 as children
			from (
					select distinct starts_with
					from t27468_data_kontaktnoe_lico as a
					inner join t27468 b on b.idkart = a.idkart
					where a.dttmcl is null and b.dttmcl is null
					and b.parent = _client_id
            ) as a
        ) as a;
        
	-- Папка с первой буквой имени контактного лица
	elseif _folder = 'letter' then
		-- Получает ID клиента
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 3, '{data, idkart}' );
		-- Получает первую букву имени контактного лица
        _starts_with = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );
		-- Собирает placeholder для папки с первой буквой имени контактного лица
        select jsonb_agg( a ) into _placeholder
		from (
              select
				jsonb_build_object(
				  'type', b.type,
                  'text', b.name,
				  'idkart', b.idkart
				) as id,
				b.name as "text", 
				b.type as "type",
				_parent_id as parent,
				case when count(c.idkart) > 0 then 1 end as children,
				case when b.on = 1 then null else 5 end as theme
			from t27468_data_kontaktnoe_lico as a
            inner join t27468 as b on a.idkart = b.idkart
            left join t27468 as c on a.idkart = c.parent
			where a.dttmcl is null and b.dttmcl is null
            and b.parent = _client_id
			and a.starts_with = _starts_with
            group by b.idkart
			order by b.name
        ) as a; 
	-- Статус контактного лица
	elseif _folder = 'status' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 3, '{data, idkart}' );
		_status_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
        
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', b.type,
                  'text', b.name,
				  'idkart', b.idkart
				) as id,
				b.name as "text", 
				b.type as "type",
				_parent_id as parent,
				case when count(c.idkart) > 0 then 1 end as children,
                case when b.on = 1 then null else 5 end as theme
			from t27468_data_kontaktnoe_lico a
			inner join t27468 b on a.idkart = b.idkart
            left join t27468 as c on a.idkart = c.parent
			where a.dttmcl is null and b.dttmcl is null
			and b.parent = _client_id
			and (_status_id is null and a.id26011 is null or a.id26011 = _status_id)
            group by b.idkart
            order by b.name
        ) as a; 
   -- Метка контактного лица
	elseif _folder = 'metka' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 3, '{data, idkart}' );
		_metka_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
		
        select jsonb_agg( a )  into _placeholder
		from (
			select
				jsonb_build_object(
				  'type', b.type,
                  'text', a.name,
				  'idkart', a.idkart
				) as id,
				a.name as "text", 
				b.type as "type",
				_parent_id as parent,
				case when count(c.idkart) > 0 then 1 end as children,
                case when a.on = 1 then null else 5 end as theme
            from t27468_data_kontaktnoe_lico a
            inner join t27468 b on a.idkart = b.idkart
            left join t27468 c on a.idkart = c.parent
            where a.dttmcl is null and b.dttmcl is null
            and b.parent = _client_id
            and (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list))
            group by a.idkart, b.type 
            order by a.name
        ) as a;
	end if;
    
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
	

end;
$$;

create function elbaza.p27468_tree_view_folder_klienti(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder для папки с первой буквой наименования клиента 
--=======================================================================================--
	_placeholder jsonb = '[]';  -- возвращаемое значение
    _placeholder_data jsonb;    -- данные Placeholder-а из сессии
    _folder text;               -- папка в дереве
	_letter text;               -- начало названия (1 буквf)
	_double_letter text;        -- начало названия (2 буквы)
	_client_ids int[];          -- массив ID клиентов, отфильтрованных по списку или полю для поиска
    _cn int;                    -- count
    _text text;                 -- название элемента в дереве
    _type text;                 -- тип элемента в дереве
    
begin
    -- сформировать placeholder по id. Возвращает папку с одной буквой или с двумя буквами
	if _id is not null then 
        -- получить данные placeholder-а по id
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
        -- получить название элемента в дереве
		_text = _placeholder_data #>> '{data, text}'; 
        -- получить тип элемента в дереве
        _type = _placeholder_data #>> '{data, type}'; 
        -- получить ID родителя
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		-- сформировать jsonb-массив из одного элемента
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
				1 as children
        ) as a; 
        
        return _placeholder;
    end if;
    
    _folder = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, folder}' ); 
    
    -- сформировать placeholder из клиентов, наименование которых начинается с выбранной буквы. 
    if _folder = 'letter' then
        -- получить букву, по которой нужно отфильтровать клиентов
        _letter = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );
        -- получить массив ID отфильтрованных клиентов (по списку и полю для поиска)
        _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
        -- посчитать количество клиентов, названия которых начинаются на данную букву
        select count(*) into _cn from t27468_data_klient where dttmcl is null and letter = _letter;
        
        -- проверка условия для доп. фильтрации по 2 букве
        if _cn <= 300 then  
            -- сформировать jsonb-массив из клиентов
            select jsonb_agg( a ) into _placeholder
            from (
                select 
                    jsonb_build_object(
                        'type', a.type,
                        'text', a.name,
                        'idkart', a.idkart
                    ) as id,
                    a.name as "text", 
                    a.type as "type",
                    _parent_id as parent,
                    1 as children,
                    case when a.on = 1 then null else 5 end as theme
                from t27468_data_klient as a
                where a.dttmcl is null 
                and a.letter = _letter
                and (_client_ids is null or a.idkart = any(_client_ids))
                order by a.name
            ) as a;
        else
            -- сформировать jsonb-массив из папок с 2 буквами
            select jsonb_agg( a ) into _placeholder
            from (
                select 
                    jsonb_build_object(
                        'type', 'folder_klienti',
                        'text', a.double_letter,
                        'folder', 'double_letter'
                    ) as id,
                    a.double_letter as "text", 
                    'folder_klienti' as "type",
                    _parent_id as parent,
                    1 as children 
                from (
                    select distinct double_letter
                    from t27468_data_klient
                    where dttmcl is null
                    and letter = _letter
                    and (_client_ids is null or idkart = any(_client_ids))
                    order by double_letter
                ) as a
            ) as a;
        end if;
        
    -- сформировать placeholder для папки из 2 букв. Собирает всех клиентов, наименование которых начинается с данных букв
    elseif _folder = 'double_letter' then
        -- получить буквы, по которой нужно отфильтровать клиентов
        _double_letter = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );
        -- получить массив ID отфильтрованных клиентов (по списку и полю для поиска)
        _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
        
        -- сформировать jsonb-массив из клиентов
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                jsonb_build_object(
                    'type', a.type,
                    'text', a.name,
                    'idkart', a.idkart
                ) as id,
                a.name as "text", 
                a.type as "type",
                _parent_id as parent,
                1 as children,
                case when a.on = 1 then null else 5 end as theme
            from t27468_data_klient as a
            where a.dttmcl is null 
            and a.double_letter = _double_letter
            and (_client_ids is null or a.idkart = any(_client_ids))
            order by a.name
        ) as a;
	end if; 
    
    -- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

create function elbaza.p27468_tree_view_klient_fizlico(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder ветки клиента-физлица
--=======================================================================================--
	_placeholder jsonb      = '[]'; -- возвращаемое значение
	_placeholder_data jsonb;        -- данные placeholder-а из сессии
	_client_id int;                 -- ID клиента
	_text text;                     -- название элемента в дереве
    _cn int;                        -- количество
    
begin
    -- если передан _id собирает возвращает в placeholder данного клиента
	if _id is not null then 
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
 		_client_id = _placeholder_data #>> '{data, idkart}'; 
 		_parent_id = _placeholder_data #>> '{item, parent}'; 
		
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				a.name as "text", 
				a.type as "type",
				_parent_id as parent,
				1 as children,
                case when a.on = 1 then null else 5 end as theme
			from t27468 as a
			where dttmcl is null
            and idkart = _client_id
        ) as a;
        
        -- записать в сессию и присвоить уникальный ключ
	    return _placeholder;
    end if;
    
    -- получить ID клиента
    _client_id	= pdb2_tree_placeholder(_name_mod, _name_tree, _parent_id, 0, '{data, idkart}'); 
    
    -- посчитать количество контактных лиц у клиента
    select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
    
    -- собрать placeholder для клиента (физическое лицо)
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_klient',
          'text', 'Контактные лица'
        ),
        'text', 'Контактные лица',
        'type', 'folder_klient',
        'parent', _parent_id,
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'children', case when _cn > 0 then 1 end);
    
    -- записать в сессию и присвоить уникальный ключ
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
	

end;
$$;

create function elbaza.p27468_tree_view_klient_yurlico(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
--=======================================================================================--
-- Возвращает placeholder ветки клиента-юрлица
--=======================================================================================--
declare
	_placeholder jsonb = '[]';
	_placeholder_data jsonb;
	_idkart int; 
    _text text;
    _client_id int;
    _cn int;
    
begin
	
    if _id is not null then 
		-- если передан _id собирает возвращает в placeholder данного клиента
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
 		_client_id = _placeholder_data #>> '{data, idkart}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		
		select jsonb_agg( a ) into _placeholder
		from (
            select
                _id as id,
                a.name as "text", 
                a.type as "type",
                _parent_id as parent,
                1 as children,
                case when a.on = 1 then null else 5 end as theme
			from t27468 as a
			where  idkart = _client_id
        ) as a;
        
        -- записать в сессию и получить уникальный ключ в дереве
	    return  _placeholder ;
    end if;
        
    -- получить ID клиента
    _client_id	= pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}'); 

    -- посчитать количество контактных лиц у клиента
    select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id;
    
    -- контактные лица
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_klient',
          'text', 'Контактные лица'
        ),
        'text', 'Контактные лица',
        'type', 'folder_klient',
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'parent', _parent_id,
        'children', case when _cn > 0 then 1 end); 

    -- посчитать количество филиалов у клиента
    select count(*) into _cn from t27468_data_klient 
    where dttmcl is null and idkart <> _client_id
    and inn = (select inn from t27468_data_klient where dttmcl is null and idkart = _client_id);

    -- филиалы
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_filter_klient',
          'text', 'Филиалы'
        ),
        'text', 'Филиалы',
        'type', 'folder_filter_klient',
        'parent', _parent_id,
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'children',  case when _cn > 0 then 1 end);

    -- посчитать количество кустов
    select count(*) into _cn from t27468_data_klient as a 
    where a.dttmcl is null and a.id24001_brush = _client_id;
    
    -- кусты
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_filter_klient',
          'text', 'Кусты'
        ),
        'text', 'Кусты',
        'type', 'folder_filter_klient',
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'parent', _parent_id,
        'children', case when _cn > 0 then 1 end);
    
    -- записать в сессию и получить уникальный ключ в дереве
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

create function elbaza.p27468_tree_view_kontaktnie_lica(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
	_rc record;
	_placeholder jsonb = '[]';
    _placeholder_data jsonb = '[]';

	_parent_idkart int; 
    _idkart int;
    _cn_all int;
    _cn_catalog int;
    _text text;
    _type text;
    
begin
	if _id is not null then
		_placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		_idkart = _placeholder_data #>> '{data, idkart}' ;
        
        -- добавить ветку		
		select jsonb_agg( a ) into _placeholder
		from (
            select
                _id as id,
                a.name as "text", 
                _type as "type",
                _parent_id as parent,
                case when a.on = 1 then null else 5 end as theme,
                case when (select count(*) from t27468 where dttmcl is null and parent = _idkart) > 0 then 1 end as children
			from t27468 as a
			where dttmcl is null 
            and idkart = _idkart
        ) as a;
        
        return _placeholder; 
	end if; 
    
	_parent_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
    
	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;

	insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
	select a.idkart, a.name, a.type, a.parent, a.on
	from t27468 as a
	left join t27468_children as mn on a.parent = mn.idkart
	left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
	where a.dttmcl is null 
		and (
			_idkart is null and a.parent = _parent_idkart or a.idkart = _idkart
		)
	order by srt.sort NULLS FIRST, a.idkart desc;
    
    for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
	loop
        -- условие поиска
		with recursive temp1( idkart ) as 
		(
			select a.idkart
			from t27468 as a
			where a.dttmcl is null and a.idkart = _rc.idkart
			union
			select a.idkart
			from t27468 as a
			inner join temp1 on temp1.idkart = a.parent
			where a.dttmcl is null
		)
		select count(*), max( case when a.idkart <> _rc.idkart or b.type ~~* '%filter%' then 1 end )
		from temp1 as a 
		inner join t27468 as b on a.idkart = b.idkart
		into _cn_all, _cn_catalog;
        
        -- ветка по условию поиска не подходит
		continue when _cn_all = 0;
        
        -- добавить ветку		
		_placeholder = _placeholder || 
				jsonb_build_object(
					'id', jsonb_build_object('type', _rc.type, 'text', _rc.name, 'idkart', _rc.idkart),
 					'parent', _parent_id,
 					'text', _rc.name,
 					'type', _rc.type,
					'children', _cn_catalog,
					'theme', case when _rc.on = 1 then null else 5 end
				);

	end loop;
    
	drop table _tmp_pdb2_tpl_tree_view;
    
    -- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

create function elbaza.p27468_tree_view_root(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
    _event text         = pdb2_event_name( _name_mod );
    _include text       = pdb2_event_include( _name_mod );
	_list_id int        = pdb2_val_include_text( _name_mod, 'list', '{value}');
	_placeholder jsonb  = '[]';
    _client_ids int[];
    _cn_all int;
    _cn_ric int;
    _cn_metki int;
    _text_pref_root text;   
    _text_pref_ric text;    
    _text_pref_metki text;  
    _text_pref_kusty text;  
    _root_id int; 
    
begin
    -- при первом открытии страницы, при поиске по тексту и по списку отфильтровать клиентов
    if _event is null or _event = 'refresh' or _event = 'values' and _include in ('find', 'list') then
        if _list_id is null then 
        -- если не выбран список - выборка по всем клиентам
            select _client_ids_out, _cn_all_out, _cn_ric_out, _cn_metki_out
            from p27468_query_all( _name_mod, _name_find)
            into _client_ids, _cn_all, _cn_ric, _cn_metki; 
        else
            -- если выбран список - выборка по отфильтрованным клиентам
            select _client_ids_out, _cn_all_out, _cn_ric_out, _cn_metki_out
            from p27468_query_list( _name_mod, _list_id, _name_find)
            into _client_ids, _cn_all, _cn_ric, _cn_metki; 
        end if; 
        
        -- записать в сессию
        perform pdb2_val_session('p27468_tree', '{client_ids}', _client_ids::text); 
        perform pdb2_val_session('p27468_tree', '{cn_all}', _cn_all); 
        perform pdb2_val_session('p27468_tree', '{cn_ric}', _cn_ric); 
        perform pdb2_val_session('p27468_tree', '{cn_metki}', _cn_metki); 
    else
        _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
        _cn_all = pdb2_val_session_text('p27468_tree', '{cn_all}'); 
        _cn_ric = pdb2_val_session_text('p27468_tree', '{cn_ric}'); 
        _cn_metki = pdb2_val_session_text('p27468_tree', '{cn_metki}'); 
    end if;
    
    if (_list_id is not null or _name_find is not null) and _cn_all = 0 then
        return null;
    end if;
     
    _text_pref_root = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
    _text_pref_ric = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_ric || '</span>' );
    _text_pref_metki = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_metki || '</span>' );
    _text_pref_kusty = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
    
    -- получаем id корня клиентов
	select idkart 
	from t27468 
	where parent = 0 
	and type = 'root_klienti' into _root_id;
	-- по Алфавиту
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_klienti',
                  'text', 'по Алфавиту',
				  'idkart', _root_id
				),
				'text', 'по Алфавиту',
                'text_pref', _text_pref_root,
				'type', 'root_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
	
    -- по РИЦам		
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_filter_klienti',
				  'text', 'по РИЦам'
				),
				'text', 'по РИЦам',
				'type', 'root_filter_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
	
    -- по Меткам 
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_filter_klienti',
				  'text', 'по Меткам'
				),
				'text', 'по Меткам',
				'type', 'root_filter_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
	-- по Кустам	
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_filter_klienti',
				  'text', 'по Кустам'
				),
				'text', 'по Кустам',
				'type', 'root_filter_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
                
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

create function elbaza.p27468_tree_view_root_filter(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
    _text text; 
	_placeholder jsonb  = '[]';
	_client_ids int[];  -- ID отфильтрованных клиентов по списку или по полю для поиска. Если данные список и поиск пустые, равно null
    _cn int;            -- count, для подсчета количества
    _cn_all int;        -- count all, для подсчета количества
    _placeholder_data jsonb;
    _type text;
    _folder text;
    _id_object jsonb;
    _idkart int;
    _text_pref text;
    
begin
    -- получить массив ID отфильтрованных клиентов
    _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 

    if _id is not null then 
        -- получить данные placeholder-а по id
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
        -- получить ID родителя
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
        -- получить название элемента в дереве
		_text = _placeholder_data #>> '{data, text}'; 
        -- получить тип элемента в дереве
        _type = _placeholder_data #>> '{data, type}'; 
        
		-- сформировать jsonb-массив из одного элемента
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
                1 as children
        ) as a; 
        
        return _placeholder;
    end if;
    
    _text = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );

    -- placeholder для корневой папки "по РИЦам". Собирает все РИЦы, которые есть у клиентов
	if _text = 'по РИЦам' then
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', COALESCE( b.text, '- нет -' ), 
				  'idkart', b.id,
				  'folder', 'ric'
				) as id,
				COALESCE( b.text, '- нет -' ) as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				case when count(*) > 0 then 1 end as children,
                case when count(*) > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || count(*) || '</span>' ) end as text_pref
			from t27468_data_klient as a 
            left join v18207_data_ritz_select as b on a.id21324 = b.id
			where a.dttmcl is null and b.dttmcl is null
            and (_client_ids is null or a.idkart = any(_client_ids))
			group by b.id, b.text 
            order by b.text
        ) as a; 
    -- placeholder для корневой папки "по Меткам". Собирает все метки, которые есть у клиентов
	elseif _text = 'по Меткам' then
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', a.text, 
				  'idkart', a.id,
				  'folder', 'metka'
				) as id,
				a.text as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
                case when a.count > 0 then 1 end as children,
                case when a.count > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || a.count || '</span>' ) end as text_pref
			from (
				select b.id, COALESCE( b.text, '- нет -' ) as text, count(*) as count
				from (
					select unnest( COALESCE( id29222_list, array[-1] )) as id29222
					from t27468_data_klient
                    where dttmcl is null and (_client_ids is null or idkart = any(_client_ids))
                ) as a
                left join v19638_data_metka_select as b on b.id = a.id29222
                where b.dttmcl is null 
                group by b.id, b.text
                order by b.text
            ) as a
        ) as a; 
        
    -- placeholder для корневой папки "по Кустам". Создает 2 папки "Основные" и "Связанные". 
	elseif _text = 'по Кустам' then
        select count(*), count(id24001_brush) into _cn_all, _cn from t27468_data_klient where dttmcl is null and (_client_ids is null or idkart = any(_client_ids));

        _placeholder = _placeholder || jsonb_build_object(
                'id', jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', 'Основные', 
				  'folder', 'kust_main'
				),
				'text', 'Основные',
				'type', 'folder_filter_klienti',
				'parent', _parent_id,
				'children', case when _cn_all - _cn > 0 then 1 end,
                'text_pref', case when _cn_all - _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">', _cn_all - _cn, '</span>' ) end);
	
            _placeholder = _placeholder || jsonb_build_object(
                'id', jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', 'Связанные', 
				  'folder', 'kust_related'
				),
				'text', 'Связанные',
				'type', 'folder_filter_klienti',
				'parent', _parent_id,
				'children', case when _cn > 0 then 1 end,
                'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">', _cn, '</span>' ) end);

    end if;
    
	-- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
	

end;
$$;

create function elbaza.p27468_tree_view_root_klienti(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
	_placeholder jsonb = '[]';
    _placeholder_data jsonb; 
	_type text;
	_idkart int; 
	_client_ids int[];
    _text text;
    _cn_all int;
    _text_pref_root text;
    _clients_all boolean;
    _cn int;
    
begin
   _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 

    -- формирование placeholder-а по id для папки "по Алфавиту". Возвращает папку "по Алфавиту"
    if _id is not null then
        _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, null ); 
        -- получить ID родителя
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
        -- получить название элемента в дереве
		_text = _placeholder_data #>> '{data, text}'; 
        -- получить тип элемента в дереве
        _type = _placeholder_data #>> '{data, type}'; 
        -- получить количество всех клиентов
        select count(*) into _cn_all from t27468_data_klient where dttmcl is null and (_client_ids is null or idkart = any(_client_ids));
        -- добавить количество клиентов к названию
        _text_pref_root = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
        
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                _id as id,
                _text as "text", 
                _type as "type",
                _parent_id as parent,
                case when _cn_all > 0 then 1 end as children,
                _text_pref_root as text_pref
        ) as a;
        
        return _placeholder;
    end if;

    -- формирование placeholder-а для папки "по Алфавиту". Собирает буквы алфавита, с которых начинаются названия клиентов
    
    select jsonb_agg( a ) into _placeholder
    from (
        select 
            jsonb_build_object(
              'type', 'folder_klienti',
              'text', a.letter,
              'folder', 'letter'
            ) as id,
            a.letter as "text", 
            'folder_klienti' as "type",
            _parent_id as parent,
            1 as children 
        from (
            select distinct letter
            from t27468_data_klient as a
            where a.dttmcl is null 
            and (_client_ids is null or a.idkart = any(_client_ids))
            order by a.letter
        ) as a
    ) as a;
    
    -- записывает в сессию и формирует уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

create function elbaza.p27470_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_name_tree text		= 'tree';
-- система	
  	_event text			= pdb2_event_name( _name_mod );
-- поле поиска
  	_find_text text;

  	_placeholder jsonb;
 	_parent integer;
	
	_name_table text;
	_name_table_children text;
	_idtree integer;
	_cmd_socket jsonb;
	
begin
	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;
  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );

-- обработка событий
	if pdb2_event_name() = 'websocket' then
-- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p27470_tree_view( null, null, a.value::integer, _name_table, _name_table_children )
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a;		
		if _cmd_socket is not null then
-- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
            
			perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		end if;
    
	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );

-- добавить корень дерева				
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
		execute format( '					
			insert into %I( parent, type, name, "on" )
			select 0, a.value ->> ''type'', a.value ->> ''text'', 1
			from jsonb_array_elements( $1 ) as a
			left join %I as b on (a.value ->> ''type'') = b.type
			where (a.value ->> ''type'') like ''root_%%'' and b.idkart is null;', _name_table, _name_table )
		using _placeholder;
		
-- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );

	elsif _event in ( 'selected', 'opened' ) then

-- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		return null;
		
	elsif _event = 'refresh' then
	
-- получить переменые
		_parent = pdb2_val_api_text( '{post,id}' );
-- список веток		
		_placeholder = p27470_tree_view( null, null, _parent, _name_table, _name_table_children );
-- ветки
		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'children' then
	
-- получить переменые
		_parent = pdb2_val_api_text( '{post,parent}' );
-- список веток		
		_placeholder = p27470_tree_view( _parent, _find_text, null, _name_table, _name_table_children );
-- ветки -- 

		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'create' then
-- добавить ветку
 		perform pdb2_tpl_tree_create( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
		
	elsif _event = 'move' then

-- перемешение ветки
		perform pdb2_tpl_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then

-- переименование ветки
		perform pdb2_tpl_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'duplicate' then

-- дублировать ветку
		perform pdb2_tpl_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then

-- удаление ветки
		perform pdb2_tpl_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );

		return null;

	elsif _event = 'values' then
	
-- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
-- собрать root
	_placeholder = p27470_tree_view( 0, _find_text, null, _name_table, _name_table_children );
	
-- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
-- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
-- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
-- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
-- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
-- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;
							
	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

create function elbaza.p27470_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );

	_tree_mod text;
	_tree_inc text;
	_tree_view text;
	_tree_idkart integer;
	_tree_b_submit integer;
	_name_table text;
	_name_table_children text;
begin
    insert into t27468_data_test(txt) values ('prop');
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );

	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_tree_idkart = pdb2_val_session_text( _tree_mod, '{idkart}' );
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
-- установить таблицу на изменение
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
-- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
-- если модуль скрыт - выход
		return null;
	end if;
-- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _tree_idkart );
-- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then
-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
-- обновить дерево
 		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', p27470_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
									]
							);
-- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _tree_idkart );	
						
		_tree_b_submit = 0;

	end if;

	if _tree_b_submit = 0 then
		
-- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
-- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );

	else
-- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
-- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );
	
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

create function elbaza.p27470_tree_view(_parent integer, _name_find text, _idkart integer, _name_table text, _name_table_children text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb_current_userid();
	_rc record;
	_placeholder jsonb[];
	_cn_all integer;
	_cn_catalog integer;
	
begin
-- item_filtr - показывает только текущего пользователя

	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;

	execute format( '
		insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
		select a.idkart, a.name, a.type, a.parent, a.on
		from %I as a
		left join %I as mn on a.parent = mn.idkart
		left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
		where a.dttmcl is null 
			and (
				$1 is null and ( a.parent = $2 or $2 = 0 and a.parent = 0 )
				or a.idkart = $1 
			)
			and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
		order by srt.sort NULLS FIRST, a.idkart desc', _name_table, _name_table_children, _pdb_userid )
	using _idkart, _parent;
	
	for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
		
	loop
-- условие поиска
		execute format( '
			with recursive temp1( idkart, ok ) as 
			(
				select a.idkart,
					case when 
						$2 is null or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				where a.dttmcl is null and a.idkart = $1
				union
				select a.idkart,
					case when 
						temp1.ok = true or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				inner join temp1 on temp1.idkart = a.parent
				where a.dttmcl is null
					and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
			)
			select count(*), max( case when a.idkart <> $1 then 1 end )
			from temp1 as a 
			inner join %I as b on a.idkart = b.idkart
			where a.ok = true
					   ;', _name_table, _name_table, _pdb_userid, _name_table )
		using _rc.idkart, _name_find
		into _cn_all, _cn_catalog;
-- ветка по условию поиска не подходит
		continue when _cn_all = 0;
-- добавить ветку		
		_placeholder = _placeholder || 
				jsonb_build_object(
					'id', _rc.idkart,
 					'parent', _rc.parent,
 					'text', _rc.name,
 					'type', _rc.type,
					'children', _cn_catalog,
					'theme', case when _rc.on = 1 then null else 5 end
				);

	end loop;
	
	drop table _tmp_pdb2_tpl_tree_view;
	
	return to_jsonb( _placeholder );

end;
$$;

create function elbaza.p27471_info(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
-- система	
  	_idkart text	= pdb2_val_api_text( '{post,idkart}' );
  	_table text		= pdb2_val_api_text( '{post,table}' );
	_json jsonb;
	_dt timestamp with time zone;
	_user_name text;
	
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );

	execute format( 'select row_to_json(a) from %I as a where a.idkart = %L', _table, _idkart )
	into _json;
	
	select a.text into _user_name
--	from v20455_select as a
	from v20455_data_select as a
	where a.id = (_json->> 'userid')::integer;
	
	perform pdb2_val_include( _name_mod, 'idkart', '{value}', _idkart );
	perform pdb2_val_include( _name_mod, 'table', '{value}', _table );
	_dt = _json->> 'dttmcr';	
	perform pdb2_val_include( _name_mod, 'dttmcr', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmup';	
	perform pdb2_val_include( _name_mod, 'dttmup', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmcl';	
	perform pdb2_val_include( _name_mod, 'dttmcl', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	perform pdb2_val_include( _name_mod, 'ispl', '{value}', _user_name );

	perform pdb2_val_include( _name_mod, 'json', '{value}', jsonb_pretty( _json, 4, 0 ) );

	perform pdb2_mdl_after( _name_mod );
	return null;

	
end;
$$;

create function elbaza.p27471_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_name_tree text		= 'tree';
-- система	
  	_event text			= pdb2_event_name( _name_mod );
-- поле поиска
  	_find_text text;

  	_placeholder jsonb;
	_parent_id text; 
	_id text; 
	_name_table text;
	_name_table_children text;
	_idtree integer;
	_cmd_socket jsonb;
	_idkart text; 
	_data jsonb;
	
begin
    --raise '%', _event;
	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;
  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );
	
-- обработка событий
	if pdb2_event_name() = 'websocket' then
-- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p27471_tree_view( null, null, a.value )
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a;	 
		if _cmd_socket is not null then
-- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
-- установить информацию по бланкам - НЕ ПРОРАБОТАНО
			perform p27471_tree_set( _name_mod, _name_tree, 'test', null);

		end if;
		
	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );
		
-- добавить корень дерева				
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
		
		insert into t27471( parent, type, name, "on" )
		select 0, a.value ->> 'type', a.value ->> 'text', 1
		from jsonb_array_elements( _placeholder ) as a
		left join t27471 as b on (a.value ->> 'type') = b.type
		where (a.value ->> 'type') = 'root_firma' and b.idkart is null;
-- установить информацию по бланкам
		perform p27471_tree_set( _name_mod, _name_tree, _name_table , null);

	elsif _event in ( 'selected', 'opened' ) then
		insert into t27471_data_test(txt) values ('selected');

-- установить информацию по бланкам
		perform p27471_tree_set( _name_mod, _name_tree, _name_table , null);

		return null;
		
	elsif _event = 'refresh' then
-- получить переменые
		_id = pdb2_val_api_text( '{post,id}' );
		_parent_id = pdb2_tree_placeholder_text( _name_mod, 'tree', _id, 1, '{item, id}' );
-- список веток	 
		_placeholder = p27471_tree_view( _parent_id, null, null );
-- ветки
		select jsonb_agg( a.value ) into _placeholder
		from jsonb_array_elements( _placeholder ) as a
		where a.value ->> 'id' = _id;
		
		perform pdb2_return( _placeholder );
		return null;

	elsif _event = 'children' then
	
-- получить переменые
		_parent_id = pdb2_val_api_text( '{post,parent}' );
-- список веток		
		_placeholder = p27471_tree_view( _parent_id, _find_text, null );
-- ветки
		perform pdb2_return( _placeholder );
		
-- 		_value = pdb_func_alert(_value, 'success',  EXTRACT(EPOCH from clock_timestamp() - TRANSACTION_TIMESTAMP())::text);
		
		return null;
		
	elsif _event = 'create' then

-- добавить ветку
		perform p27471_tree_create( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
		
	elsif _event = 'move' then

-- перемешение ветки
		perform p27471_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then
-- переименование ветки
		perform p27471_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'duplicate' then

-- дублировать ветку
		perform p27471_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then

-- удаление ветки
		perform p27471_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'values' then
	
-- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;
-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
-- собрать root
	_placeholder = p27471_tree_view( '0', _find_text, null );
-- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
-- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
-- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
-- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
-- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
-- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;
							
	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

create function elbaza.p27471_tree_create(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
-- система	
 	_pdb_userid	integer	= pdb_current_userid();

  	_placeholder jsonb = '[]';
 	_after text;

	_type text; 
	_name text;
 	_children jsonb;
	
 	_types jsonb;
	_cn integer;
	_idkart int; 		-- ID созданного элемента в таблице t27471
	_parent_idkart int; -- ID родителя в таблице t27471
	_id text;			-- ID элемента в дереве
	_parent_id text;	-- ID родителя в дереве
	_placeholder_data jsonb;
    _parent text;
begin
    _types = pdb2_val_include( _name_mod, _name_tree, '{data,types}' );	
-- получить переменые 
	_parent_id = pdb2_val_api_text( '{post, parent}' ); 
	_parent_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id, 0, '{data, idkart}');
	_type = pdb2_val_api_text( '{post, type}' ); 
	_after = pdb2_val_api_text( '{post, after}' );
-- установить имя по умолчанию		
	_name = pdb_val_text( _types, array[_type,'text'] );
-- добавить ветку
	insert into t27471( parent, type, name, userid ) values( _parent_idkart, _type, _name, _pdb_userid ) 
	returning idkart into _idkart;
-- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    
-- проверка записи
	select count(*) from t27471_children as a where a.idkart = _parent_idkart into _cn; 
	
	_children = pdb2_val_api( '{post,children}' );
	
	-- получает jsonb-массив idkart для children элементов
	select jsonb_agg(pdb2_tree_placeholder_text( 'p27471_tree', 'tree', a.value, 0,  '{data, idkart}' ) )
	from jsonb_array_elements_text(_children) as a
	into _children;
	
	if _cn > 0 then
-- изменить позцию позиции
		update t27471_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_idkart;
	else
-- установить позицию
		insert into t27471_children( idkart, children ) values ( _parent_idkart, pdb_sys_jsonb_to_int_array( _children ));
	end if;
-- получить новую ветку	 
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', _type,
				  'idkart', _idkart
				),
				'text', _name,
				'type', _type,
				'parent', _parent_id,
				'children', case when _type in ('item_dokument') then 1 end,
				'theme', 5);
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
    _id = _placeholder #>> '{0, id}';
	-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _id ); 
-- установить информацию по бланкам
	perform p27471_tree_set( _name_mod, _name_tree, _name_table , null); 
-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );
-- новая ветка
-- [{"id": "370d78db3b9ea91dee16a5c35e3c1cd5", "text": "Клиент (Физическое лицо)", "type": "item_klient_fizlico", "theme": 5, "parent": "53eccdc70435c519f15f1fff958f4971", "children": 1}]
    perform pdb2_return( _placeholder );
end;
$$;

create function elbaza.p27471_tree_duplicate(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Дублирует элемент дерева и всю ветку данного элемента. 
--=================================================================================================
declare
  	_idkart integer;	    -- ID нового элемента (копии) из таблицы дерева
 	_after_idkart integer;  -- ID дублируемого элемента из таблицы дерева 
	_parent_idkart integer; -- parent дублируемого элемента из таблицы дерева
	_id text; 		 		-- ID нового элемента в дереве
	_after_id text;	 		-- ID дублируемого элемента в дереве
	_parent_id text; 		-- parent дублируемого элемента в дереве
	_children jsonb; 		-- children элементы внутри папки _parent_id
  	_placeholder jsonb = '[]';	-- placeholder для новой записи
	_cn integer;			-- count для проверки наличия записи
	_name text;				-- название нового элемента
	_type text; 			-- тип нового элемента
	_after text;			
	
begin
	-- получить переменые
	_parent_id = pdb2_val_api_text( '{post,parent}' ); 
	_children = pdb2_val_api( '{post,children}' );		
	_after_id = pdb2_val_api_text( '{post,id}' );
	
	_parent_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, idkart}' );
	_after_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _after_id, 0, '{data, idkart}' );
	-- создает дубликат записи в таблице и возвращает его idkart
	_idkart = p27471_tree_duplicate_copy( _after_idkart, null ); 
	-- получает название и тип нового элемента
	select type, name from t27471 where idkart = _idkart into _type, _name;
	-- формирует ветку для нового элемента
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', _type,
				  'idkart', _idkart
				),
				'text', _name,
				'type', _type,
				'parent', _parent_id,
				'theme', 5);
	-- преобразует id placeholderа и сохраняет его данные 			
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
 	-- получает преобразованный id - уникальный id в дереве
	_id = _placeholder #>> '{0, id}';

	-- дублировать запись
	-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, 'tree', '{selected, 0}', _id );
	
	-- превращает массив ключей children в дереве, в массив idkart 
	select jsonb_agg(pdb2_tree_placeholder_text( _name_mod, _name_tree, a.value, 0, '{data, idkart}' ) ) 
	from jsonb_array_elements_text(_children) as a
	into _children;
	
	-- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
	-- проверка записи
	execute format ('select count(*) from %I as a where a.idkart = $1', _name_table_children)
    using _parent_idkart into _cn; 
    
	if _cn > 0 then
	-- изменить позцию позиции
        execute format( 'update %I set children = pdb_sys_jsonb_to_int_array( $1 ) where idkart = $2;', _name_table_children )
		using _children, _parent_idkart;
	else
	-- установить позицию
        execute format( 'insert into %I( idkart, children ) values ( $1, $2 );', _name_table_children )
		using _parent_idkart, pdb_sys_jsonb_to_int_array( _children );
	end if;
	-- установить информацию по бланкам
	perform p27471_tree_set( _name_mod, _name_tree, _name_table, null);
	-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );	
	-- новая ветка
	perform pdb2_return( _placeholder );
	
end;
$$;

create function elbaza.p27471_tree_duplicate_copy(_idkart integer, _parent integer) returns integer
    language plpgsql
as
$$
--=================================================================================================
-- Вставляет в таблицу копию исходного элемента и всех дочерних элементов
--=================================================================================================
declare
 	_pdb_userid	integer	= pdb_current_userid(); -- ID текущего пользователя

	_new_parent integer;            -- idkart копии после вставки в таблицу 
	_all_parent integer[];          -- массив idkart всех копий, вложенных в текущего родителя
	
begin
    -- вставить копию текущей записи в таблицу и вернуть idkart
	insert into t27471( userid, parent, type, name, description, property_data )
	select _pdb_userid, COALESCE( _parent, a.parent ), a.type, concat( a.name, ' - копия' ),
		a.description, a.property_data
	from t27471 as a where a.idkart = _idkart
	returning idkart
	into _new_parent;

    -- повторить действие для всех дочерних элементов
	select array_agg( a.new_parent )
	from (
		select p27471_tree_duplicate_copy( a.idkart, _new_parent ) as new_parent
		from t27471 as a
		left join t27471_children as mn on a.parent = mn.idkart
		left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
		where a.dttmcl is null and a.parent = _idkart
		order by srt.sort NULLS FIRST, a.idkart desc
	) as a
	into _all_parent;
	
    -- вернуть idkart копии исходного элемента
	return _new_parent;

end;
$$;

create function elbaza.p27471_tree_move(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_idkart integer; 			-- idkart перемещаемого элемента из таблицы t27471
	_parent_idkart_new integer; -- parent перемещаемого элемента из таблицы t27471 после перемещения
	_parent_idkart_old integer; -- parent перемещаемого элемента из таблицы t27471 до перемещения
    _client_idkart_old integer;
    _client_idkart_new integer;
	_cn integer;
	
	_id text; 					-- ID перемещаемого элемента в дереве
	_parent_id_new text; 		-- ID папки, в который перемещается элемент
	_parent_id_old text; 
 	_children jsonb;			-- массив id children-элементов для parent
	
begin
	-- получает ID перемещаемого элемента в дереве
	_id = pdb2_val_api_text( '{post,id}' );
	-- получает ID родителя в дереве, куда перемещается элемент  
	_parent_id_new = pdb2_val_api_text( '{post,parent}' );
 	_parent_id_old = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{item, parent}' );
	-- получает jsonb-массив из children элементов, куда перемещается элемент 
	_children = pdb2_val_api( '{post,children}' );
	-- получает idkart перемещаемого элемента
	_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, null ) #>> '{data, idkart}';
	-- получает idkart родителя, куда перемещается элемент
	_client_idkart_new = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id_new, 0, null ) #>> '{data, idkart}';
    _parent_idkart_new = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id_old, 0, null ) #>> '{data, parent}';
    
    --raise '%, %', _parent_idkart_new, _client_idkart_new;
	-- получает jsonb-массив idkart для children элементов
	select jsonb_agg(pdb2_tree_placeholder( 'p27471_tree', 'tree', a.value, 0, null ) #>> '{data, idkart}') 
	from jsonb_array_elements_text(_children) as a
	into _children;
	-- получает idkart родителя, откуда перемещается элемент
	select a.parent, t27471_data_dokument.client
    from t27471 as a 
    join t27471_data_dokument on a.idkart = t27471_data_dokument.idkart
    where a.idkart = _idkart 
	into _parent_idkart_old, _client_idkart_old; 
    --raise '%, %',  _client_idkart_old, _client_idkart_new;
	-- смена родителя
	update t27471 set dttmup = now(), parent = _client_idkart_new where idkart = _idkart;
    update t27471_data_dokument set dttmup = now(), client = _client_idkart_new where idkart = _idkart;
	
	-- проверка записи
	select count(*) from t27471_children as a where a.idkart =_parent_idkart_new 
	into _cn;

	if _cn > 0 then
-- изменить позцию позиции
		update t27471_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_idkart_new;
	else
-- установить позицию
		insert into t27471_children( idkart, children ) values ( _parent_idkart_new, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
-- подготвить данные для сокета - обновить родителя	
	if _parent_idkart_new = _parent_idkart_old then
		perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_new );	
	else
-- проверка вложенности _parent_idkart_old в _parent_idkart_new
			with recursive temp1 ( parent ) as 
			(	
				select a.parent
				from t27471 as a
				where a.idkart = _parent_idkart_new
				union all
				select a.parent
				from t27471 as a
				inner join temp1 as t on a.idkart = t.parent
			)
			select count(*) from temp1 as a
			where a.parent = _parent_idkart_old
			into _cn;
			
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_old );
			return;
		end if;
-- проверка вложенности _parent_idkart_new в _parent_idkart_old
			with recursive temp1 ( parent ) as 
			(	
				select a.parent
				from t27471 as a
				where a.idkart = _parent_idkart_old
				union all
				select a.parent
				from t27471 as a
				inner join temp1 as t on a.idkart = t.parent
			)
			select count(*) from temp1 as a
			where a.parent = _parent_idkart_new
			into _cn;
			
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_new );
			return;
		end if;
-- обновить оба родителя 
		perform pdb2_val_page( '{pdb,socket_data,ids}', array[ _parent_id_new, _parent_id_old ] );
			
	end if;
	
end;
$$;

create function elbaza.p27471_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );

	_tree_mod text;
	_tree_inc text;
	_tree_view text;
	_idkart integer;
	_tree_b_submit integer;
	_name_table text;
	_name_table_children text;
	_id text;
	_parent_id text;
    _name text;
	_desc text;
begin
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );
	
	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_id = pdb2_val_session_text( _tree_mod, '{id}' );
	_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, idkart}');
--  {"data": {"type": "item_klient", "idkart": 222}, "item": {"id": "5cf857ff528063d017a7301ebc5e746b", "parent": "71b4b01d45ba1e3378c19cc45e00c75e"}}
-- 	{"data": {"type": "item_dokument", "idkart": 223}, "item": {"id": "80f24d89cb793ec46f2dcc71a753742e", "parent": "71b4b01d45ba1e3378c19cc45e00c75e"}}
    _tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
-- установить таблицу на изменение
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
-- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
-- если модуль скрыт - выход
		return null;
	end if;
-- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _idkart );
-- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then
		_id = pdb2_val_include_text( 'p27471_tree', 'tree', '{selected,0}' );
-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
-- обновить дерево
 		
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', p27471_tree_view( null, null, _id ) ),
                                        jsonb_build_object( 
									  		'cmd', 'reload_parent',
									  		'data', array[_id] )
									]
							);
			  
-- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	
						
		_tree_b_submit = 0;

	end if;
		
	if _tree_b_submit = 0 then
-- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
-- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );

	else
-- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
-- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );
    
    if _name_mod in ('p27471_property_klient') then
        _name = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, text}');
        perform pdb2_val_include( _name_mod, 'name', '{value}', _name );
        perform pdb2_val_include( _name_mod, 'on', '{value}', 1 );
    end if;
    
    if _name_mod in ('p27471_property_dokument') then
        --raise '%', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data}');
        perform pdb2_val_include( _name_mod, 'idkart', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, idkart}') );
        perform pdb2_val_include( _name_mod, 'dokument_ispl', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, userid}') );
        perform pdb2_val_include( _name_mod, 'dokument_dttmcr', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, dttmcr}') );
        perform pdb2_val_include( _name_mod, 'dokument_json', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, property_data}') );
    end if;
	perform pdb2_mdl_after( _name_mod );
    return null;
	
end;
$$;

create function elbaza.p27471_tree_remove(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_idkart integer;
	_id text;
  	_parent text;
  	_idkart_old integer;
	_id_old text;
	_parent_id text;
	_placeholder_data jsonb;
    _data jsonb;
    _placeholder jsonb;
    _tree_idkart text;
	_reload text[];
    _cmd_socket jsonb;
    _find_text text;
    _tx_id text;
    _tx_parent text;
begin
    _tree_idkart = pdb2_val_api_text( '{post,id}' );
	_data = pdb2_tree_placeholder( _name_mod, 'tree', _tree_idkart, 4, '{data}' );
    _tx_id = pdb2_val_api_text( '{post,id}' );
	_tx_parent = pdb2_val_api_text( '{post,parent}' );
-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
    _placeholder_data = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, null);
	_idkart = _placeholder_data #>> '{data, idkart}';
	_parent_id = _placeholder_data #>> '{item, parent}';
    perform p27471_tree_view_root(_parent_id, null, null); 
-- удаление ветки
    execute format( 'update %I set dttmcl = now() where idkart = $1;', _name_table)
	using _idkart;

	_id_old = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	
	if _id = _id_old then
-- убрать позицию
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
	end if;
-- установить информацию по бланкам
 	perform p27471_tree_set( _name_mod, _name_tree, _name_table, null );

    --raise '%, %', _name_mod, _name_tree;
    _placeholder = p27471_tree_view( '0', _find_text, null );
-- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
-- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
-- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
-- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
-- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
-- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;    
    
    _id = _parent_id;
    _parent_id = pdb2_tree_placeholder_text( _name_mod, 'tree', _id, 4, '{item, id}' );
-- список веток	 
    _placeholder = p27471_tree_view( _parent_id, null, null );
-- ветки
    select jsonb_agg( a.value ) into _placeholder
    from jsonb_array_elements( _placeholder ) as a
    where a.value ->> 'id' = _id;

    perform pdb2_return( _placeholder );
    perform pdb2_event_module();
    
    perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );
    --raise '%', _data;
    if _data ->> 'type' = 'root_firma' then
    
         perform pdb2_val_include( _name_mod, 'idkart', '{var}', null );
		 perform pdb2_mdl_before( _name_mod );
		 --_idkart = pdb2_val_include_text( _name_mod, 'idkart', '{var}' );
-- запросить root папок
		--_value = lk_27102_tree_view( _value, _mod_tree, null, null, null ); 
		_placeholder = p27471_tree_view( _parent_id, null, null );
        --raise '%', _placeholder;
-- найти позицию - root_appeal
		select a.value ->> 'id' into _id
		from jsonb_array_elements( _placeholder ) as a
		where a.value ->> 'type' = 'root_firma';
        
        --raise '%', _id;
-- перезагрузить дерево 			
		perform pdb2_val_include( _name_mod, 'tree', '{task}',
							  array[ 
									jsonb_build_object( 'cmd', 'reload_id', 'data', 
											array[
												_tx_parent
											]
									)
							  ]
						);			
-- получить список элементов			
		--_value = lk_27102_tree_view( _value, _mod_tree, _id, null, null ); 
		perform pdb2_return( _placeholder );
        
--         _data = pdb2_tree_placeholder( _name_mod, 'tree', _tree_idkart, 4, null ) ->> 'item';
-- 	    _placeholder = p27471_tree_view( _data ->> 'parent', null, null );
        
        
        
--         select jsonb_agg( a.value ) into _placeholder
--         from jsonb_array_elements( _placeholder ) as a
--         where a.value #>> '{type}' <> 'folder_filter2';
        
--         perform pdb2_tree_placeholder( _name_mod, 'tree', _placeholder );
-- 		_placeholder = pdb2_val_include( _name_mod, 'tree', '{placeholder}' );
--         --raise '%, %', _data, _placeholder;
--         select array_agg( a.value ->> 'id' ) into _reload
--         from jsonb_array_elements( _placeholder ) as a;
--         --raise '%', _reload;
--         perform pdb2_val_include( _name_mod, 'tree', '{task}',
--                                   array[ 
--                                         jsonb_build_object( 'cmd', 'reload_id', 'data', _reload )
--                                   ]
--                                                 );
--         perform pdb2_return( _placeholder );
        --raise '%', pdb2_val_include_text(_name_mod, 'tree', '{task}');
    end if;
 
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
    _id = _placeholder #>> '{0, id}';
	-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _id ); 
-- установить информацию по бланкам
	perform p27471_tree_set( _name_mod, _name_tree, _name_table , null); 
-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );
-- новая ветка
-- [{"id": "370d78db3b9ea91dee16a5c35e3c1cd5", "text": "Клиент (Физическое лицо)", "type": "item_klient_fizlico", "theme": 5, "parent": "53eccdc70435c519f15f1fff958f4971", "children": 1}]
    perform pdb2_return( _placeholder );
end;
$$;

create function elbaza.p27471_tree_rename(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_id text;
	_idkart int;
	_name text;
    
begin

-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
	_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, idkart}' );
 	_name = pdb2_val_api_text( '{post,text}' );
-- смена текста
	update t27471 set dttmup = now(), name = _name where idkart =_idkart 
	returning name into _name;
-- установить информацию по бланкам
	perform p27471_tree_set( _name_mod, _name_tree, _name_table, null );		
-- новое имя ветки 	
	perform pdb2_return( to_jsonb( _name ) );
-- подготвить данные для сокета - обновить id	
    

 	perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	

end;
$$;

create function elbaza.p27471_tree_set(_name_mod text, _name_tree text, _name_table text, _id text) returns void
    language plpgsql
as
$$
declare 
	_id_old text; 
	_idkart int; -- idkart элемента в таблице t27471
	_idkart_old int; -- старый idkart
	_type text; 
	_mod_property text;
	_data jsonb;
	
begin
-- установить информацию по выделенной ветки
	_id = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	_data = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, '{data}' );
	_type = _data ->> 'type';
	_idkart = _data ->> 'idkart'; 
    
 	if _type is not null then
		_mod_property = pdb2_val_include_text( _name_mod, _name_tree, array[ 'pdb','action','visible_module', _type] );
	end if;
	if _mod_property is null then
		_mod_property = pdb2_val_include_text( _name_mod, _name_tree, array[ 'pdb','action','visible_module',''] );
	end if;
-- обработка бланка
	if _mod_property is not null then
-- убрать автомат	
		perform pdb2_val_include( _name_mod, _name_tree, array[ 'pdb','action','visible_module'], null );
-- запомнитьв сессии данные для бланка
		perform pdb2_val_module( _mod_property, '{hide}', null );
		perform pdb2_val_session( _name_mod, '{view}', _mod_property );
		_id_old = pdb2_val_session_text( _name_mod, '{id}' );
		if _id = _id_old then
		else
			perform pdb2_val_session( _name_mod, '{id}', _id );
			perform pdb2_val_session( _name_mod, '{b_submit}', 0 );
		end if;
	end if;
end;
$$;

create function elbaza.p27471_tree_view(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Определяет тип элемента и вызывает соответствующую функцию -- 
-- Иерархия типов элементов дерева:
-- root_firma (Фирма) -> folder_filter (Папка фильтра) -> item_klient (Клиент) -> item_dolument (Документ)
--=======================================================================================--

	_pdb_userid integer	= pdb_current_userid();
	_placeholder jsonb;
	_type text;
	
begin  
	-- тип элемента в дереве
	_type = pdb2_tree_placeholder_text('p27471_tree', 'tree', coalesce(_id, _parent_id), 0, '{data, type}'); 
    if _type is null then 
		return p27471_tree_view_root(_parent_id, _name_find, _id); 
    elseif _type = 'root_firma' then 
        return p27471_tree_view_filter_folder(_parent_id, _name_find, _id);
    elseif _type = 'folder_filter' then 
        return p27471_tree_view_filter_folder2(_parent_id, _name_find, _id);
    elseif _type = 'folder_filter2' then 
        return p27471_tree_view_klient(_parent_id, _name_find, _id);
    elseif _type = 'item_klient' then
        return p27471_tree_view_dokument(_parent_id, _name_find, _id);
	end if;
    
	return null;
end;
$$;

create function elbaza.p27471_tree_view_dokument(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder документа
--=======================================================================================--
	_placeholder jsonb = '[]';
	_idkart int; -- id родительского элемента (id клиента)
	_parent_id text; -- id родителя
    _parent_idkart int; -- родитель родителя
	
begin
    _parent_id = pdb2_val_api_text( '{post, parent}' ); 
	_parent_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id, 0, '{data, parent}');
    _idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, idkart}' );
    
    -- Собирает placeholder для документа
    select jsonb_agg( a ) into _placeholder
    from (
        select 
            jsonb_build_object(
              'type', 'item_dokument',  
              'idkart', a.idkart,
              'dttmcr', a.dttmcr,
              'userid', a.userid,
              'property_data', t27471.property_data
            ) as id,
            a.name as "text", 
            'item_dokument' as "type",
            _parent_id as parent,
            1 as children,
            case when a.on = 1 then null else 5 end as theme
        from t27471_data_dokument as a
        join t27471 on a.idkart = t27471.idkart
        where a.dttmcl is null
        and t27471.dttmcl is null
        and t27471.parent = _parent_idkart   -- родитель равен клиенту
        and a.client = _idkart  -- client равен id родителя
        and (_name_find is null or a.name ilike  concat( '%', _name_find, '%' )) -- поиск
    ) as a;
    
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );

	return _placeholder;

end;
$$;

create function elbaza.p27471_tree_view_filter_folder(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder папки фильтра
--=======================================================================================--
	_placeholder jsonb = '[]';
    _parent_id text;
    _parent_idkart int;
begin
	_parent_id = pdb2_val_api_text( '{post, parent}' ); 
	_parent_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id, 0, '{data, idkart}');
    
    select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter',
				  'folder', 'folder_filter',
				  'text', a.letter,
                  'parent', a.parent
				) as id,
				a.letter as "text", 
				'folder_filter' as "type",
				_parent_id as parent,
				1 as children 
			from (
                select distinct a.letter, t27471.parent
				from elbaza.t27468_data_klient as a -- соединяем с таблицей "Базы клиентов"
                join elbaza.t27471_data_dokument on a.idkart = t27471_data_dokument.client -- соединяем с таблицей документов, где связь - id клиента - клиента в документе
                join elbaza.t27471 on t27471_data_dokument.idkart = t27471.idkart -- соединяем с общей таблицей Документов для получения родителя
				where a.dttmcl is null
                and t27471_data_dokument.dttmcl is null
                and t27471.dttmcl is null
                and t27471.parent = _parent_idkart
                and (_name_find is null or t27471_data_dokument.name ilike  concat( '%', _name_find, '%' )) -- поиск
				order by a.letter, t27471.parent -- сортировка по букве алфавита
			) as a
        ) as a;
    
	
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
	
	return _placeholder;

end;
$$;

create function elbaza.p27471_tree_view_filter_folder2(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder папки фильтра
--=======================================================================================--
	_placeholder jsonb = '[]';
    _parent_id text;
    _parent_idkart int;
    _letter text;
begin
	_parent_id = pdb2_val_api_text( '{post, parent}' ); 
	_parent_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id, 0, '{data, parent}');
    _letter = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, text}' );

    select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter2',
				  'folder', 'folder_filter2',
				  'text', a.double_letter,
                  'parent', a.parent
				) as id,
				a.double_letter as "text", 
				'folder_filter2' as "type",
				_parent_id as parent,
				1 as children 
			from (
                select distinct a.double_letter, t27471.parent
				from elbaza.t27468_data_klient as a -- соединяем с таблицей "Базы клиентов"
                join elbaza.t27471_data_dokument on a.idkart = t27471_data_dokument.client -- соединяем с таблицей документов, где связь - id клиента - клиента в документе
                join elbaza.t27471 on t27471_data_dokument.idkart = t27471.idkart -- соединяем с общей таблицей Документов для получения родителя
				where a.dttmcl is null
                and t27471_data_dokument.dttmcl is null
                and t27471.dttmcl is null
                and t27471.parent = _parent_idkart
                and a.letter = _letter
                and (_name_find is null or t27471_data_dokument.name ilike  concat( '%', _name_find, '%' )) -- поиск
				order by a.double_letter, t27471.parent -- сортировка по букве алфавита
			) as a
        ) as a;
    
	
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
	
	return _placeholder;

end;
$$;

create function elbaza.p27471_tree_view_klient(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder ветки клиента
--=======================================================================================--
	_placeholder jsonb = '[]';
	_parent_id text;
    _parent_idkart int;
    _starts_with text;
	
begin
     _parent_id = pdb2_val_api_text( '{post, parent}' ); 
     _parent_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, parent}');
     _starts_with = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, text}' );  -- буква родительского элемента, с которой начинается название клиента
     
    -- Собирает placeholder для клиента 
    select jsonb_agg( a ) into _placeholder
    from (
        select 
            jsonb_build_object(
              'type', 'item_klient',  
              'idkart', a.idkart,
              'text', a.name,
              'parent', a.parent
            ) as id,
            a.name as "text", 
            1 as "on",
            'item_klient' as "type",
            _parent_id as parent,
            1 as children
        from 
        (
            select distinct a.name, a.idkart, t27471.parent
            from elbaza.t27468_data_klient as a -- соединяем с таблицей "Базы клиентов"
            join elbaza.t27471_data_dokument on t27471_data_dokument.client = a.idkart -- соединяем с таблицей документов, где связь - id клиента - клиента в документе
            join elbaza.t27471 on t27471_data_dokument.idkart = t27471.idkart
            where a.dttmcl is null
            and t27471_data_dokument.dttmcl is null
            and t27471.dttmcl is null
            and a.double_letter = _starts_with  -- буква в "Базе клиентов" равна букве род элемента
            and t27471.parent = _parent_idkart
            and (_name_find is null or t27471_data_dokument.name ilike  concat( '%', _name_find, '%' )) -- поиск
        ) as a
    ) as a;
    
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );

	return _placeholder;

end;
$$;

create function elbaza.p27471_tree_view_root(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder фирм
--=======================================================================================--
	_placeholder jsonb = '[]';
    _parents int[];
    
begin
    -- Собирает placeholder для фирм
    if _name_find is not null then
        select 
            ARRAY_AGG(a.parent)
        into _parents
        from elbaza.t27471 as a
        left join elbaza.t27471_data_dokument on a.idkart = t27471_data_dokument.idkart
        where a.dttmcl is null
        and t27471_data_dokument.dttmcl is null
        and ( _name_find is null or t27471_data_dokument.name ilike concat( '%', _name_find, '%' )); -- поиск
        
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                jsonb_build_object(
                  'type', a.type,
                  'idkart', a.idkart
                ) as id,
                a.name as "text", 
                a.type as "type",
                a.parent as parent,
                1 as children 
            from t27471 as a
            where parent = 0
            and idkart = any(_parents)
            and dttmcl is null
        ) as a; 
    else
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                jsonb_build_object(
                  'type', a.type,
                  'idkart', a.idkart
                ) as id,
                a.name as "text", 
                a.type as "type",
                a.parent as parent,
                1 as children 
            from t27471 as a
            where parent = 0
            and dttmcl is null
        ) as a; 
    end if;
        
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
    return _placeholder;
end;
$$;

create function elbaza.p27472_tab(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );

	_from text;
	_fields jsonb;
	_where text[];
	_tab text;
	_tmp jsonb;
	_date_create timestamptz = 'today';
	_filter_val text 	= pdb2_val_include_text( 'p27472_table', 'filter', '{value}' ); -- id выбранного фильтра
	_filter jsonb;  -- json для фильтров
	_status_s int[];  -- массив для статусов
    _idkart jsonb;

begin
    if pdb2_val_api_text( '{post, awdId}' ) = 6::text then
        update t29567
        set group_id = 1,
        dttmup = now()
        where group_id = 2
        and page = 1;
        perform pdb_func_alert( _value, 'success', 'История очищена' );
    end if;
	
	update t29567 
    set group_id = 1,
    dttmup = now()
    WHERE group_id = 2 
    and dttmup::date <> current_date
    and idispl = _pdb_userid
    and page = 1
    and dttmcl is null;
    
	-- Инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
    
	-- Получение всех фильтров
	SELECT json_agg(obj.val) INTO _tmp
	FROM (
		SELECT jsonb_build_object(
			'text', child.group_name,
			'children', child.children 
		)  AS val
		FROM (
			SELECT array_agg(b.value) AS children, b.group_name AS group_name 
			FROM (
                (SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 1  -- для определенной страницы
                and a.group_id = 1
                order by a.idkart)
                union all
				(SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 1  -- для определенной страницы
                and ((a.group_id = 2) or (a.group_id = 3 and (a.dttmcr::date = current_date)))
                order by a.idkart)
			) AS b 		
			GROUP BY b.group_name
		) AS child
	) as obj;
    
        
    perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', null );
	perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', _tmp );
    
	
    --raise '%', _tmp;
    
	--raise '%', pdb2_val_include_text( _name_mod, 'table', '{pdb, includes, find}');
    
	-- Получение данных для определенного фильтра
	if _filter_val is not null then
        
		select jsonb_build_object(
			'list_name', a.filter_name,
			'date_start', a.date_start,
			'date_end', a.date_end,
            'phone_address_to', a.phone_address_to,
			'phone_address_from', a.phone_address_from,
			'time_start', a.time_start,
			'time_end', a.time_end,
			'id21311', a.id21311,
			'id21301', a.id21301,
            'group', a.group_id
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
        
        if (_filter ->> 'group')::int = 1 then
            update t29567
            set group_id = 2,
            dttmup = now()
            where idkart::text = _filter_val;
        end if;
        
        if _filter is not null then
            if (_filter ->> 'group')::int = 3 then
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
                perform pdb2_val_include( _name_mod, 'filter', '{value}', (_filter ->> 'list_name'));
                --raise '%', pdb2_val_include_text( _name_mod, 'filter', '{data}');
            else 
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', null);
            end if;
        else
            insert into t29567 (idispl, filter_name, group_id, page)
            values (_pdb_userid, _filter_val, 3, 1);
            perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
        end if;
        
	end if;

	
	_tab = pdb2_val_include_text( _name_mod, 'tabs', '{value}' );
		
	if _tab = '1' then
		-- Выберутся все записи
	elsif _tab = '2' then
		-- Исходящие:
		_where = _where || format( 'b.idkart = 18' );
	elsif _tab = '3' then
		-- Входящие:
		_where = _where || format( 'b.idkart = 20' );
	end if;
    
    -- Дата "От"
    if (_filter ->> 'group')::int <> 3 then
        if (_filter ->> 'date_start') is not null then 
            _where = _where || format( 'a.time_start::date >= %L', (_filter ->> 'date_start')::date );
        end if;
        -- Дата "До"
        if (_filter ->> 'date_end') is not null then 
            _where = _where || format( 'a.time_end::date <= %L', (_filter ->> 'date_end')::date );
        end if;
        -- Телефон
        if (_filter ->> 'phone_address_to') is not null then 
            _where = _where || format( 'a.number_called ilike ''%%%s%%''', (_filter ->> 'phone_address_to') );
        end if;
        -- Сообщение
        if (_filter ->> 'phone_address_from') is not null then 
            _where = _where || format( 'a.number_who_called ilike ''%%%s%%''', (_filter ->> 'phone_address_from') );
        end if;
        -- Статус сообщения
        if (_filter ->> 'time_start') is not null then 
            _where = _where || format( 'extract(epoch from (a.time_end - a.time_start)) >= %L', (_filter ->> 'time_start') );
        end if;
        if (_filter ->> 'time_end') is not null then 
            _where = _where || format( 'extract(epoch from (a.time_end - a.time_start)) >= %L', (_filter ->> 'time_end') );
        end if;
        -- Исполнитель
        if (_filter ->> 'id21311') is not null then 
            _where = _where || format( 'a.userid = %L', (_filter ->> 'id21311') );
        end if;
        -- Подраздедение
        if (_filter ->> 'id21301') is not null then 
            _where = _where || format( 'podr.idkart = %L', (_filter ->> 'id21301') );
        end if;
    end if;
    
	-- Неудалённые записи
	_where = _where || format( 'a.dttmcl is null' );
	-- За сегодня
	--_where = _where || format( 'a.dttmcr >= ''%s''::date', _date_create );
	-- Созданные текущим пользователем
	--_where = _where || format( 'a.userid = %s', _pdb_userid ); -- пока отключила

	-- Выбирает данные
	_from = format(		
		'SELECT
			a.idkart,
			b.name as type,
			b.idkart as type_idkart,
			to_char(a.time_start, ''DD.MM.YYYY HH24:MI:SS'') AS time_start,
			to_char(a.time_end, ''DD.MM.YYYY HH24:MI:SS'') AS time_end,
			ROUND(EXTRACT(EPOCH FROM a.time_end))-ROUND(EXTRACT(EPOCH FROM a.time_start)) AS duration,
			a.number_called,
			a.number_who_called,
			c.user_name as fio
		FROM t27472 AS a
		LEFT JOIN t19391 AS b ON a.type = b.idkart
		LEFT JOIN t20455_data AS c ON a.subscriber = c.idkart
        left join t20175_data_podrazdeleniye as podr on a.userid = podr.userid
	');

	-- Подготовка списка полей
	_fields = jsonb_build_array(
		jsonb_build_object( 'text', 'type', 'sort', 'type' ),
		jsonb_build_object( 'text', 'time_start', 'sort', 'time_start' ),
		jsonb_build_object( 'text', 'time_end', 'sort', 'time_end' ),
		jsonb_build_object( 'text', 'duration', 'sort', 'duration', 'align', '''center''' ),
		jsonb_build_object( 'text', 'number_called', 'sort', 'number_called' ),
		jsonb_build_object( 'text', 'number_who_called', 'sort', 'number_who_called' ),
		jsonb_build_object( 'text', 'fio', 'sort', 'fio' ),
		jsonb_build_object( 'align', '''center''', 'includes', array['dropdown'] )
	);
				
	-- Инициализация таблицы
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,from}', _from );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,where}', _where );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,table,fields}', _fields );
--============================================================================================================
	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.p27473_tab(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );

	_from text;
	_fields jsonb;
	_where text[];
	_tab text;
	_b_submit int 		= pdb2_val_include_text( _name_mod, 'b_submit', '{value}' );  	-- id кнопки
	_MOD_TABLE text 	= 'p27473_table';  												-- таблица, с которой работаем
	_filter jsonb;  																	-- json для фильтров
    _filter_val text 	= pdb2_val_include_text( _MOD_TABLE, 'filter', '{value}' );  	-- id определенного фильтра
	_tmp json;  -- json для всех фильтров
	_status_s int[];  -- массив для статусов
    _idkart jsonb; 																	-- массив для статусов
	_date_create timestamptz = 'today';

begin
    if pdb2_val_api_text( '{post, awdId}' ) = 6::text then
        update t29567
        set group_id = 1,
        dttmup = now()
        where group_id = 2
        and page = 3;
        perform pdb_func_alert( _value, 'success', 'История очищена' );
    end if;
	
	update t29567 
    set group_id = 1,
    dttmup = now()
    WHERE group_id = 2 
    and dttmup::date <> current_date
    and idispl = _pdb_userid
    and page = 3
    and dttmcl is null;
    
	-- Инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
    
	-- Получение всех фильтров
	SELECT json_agg(obj.val) INTO _tmp
	FROM (
		SELECT jsonb_build_object(
			'text', child.group_name,
			'children', child.children 
		)  AS val
		FROM (
			SELECT array_agg(b.value) AS children, b.group_name AS group_name 
			FROM (
                (SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 3  -- для определенной страницы
                and a.group_id = 1
                order by a.idkart)
                union all
				(SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 3  -- для определенной страницы
                and ((a.group_id = 2) or (a.group_id = 3 and (a.dttmcr::date = current_date)))
                order by a.idkart)
			) AS b 		
			GROUP BY b.group_name
		) AS child
	) as obj;
    
        
    perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', null );
	perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', _tmp );
    
	
    --raise '%', _tmp;
    
	--raise '%', pdb2_val_include_text( _name_mod, 'table', '{pdb, includes, find}');
    
	-- Получение данных для определенного фильтра
	if _filter_val is not null then
        
		select jsonb_build_object(
			'list_name', a.filter_name,
			'date_start', a.date_start,
			'date_end', a.date_end,
            'email_from', a.email_from,
            'email_to', a.email_to,
			'email_files', a.email_files,
			'email_subject', a.message,
			'status', a.status::int[],
			'gateway', a.gateway,
			'id21311', a.id21311,
			'id21301', a.id21301,
            'group', a.group_id
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
        
        if (_filter ->> 'group')::int = 1 then
            update t29567
            set group_id = 2,
            dttmup = now()
            where idkart::text = _filter_val;
        end if;
        
        if _filter is not null then
            if (_filter ->> 'group')::int = 3 then
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
                perform pdb2_val_include( _name_mod, 'filter', '{value}', (_filter ->> 'list_name'));
                --raise '%', pdb2_val_include_text( _name_mod, 'filter', '{data}');
            else 
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', null);
            end if;
        else
            insert into t29567 (idispl, filter_name, group_id, page)
            values (_pdb_userid, _filter_val, 3, 3);
            perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
        end if;
        
	end if;

	
	_tab = pdb2_val_include_text( _name_mod, 'tabs', '{value}' );
		
	if _tab = '1' then
		-- Выберутся все записи
	elsif _tab = '2' then
		-- Исходящие:
		_where = _where || format( 'tp.idkart = 29' );
	elsif _tab = '3' then
		-- Входящие:
		_where = _where || format( 'tp.idkart = 28' );
	end if;
    
    --raise '%', (_filter ->> 'email_files');
    if (_filter ->> 'group')::int <> 3 then
        if (_filter ->> 'date_start') is not null then 
            _where = _where || format( 'a.email_date::date >= %L', (_filter ->> 'date_start')::date );
        end if;
        -- Дата "До"
        if (_filter ->> 'date_end') is not null then 
            _where = _where || format( 'a.email_date::date <= %L', (_filter ->> 'date_end')::date );
        end if;
        -- Телефон
        if (_filter ->> 'email_from') is not null then 
            _where = _where || format( 'a.email_from ilike ''%%%s%%''', (_filter ->> 'email_from') );
        end if;
        -- Сообщение
        if (_filter ->> 'email_to') is not null then 
            _where = _where || format( 'a.email_to ilike ''%%%s%%''', (_filter ->> 'email_to') );
        end if;
        if (_filter ->> 'email_files') is not null then 
            _where = _where || format( 'a.file_status::int = %L', (_filter ->> 'email_files')::int );
        end if;
        if (_filter ->> 'email_subject') is not null then 
            _where = _where || format( 'a.email_subject ilike ''%%%s%%''', (_filter ->> 'email_subject') );
        end if;
        _status_s = (select array_agg( a.value::integer ) 
                     from jsonb_array_elements_text( (_filter ->> 'status')::jsonb ) as a); -- массив статусов
        -- Статус сообщения
        if (_filter ->> 'status') is not null then 
            _where = _where || format( 'st.idkart = any( %L )',(_status_s));
        end if;
        -- Шлюз сообщения
        if (_filter ->> 'gateway') is not null then 
            _where = _where || format( 'gw.idkart = %L', (_filter ->> 'gateway') );
        end if;
        -- Исполнитель
        if (_filter ->> 'id21311') is not null then 
            _where = _where || format( 'a.userid = %L', (_filter ->> 'id21311') );
        end if;
        -- Подраздедение
        if (_filter ->> 'id21301') is not null then 
            _where = _where || format( 'podr.idkart = %L', (_filter ->> 'id21301') );
        end if;
    end if;
    
	-- Неудалённые записи
	_where = _where || format( 'a.dttmcl is null' );

	-- Выбирает данные
	_from = format(		
		'SELECT
			a.idkart,
			tp.name as type_name, --Тип письма
			st.name as status_name, --Статус
			to_char(a.email_date, ''DD.MM.YYYY HH:MM:SS'') as email_date, --Дата и время
			case
				when a.file_status is null then ''нет''
				else ''да''
			end as file_status, --Вложение
			a.email_from_name || '' '' || a.email_from as email_from, --От кого
			a.email_to, --Кому
			a.email_subject, --Тема письма
			''elbaza@institutrb.ru'' as shluz--Почтовый шлюз
		from t27473 as a
		left join t19391_data_email_type as tp on a.email_type = tp.idkart
		left join t19391_data_email_status as st on a.email_status = st.idkart
        left join t19391_data_sms_gateway as gw on a.gateway = gw.idkart
        left join t20175_data_podrazdeleniye as podr on a.userid = podr.userid
	');

	-- Подготовка списка полей
	_fields = jsonb_build_array(
		jsonb_build_object( 'text', 'type_name', 'sort', 'type_name' ),
		jsonb_build_object( 'text', 'status_name', 'sort', 'status_name' ),
		jsonb_build_object( 'text', 'email_date', 'sort', 'email_date' ),
		jsonb_build_object( 'text', 'file_status', 'sort', 'file_status' ),
		jsonb_build_object( 'text', 'email_from', 'sort', 'email_from' ),
		jsonb_build_object( 'text', 'email_to', 'sort', 'email_to' ),
		jsonb_build_object( 'text', 'email_subject', 'sort', 'email_subject' ),
		jsonb_build_object( 'text', 'shluz', 'sort', 'shluz' ),
		jsonb_build_object( 'align', '''center''', 'includes', array['dropdown'] )
	);
				
	-- Инициализация таблицы
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,from}', _from );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,where}', _where );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,table,fields}', _fields );
--============================================================================================================
	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.p27474_tab(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_filter_val text 	= pdb2_val_include_text( 'p27474_table', 'filter', '{value}' ); -- id выбранного фильтра
	_from text;
	_fields jsonb;
	_where text[];
	_tab text;  -- табы
	_tmp json;  -- json для всех фильтров
	_filter jsonb;  -- json для фильтров
	_status_s int[];  -- массив для статусов
    _idkart jsonb;
    _button int         = pdb2_val_include_text( _name_mod, 'button', '{value}' );
begin
    if pdb2_val_api_text( '{post, awdId}' ) = 6::text then
        update t29567
        set group_id = 1,
        dttmup = now()
        where group_id = 2
        and page = 2;
        perform pdb_func_alert( _value, 'success', 'История очищена' );
    end if;
    
    update t29567 
    set group_id = 1,
    dttmup = now()
    WHERE group_id = 2 
    and dttmup::date <> current_date
    and idispl = _pdb_userid
    and page = 2
    and dttmcl is null;
    
	-- Инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
    
	-- Получение всех фильтров
	SELECT json_agg(obj.val) INTO _tmp
	FROM (
		SELECT jsonb_build_object(
			'text', child.group_name,
			'children', child.children 
		)  AS val
		FROM (
			SELECT array_agg(b.value) AS children, b.group_name AS group_name 
			FROM (
                (SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 2  -- для определенной страницы
                and a.group_id = 1
                order by a.idkart)
                union all
				(SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 2  -- для определенной страницы
                and ((a.group_id = 2) or (a.group_id = 3 and (a.dttmcr::date = current_date)))
                order by a.idkart)
			) AS b 		
			GROUP BY b.group_name
		) AS child
	) as obj;
    
        
    perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', null );
	perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', _tmp );
    
	
    --raise '%', _tmp;
    
	--raise '%', pdb2_val_include_text( _name_mod, 'table', '{pdb, includes, find}');
    
	-- Получение данных для определенного фильтра
	if _filter_val is not null then
        
		select jsonb_build_object(
			'list_name', a.filter_name,
			'date_start', a.date_start,
			'date_end', a.date_end,
			'phone', a.phone_address_from,
			'sms_message', a.message,
			'status', a.status::int[],
			'gateway', a.gateway,
			'id21311', a.id21311,
			'id21301', a.id21301,
            'group', a.group_id
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
        
        if (_filter ->> 'group')::int = 1 then
            update t29567
            set group_id = 2,
            dttmup = now()
            where idkart::text = _filter_val;
        end if;
        
        if _filter is not null then
            if (_filter ->> 'group')::int = 3 then
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
                perform pdb2_val_include( _name_mod, 'filter', '{value}', (_filter ->> 'list_name'));
                --raise '%', pdb2_val_include_text( _name_mod, 'filter', '{data}');
            else 
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', null);
            end if;
        else
            insert into t29567 (idispl, filter_name, group_id, page)
            values (_pdb_userid, _filter_val, 3, 2);
            perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
        end if;
        
	end if;

    
	-- Табы
	_tab = pdb2_val_include_text( _name_mod, 'tabs', '{value}' );
	
	if _tab = '1' then
		-- Выберутся все записи
	elsif _tab = '2' then
		-- Исходящие:
		_where = _where || format( 'tp.idkart = 29' );
	elsif _tab = '3' then
		-- Входящие:
		_where = _where || format( 'tp.idkart = 28' );
	end if;
	
	-- Фильтры:
	-- Дата "От"
    if (_filter ->> 'group')::int <> 3 then
        if (_filter ->> 'date_start') is not null then 
            _where = _where || format( 'a.dttmcr >= %L', (_filter ->> 'date_start') );
        end if;
        -- Дата "До"
        if (_filter ->> 'date_end') is not null then 
            _where = _where || format( 'a.dttmcr <= %L', (_filter ->> 'date_end') );
        end if;
        -- Телефон
        if (_filter ->> 'phone') is not null then 
            _where = _where || format( 'a.sms_phone ilike ''%%%s%%''', (_filter ->> 'phone') );
        end if;
        -- Сообщение
        if (_filter ->> 'sms_message') is not null then 
            _where = _where || format( 'a.sms_message ilike ''%%%s%%''', (_filter ->> 'sms_message') );
        end if;
        _status_s = (select array_agg( a.value::integer ) 
                     from jsonb_array_elements_text( (_filter ->> 'status')::jsonb ) as a); -- массив статусов
        -- Статус сообщения
        if (_filter ->> 'status') is not null then 
            _where = _where || format( 'st.idkart = any( %L )',(_status_s));
        end if;
        -- Шлюз сообщения
        if (_filter ->> 'gateway') is not null then 
            _where = _where || format( 'gw.idkart = %L', (_filter ->> 'gateway') );
        end if;
        -- Исполнитель
        if (_filter ->> 'id21311') is not null then 
            _where = _where || format( 'a.id21311 = %L', (_filter ->> 'id21311') );
        end if;
        -- Подраздедение
        if (_filter ->> 'id21301') is not null then 
            _where = _where || format( 'a.id21301 = %L', (_filter ->> 'id21301') );
        end if;
    end if;
	
	-- Неудалённые записи
	_where = _where || format( 'a.dttmcl is null' );

	-- Выбирает данные
	_from = format(		
		'select
			a.idkart,
			tp.name as sms_type,
			st.name as sms_status,
			a.dttmcr,
			to_char(a.dttmcr, ''dd.mm.yy HH24:MI:SS'') as sms_datatime_fmt,
			a.sms_phone,
			a.sms_message,
			gw.name as sms_gateway
		from t27474 as a
		left join t19391_data_email_type as tp on a.sms_type = tp.idkart
		left join t19391_data_email_status as st on a.sms_status = st.idkart
		left join t19391_data_sms_gateway as gw on a.sms_gateway = gw.idkart
	');
	
	-- Подготовка списка полей
	_fields = jsonb_build_array(
		jsonb_build_object( 'text', 'sms_type', 'sort', 'sms_type' ),
		jsonb_build_object( 'text', 'sms_status', 'sort', 'sms_status' ),
		jsonb_build_object( 'text', 'sms_datatime_fmt', 'sort', 'sms_datatime_fmt' ),
		jsonb_build_object( 'text', 'sms_phone', 'sort', 'sms_phone' ),
		jsonb_build_object( 'text', 'sms_message', 'sort', 'sms_message' ),
		jsonb_build_object( 'text', 'sms_gateway', 'sort', 'sms_gateway' ),
		jsonb_build_object( 'align', '''center''', 'includes', array['dropdown'] )
	);
				
	-- Инициализация таблицы
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,from}', _from );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,where}', _where );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,table,fields}', _fields );
--============================================================================================================
	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.p30436_create(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
-- система	
 	_pdb_userid	integer	= pdb_current_userid();

  	_idkart integer;
  	_placeholder jsonb;
 	_after text;

	_parent integer;
	_type text; 
	_name text;
 	_children jsonb;

 	_types jsonb;
	_cn integer;
	_list_id int;
    _data_filter jsonb;
    _root_id int; 
    _root_type text; 
    _root_name text; 
    
begin
    -- если тип -- список, создать фильтр
    -- иначе -- получить фильтр
    -- добавить элемент фильтр
    -- сохранить фильтр
    
-- информация по дереву
	_types = pdb2_val_include( _name_mod, _name_tree, '{data,types}' );		
-- получить переменые
	_parent = pdb2_val_api_text('{post,parent}');
	_type = pdb2_val_api_text( '{post,type}' );
	_children = pdb2_val_api( '{post,children}' );
	_after = pdb2_val_api_text( '{post,after}' );
 -- установить имя по умолчанию		
	_name = pdb_val_text( _types, array[_type,'text'] );
-- добавить ветку
	insert into t30436( parent, type, name, userid ) values( _parent, _type, _name, _pdb_userid) returning idkart
	into _idkart;
    
    if _type = 'item_spisok' then
        -- при создании списка сформировать фильтр для списка
        select idkart, name, type into _root_id, _root_name, _root_type from t30436 where parent = 0 and type = 'root_spiski';
        
        _data_filter = jsonb_build_object(
                    _root_id, jsonb_build_object(
                           'id', _root_id,
                           'name', _root_name,
                           'type', _root_type,
                           'parent', 0,
                           'on', 1),
                    _idkart, jsonb_build_object(
                            'id', _idkart,
                            'name', _name,
                            'type', _type,
                            'parent', _root_id)
                    );
        -- сохранить фильтр
        update t30436_data_spisok set data_filter = _data_filter where idkart = _idkart;
    elseif _type <> 'folder_spiski' then
        -- при создании элементов списка, добавить в фильтр новый элемент
        -- получить id списка в котором создан элемент и его фильтр
        select idkart, data_filter into _list_id, _data_filter from t30436_data_spisok where userid = _pdb_userid and data_filter ? _parent::text;
        -- добавить новый элемент в фильтр
        _data_filter = _data_filter || jsonb_build_object(_idkart, 
                        jsonb_build_object('id', _idkart,
                                           'name', _name,
                                           'type', _type,
                                           'parent', _parent));
        -- сохранить фильтр
        update t30436_data_spisok set data_filter = _data_filter where idkart = _list_id;
    end if;
    
-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _idkart );
-- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
-- проверка записи
	select count(*) from t30436_children as a where a.idkart = _parent into _cn;
	if _cn > 0 then
-- изменить позцию позиции
		update t30436_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent;
	else
-- установить позицию
		insert into t30436_children( idkart, children ) values ( _parent, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
-- получить новую ветку		
	_placeholder = pdb2_tpl_tree_view( null, null, _idkart, _name_table, _name_table_children );
-- установить информацию по бланкам
	perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );	
-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent );
-- новая ветка

	perform pdb2_return( _placeholder );

end;
$$;

create function elbaza.p30436_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
    _pdb_userid integer	= pdb_current_userid();

	_b_submit integer	= pdb2_val_include_text( _name_mod, 'b_submit', '{var}' );
	_event text			= pdb2_event_name( _name_mod );
	_include text		= pdb2_event_include( _name_mod );

	_list_name text;            
	_list_name_new text;       

	-- id выбранного названия списка
    _data_filter_old jsonb;
    _data_filter_new jsonb = '{}';
    _filter_id int;
    _filter_parent int; 
    _list_id_new int; 
    _rc record;
    _idkart_matches jsonb;
    _list_id int = pdb2_val_include_text('p30436_property_spisok', 'idkart', '{var}');
    _users jsonb = pdb2_val_include_text(_name_mod, 'users', '{value}');
    
begin 
    -- Инициализация переменных
	perform pdb2_mdl_before( _name_mod );
    
	-- Получает название выбранного шаблона по id для вставки в поля с названием шаблона:
	select a.name into _list_name
	from t30436_data_spisok as a
	where a.idkart = _list_id;
	-- Прописывает название шаблона письма в поля
	perform pdb2_val_include( _name_mod, 'list_name', '{value}', _list_name );

	if _event is null then
	    perform pdb2_val_include( _name_mod, 'list_name_new', '{value}', _list_name );
    end if;
    
	if _event = 'submit' then
    
		-- Получает выбранные значения из полей:
		_list_name = pdb2_val_include_text( _name_mod, 'list_name', '{value}' );    -- оригинальное название списка
		
		_list_name_new = COALESCE(                                                   -- выходное название списка
			pdb2_val_include_text( _name_mod, 'list_name_new', '{value}'), _list_name
		);
        -- получить фильтр для добавления к скопированному списку
        select data_filter into _data_filter_old from t30436_data_spisok where idkart = _list_id; 
        
        for _rc in select * from unnest(pdb_sys_jsonb_to_int_array(_users)) as usr
        loop
            perform pdb2_val_session('p30436_form', '{idkart_matches}', null);
            -- сохранить копию и получить id скопированной записи
            _list_id_new = p30436_tree_share_copy( _list_id, null, _list_name_new, _rc.usr);
            
            _idkart_matches = pdb2_val_session('p30436_form', '{idkart_matches}'); 
            
            for _rc in 
                select a.key, a.value from jsonb_each(_data_filter_old) as a
                order by a.key 
            loop
                if _rc.value ->> 'type' = 'root_spiski' then
                    _data_filter_new = jsonb_build_object(_rc.key, _rc.value);
                else
                    _filter_id = coalesce(_idkart_matches ->> _rc.key::text, _rc.key::text); 
                    _filter_parent = coalesce(_idkart_matches ->> (_rc.value ->> 'parent'), (_rc.value ->> 'parent')); 
                    _rc.value = pdb_val(_rc.value, array['id'], _filter_id);
                    _rc.value = pdb_val(_rc.value, array['parent'], _filter_parent);
                    _data_filter_new = _data_filter_new || jsonb_build_object(_filter_id, _rc.value);
                end if;
            end loop;
            update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new; 
        end loop;
    
        perform pdb2_val_function( 'message', 'share_success', 1 ); 
    end if;
         
	perform pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

create function elbaza.p30436_list_types() returns jsonb
    language plpgsql
as
$$
declare 
	_types jsonb	= '{}';
	_fields jsonb;
	_types_all jsonb;
    
begin
	    -- Создает список типов для элементов фильтра. 
        -- Структура {Название элемента: {порядковый номер значения: {значения}}}
        
        _types = 
        jsonb_build_object('1', jsonb_build_object('filter_type', 'id29065_list',
                                                 'filter_name', 'Геопозиция (группа)',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,2,3,4}')); 
        
        --2 
        _types = _types || 
        jsonb_build_object('2', jsonb_build_object('filter_type', 'category',
                                                 'filter_name', 'Клиент: Категория',
                                                 'select_type', 'tr_select_multi_text',
                                                 'condition_types', '{1,2,3,4}')); 
        -- 3
        _types = _types || 
        jsonb_build_object('3', 
                             jsonb_build_object('filter_type', 'client_id',
                                                 'filter_name', 'Клиент: Код клиента',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,2,3,4}')); 

        
        -- 4
        _types = _types || 
        jsonb_build_object('4', 
                             jsonb_build_object('filter_type', 'nm_full',
                                                 'filter_name', 'Клиент: Наименование клиента (полное)',
                                                 'select_type', 'tr_text',
                                                 'condition_types', '{1,2,3,4,21,22,23}')); 
        
        
       --5
       _types = _types || 
       jsonb_build_object('5', 
                             jsonb_build_object('filter_type', 'nm',
                                                 'filter_name', 'Клиент: Наименование клиента (сокращенное)',
                                                 'select_type', 'tr_text',
                                                 'condition_types', '{1,2,3,4,21,22,23}')); 

       -- 6                 
       _types = _types || 
       jsonb_build_object('6', 
                             jsonb_build_object('filter_type', 'id29064_list',
                                                 'filter_name', 'Клиент: Налогообложение (группа)',
                                                 'select_type', 'tr_select_multi_text',
                                                 'condition_types', '{1,2,3,4}')); 
       -- 7                    
       _types = _types || 
       jsonb_build_object('7', 
                             jsonb_build_object('filter_type', 'id29063_list',
                                                 'filter_name', 'Клиент: ОКВЭД (группа)',
                                                 'select_type', 'tr_select_multi_text',
                                                 'condition_types', '{1,2,3,4}')); 
        -- 8
        _types = _types || 
        jsonb_build_object('8', 
                             jsonb_build_object('filter_type', 'id29063main_list',
                                                 'filter_name', 'Клиент: ОКВЭД основного (группа)',
                                                 'select_type', 'tr_select_multi_text',
                                                 'condition_types', '{1,2,3,4}')); 
        -- 9
        _types = _types || 
        jsonb_build_object('9', 
                             jsonb_build_object('filter_type', 'id29062_list',
                                                 'filter_name', 'Клиент: ОКОПФ (группа)',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,2,3,4}'));
        -- 10
        _types = _types || 
        jsonb_build_object('10', 
                             jsonb_build_object('filter_type', 'id21324',
                                                 'filter_name', 'Клиент: РИЦ',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,2,3,4}')); 
        -- 11
        _types = _types || 
        jsonb_build_object('11', 
                             jsonb_build_object('filter_type', 'vr_adr',
                                                 'filter_name', 'Клиент: Фактический адрес',
                                                 'select_type', 'tr_dadata_adr',
                                                 'condition_types', '{1,2,3,4}', 
                                                 'array', 1,
                           					     'data_type', 'ADDRESS',
      				                             'data_bounds', 'region-street'));
    
    _types_all = jsonb_build_object('item_kliyent', _types);
     
    -- Контактное лицо
    _types = 
        jsonb_build_object('1', 
                             jsonb_build_object('filter_type', 'user_email_find',
                                                 'filter_name', 'Конт. лицо: Email',
                                                 'select_type', 'tr_text',
                                                 'condition_types', '{1,6,7,8,9,10,11}')); 
    _types = _types || 
        jsonb_build_object('2', 
                             jsonb_build_object('filter_type', 'id29061_list',
                                                 'filter_name', 'Конт. лицо: Профиль (группа)',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,6,10,11}')); 
     _types = _types || 
        jsonb_build_object('3', 
                             jsonb_build_object('filter_type', 'user_phone_find',
                                                 'filter_name', 'Конт. лицо: Телефон',
                                                 'select_type', 'tr_text',
                                                 'condition_types', '{1,6,7,8,9,10,11}')); 
     _types = _types || 
        jsonb_build_object('4', 
                             jsonb_build_object('filter_type', 'user_name',
                                                 'filter_name', 'Конт. лицо: ФИО',
                                                 'select_type', 'tr_text',
                                                 'condition_types', '{1,6,7,8,9,10,11}')); 
	
    _types_all = _types_all || jsonb_build_object('item_kontaktnoye_litso', _types);

    -- Метка
    _types = jsonb_build_object('1', 
                             jsonb_build_object('filter_type', 'id29222_list',
                                                 'filter_name', 'Метка: Наименование метки',
                                                 'select_type', 'tr_select_multi_int',
                                                 'array', 1,
                                                 'condition_types', '{1,6,10,11}')); 
    
    _types_all = _types_all || jsonb_build_object('item_metka', _types);
    -- Статус
    _types = jsonb_build_object('1', 
                             jsonb_build_object('filter_type', 'status_dttmcr',
                                                 'filter_name', 'Дата статуса',
                                                 'select_type', 'tr_date',
                                                 'condition_types', '{1,6,10,11}')); 
    _types = _types || jsonb_build_object('2', 
                             jsonb_build_object('filter_type', 'id26011',
                                                 'filter_name', 'Статус: Наименование статуса',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,6,10,11}')); 
    
    _types_all = _types_all || jsonb_build_object('item_status', _types);
    
    -- Дистрибутив
    _types = jsonb_build_object('1', 
                             jsonb_build_object('filter_type', 'id22006',
                                                 'filter_name', 'Дистрибутив: Серия',
                                                 'select_type', 'tr_select_multi_int',
                                                 'array', 1,
                                                 'condition_types', '{1,6,10,11}')); 
    _types = _types || jsonb_build_object('2', 
                             jsonb_build_object('filter_type', 'id22007',
                                                 'filter_name', 'Дистрибутив: Сетивитость / Технология',
                                                 'select_type', 'tr_select_multi_int',
                                                 'array', 1,
                                                 'condition_types', '{1,6,10,11}')); 
	_types = _types || jsonb_build_object('3', 
                             jsonb_build_object('filter_type', 'id22001',
                                                 'filter_name', 'Дистрибутив: Сетивитость / Технология',
                                                 'select_type', 'tr_select_multi_int',
                                                 'array', 1,
                                                 'condition_types', '{1,6,10,11}')); 
    _types = _types || jsonb_build_object('4', 
                             jsonb_build_object('filter_type', 'is_close',
                                                 'filter_name', 'Дистрибутив: Сопр/Откл',
                                                 'select_type', 'tr_select_one',
                                                 'condition_types', '{1,6,10,11}')); 
    
    _types_all = _types_all || jsonb_build_object('item_distributiv', _types);

    -- Менеджер
    _types = jsonb_build_object('1', 
                             jsonb_build_object('filter_type', 'id24015',
                                                 'filter_name', 'Менеджер: Ответственный',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,6,10,11}')); 
    
    _types_all = _types_all || jsonb_build_object('item_menedzher', _types);
    
    -- Направление
    _types = jsonb_build_object('1', 
                             jsonb_build_object('filter_type', 'id29001',
                                                 'filter_name', 'Направление: Направление',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,6,10,11}')); 
    
    _types_all = _types_all || jsonb_build_object('item_napravleniye', _types);

    -- Задание
    _types = jsonb_build_object('1', 
                             jsonb_build_object('filter_type', 'date',
                                                 'filter_name', 'Дата создания',
                                                 'select_type', 'tr_date',
                                                 'condition_types', '{1,2,3,4,5,6,7,8,9,10,11}')); 
    _types = _types || jsonb_build_object('2', 
                             jsonb_build_object('filter_type', 'num_26103',
                                                 'filter_name', 'Задание: Номер задания',
                                                 'select_type', 'tr_select_multi_int',
                                                 'condition_types', '{1,6,10,11}')); 

    _types_all = _types_all || jsonb_build_object('item_zadaniye', _types);
    
    -- Dadata
    _types = jsonb_build_object('1', 
                         jsonb_build_object('filter_type', 'vr_income',
                                             'filter_name', 'Datada: Доходы',
                                             'select_type', 'tr_num',
                                             'condition_types', '{1,2,3,4,5,6,7,8,9,10,11}')); 

    _types = _types || jsonb_build_object('2', 
                         jsonb_build_object('filter_type', 'vr_smb',
                                             'filter_name', 'Datada: Категория предприятия',
                                             'select_type', 'tr_select_multi_text',
                                             'condition_types', '{1,6,10,11}')); 

    _types = _types || jsonb_build_object('3', 
                         jsonb_build_object('filter_type', 'vr_okveds',
                                             'filter_name', 'Datada: Коды ОКВЭД',
                                             'select_type', 'tr_select_multi_text',
                                             'array', 1,					
                                             'condition_types', '{1,6,10,11}')); 

    _types = _types || jsonb_build_object('4', 
                         jsonb_build_object('filter_type', 'vr_okved',
                                             'filter_name', 'Datada: Коды основного ОКВЭД',
                                             'select_type', 'tr_select_multi_text',
                                             'condition_types', '{1,6,10,11}')); 

    _types = _types || jsonb_build_object('5', 
                         jsonb_build_object('filter_type', 'vr_penalty',
                                             'filter_name', 'Datada: Налоговые штрафы',
                                             'select_type', 'tr_num',
                                             'condition_types', '{1,2,3,4,5,6,7,8,9,10,11}')); 

    _types = _types || jsonb_build_object('6', 
                         jsonb_build_object('filter_type', 'vr_tax',
                                             'filter_name', 'Datada: Налогообложение',
                                             'select_type', 'tr_select_multi_text',
                                             'condition_types', '{1,6,10,11}')); 
    
    _types = _types || jsonb_build_object('7', 
                        jsonb_build_object('filter_type', 'vr_debt',
                                             'filter_name', 'Datada: Недоимки по налогам',
                                             'select_type', 'tr_num',
                                             'condition_types', '{1,6,10,11}')); 
    
    _types = _types || jsonb_build_object('8', 
                         jsonb_build_object('filter_type', 'vr_opf',
                                             'filter_name', 'Datada: ОКОПФ',
                                             'select_type', 'tr_select_multi_text',
                                             'condition_types', '{1,6,10,11}')); 

    _types = _types || jsonb_build_object('9', 
                         jsonb_build_object('filter_type', 'vr_expense',
                                             'filter_name', 'Datada: Расходы',
                                             'select_type', 'tr_num',
                                             'condition_types', '{1,2,3,4,5,6,7,8,9,10,11}')); 

    _types = _types || jsonb_build_object('10', 
                         jsonb_build_object('filter_type', 'vr_managers',
                                             'filter_name', 'Datada: Руководитель',
                                             'select_type', 'tr_text',
                                             'array', 1,					
                                             'condition_types', '{1,6,10,11}')); 
    
    _types = _types || jsonb_build_object('11', 
                         jsonb_build_object('filter_type', 'vr_state',
                                             'filter_name', 'Datada: Состояние',
                                             'select_type', 'tr_select_multi_text',
                                             'array', 1,					
                                             'condition_types', '{1,6,10,11}')); 
    
    _types = _types || jsonb_build_object('12', 
                         jsonb_build_object('filter_type', 'vr_type',
                                             'filter_name', 'Datada: Тип организации',
                                             'select_type', 'tr_select_multi_text',
                                             'condition_types', '{1,6,10,11}')); 
    
    _types = _types || jsonb_build_object('13', 
                         jsonb_build_object('filter_type', 'vr_capital',
                                             'filter_name', 'Datada: Уставной капитал',
                                             'select_type', 'tr_num',
                                             'condition_types', '{1,2,3,4,5,6,7,8,9,10,11}')); 
    
    _types = _types || jsonb_build_object('14', 
                         jsonb_build_object('filter_type', 'vr_founders',
                                             'filter_name', 'Datada: Учередители',
                                             'select_type', 'tr_text',
                                             'array', 1,					
                                             'condition_types', '{1,6,10,11}')); 

    _types_all = _types_all || jsonb_build_object('item_datada', _types);

	return _types_all;
	
end;
$$;

create function elbaza.p30436_tool_filter_client(_data jsonb, _alias_filter text, _alias_table text) returns text
    language plpgsql
as
$$
--=================================================================================================
-- Принимает jsonb-объект из элемента списка его значения, формирует для него массив условий where, и возвращает его
-- Элемент списка - Клиент, Контактное лицо, Метка и т.д.
--=================================================================================================
declare 
    _condition integer; -- оператор (=, !=, >, < и др.)
	_filter_type text;  -- тип фильтра (наименование, РИЦ, адрес и др.)
	_select_type text;  -- тип значения в фильтре (множественный селект, одиночный селект, текст, дата и др)
	_array boolean;     -- тип значения в таблице, true = массив, false - не массив
	_val jsonb;         -- jsonb-объект с вышеуказанными значениями
    _filters jsonb;     -- все фильтры текущего элемента 
    _rc record;         -- ключ-значение (id элемента и его значение)
    _items text[];      -- массив с условиями where для текущего элемента
    _alias text;
    
begin 
    
    _filters = _data -> 'filters'; -- получить все фильтры текущего элемента
    
    -- для каждого фильтра сформировать условие where 
    for _rc in 
        select a.key, a.value 
        from jsonb_each(_filters) as a
        where a.value ->> 'meaning' is not null -- пропустить, если не установлено значение
    loop
        _condition = _rc.value ->> 'condition'; -- оператор
        _select_type = _rc.value ->> 'select_type'; -- тип значения
        _val = _rc.value -> 'meaning';              -- значение
        _array = case when _rc.value ->> 'array' = '1' then true end; -- массив или нет
        _filter_type = _rc.key; -- ключ - название фильтра
        
        if _filter_type in ('nm', 'nm_full', 'category', 'id21324', 'id29222_list', 'id26011', 'status_dttmcr') then
            -- данные находятся в основной таблице клиентов
            _alias = _alias_table;
        
        elseif _filter_type = 'id29064_list' then
            -- группа налогообложение
            _filter_type = 'vr_tax';
            _alias = _alias_filter;
            -- развернуть группы и сделать один массив		
            select jsonb_agg( b.code ) into _val
            from (
                select jsonb_array_elements_text( a.kd_tax_list )::int as val
                from t18888_data_gruppa_nalogooblozheniye as a 
                where a.dttmcl is null and '["4"]' ? a.idkart::text
            ) as a
            inner join t18888_data_nalogooblozheniye as b on b.idkart = a.val;
            
        elsif _filter_type = 'id29062_list' then
            -- группа ОКОПФ
            _filter_type = 'vr_opf';
            _alias = _alias_filter;
            
            -- развернуть группы и сделать один массив		
            select jsonb_agg( b.code ) into _val
            from (
                select jsonb_array_elements_text( a.kd_okpf_list )::int as val
                from t18311_data_gruppa_okopf as a 
                where a.dttmcl is null and _val ? a.idkart::text
            ) as a
            inner join t18311_data_okopf as b on b.idkart = a.val;
            
	    elsif _filter_type = 'id29063main_list' then
            -- группа ОКВЭД основной
		    _filter_type = 'vr_okved';
            _alias = _alias_filter;

            select jsonb_agg( b.code ) into _val
            from (
                select jsonb_array_elements_text( a.kd_okveds_list )::int as val
                from t18362_data_gruppa_okved as a 
                where a.dttmcl is null and _val ? a.idkart::text
            ) as a
            inner join t18362_data_okved as b on a.val = b.idkart
            where b.code is not null;
            
        elsif _filter_type = 'id29063_list' then
            -- группа ОКВЭД
            _filter_type = 'vr_okveds';
            _alias = _alias_filter;
            _array = true; 
            
            -- развернуть группы и сделать один массив		
            select jsonb_agg( b.code ) into _val
            from (
                select jsonb_array_elements_text( a.kd_okveds_list )::int as val
                from t18362_data_gruppa_okved as a 
                where a.dttmcl is null and _val ? a.idkart::text
            ) as a
            inner join t18362_data_okved as b on a.val = b.idkart
            where b.code is not null;
            
        elsif _filter_type = 'id29065_list' then
            -- группа ГЕО
            _filter_type = 'vr_adr'; 
            _select_type = 'tr_text';
            _array = true;
            _alias = _alias_filter;

            -- развернуть группы и сделать один массив
            select jsonb_agg( a.val ) into _val
            from (
                select 
                    COALESCE(	
                        a.data #>> '{street_fias_id}',			-- улица
                        a.data #>> '{settlement_fias_id}',		-- населенный пункт
                        a.data #>> '{city_district_fias_id}',	-- район города
                        a.data #>> '{city_fias_id}',			-- город
                        a.data #>> '{area_fias_id}',			-- район в регоне
                        a.data #>> '{region_fias_id}'			-- регион
                    ) as val
                from (
                    select ((a.address #>> '{json}')::jsonb) -> 'data' as data
                    from t19008_data_adres as a 
                    where a.dttmcl is null and _val ? a.geopozitsiya::text
                ) as a
            ) as a;
        else
            -- данные находятся в основной таблице с фильтрами dadata
            _alias = _alias_filter;
        end if;
        
        _items = _items || p30436_tool_filter_table_sql_item( _condition, _filter_type, _alias, _select_type, _array, _val );
        
    end loop;
    
    return _items;

end;
$$;

create function elbaza.p30436_tool_filter_item(_data jsonb, _alias text) returns text
    language plpgsql
as
$$
--=================================================================================================
-- Принимает jsonb-объект из элемента списка его значения, формирует для него массив условий where, и возвращает его
-- Элемент списка - Клиент, Контактное лицо, Метка и т.д.
--=================================================================================================
declare 
    _condition integer; -- оператор (=, !=, >, < и др.)
	_filter_type text;  -- тип фильтра (наименование, РИЦ, адрес и др.)
	_select_type text;  -- тип значения в фильтре (множественный селект, одиночный селект, текст, дата и др)
	_array boolean;     -- тип значения в таблице, true = массив, false - не массив
	_val jsonb;         -- jsonb-объект с вышеуказанными значениями
    _filters jsonb;     -- все фильтры текущего элемента 
    _rc record;         -- ключ-значение (id элемента и его значение)
    _items text[];      -- массив с условиями where для текущего элемента
    
begin 

    _filters = _data -> 'filters'; -- получить все фильтры текущего элемента
    
    -- для каждого фильтра сформировать условие where 
    for _rc in 
        select a.key, a.value 
        from jsonb_each(_filters) as a
        where a.value ->> 'meaning' is not null -- пропустить, если не установлено значение
    loop
        _filter_type = _rc.key; -- ключ - название фильтра
        _condition = _rc.value ->> 'condition'; -- оператор
        _select_type = _rc.value ->> 'select_type'; -- тип значения
        _val = _rc.value -> 'meaning';              -- значение
        _array = case when _rc.value ->> 'array' = '1' then true end; -- массив или нет
        _items = _items || p30436_tool_filter_table_sql_item( _condition, _filter_type, _alias, _select_type, _array, _val );
    end loop;
    
    return _items;

end;
$$;

create function elbaza.p30436_tool_filter_table(_data jsonb, _parent text) returns text
    language plpgsql
as
$$
--=================================================================================================
-- Принимает фильтр списка, формирует условия where для всех элементов фильтра, объединяет их 
-- с учетом операторов (and, or) и скобок в текстовую строку и возвращает эту строку
--=================================================================================================

declare 
    _rc record;             -- key-value, ключ - id элемента в дереве, значение - jsonb-объект с данными элемента
    _where text[];          -- массив условий where с учетом операторов and и or
    _klienty text[];        -- массив условий where для элементов списка "Клиенты" и "Datada", "Метки 1 уровня", "Статусы 1 уровня"
    _kontaktnie_lica text[]; -- массив условий where для элементов списка "Контактные лица", "Метки 2 уровня", "Статусы 2 уровня"
    _napravleniya text[];   -- массив условий where для элементов списка "Направление", "Метки 3 уровня", "Статусы 3 уровня"
    _zadaniya text[];       -- массив условий where для элементов списка "Задания", "Метки 5 уровня", "Статусы 5 уровня"
    _distributivy text[];   -- массив условий where для элементов списка "Дистрибутивы"
    _item_arr text[];       -- переменная для хранения массива условий where для текущего элемента
    _item text;             -- текст условий where для текущего элемента вместе с операторами and и or
    _sql text;              -- переменная для объединения условий where с учетом операторов и скобок
    _and_or text;           -- тип оператора and или or
    _type_parent text;      -- тип родителя элемента (Поля И, Поля ИЛИ, Группа И, Группа ИЛИ)
    _type text;             -- тип элемента списка (Клиент, Контактное лицо, Метка ...)
    _level text;            -- уровень элемента списка - для меток, статусов и менеджеров
    _alias text;            -- alias для таблицы, из которой будут запрашиваться данные
    
begin
    
    if _parent is null then -- при первом вызове функции, выбрать в качестве parent - список
        select a.key from jsonb_each(_data) as a
        where a.value ->> 'type' = 'item_spisok'
        into _parent;
    end if;
    
    for _rc in 
		select a.key, a.value
		from jsonb_each( _data ) as a
		where a.value ->> 'parent' = _parent
        and a.value ->> 'on' = '1'  -- если элемент отключен, не включать эту ветку
	loop
        _type = _rc.value ->> 'type';  -- получить тип элемента
        _level = _rc.value ->> 'level'; -- получить уровень элемента
                    
		if _type in ( 'folder_polya_i', 'folder_gruppa_i', 'folder_polya_ili', 'folder_gruppa_ili' ) then
            _item = p30436_tool_filter_table( _data, _rc.key );
            if _item <> '()' then
                _where = _where || _item; -- для папок "Поля И", "Поля ИЛИ", "Группа И", "Группа ИЛИ"
            end if;
        elseif _type in ('item_kliyent', 'item_datada') or (_level = '1' and _type in ('item_metka', 'item_status')) then
            continue when _rc.value -> 'filters' is null; -- если у текущего элемента списка нет фильтров, пропустить итерацию
            _item_arr = p30436_tool_filter_client(_rc.value, 'client', 'client_data'); -- массив условий where для текущего элемента
            if _item_arr is not null then                  
                _klienty = _klienty || _item_arr;          -- добавить массив условий where для данного типа элемента
            end if;
        elseif _type = 'item_kontaktnoye_litso' or (_level = '2' and _type in ('item_metka', 'item_status')) then
            continue when _rc.value -> 'filters' is null; 
            _alias = 'kontaktnoe_lico';
            _item_arr = p30436_tool_filter_item(_rc.value, _alias);  
            if _item_arr is not null then
                _kontaktnie_lica = _kontaktnie_lica || _item_arr;
            end if;
        elseif _type = 'item_napravleniye' or (_level = '3' and _type in ('item_metka', 'item_status', 'item_menedzher')) then
            continue when _rc.value -> 'filters' is null; 
            _alias = 'napravleniye';
            _item_arr = p30436_tool_filter_item(_rc.value, _alias);  
            if _item_arr is not null then
                _napravleniya = _napravleniya || _item_arr;
            end if;
        elseif _type = 'item_zadaniye' or (_level = '5' and _type in ('item_metka', 'item_status', 'item_menedzher'))  then
           continue when _rc.value -> 'filters' is null; 
            _alias = 'zadaniye';
            _item_arr = p30436_tool_filter_item(_rc.value, _alias);  
            if _item_arr is not null then
                _zadaniya = _zadaniya || _item_arr;
            end if;
        elseif _type = 'item_distributiv' then
            continue when _rc.value -> 'filters' is null; 
            _alias = 'distributiv';
            _item_arr = p30436_tool_filter_item(_rc.value, _alias);  
            if _item_arr is not null then
                _distributivy = _distributivy || _item_arr;
            end if;
        end if;
    end loop;
    
    _type_parent = _data #>> array[_parent, 'type']; -- тип родителя элемента
    
	if _type_parent in ( 'folder_gruppa_ili', 'folder_polya_ili' ) then
		_and_or = ' or '; -- разделитель or для условия where
	else
		_and_or = ' and '; -- разделитель and для условия where
	end if;
    
    
	if _where is not null then
		_sql = array_to_string ( _where, _and_or ); -- объединить условия where текущей папки через разделитель
        return '(' || _sql || ')'; 
	end if; 
	
  	_sql = array_to_string ( _klienty, _and_or ); -- условия where для элементов "Клиент" и "Дадата", "Метка 1 уровень", "Статус 1 уровень"
    
	if _kontaktnie_lica is not null then        -- условия where для элементов "Контактное лицо", "Метка 2 уровень", "Статус 2 уровень"
		_item = array_to_string ( _kontaktnie_lica, _and_or );
		_sql = concat( _sql || _and_or, 
				   format( 'client.client_id in ( select kontaktnoe_lico.client_id from t27468_data_kontaktnoe_lico as kontaktnoe_lico where kontaktnoe_lico.dttmcl is null and kontaktnoe_lico.client_id = client.client_id and (%s) ) ', _item ));
	end if;
    if _napravleniya is not null then   -- условия where для элементов "Направление", "Метка 3 уровень", "Статус 4 уровень"
		_item = array_to_string ( _napravleniya, _and_or );
		_sql = concat( _sql || _and_or, 
				   format( 'client.client_id in ( select napravleniye.client_id from ___ as napravleniye where napravleniye.dttmcl is null and napravleniye.client_id = client.client_id and (%s) ) ', _item ));
	end if;
    if _zadaniya is not null then   -- условия where для элементов "Задания", "Метка 5 уровень", "Статус 5 уровень"
		_item = array_to_string ( _zadaniya, _and_or );
		_sql = concat( _sql || _and_or, 
				   format( 'client.client_id in ( select zadaniye.client_id from ___ as zadaniye where zadaniye.dttmcl is null and zadaniye.client_id = client.client_id and (%s) ) ', _item ));
	end if;
    if _distributivy is not null then   -- условия where для элементов "Дистрибутив"
		_item = array_to_string ( _distributivy, _and_or );
		_sql = concat( _sql || _and_or, 
				   format( 'client.client_id in ( select distributiv.client_id from ___ as distributiv where distributiv.dttmcl is null and distributiv.client_id = client.client_id and (%s) ) ', _item ));
	end if;
    

    return '(' || _sql || ')';
    
end;
$$;

create function elbaza.p30436_tool_filter_table_sql_item(_condition integer, _filter_type text, _alias text, _select_type text, _array boolean, _val jsonb) returns text
    language plpgsql
as
$$
--=================================================================================================
-- Формирует условие where для определенного фильтра, с учетом выбранного оператора и типа значения
--=================================================================================================
declare 
-- типы значений фильтра
    _array_text text[];     -- массив текстовых значений фильтра
	_array_int integer[];   -- массив целочисленных значений фильтра
	_array_num numeric[];   -- массив вещественных чисел
	_array_date date[];     -- массив дат фильтра
    
	_item_text text;        -- текстовое значения фильтра
	_item_int integer;      -- целочисленное значения фильтра
	_item_num numeric;      -- вещественное число
	_item_date date;        -- дата
    
begin
-- типы операторов и их числовые обозначения
-- 1    = 
-- 2    >=
-- 3    <=
-- 4    >
-- 5    <
-- 6    !=
-- 7    text*
-- 8    *text
-- 9    *text*
-- 10   нет значения
-- 11   есть значение

-- array

-- типы значений фильтра
-- tr_select_multi
-- tr_select_one
-- tr_select_multi_int
-- tr_select_one_int
-- tr_select_multi_num
-- tr_select_one_num
-- tr_select_multi_date
-- tr_select_one_date
-- tr_date
-- tr_text
-- tr_int
-- tr_num
-- tr_dadata_adr
    
    if _condition = 10 then  -- оператор "нет значения"
		return format( '%s.%s is null', _alias, _filter_type );
	elsif _condition = 11 then -- оператор "есть значение"
		return format( '%s.%s is not null', _alias, _filter_type );
	end if;
    
    -- тип значения в фильтре - множественный/единственный селект для текстовых значений
    if _select_type in ( 'tr_select_multi_text', 'tr_select_one_text' ) then
		-- превращает jsonb-массив в текстовый массив
        _array_text = pdb_sys_jsonb_to_text_array( _val ); 
			 		
        if _array_text is null then
        -- пропустить проверку
		elsif _array = true then -- если тип значения в таблице - массив
			if _condition = 1 then  -- равно
				return format( '%s.%s && %L', _alias, _filter_type, _array_text );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s is not null and (%s.%s && %L) = false', _alias, _filter_type, _alias, _filter_type, _array_text );
			end if;
		else -- если тип значения в таблице - не массив
			if _condition = 1 then -- равно
				return format( '%s.%s = any ( %L )', _alias, _filter_type, _array_text );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != all ( %L )', _alias, _filter_type, _array_text );
			end if;
		end if;
    -- тип значения в фильтре - множественный/единственный селект для целых чисел
    elsif _select_type in ( 'tr_select_multi_int', 'tr_select_one_int' ) then
        -- превращает jsonb-массив в массив целых чисел
		_array_int = pdb_sys_jsonb_to_text_array( _val ); 
		if _array_int is null then
        -- пропустить проверку		
		elsif _array = true then -- если тип значения в таблице - массив
			if _condition = 1 then -- не равно
				return format( '%s.%s && %L', _alias, _filter_type, _array_int );
			elsif _condition = 6 then  -- не равно
				return format( '%s.%s is not null and (%s.%s && %L) = false', _alias, _filter_type, _alias, _filter_type, _array_int );
			end if;
		else -- если тип значения в таблице - не массив
			if _condition = 1 then -- не равно
				return format( '%s.%s = any ( %L )', _alias, _filter_type, _array_int );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != all ( %L )', _alias, _filter_type, _array_int );
			end if;
		end if;
        
    -- тип значения в фильтре - множественный/единственный селект для вещественных чисел
    elsif _select_type in ( 'tr_select_multi_num', 'tr_select_one_num' ) then
		-- преобразует из jsonb массива в numeric массив
		select array_agg( (a.value #>> '{}')::numeric ) into _array_num
		from jsonb_array_elements( '[]'::jsonb || _val ) as a
		where jsonb_typeof( a.value ) in ( 'string', 'number' );

		if _array_num is null then
        -- пропустить проверку		
		elsif _array = true then -- если тип значения в таблице - массив
			if _condition = 1 then -- равно
				return format( '%s.%s && %L', _alias, _filter_type, _array_num );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s is not null and (%s.%s && %L) = false', _alias, _filter_type, _alias, _filter_type, _array_num );
			end if;
		else -- если тип значения в таблице - не массив
			if _condition = 1 then -- равно
				return format( '%s.%s = any ( %L )', _alias, _filter_type, _array_num );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != all ( %L )', _alias, _filter_type, _array_num );
			end if;
		end if;
        
    -- тип значения в фильтре - дата 
    elsif _select_type = 'tr_date' then
		-- преобразовать в дату
		_item_date = pdb_val_text( _val, null );
	
        if _item_date is null then
        -- пропустить проверку		
		elsif _array = true then -- если тип значения в таблице массив
			if _condition = 1 then -- равно
				return format( '%L = any( %s.%s )', _item_date, _alias, _filter_type );
			elsif _condition = 6 then -- не равно
				return format( '%L != all( %s.%s )', _item_date, _alias, _filter_type );
			end if;
		else -- если тип значения в таблице не массив
			if _condition = 1 then -- равно
				return format( '%s.%s = %L', _alias, _filter_type, _item_date );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != %L', _alias, _filter_type, _item_date );
			elsif _condition = 2 then -- больше или равно
				return format( '%s.%s >= %L', _alias, _filter_type, _item_date );
			elsif _condition = 3 then -- меньше или равно
				return format( '%s.%s <= %L', _alias, _filter_type, _item_date );
			elsif _condition = 4 then -- больше
				return format( '%s.%s > %L', _alias, _filter_type, _item_date );
			elsif _condition = 5 then -- меньше
				return format( '%s.%s < %L', _alias, _filter_type, _item_date );
			end if;
		end if;
    -- тип значения в фильтре - целое число
    elsif _select_type = 'tr_int' then
        -- преобразовать в int
		_item_int = pdb_val_text( _val, null );
	    
		if _item_int is null then
        -- пропустить проверку		
		elsif _array = true then -- если тип значения в таблице массив
			if _condition = 1 then -- равно
				return format( '%L = any( %s.%s )', _item_int, _alias, _filter_type );
			elsif _condition = 6 then -- не равно
				return format( '%L != all( %s.%s )', _item_int, _alias, _filter_type );
			end if;
		else -- если тип значения в таблице не массив
			if _condition = 1 then -- равно
				return format( '%s.%s = %L', _alias, _filter_type, _item_int );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != %L', _alias, _filter_type, _item_int );
			elsif _condition = 2 then -- больше или равно
				return format( '%s.%s >= %L', _alias, _filter_type, _item_int );
			elsif _condition = 3 then -- меньше или равно
				return format( '%s.%s <= %L', _alias, _filter_type, _item_int );
			elsif _condition = 4 then -- больше
				return format( '%s.%s > %L', _alias, _filter_type, _item_int );
			elsif _condition = 5 then -- меньше
				return format( '%s.%s < %L', _alias, _filter_type, _item_int );
			end if;
		end if;
        
    -- тип значения в фильтре - numeric
	elsif _select_type = 'tr_num' then
	    -- преобразовать значение
		_item_num = pdb_val_text( _val, null );
	    
		if _item_num is null then
        -- пропустить проверку		
		elsif _array = true then -- если тип значения в таблице - массив
			if _condition = 1 then -- равно
				return format( '%L = any( %s.%s )', _item_num, _alias, _filter_type );
			elsif _condition = 6 then -- не равно
				return format( '%L != all( %s.%s )', _item_num, _alias, _filter_type );
			end if;
		else -- если тип значения в таблице - не массив
			if _condition = 1 then -- равно
				return format( '%s.%s = %L', _alias, _filter_type, _item_num );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != %L', _alias, _filter_type, _item_num );
			elsif _condition = 2 then -- больше или равно
				return format( '%s.%s >= %L', _alias, _filter_type, _item_num );
			elsif _condition = 3 then -- меньше или равно
				return format( '%s.%s <= %L', _alias, _filter_type, _item_num );
			elsif _condition = 4 then -- больше
				return format( '%s.%s > %L', _alias, _filter_type, _item_num );
			elsif _condition = 5 then -- меньше
				return format( '%s.%s < %L', _alias, _filter_type, _item_num );
			end if;
		end if;
        
    -- тип значения в фильтре - текст
	elsif _select_type = 'tr_text' then
	    -- преобразовать значение
		_item_text = pdb_val_text( _val, null );
	
		if _item_text is null then
        -- пропустить проверку		
		elsif _array = true then  -- если тип значения в таблице - массив
			if _condition = 1 then -- равно 
				return format( '%L = any( %s.%s )', _item_text, _alias, _filter_type );
			elsif _condition = 6 then -- не равно
				return format( '%L != all( %s.%s )', _item_text, _alias, _filter_type );
			end if;
		else -- если тип значения в таблице - не массив
			if _condition = 1 then -- равно
				return format( '%s.%s = %L', _alias, _filter_type, _item_text );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != %L', _alias, _filter_type, _item_text );
			elsif _condition = 7 then -- подстрока text*
				_item_text = concat( _item_text, '%' );
				return format( '%s.%s ilike %L', _alias, _filter_type, _item_text );
			elsif _condition = 8 then -- подстрока *text
				_item_text = concat( '%', _item_text );
				return format( '%s.%s ilike %L', _alias, _filter_type, _item_text );
			elsif _condition = 9 then -- подстрока *text*
				_item_text = concat( '%', _item_text, '%' );
				return format( '%s.%s ilike %L', _alias, _filter_type, _item_text );
			end if;
		end if;
        
    -- тип значения в фильтре - адрес dadata
	elsif _select_type = 'tr_dadata_adr' then
    -- адреса местоположения
		_val = _val #>> '{json,data}';
		_item_text = COALESCE(	
					_val #>> '{street_fias_id}',		-- улица
					_val #>> '{settlement_fias_id}',	-- населенный пункт
					_val #>> '{city_district_fias_id}',	-- район города
					_val #>> '{city_fias_id}',			-- город
					_val #>> '{area_fias_id}',			-- район в регоне
					_val #>> '{region_fias_id}'			-- регион
				); -- получить id адреса

		if _item_text is null then
    -- пропустить проверку		
		elsif _array = true then  -- если тип значения в таблице - массив
			if _condition = 1 then -- равно
				return format( '%L = any( %s.%s )', _item_text, _alias, _filter_type );
			elsif _condition = 6 then -- не равно
				return format( '%L != all( %s.%s )', _item_text, _alias, _filter_type );
			end if;
		else -- если тип значения в таблице - не массив
			if _condition = 1 then -- равно
				return format( '%s.%s = %L', _alias, _filter_type, _item_text );
			elsif _condition = 6 then -- не равно
				return format( '%s.%s != %L', _alias, _filter_type, _item_text );
			end if;
		end if;
	end if;    
    
	return null;
	
end;
$$;

create function elbaza.p30436_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
--=================================================================================================
-- Формирует дерево для списков и обрабатывает его события
--=================================================================================================

declare 
	_name_tree text		= 'tree'; -- название инклюда дерева
    -- система	
  	_event text			= pdb2_event_name( _name_mod ); -- событие модуля
    -- поле поиска
  	_find_text text;

  	_placeholder jsonb; -- placeholder для дерева
 	_parent integer;    -- родитель элемента в дереве
	
	_name_table text;   -- название таблицы, в котором хранится структура дерева
	_name_table_children text;  -- название таблицы, в котором хранится информация о сортировке
	_idtree integer;    -- id элемента в дереве
	_cmd_socket jsonb;  -- команды для сокета
    _type text;         -- тип элемента в дереве

begin
    -- получить название таблицы дерева
 	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
    -- получить название таблицы сортировки
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
    -- получить название инклюда для поиска
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;
    -- получить текст поиска
  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );
    
    -- обработка событий
	if pdb2_event_name() = 'submit' then
        _idtree = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' ); -- получить id выделенного элемента в дереве
        select type into _type from t30436 where idkart = _idtree;  -- получить тип выделенного элемента в дереве
        if _type <> 'folder_spiski' then                            
            perform p30436_update_list( _idtree, _type ); -- обновить список
        end if;
    elseif pdb2_event_name() = 'websocket' then 
    -- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p30436_tree_view( null, null, a.value::integer, _name_table, _name_table_children )
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a;		
		if _cmd_socket is not null then
            -- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
            -- установить информацию по бланкам - НЕ ПРОРАБОТАНО
            -- perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		end if;
    end if;
    
    if _event = 'create' then
        -- добавить ветку
		perform p30436_create( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
		
	elsif _event = 'move' then
        -- перемешение ветки
		perform p30436_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then

        -- переименование ветки
		perform pdb2_tpl_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'duplicate' then

        -- дублировать ветку
		perform p30436_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then
        -- удаление ветки
		perform p30436_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
    
	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );

        -- добавить корень дерева	
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
		execute format( '
			insert into %I( parent, type, name, "on" )
			select 0, a.value ->> ''type'', a.value ->> ''text'', 1
			from jsonb_array_elements( $1 ) as a
			left join %I as b on (a.value ->> ''type'') = b.type
			where (a.value ->> ''type'') like ''root_%%'' and b.idkart is null;', _name_table, _name_table )
		using _placeholder;
		
        -- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );

	elsif _event in ( 'selected', 'opened' ) then

        -- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		return null;
		
	elsif _event = 'refresh' then
	
        -- получить переменые
		_parent = pdb2_val_api_text( '{post,id}' );
        -- список веток		
		_placeholder = p30436_tree_view( null, null, _parent, _name_table, _name_table_children );
        -- ветки
		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'children' then
	
        -- получить переменые
		_parent = pdb2_val_api_text( '{post,parent}' );
        -- список веток		
		_placeholder = p30436_tree_view( _parent, _find_text, null, _name_table, _name_table_children );
        -- ветки
		perform pdb2_return( _placeholder );
		return null;

	elsif _event = 'values' then
	
        -- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;

    -- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
    -- собрать root
	_placeholder = p30436_tree_view( 0, _find_text, null, _name_table, _name_table_children );
    -- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
    -- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
    -- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
    -- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
    -- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
    -- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;
							
	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

create function elbaza.p30436_tree_duplicate(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Дублирует элемент дерева и всю ветку данного элемента. При дублировании списка - дублирует также
-- его фильтр. При дублировании другого элемента, обновляет фильтр списка
--=================================================================================================
declare
 	_pdb_userid	integer	= pdb2_current_userid(); -- текущий пользователь
 	_after integer;     -- idkart исходного элемента
    _idkart integer;    -- idkart копии
  	_placeholder jsonb;	-- placeholder для нового элемента дерева
	_parent integer;    -- папка, в которой находится исходный элемент
	_children jsonb;    -- все элементы папки, в которой находится исходный элемент
	_cn integer;        -- count, для проверки наличия элемента в таблице
    _data_filter_old jsonb; -- фильтр списка в котором находится исходный элемент
    _data_filter_new jsonb = '{}'; -- новый фильтр списка с копиями
    _data_filter_item jsonb;
    _type text;         -- тип исходного элемента
    _list_id_new int;   -- id нового списка (при дублировании списка)
    _rc record;         
    _idkart_matches jsonb; -- словарь соответствий после дублирования (idkart_исходн. : idkart_копии)
    _filter_id text;    -- id для фильтра
    _filter_parent text; -- parent для фильтра
    
begin
-- получить переменые
	_parent = pdb2_val_api_text( '{post,parent}' );
 	_children = pdb2_val_api( '{post,children}' );
	_after = pdb2_val_api_text( '{post,id}' );
    -- дублировать запись
    -- очистить сессию, для сохранения соответствий между id оригинала и дубликата
    perform pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}', null);
    -- сохранить копию и получить id скопированной записи
    _idkart = p30436_tree_duplicate_copy( _after, null, _name_table, _name_table_children );
    -- соответствия id (id_оригинала : id_копии) 
    _idkart_matches = pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}');
    
    -- получить фильтр исходного элемента
    select data_filter into _data_filter_old from t30436_data_spisok where userid = _pdb_userid and data_filter ? _after::text;
    -- получить тип исходного элемента
    select type into _type from t30436 where idkart = _idkart; 
    
    -- сформировать новый фильтр для копии
    if _type = 'item_spisok' then
        _list_id_new = _idkart; 
        -- получить все значения из старого фильтра, обновив id и parent на новые
        for _rc in 
            select a.key, a.value from jsonb_each(_data_filter_old) as a
            order by a.key 
        loop
            if _rc.value ->> 'type' = 'root_spiski' then
                _data_filter_new = jsonb_build_object(_rc.key, _rc.value);
            else
                _filter_id = coalesce(_idkart_matches ->> _rc.key::text, _rc.key::text); 
                _filter_parent = coalesce(_idkart_matches ->> (_rc.value ->> 'parent'), (_rc.value ->> 'parent')); 
                _rc.value = pdb_val(_rc.value, array['id'], _filter_id);
                _rc.value = pdb_val(_rc.value, array['parent'], _filter_parent);
                _rc.value = pdb_val(_rc.value, array['on'], null);
                _data_filter_new = _data_filter_new || jsonb_build_object(_filter_id, _rc.value);
            end if;
        end loop;
    elseif _type ~* 'item' then
        -- при дублировании элементов списка, добавить текущий фильтр копию этого элемента
        _list_id_new = (select idkart from t30436_data_spisok where userid = _pdb_userid and data_filter ? _after::text);
        _data_filter_new = _data_filter_old || jsonb_build_object(_idkart, pdb_val(_data_filter_old -> _after::text, array['id'], _idkart)); 
    end if;
    -- сохранить новый фильтр
    update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new; 
    -- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _idkart );
    -- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    -- проверка записи
	select count(*) from t30436_children as a where a.idkart = _parent into _cn;
    
	if _cn > 0 then
    -- изменить позцию позиции
		update t30436_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent;
	else
    -- установить позицию
		insert into t30436_children( idkart, children ) values ( _parent, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
    -- получить новую ветку		
	_placeholder = p30436_tree_view( null, null, _idkart, _name_table, _name_table_children );	
    -- установить информацию по бланкам
	perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
    -- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent );	
    -- новая ветка
	perform pdb2_return( _placeholder );
	
end;
$$;

create function elbaza.p30436_tree_duplicate_copy(_idkart integer, _parent integer, _name_table text, _name_table_children text) returns integer
    language plpgsql
as
$$
--=================================================================================================
-- Вставляет в таблицу копию исходного элемента и всех дочерних элементов, сохраняет в сессии  
-- соответствие ключей исходных элементов и их копий
--=================================================================================================

declare
    _pdb_userid integer = pdb_current_userid(); -- id текущего пользователя
    
	_new_parent integer;    -- idkart копии после вставки в таблицу 
	_all_parent integer[];  -- массив idkart всех копий, вложенных в текущего родителя
    _idkart_matches jsonb;  -- словарь соответствий всех исходных idkart и копий
    
begin
	-- вставить копию текущей записи в таблицу и вернуть idkart
    insert into t30436( userid, parent, type, name, description, property_data )
    select _pdb_userid, COALESCE( _parent, a.parent ), a.type, concat( a.name, ' - копия' ),
        a.description, a.property_data
    from t30436 as a where a.idkart = _idkart
    returning idkart
	into _new_parent;
	
    -- добавить в словарь пару ключ-значение
    _idkart_matches = pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}');
    if _idkart_matches is null then
        _idkart_matches  =  jsonb_build_object(_idkart, _new_parent);
    else    
        _idkart_matches = _idkart_matches || jsonb_build_object(_idkart, _new_parent);
    end if;
    -- сохранить в сессии
    perform pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}', _idkart_matches);
    
    -- повторить действие для всех дочерних элементов
    select array_agg( a.new_parent )
    from (
        select p30436_tree_duplicate_copy( a.idkart, _new_parent, _name_table, _name_table_children) as new_parent
        from t30436 as a
        left join t30436_children as mn on a.parent = mn.idkart
        left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
        where a.dttmcl is null and a.parent = _idkart
        order by srt.sort NULLS FIRST, a.idkart desc
    ) as a
	into _all_parent; 
	
    -- вернуть idkart копии исходного элемента
	return _new_parent;

end;
$$;

create function elbaza.p30436_tree_move(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Обновляет таблицу дерева и фильтр списка при перемещении элементов в дереве
-- возможно перемещение папок внутри списка, между списками и папок пользователя
--=================================================================================================

declare 
 	_pdb_userid	integer	= pdb_current_userid(); -- текущий пользователь

  	_idkart integer;     -- id перемещенного элемента
	_parent_new integer; -- id папки куда переместили
	_parent_old integer; -- id папки откуда переместили
 	_children jsonb;     -- список id всех элементов папки, куда переместили элемент (с учетом перемещенного)
	_cn integer;         -- count, для проверки наличия записи в таблице
    _list_id_old int;    -- id списка, откуда переместили элемент
	_list_id_new int;    -- id списка, куда переместили элемент
    
    _item_filter jsonb; 
    _data_filter_old jsonb; -- фильтр списка, из которого переместили элемент
    _data_filter_new jsonb; -- фильтр списка, в который переместили элемент
    _type text;
    
begin
    -- получить переменные
	_idkart = pdb2_val_api_text( '{post,id}' );
	_parent_new = pdb2_val_api_text( '{post,parent}' );
	_children = pdb2_val_api( '{post,children}' );
    
    -- получить родителя, откуда переместили элемент
	select a.parent, a.type from t30436 as a where a.idkart = _idkart into _parent_old, _type;
    -- смена родителя
	update t30436 set dttmup = now(), parent = _parent_new where idkart = _idkart;
    -- проверка записи
	select count(*) from t30436_children as a where a.idkart = _parent_new into _cn;
	if _cn > 0 then
    -- изменить позцию позиции
		update t30436_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_new;
	else
    -- установить позицию
		insert into t30436_children( idkart, children ) values ( _parent_new, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
    
    -- при перемещении самих списков и папок со списками фильтры не меняются, в остальных случаях обновить оба фильтра
    if _type not in ('item_spisok', 'folder_spiski') then
        -- получить id нового списка и его фильтр
        select idkart, data_filter into _list_id_new, _data_filter_new from t30436_data_spisok where userid = _pdb_userid and data_filter ? _parent_new::text;
        
        -- получить id старого списка и его фильтр
        select idkart, data_filter into _list_id_old, _data_filter_old from t30436_data_spisok where userid = _pdb_userid and data_filter ? _parent_old::text;
        
        -- если перемещение внутри списка, обновить родителя
        if _list_id_new = _list_id_old then
            _data_filter_new = pdb_val( _data_filter_new, array[_idkart::text, 'parent'], _parent_new );
            update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new;
        else
        -- если перемещение между списками обновить оба фильтра: удалить перемещенную ветку из старого списка и добавить в новый
            with recursive temp1 ( id, val ) as  -- обновить новый фильтр
            (
                select _idkart::text, _data_filter_old -> _idkart::text
                union all
                select a.key, a.value
                from jsonb_each( _data_filter_old ) as a
                inner join temp1 as t on a.value ->> 'parent' = t.id
            )
            select jsonb_object_agg(a.id, a.val) into _item_filter
            from temp1 as a;
            -- обновить родителя в фильтре
            _item_filter = pdb_val( _item_filter, array[_idkart::text, 'parent'], _parent_new );
            -- добавить в новый фильтр
            _data_filter_new = _data_filter_new || _item_filter; 

            with recursive temp1 ( id ) as -- обновить старый фильтр
            (
                select _idkart::text
                union all
                select a.key
                from jsonb_each( _data_filter_old ) as a
                inner join temp1 as t on a.value ->> 'parent' = t.id
            )
            select jsonb_object_agg( a.key, a.value ) into _data_filter_old
            from jsonb_each( _data_filter_old ) as a
            left join temp1 as t on a.value ->> 'id' = t.id
            where t.id is null;

            -- сохранить старый фильтр
            update t30436_data_spisok set data_filter = _data_filter_old where idkart = _list_id_old;
            -- сохранить новый фильтр
            update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new;
        end if;
	end if;
    
    -- подготвить данные для сокета - обновить родителя	
	if _parent_new = _parent_old then
		perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_new );	
	else
    -- проверка вложенности _parent_old в _parent
        with recursive temp1 ( parent ) as  -- получить всех родителей parent_new
        (	
            select a.parent
            from t30436 as a
            where a.idkart = _parent_new
            union all
            select a.parent
            from t30436 as a
            inner join temp1 as t on a.idkart = t.parent
        )
        select count(*) from temp1 as a
        where a.parent = _parent_old
        into _cn;
        
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_old );
			return;
		end if;
-- проверка вложенности _parent в _parent_old
        with recursive temp1 ( parent ) as 
        (	
            select a.parent
            from t30436 as a
            where a.idkart = _parent_old
            union all
            select a.parent
            from t30436 as a
            inner join temp1 as t on a.idkart = t.parent
        )
        select count(*) from temp1 as a
        where a.parent = _parent_new
		into _cn;
        
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_new );
			return;
		end if;
-- обновить оба родителя 
		perform pdb2_val_page( '{pdb,socket_data,ids}', array[ _parent_new, _parent_old ] );	
	end if;
end;
$$;

create function elbaza.p30436_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
--=================================================================================================
-- Отображает модуль "Свойства объекта" для выделенного элемента дерева
--=================================================================================================
declare 
	_include text			= pdb2_event_include( _name_mod ); -- название инклюда, вызвавшего событие
	_event text				= pdb2_event_name( _name_mod ); -- название события

	_tree_mod text;     -- название модуля дерева
	_tree_inc text;     -- название инклюда дерева
	_tree_view text;    -- название модуля свойства
	_tree_idkart integer; -- idkart выделенного элемента в дереве
	_tree_b_submit integer; -- значение кнопки b_submit
	_name_table text;   -- название таблицы дерева
	_name_table_children text; -- название таблицы с children элементами

begin
    -- получить данные по дереву
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );
    
    -- получить данные по свойству
	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_tree_idkart = pdb2_val_session_text( _tree_mod, '{idkart}' );
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
    -- установить таблицу на изменение
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
    -- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
    -- если модуль скрыт - выход
		return null;
	end if;

    -- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _tree_idkart );

    -- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then		-- кнопка "Изменить"	
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then    -- кнопка "Отменить"
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then

        -- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
        -- обновить дерево
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', p30436_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
									]
							);
        -- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _tree_idkart );	
						
		_tree_b_submit = 0;

	end if;

	if _tree_b_submit = 0 then
		
        -- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
        -- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );

	else
        -- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
    -- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );
	
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

create function elbaza.p30436_tree_remove(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Удаляет элемент в дереве и удаляет всю его ветку в фильтре списка
--=================================================================================================
declare 
 	_pdb_userid	integer	= pdb_current_userid(); -- текущий пользователь

  	_idkart integer; -- idkart удаленного элемента в таблице дерева   
  	_parent integer; -- parent удаленного элемента в таблице дерева 
  	_idkart_old integer; -- id выделенного элемента в дереве
    _list_id int;   -- список в котором находится удаленный элемент дерева
    _data_filter jsonb; -- фильтр списка
    
begin
    -- получить переменые
	_idkart = pdb2_val_api_text( '{post,id}' );
    -- удаление ветки
	update t30436 set dttmcl = now() where idkart = _idkart returning parent into _parent;
    -- получить id выделенного элемента в дереве
	_idkart_old = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	if _idkart = _idkart_old then -- если удаляется выделенный элемент
    -- убрать позицию
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
	end if;
    
    -- получить id списка
    select idkart, data_filter into _list_id, _data_filter from t30436_data_spisok where userid = _pdb_userid and data_filter ? _idkart::text;
    
    -- удалить из фильтра ветку
    with recursive temp1 ( id ) as 
    (
        select _idkart::text
        union all
        select a.key
        from jsonb_each( _data_filter ) as a
        inner join temp1 as t on a.value ->> 'parent' = t.id
    )
    select jsonb_object_agg( a.key, a.value ) into _data_filter
    from jsonb_each( _data_filter ) as a
    left join temp1 as t on a.value ->> 'id' = t.id
    where t.id is null;
    
    -- обновить список
    update t30436_data_spisok set data_filter = _data_filter where idkart = _list_id;
    
    -- установить информацию по бланкам
	perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
    -- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent );	
		
end;
$$;

create function elbaza.p30436_tree_share_copy(_idkart integer, _parent integer, _list_name text, _pdb_userid integer) returns integer
    language plpgsql
as
$$
--=================================================================================================
-- При нажатии кнопки "Поделиться списком" копирует все элементы списка в таблице дерева под новым
-- userid. Сохраняет в сессии соответствие ключей исходных элементов и их копий
--=================================================================================================
declare
    
	_new_parent integer;    -- idkart копии после вставки
	_all_parent integer[];  -- массив из idkart копий всех элементов текущего родителя
    _idkart_matches jsonb;  -- словарь соответствий idkart исходных элементов и их копий
    
begin

	-- вставить копию записи в таблицу дерева под новым userid
    insert into t30436( userid, parent, type, name, "on", description, property_data )
    select _pdb_userid, COALESCE( _parent, a.parent ), a.type, coalesce(_list_name, a.name),
        a."on", a.description, a.property_data
    from t30436 as a where a.idkart = _idkart
    returning idkart
	into _new_parent;
	
    -- добавить в словарь соответствие старого и нового ключа
    _idkart_matches = pdb2_val_session('p30436_form', '{idkart_matches}');
    if _idkart_matches is null then
        _idkart_matches  =  jsonb_build_object(_idkart, _new_parent);
    else    
        _idkart_matches = _idkart_matches || jsonb_build_object(_idkart, _new_parent);
    end if;
    -- сохранить в сессию
    perform pdb2_val_session('p30436_form', '{idkart_matches}', _idkart_matches);
    
    -- выполнить действие для всех дочерних элементов
    select array_agg( a.new_parent )
    from (
        select p30436_tree_share_copy( a.idkart, _new_parent, null, _pdb_userid) as new_parent
        from t30436 as a
        left join t30436_children as mn on a.parent = mn.idkart
        left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
        where a.dttmcl is null and a.parent = _idkart
        order by srt.sort NULLS FIRST, a.idkart desc
    ) as a
	into _all_parent; 
    
    -- вернуть idkart нового списка
	return _new_parent;

end;
$$;

create function elbaza.p30436_tree_view(_parent integer, _name_find text, _idkart integer, _name_table text, _name_table_children text) returns jsonb
    language plpgsql
as
$$
--=================================================================================================
-- Формирует placeholder из дочерних элементов выбранного родителя. 
-- При передаче параметра idkart формирует объект data с параметрами для task-а 
-- _parent - idkart родителя в таблице дерева
-- _name_find - текст в поле для поиска
-- _idkart - idkart элемента в таблице дерева
--=================================================================================================
declare
    _pdb_userid	integer	= pdb2_current_userid(); -- текущий пользователь
	_rc record;
	_placeholder jsonb[]; -- placeholder с массивом всех дочерних элементов текущего элемента
	_cn_all integer;      -- количество вложенных элементов 
	_cn_catalog integer;  -- 1 - у элемента есть вложенные элементы, null - нет
	
begin
    -- создать временную таблицу для хранения записей
	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;
    
    -- получает все дочерние элементы для parent, и вставляет их во временную таблицу
    -- если передан idkart вставляет в таблицу элемент с указанным idkart
    -- показывает только элементы, созданные текущим пользователем либо корневую папку, если таких элементов нет 
    insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
    select a.idkart, a.name, a.type, a.parent, a.on
    from t30436 as a
    left join t30436_children as mn on a.parent = mn.idkart
    left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
    where a.dttmcl is null 
        and (a.userid = _pdb_userid or a.parent = 0)
        and (
            _idkart is null and ( a.parent = _parent or _parent = 0 and a.parent = 0 )
            or a.idkart = _idkart
        )
    order by srt.sort NULLS FIRST, a.idkart desc; 
    
    -- для всех элементов во временной таблице, собирает idkart его ветки в дереве
    -- ищет элементы, у которых наименование совпадает с _name_find (если оно не null)
    -- формирует placeholder если количество вложенных элементов > 0
	for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
		
	loop
        -- условие поиска
        with recursive temp1( idkart, ok ) as 
        (
            select a.idkart,
                case when 
                    _name_find is null or 
                    a.name ~* _name_find and a.type not like '%folder%'
                then true end
            from t30436 as a
            where a.dttmcl is null and a.idkart = _rc.idkart
            union
            select a.idkart,
                case when 
                    temp1.ok = true or 
                    a.name ~* _name_find and a.type not like '%folder%'
                then true end
            from t30436 as a
            inner join temp1 on temp1.idkart = a.parent
            where a.dttmcl is null
        )
        select count(*), max( case when a.idkart <> _rc.idkart then 1 end )
        from temp1 as a where a.ok = true
		into _cn_all, _cn_catalog;
				
        -- ветка по условию поиска не подходит
		continue when _cn_all = 0;
        -- добавить ветку		
		_placeholder = _placeholder || 
				jsonb_build_object(
					'id', _rc.idkart,
 					'parent', _rc.parent,
 					'text', _rc.name,
 					'type', _rc.type,
					'children', _cn_catalog,   
					'theme', case when _rc.on = 1 then null else 5 end  -- выделяет красным
				);

	end loop;
	
	drop table _tmp_pdb2_tpl_tree_view; 
					
	return to_jsonb( _placeholder );

end;
$$;

create function elbaza.p30436_update_list(_idkart integer, _type text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Обновляет фильтр списка при изменении элементов в таблице дерева или значений в property_data
--=================================================================================================

declare 
 	_pdb_userid	integer	= pdb_current_userid(); -- текущий пользователь

    _data_filter jsonb;     -- обновляемый фильтр списка
    _item_filter jsonb = '{}';
    _property_data jsonb;   -- данные обновленного элемента в дереве из поля property_data
    _data_types jsonb	 = p30436_list_types(); -- описание типов элементов списка и их фильтров
    _list_id int;           -- id списка
    _rc record;             -- переменная для цикла
    _filter_type text;      -- тип фильтра (Наименование, РИЦ, Метка и т.д.)
    _select_type text;      -- тип значения в фильтре (множественный селект, одиночный селект, текст, дата и др)
    _meaning jsonb;         -- значение фильтра
    _condition jsonb;       -- оператор (=, !=, >, < и др.)
    _array int;             -- тип значения в таблице, true = массив, false - не массив
    _parent int;            -- значение parent измененного элемента
    _on int;                -- значение on измененного элемента
    _level int;             -- значение level измененного элемента
    
begin
    -- получить id списка, в котором находится измененный элемент и его фильтр
    select idkart, data_filter into _list_id, _data_filter from t30436_data_spisok where userid = _pdb_userid and data_filter ? _idkart::text;
    -- получить данные по измененному элементу
    select property_data, parent, "on" into _property_data, _parent, _on from t30436 where idkart = _idkart;
    -- обновить значения фильтра 
    if _type ~* 'item' then
        for _rc in 
            select a.value, regexp_replace(a.key, '\D', '', 'g') as num
            from jsonb_each_text(_property_data) as a
            where a.key ~* '^on_' and a.value = '1' -- выбрать только включенные фильтры
        loop
            _meaning = _property_data -> ('meaning_'||_rc.num); -- пропустить, если не установлено значение
            continue when _meaning is null; 
            
            _filter_type = _data_types #>> array[_type, _rc.num, 'filter_type']; -- тип фильтра (РИЦ, метка, статус и др.)
            _select_type = _data_types #>> array[_type, _rc.num, 'select_type']; -- тип выбора (текст, селект, дата и др.)
            _array = _data_types #>> array[_type, _rc.num, 'array']; -- массив или нет
            _condition = _property_data -> ('condition_'||_rc.num); -- тип оператора (=, !=, > < и др)
            _level = _property_data ->> 'level';                    -- уровень для меток, статусов, менеджеров
            _item_filter = _item_filter || jsonb_build_object(_filter_type, jsonb_build_object(
                                                              'select_type', _select_type,
                                                              'array', _array,
                                                              'meaning', _meaning,
                                                              'condition', _condition));
        end loop;
    end if;
    -- если изменены значения фильтров
    if _item_filter <> '{}' then
        _item_filter = jsonb_build_object('id', _idkart, 'type', _type, 'on', _on, 'parent', _parent, 'level', _level, 'filters', _item_filter);
    else -- если изменены только общие поля
        _item_filter = jsonb_build_object('id', _idkart, 'type', _type, 'on', _on, 'parent', _parent, 'level', _level);
    end if;
    -- обновить фильтр
    _data_filter = jsonb_set(_data_filter, array[_idkart::text], _item_filter);
    
    -- обновить список
    update t30436_data_spisok set data_filter = _data_filter where idkart = _list_id; 
end;
$$;

create function elbaza.t17427_data_forma_obucheniya_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t17427 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t17427 as a
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
		a.property_data ->> 'sort_form'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name_form,
		NEW."group",
		NEW.description,
		NEW.sort_form
	from t17427 as a
	left join t17427 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t17427_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t17427 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t17427 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_forma_obucheniya' then
				update t17427_data_forma_obucheniya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t17427_data_forma_obucheniya( idkart ) values( _rc.idkart );
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t17427 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t17427_children where idkart = OLD.idkart;
	delete from t17427_data_forma_obucheniya where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t17428_data_adresa_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t17428 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t17428 as a
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
		a.parent,
		a.property_data ->> 'address',
		a.property_data -> 'address_dt',
		a.property_data -> 'info',
		a.property_data -> 'address_list'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.parent,
		NEW.address,
		NEW.address_dt,
		NEW.info,
		NEW.address_list
	from t17428 as a
	left join t17428 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t17428_data_mestoraspolozheniye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t17428 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t17428 as a
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
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t17428 as a
	left join t17428 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t17428_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t17428 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t17428 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_mestoraspolozheniye' then
				update t17428_data_mestoraspolozheniye set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t17428_data_mestoraspolozheniye( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_adresa' then
				update t17428_data_adresa set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t17428_data_adresa( idkart ) values( _rc.idkart );
				end if;
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t17428 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t17428_children where idkart = OLD.idkart;
	delete from t17428_data_mestoraspolozheniye where idkart = OLD.idkart;
	delete from t17428_data_adresa where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t17429_data_vid_meropriyatiya_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t17429 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t17429 as a
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
		a.property_data ->> 'code_cond',
		a.property_data ->> 'cost_market',
		a.property_data ->> 'is_children'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.code_cond,
		NEW.cost_market,
		NEW.is_children
		
		
	from t17429 as a
	left join t17429 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t17429_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t17429 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t17429 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_vid_meropriyatiya' then
				update t17429_data_vid_meropriyatiya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t17429_data_vid_meropriyatiya( idkart ) values( _rc.idkart );
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t17429 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t17429_children where idkart = OLD.idkart;
	delete from t17429_data_vid_meropriyatiya where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t17430_data_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t17430 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t17430 as a
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
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t17430 as a
	left join t17430 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t17430_filtr_iu() returns trigger
    language plpgsql
as
$$
declare
	_link_table text;
	_ids_polzovateley integer[];
	_date_b date; 
	_date_e date; 
	_limit_obyekt_logirovaniya integer;
	_ids_obyekt_logirovaniya integer[];
begin
 
	if NEW.type = 'item_filtr' and NEW.dttmcl is null then
	
-- взять имя таблицы
		select a.link_table into _link_table
		from t17430 as a where a.idkart = NEW.parent;
-- получение данных по условию	
		-- пользователи
		_ids_polzovateley = pdb_sys_jsonb_to_int_array( NEW.property_data -> 'ids_polzovateley' );
		-- записи		
		_ids_obyekt_logirovaniya = pdb_sys_jsonb_to_int_array( NEW.property_data -> 'ids_obyekt_logirovaniya' );
		-- даты
		_date_b = NEW.property_data #>> '{period,0}';
		_date_e = NEW.property_data #>> '{period,1}';
		-- лимит
		_limit_obyekt_logirovaniya =  NEW.property_data ->> 'limit_obyekt_logirovaniya';
		_limit_obyekt_logirovaniya = COALESCE( _limit_obyekt_logirovaniya, 100 );
		
		if _ids_polzovateley is null and _ids_obyekt_logirovaniya is null and _date_b is null and _date_e is null then
			return NEW;
		end if;
		
		create local temp table _tmp_t17430_filtr_iu on commit drop as
			select _link_table as link_table, a.link_idkart
			from t17430_log as a
			where a.link_table = _link_table
				and (_ids_polzovateley is null or a.userid = any( _ids_polzovateley ) )
				and (_ids_obyekt_logirovaniya is null or a.link_idkart = any ( _ids_obyekt_logirovaniya) )
				and (_date_b is null or a.dttmcr >= _date_b)
				and (_date_e is null or a.dttmcr <= _date_e)
			group by a.link_idkart
			limit _limit_obyekt_logirovaniya;
-- закрыть звписи		
		update t17430 set dttmcl = now()
		where t17430.dttmcl is null
			and t17430.parent = NEW.idkart
			and not EXISTS (
				select a.link_idkart
				from _tmp_t17430_filtr_iu as a
				where t17430.link_table = a.link_table
					and t17430.link_idkart = a.link_idkart
			);
-- востановить закрытые если есть
		update t17430 set dttmcl = null, dttmup = now()
		from (
			select a.link_table, a.link_idkart, max( a.idkart ) as idkart
			from t17430 as a
			inner join _tmp_t17430_filtr_iu as b on
				a.link_table = b.link_table
				and a.link_idkart = b.link_idkart
			where a.parent = NEW.idkart
			group by a.link_table, a.link_idkart		
		) as a
		where t17430.dttmcl is not null
			and t17430.idkart = a.idkart;			
-- добавить записи 
		insert into t17430( parent, type, "on", name, link_table, link_idkart )
		select 
			NEW.idkart, 'item_obyekt_logirovaniya' as "type", 1 as "on", 
			concat( a.link_table, ' - ', a.link_idkart ) as "name", a.link_table, a.link_idkart
		from _tmp_t17430_filtr_iu as a
		left join t17430 as b on
			b.dttmcl is null
			and b.parent = NEW.idkart
			and b.link_table = a.link_table
			and b.link_idkart = a.link_idkart
		where b.idkart is null
		order by a.link_idkart desc;
		
		drop table _tmp_t17430_filtr_iu;
		
	end if;

	return NEW;

end;
$$;

create function elbaza.t17430_iu_bef() returns trigger
    language plpgsql
as
$$
begin
 
 	if NEW.name is null then
		NEW.name = NEW.link_table;
	end if;

	return NEW;
	
end;
$$;

create function elbaza.t17430_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t17430 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart ) as 
			(
				select NEW.idkart
				union all
				select a.idkart from t17430 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart
			from temp1 as t
		loop

			update t17430_data set idkart = idkart where idkart = _rc.idkart
			returning idkart into _iddata;

			if _iddata is null then
				insert into t17430_data( idkart ) values( _rc.idkart );
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t17430 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t17430_children where idkart = OLD.idkart;
	delete from t17430_data where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t17430_log_iu() returns trigger
    language plpgsql
as
$$
declare 
	_parent integer;
begin

	if (select count(*) from t17430 as a where a.link_table = NEW.link_table and a.type = 'item_tablitsa' ) = 0 then
		select a.idkart into _parent
		from t17430 as a
		where a.dttmcl is null
			and a.type = 'root_tablitsa';
		insert into t17430( parent, type, "on", name, link_table )
		values ( _parent, 'item_tablitsa', 1, NEW.link_table, NEW.link_table );
	end if;

	return NEW;
	
end;
$$;

create function elbaza.t18207_data_firmy_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18207 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18207 as a
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
		a.parent,
		a.property_data ->> 'kd',
		a.property_data ->> 'off_saldo',
		a.property_data -> 'header_image'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.parent,
		NEW.kd,
		NEW.off_saldo,
		NEW.header_image
	from t18207 as a
	left join t18207 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18207_data_rekvizity_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18207 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18207 as a
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
		a.parent,
		a.property_data ->> 'date_beg',
		a.property_data ->> 'date_end',
		a.property_data -> 'header_image'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.parent,
		NEW.date_beg,
		NEW.date_end,
		NEW.header_image
	from t18207 as a
	left join t18207 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18207_data_ritz_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18207 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18207 as a
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
		a.property_data ->> 'kd'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.kd
	from t18207 as a
	left join t18207 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18207_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t18207 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t18207 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_ritz' then
				update t18207_data_ritz set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18207_data_ritz( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_rekvizity' then
				update t18207_data_rekvizity set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18207_data_rekvizity( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_firmy' then
				update t18207_data_firmy set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18207_data_firmy( idkart ) values( _rc.idkart );
				end if;
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t18207 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t18207_children where idkart = OLD.idkart;
	delete from t18207_data_ritz where idkart = OLD.idkart;
	delete from t18207_data_rekvizity where idkart = OLD.idkart;
	delete from t18207_data_firmy where idkart = OLD.idkart;

	return OLD;
end;
$$;

create function elbaza.t18260_data_funktsional_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18260 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18260 as a
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
		a.parent,
		a.property_data ->> 'is_content'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.parent,
		NEW.is_content
	from t18260 as a
	left join t18260 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18260_data_napravleniye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18260 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18260 as a
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
		a.property_data ->> 'dir_code'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.dir_code
	from t18260 as a
	left join t18260 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18260_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t18260 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t18260 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_funktsional' then
				update t18260_data_funktsional set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18260_data_funktsional( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_napravleniye' then
				update t18260_data_napravleniye set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18260_data_napravleniye( idkart ) values( _rc.idkart );
				end if;
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t18260 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t18260_children where idkart = OLD.idkart;
	delete from t18260_data_funktsional where idkart = OLD.idkart;
	delete from t18260_data_napravleniye where idkart = OLD.idkart;

	return OLD;
end;
$$;

create function elbaza.t18311_data_gruppa_okopf_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18311 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18311 as a
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
		a.property_data -> 'kd_okpf_list',
		a.property_data ->> 'is_content'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.kd_okpf_list,
		NEW.is_content
	from t18311 as a
	left join t18311 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18311_data_okopf_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18311 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18311 as a
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
		a.property_data ->> 'code',
		a.property_data ->> 'info'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.code,
		NEW.info
	from t18311 as a
	left join t18311 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18311_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t18311 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart,a.type from t18311 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type in ( 'item_tip_opf', 'item_vid_opf', 'item_razdel_okopf' ) then
				update t18311_data_okopf set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18311_data_okopf( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_gruppa_okopf' then
				update t18311_data_gruppa_okopf set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18311_data_gruppa_okopf( idkart ) values( _rc.idkart );
				end if;
			end if;
	
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t18311 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t18311_children where idkart = OLD.idkart;
	delete from t18311_data_okopf where idkart = OLD.idkart;
	delete from t18311_data_gruppa_okopf where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t18362_data_gruppa_okved_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18362 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18362 as a
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
		a.property_data -> 'kd_okveds_list',
		a.property_data ->> 'is_content'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.kd_okveds_list,
		NEW.is_content
	from t18362 as a
	left join t18362 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18362_data_okved_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18362 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18362 as a
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
		a.type,
		a.property_data ->> 'code',
		a.property_data ->> 'info'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.type,
		NEW.code,
		NEW.info
	from t18362 as a
	left join t18362 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18362_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t18362 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t18362 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type in ('item_razdel_okved', 'item_podrazdel_okved', 'item_okved_uroven_1', 
				'item_okved_uroven_2', 'item_okved_uroven_3', 'item_okved_uroven_4' )
			then
				update t18362_data_okved set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18362_data_okved( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_gruppa_okved' then
				update t18362_data_gruppa_okved set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18362_data_gruppa_okved( idkart ) values( _rc.idkart );
				end if;
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t18362 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t18362_children where idkart = OLD.idkart;
	delete from t18362_data_okved where idkart = OLD.idkart;
	delete from t18362_data_gruppa_okved where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t18888_data_gruppa_nalogooblozheniye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18888 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18888 as a
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
		a.property_data -> 'kd_tax_list'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.kd_tax_list
	from t18888 as a
	left join t18888 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18888_data_nalogooblozheniye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t18888 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t18888 as a
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
		a.property_data ->> 'code'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.code
	from t18888 as a
	left join t18888 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t18888_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t18888 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t18888 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_nalogooblozheniye' then
				update t18888_data_nalogooblozheniye set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18888_data_nalogooblozheniye( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_gruppa_nalogooblozheniye' then
				update t18888_data_gruppa_nalogooblozheniye set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t18888_data_gruppa_nalogooblozheniye( idkart ) values( _rc.idkart );
				end if;
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t18888 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t18888_children where idkart = OLD.idkart;
	delete from t18888_data_nalogooblozheniye where idkart = OLD.idkart;
	delete from t18888_data_gruppa_nalogooblozheniye where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t19008_data_adres_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19008 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19008 as a
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
        a.parent,
		a.description,
		a.property_data -> 'address'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
        NEW.geopozitsiya,
		NEW.description,
		NEW.address
	from t19008 as a
	left join t19008 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19008_data_geopozitsiya_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19008 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19008 as a
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
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19008 as a
	left join t19008 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19008_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t19008 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19008 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
		
			if _rc.type = 'item_geopozitsiya' then
				update t19008_data_geopozitsiya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19008_data_geopozitsiya( idkart ) values( _rc.idkart );
				end if;
			end if;
			
			if _rc.type = 'item_adres' then
				update t19008_data_adres set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19008_data_adres( idkart ) values( _rc.idkart );
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t19008 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t19008_children where idkart = OLD.idkart;
	delete from t19008_data_geopozitsiya where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t19067_data_profil_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19067 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19067 as a
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
		a.property_data ->> 'is_content'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.is_content
	from t19067 as a
	left join t19067 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19067_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t19067 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19067 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_profil' then
				update t19067_data_profil set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19067_data_profil( idkart ) values( _rc.idkart );
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t19067 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t19067_children where idkart = OLD.idkart;
	delete from t19067_data_profil where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t19391_data_call_type_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_doc_type_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_email_status_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_email_type_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_kvalifikatsiya_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_normativ_iu_bef() returns trigger
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
		b."name",
		a.description,
		a.property_data ->> 'number'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.number
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_promokod_iu_bef() returns trigger
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
		b."name",
		a.description,
		a.property_data ->> 'start_date',
		a.property_data ->> 'end_date'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.date_start,
		NEW.date_end
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_sertifikat_iu_bef() returns trigger
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
		b."name",
		a.description,
		a.property_data ->> 'link'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.link
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_service_type_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_sms_gateway_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_usluga_iu_bef() returns trigger
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
		b."name",
		a.description,
		(a.property_data ->> 'zadaniye')::int,
		a.property_data ->> 'articul',
		(a.property_data ->> 'number')::int,
		(a.property_data ->> 'cost')::numeric
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.zadaniye,
		NEW.articul,
		NEW.number,
		NEW.cost
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_utm_campaign_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_utm_content_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_utm_medium_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_utm_metki_iu_bef() returns trigger
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

create function elbaza.t19391_data_utm_source_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_data_utm_term_iu_bef() returns trigger
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
		b."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19391 as a
	left join t19391 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19391_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP = 'INSERT' or TG_OP = 'UPDATE' ) then
	
		-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t19391 as a 
				where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;
	
		-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19391 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
			if _rc.type = 'item_sms_gateway' then
			
				update t19391_data_sms_gateway set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_sms_gateway( idkart ) values( _rc.idkart );
				end if;
		
		
			elsif _rc.type = 'item_sertifikat' then
			
				update t19391_data_sertifikat set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_sertifikat( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_usluga' then
			
				update t19391_data_usluga set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_usluga( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_kvalifikatsiya' then
			
				update t19391_data_kvalifikatsiya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_kvalifikatsiya( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_metki' then
			
				update t19391_data_utm_metki set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_metki( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_promokod' then
			
				update t19391_data_promokod set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_promokod( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_normativ' then
			
				update t19391_data_normativ set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_normativ( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_call_type' then
			
				update t19391_data_call_type set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_call_type( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_source' then
			
				update t19391_data_utm_source set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_source( idkart ) values( _rc.idkart );
				end if;

			elsif _rc.type = 'item_utm_medium' then
			
				update t19391_data_utm_medium set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_medium( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_campaign' then
			
				update t19391_data_utm_campaign set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_campaign( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_content' then
			
				update t19391_data_utm_content set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_content( idkart ) values( _rc.idkart );
				end if;

			elsif _rc.type = 'item_utm_term' then
			
				update t19391_data_utm_term set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_term( idkart ) values( _rc.idkart );
				end if;

			elsif _rc.type = 'item_utm_metki' then
			
				update t19391_data_utm_metki set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_metki( idkart ) values( _rc.idkart );
				end if;
				
			end if;

		end loop;
		
		return NEW;
	end if;
	
	-- проверка на удаление записи
	if (select count(*) from t19391 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
	
	-- удаление связей
	delete from t19391_children where idkart = OLD.idkart;
	delete from t19391_data_sertifikat where idkart = OLD.idkart;
	delete from t19391_data_usluga where idkart = OLD.idkart;
	delete from t19391_data_kvalifikatsiya where idkart = OLD.idkart;
	delete from t19391_data_utm_metki where idkart = OLD.idkart;
	delete from t19391_data_promokod where idkart = OLD.idkart;
	delete from t19391_data_normativ where idkart = OLD.idkart;
	delete from t19391_data_call_type where idkart = OLD.idkart;
	delete from t19391_data_utm_source where idkart = OLD.idkart;
	delete from t19391_data_utm_medium where idkart = OLD.idkart;
	delete from t19391_data_utm_campaign where idkart = OLD.idkart;
	delete from t19391_data_utm_content where idkart = OLD.idkart;
	delete from t19391_data_utm_term where idkart = OLD.idkart;
	delete from t19391_data_sms_gateway where idkart = OLD.idkart;

	return OLD;
end;
$$;

create function elbaza.t19450_data_peremennaya_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19450 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19450 as a
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
		a.property_data ->> 'section_num',
		a.property_data ->> 'param_name',
		a.property_data ->> 'section_help'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.section_num,
		NEW.param_name,
		NEW.section_help
	from t19450 as a
	left join t19450 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19450_data_tip_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19450 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19450 as a
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
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19450 as a
	left join t19450 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19450_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t19450 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19450 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_peremennaya' then
				update t19450_data_peremennaya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19450_data_peremennaya( idkart ) values( _rc.idkart );
				end if;
			end if;
			
			if _rc.type = 'item_tip' then
				update t19450_data_tip set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19450_data_tip( idkart ) values( _rc.idkart );
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t19450 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t19450_children where idkart = OLD.idkart;
	delete from t19450_data_peremennaya where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t19638_data_gruppa_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19638 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19638 as a
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
		(a.property_data ->> 'group_state_code')::int,
		(a.property_data ->> 'type')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.group_state_code,
		NEW.type
	from t19638 as a
	left join t19638 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19638_data_metka_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t19638 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t19638 as a
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
		(a.property_data ->> 'state_code')::int,
		(a.property_data ->> 'regul_green')::int,
		(a.property_data ->> 'regul_yellow')::int,
		(a.property_data ->> 'regul_red')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.state_code,
		NEW.regul_green,
		NEW.regul_yellow,
		NEW.regul_red
	from t19638 as a
	left join t19638 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19638_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t19638 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19638 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_gruppa' then
				update t19638_data_gruppa set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19638_data_gruppa( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_metka' then
				update t19638_data_metka set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19638_data_metka( idkart ) values( _rc.idkart );
				end if;
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t19638 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t19638_children where idkart = OLD.idkart;
	delete from t19638_data_gruppa where idkart = OLD.idkart;
	delete from t19638_data_metka where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t19697_data_gruppa_iu_bef() returns trigger
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
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19697 as a
	left join t19697 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19697_data_iu_bef() returns trigger
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
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description
	from t19697 as a
	left join t19697 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19697_data_status_iu_bef() returns trigger
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

create function elbaza.t19697_data_tip_iu_bef() returns trigger
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
		(a.property_data ->> 'napravleniye')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.napravleniye
	from t19697 as a
	left join t19697 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t19697_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t19697 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type") as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19697 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
			if _rc.type = 'item_status' then
				update t19697_data_status set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19697_data_status( idkart ) values( _rc.idkart );
				end if;
				
			elseif _rc.type = 'item_gruppa' then
				
				update t19697_data_gruppa set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19697_data_gruppa( idkart ) values( _rc.idkart );
				end if;
				
 			elseif _rc.type = 'item_tip' then
			
				update t19697_data_tip set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19697_data_tip( idkart ) values( _rc.idkart );
				end if;
			end if; 
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t19697 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t19697_children where idkart = OLD.idkart;
	delete from t19697_data where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t20092_data_dostup_iu_bef() returns trigger
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
		(a.property_data ->> 'podrazdeleniya')::int,
		(a.property_data ->> 'gruppy')::int,
		(a.property_data ->> 'sotrudniki')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.podrazdeleniya,
		NEW.gruppy,
		NEW.sotrudniki
	from t20092 as a
	left join t20092 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t20092_data_status_iu_bef() returns trigger
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
		(a.property_data ->> 'status')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.status
	from t20092 as a
	left join t20092 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t20092_data_zadanye_iu_bef() returns trigger
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

create function elbaza.t20092_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t20092 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type") as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t20092 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_status' then
			
				update t20092_data_status set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20092_data_status( idkart ) values( _rc.idkart );
				end if;
				
			elseif _rc.type = 'item_zadaniye' then
				
				update t20092_data_zadanye set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20092_data_zadanye( idkart ) values( _rc.idkart );
				end if;
				
 			elseif _rc.type = 'item_dostup' then
			
				update t20092_data_dostup set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20092_data_dostup( idkart ) values( _rc.idkart );
				end if;
				
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t20092 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t20092_children where idkart = OLD.idkart;
	delete from t20092_data where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t20175_data_gruppa_iu_bef() returns trigger
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

create function elbaza.t20175_data_podrazdeleniye_iu_bef() returns trigger
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

create function elbaza.t20175_data_sotrudnik_iu_bef() returns trigger
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

create function elbaza.t20175_iu_bef() returns trigger
    language plpgsql
as
$$
begin
 
 	if NEW.type = 'item_sotrudnik' and NEW.property_data ->> 'fio' is not null then
		select concat( a.text, ' ('|| (NEW.property_data ->> 'dolzhnost') || ')' ) into NEW.name
		from v20455_data_select as a
		where a.id = (NEW.property_data ->> 'fio')::integer;
	end if;
	
	return NEW;
end;
$$;

create function elbaza.t20175_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t20175 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t20175 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_sotrudnik' then
				update t20175_data_sotrudnik set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20175_data_sotrudnik( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_gruppa' then
				update t20175_data_gruppa set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20175_data_gruppa( idkart ) values( _rc.idkart );
				end if;
			elsif _rc.type = 'item_podrazdeleniye' then
				update t20175_data_podrazdeleniye set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t20175_data_podrazdeleniye( idkart ) values( _rc.idkart );
				end if;

			end if;		
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t20175 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t20175_children where idkart = OLD.idkart;
	delete from t20175_data_sotrudnik where idkart = OLD.idkart;
	delete from t20175_data_podrazdeleniye where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t20455_data_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t20455 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t20455 as a
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
		a.property_data #>> '{profile,fullname,text}'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.user_name
	from t20455 as a
	left join t20455 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t20455_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t20455 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart ) as 
			(
				select NEW.idkart
				union all
				select a.idkart from t20455 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart
			from temp1 as t
		loop

			update t20455_data set idkart = idkart where idkart = _rc.idkart
			returning idkart into _iddata;

			if _iddata is null then
				insert into t20455_data( idkart ) values( _rc.idkart );
			end if;

		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t20455 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t20455_children where idkart = OLD.idkart;
	delete from t20455_data where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t27467_data_dokument_iu_bef() returns trigger
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

create function elbaza.t27467_data_peremennaya_iu_bef() returns trigger
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
		a.property_data ->> 'text',
		a.property_data ->> 'help'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.text,
		NEW.help
	from t27467 as a
	left join t27467 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27467_data_pismo_iu_bef() returns trigger
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
		a.property_data ->> 'blank_code',
		a.property_data -> 'files2',
		a.property_data ->> 'email_body',
		a.property_data ->> 'email_subject',
		a.property_data ->> 'sender_name'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.blank_code,
		NEW.files2,
		NEW.email_body,
		NEW.email_subject,
		NEW.sender_name
	from t27467 as a
	left join t27467 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27467_data_sms_iu_bef() returns trigger
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
		a.property_data ->> 'blank_code',
		a.property_data ->> 'body'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.blank_code,
		NEW.body
	from t27467 as a
	left join t27467 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27467_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP = 'INSERT' or TG_OP = 'UPDATE' ) then
		-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27467 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- 		raise '%', NEW;
		-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t27467 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_dokument' then
				update t27467_data_dokument set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_dokument (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_peremennaya' then
			
				update t27467_data_peremennaya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_peremennaya (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_pismo' then
			
				update t27467_data_pismo set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_pismo (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_sms' then
			
				update t27467_data_sms set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27467_data_sms (idkart) values (_rc.idkart);
				end if;
			end if;
			
		end loop;
		
		return NEW;
	end if;
	
	-- проверка на удаление записи
	if (select count(*) from t27467 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
	
	-- удаление связей
	delete from t27467_children where idkart = OLD.idkart;
	delete from t27467_data_dokument where idkart = OLD.idkart;
	delete from t27467_data_peremennaya where idkart = OLD.idkart;
	delete from t27467_data_pismo where idkart = OLD.idkart;
	delete from t27467_data_sms where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t27468_data_klient_fizlico_iu_bef() returns trigger
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
		a.property_data -> 'dt_address',
		a.property_data ->> 'inn',
		a.property_data ->> 'snils',
		a.property_data ->> 'bank_name',
		a.property_data ->> 'bank_cor_account',
		a.property_data ->> 'bank_bic',
		a.property_data ->> 'bank_account',
		a.property_data -> 'find_bic'
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
		NEW.dt_address,
		NEW.inn,
		NEW.snils,
		NEW.bank_name,
		NEW.bank_cor_account,
		NEW.bank_bic,
		NEW.bank_account,
		NEW.find_bic
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27468_data_klient_yurlico_iu_bef() returns trigger
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

create function elbaza.t27468_data_klienty_iu_bef() returns trigger
    language plpgsql
as
$$
declare
    _iddata int;
    _filter_data jsonb;
    
begin

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
        a.type,
        a.property_data ->> 'id21324',
        pdb_sys_jsonb_to_int_array(a.property_data -> 'id29222_list'),
        a.property_data ->> 'id26011',
        a.property_data ->> 'id24001_brush',
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
		a.property_data ->> 'acc_position',
		upper(left(a.name, 1)),
		upper(left(a.name, 2))
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
        NEW.type,
        NEW.id21324,
        NEW.id29222_list,
        NEW.id26011,
        NEW.id24001_brush,
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
		NEW.acc_position,
		NEW.letter,
		NEW.double_letter
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;
    
	return NEW;
    
    if TG_OP = 'UPDATE' then
    
        _filter_data = jsonb_build_object( 'ddt_client_json', NEW.ddt_client_json, 
                                       'ddt_adr_json', NEW.ddt_adr_json);
        -- в таблице не все поля прописаны - пока отключил                                    
        perform p27468_filter_data( NEW.idkart, _filter_data );
        
        return NEW; 
    end if; 
    
	
end;
$$;

create function elbaza.t27468_data_kontaktnoe_lico_iu_bef() returns trigger
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
		upper(left(a.name, 1)),
		a.property_data ->> 'id26011',
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29222_list'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29061'),
		(a.property_data ->> 'user_position')::int,
		a.property_data ->> 'user_birthday',
		(a.property_data ->> 'user_sex')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
		NEW.starts_with,
		NEW.id26011,
		NEW.id29222_list,
		NEW.id29061,
		NEW.user_position,
		NEW.user_birthday,
		NEW.user_sex
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27468_data_pochta_iu_bef() returns trigger
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
		(a.property_data ->> 'email_type')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
		NEW.email_type
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27468_data_rebenok_iu_bef() returns trigger
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
		a.property_data ->> 'child_birthday',
		(a.property_data ->> 'child_sex')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
		NEW.child_birthday,
		NEW.child_sex
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27468_data_telefon_iu_bef() returns trigger
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
		(a.property_data ->> 'phone_type')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
		NEW.description,
		NEW.phone_type
	from t27468 as a
	left join t27468 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27468_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;
	_parent int; 
	
begin
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27468 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;	
		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t27468 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
			if _rc.type = 'item_klient_yurlico' or _rc.type = 'item_klient_fizlico' then
				update t27468_data_klient set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_klient (idkart) values (_rc.idkart);
				end if;
            
			elseif _rc.type = 'item_kontaktnoe_lico' then
				update t27468_data_kontaktnoe_lico set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_kontaktnoe_lico (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_telefon' then
				update t27468_data_telefon set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_telefon (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_pochta' then
				update t27468_data_pochta set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_pochta(idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_rebenok' then
				update t27468_data_rebenok set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27468_data_rebenok (idkart) values (_rc.idkart);
				end if;
			
			end if;
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t27468 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t27468_data_klient where idkart = OLD.idkart;
	delete from t27468_data_kontaktnoe_lico where idkart = OLD.idkart;
	delete from t27468_data_telefon where idkart = OLD.idkart;
	delete from t27468_data_pochta where idkart = OLD.idkart;
	delete from t27468_data_rebenok where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t27468_iud_bef() returns trigger
    language plpgsql
as
$$
declare
	_idkart_letter int;
	_idkart_letter_old int;
	_idkart_alpha int; 
	_starts_with_new text = upper(left(NEW.name, 1)); 
	_starts_with_old text = upper(left(OLD.name, 1)); 
	_klient_idkart int; 
	_children int[];
	_cn int; 
	
begin

	if (NEW.type in ('item_klient_yurlico', 'item_klient_fizlico', 'item_kontaktnoe_lico'))
		and (OLD.name is null or _starts_with_new <> _starts_with_old) then 
		
		if NEW.type = 'item_kontaktnoe_lico' then
		-- найти клиента в дереве
			if TG_OP = 'INSERT' then 
				_klient_idkart = NEW.parent;
			else
				with recursive temp1 ( idkart, parent, type) as 
				(
					select idkart, parent, type, name
					from t27468 as a
					where a.idkart = NEW.idkart
					union all
					select a.idkart, a.parent, a.type, a.name
					from t27468 as a
					inner join temp1 as t on t.parent = a.idkart
				)
				select t.idkart into _klient_idkart
				from temp1 as t
				where t.type = 'item_klient_fizlico' or t.type = 'item_klient_yurlico';
			end if;
			-- найти элемент "по Алфавиту" для контактного лица
			select idkart from t27468 where parent = 
			(select idkart from t27468 where parent = _klient_idkart and name = 'Контактные лица')
			into _idkart_alpha;
		else
			-- найти элемент "по Алфавиту" для клиента
			select idkart from t27468 where parent = 0 and name = 'по Алфавиту' into _idkart_alpha;
		end if;
		
		-- найти новую букву имени в дереве
		select idkart from t27468 where parent = _idkart_alpha and name = _starts_with_new into _idkart_letter; 
		-- найти старую букву имени в дереве
		select idkart from t27468 where parent = _idkart_alpha and name = _starts_with_old into _idkart_letter_old; 
		
		-- если буквы нет в дереве, добавить
		if _idkart_letter is null then
			insert into t27468(parent, name, type, "on") values (_idkart_alpha, _starts_with_new, 'folder_klient', 1) 
			returning idkart into _idkart_letter; 
		end if;
		
		-- если у прежней папки нет других вложенных элементов, удалить
		if (select count(*) from t27468 where parent = _idkart_letter_old) = 1 then 
			delete from t27468 where idkart = _idkart_letter_old; 
		end if; 
		
		-- упорядочивание алфавита
		select array_agg(a.idkart)  into _children
		from 
			(select idkart from t27468
			where dttmcl is null 
			and parent = _idkart_alpha
			order by name) as a; 
		
		select count(*) from t27468_children as a where a.idkart = _idkart_alpha into _cn; 

		if _cn > 0 then 
			update t27468_children set children = _children where idkart = _idkart_alpha; 
		else
			insert into t27468_children( idkart, children ) values ( _idkart_alpha, _children );
		end if;

		-- назначить нового родителя
		NEW.parent = _idkart_letter; 
	end if;
		
	return NEW;
	
end;
$$;

create function elbaza.t27469_data_dokument_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		(a.property_data ->> 'templ_doc')::int,
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id20175_podrazdelenie'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id20175_gruppa'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id20175_sotrudnik'),
		a.property_data ->> 'date_end',
		a.property_data ->> 'date_begin'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.templ_doc,
		NEW.id20175_podrazdelenie,
		NEW.id20175_gruppa,
		NEW.id20175_sotrudnik,
		NEW.date_end,
		NEW.date_begin
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_lektor_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data -> 'photo',
		a.property_data ->> 'name_specialist',
		a.property_data -> 'fio',
		a.property_data ->> 'description_lektor'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.photo,
		NEW.name_specialist,
		NEW.fio,
		NEW.description_lektor
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_meropriyatiye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data -> 'files2',
		(a.property_data ->> 'add_slider')::int,
		(a.property_data ->> 'id17429')::int,
		a.property_data ->> 'code_event',
		a.property_data ->> 'topic_event',
		a.property_data ->> 'name_event',
		a.property_data ->> 'official_event',
		a.property_data ->> 'description_event',
		pdb_sys_jsonb_to_int_array( a.property_data -> 'id19067_list' ),
		pdb_sys_jsonb_to_int_array( a.property_data -> 'id18888_list' ),
		pdb_sys_jsonb_to_int_array( a.property_data -> 'id18311_list' ),
		a.property_data ->> 'meta_keywords',
		a.property_data ->> 'meta_description'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.files2,
		NEW.add_slider,
		NEW.id17429,
		NEW.code_event,
		NEW.topic_event,
		NEW.name_event,
		NEW.official_event,
		NEW.description_event,
		NEW.id19067_list,
		NEW.id18888_list,
		NEW.id18311_list,
		NEW.meta_keywords,
		NEW.meta_description
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_peremennaya_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data ->> 'text',
		a.property_data ->> 'help',
		(a.property_data ->> 'section_type')::int,
		(a.property_data ->> 'id19450')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.text,
		NEW.help,
		NEW.section_type,
		NEW.id19450
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_programma_1_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data ->> 'prog_text'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.prog_text
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_programma_2html_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data ->> 'prog_text',
		(a.property_data ->> 'nw_material')::int,
		(a.property_data ->> 'nw_lanch')::int,
		(a.property_data ->> 'nw_coffe')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.prog_text,
		NEW.nw_material,
		NEW.nw_lanch,
		NEW.nw_coffe
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_programma_2text_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data ->> 'prog_text',
		(a.property_data ->> 'nw_material')::int,
		(a.property_data ->> 'nw_lanch')::int,
		(a.property_data ->> 'nw_coffe')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.prog_text,
		NEW.nw_material,
		NEW.nw_lanch,
		NEW.nw_coffe
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_programma_3html_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data ->> 'prog_text',
		(a.property_data ->> 'nw_material')::int,
		(a.property_data ->> 'nw_lanch')::int,
		(a.property_data ->> 'nw_coffe')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.prog_text,
		NEW.nw_material,
		NEW.nw_lanch,
		NEW.nw_coffe
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_programma_3table_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		(a.property_data ->> 'nw_material')::int,
		(a.property_data ->> 'nw_lanch')::int,
		(a.property_data ->> 'nw_coffe')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.nw_material,
		NEW.nw_lanch,
		NEW.nw_coffe
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_programma_3table_row_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		(a.property_data ->> 'position')::int,
		a.property_data ->> 'hours',
		a.property_data ->> 'block_topic',
		a.property_data ->> 'content'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.position,
		NEW.hours,
		NEW.block_topic,
		NEW.content
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_raspisaniye_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		(a.property_data ->> 'corporate')::boolean,
		a.property_data ->> 'slug',
		a.property_data ->> 'registr_event',
		a.property_data ->> 'date_event_end',
		a.property_data ->> 'date_event',
		(a.property_data ->> 'id28104')::int,
		(a.property_data ->> 'doc_blank')::int,
		a.property_data ->> 'cost_event',
		(a.property_data ->> 'id29071')::int,
		(a.property_data ->> 'id21307')::int,
		(a.property_data ->> 'type_registr')::int,
		pdb_sys_jsonb_to_int_array(a.property_data -> 'promocodes'),
		a.property_data ->> 'description_event'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.corporate,
		NEW.slug,
		NEW.registr_event,
		NEW.date_event_end,
		NEW.date_event,
		NEW.id28104,
		NEW.doc_blank,
		NEW.cost_event,
		NEW.id29071,
		NEW.id21307,
		NEW.type_registr,
		NEW.promocodes,
		NEW.description_event
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_razdatochnyy_material_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		a.property_data -> 'file_data',
		a.property_data ->> 'file_url',
		a.property_data ->> 'file_description'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.file_data,
		NEW.file_url,
		NEW.file_description
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_spisok_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		(a.property_data ->> 'id23004')::int,
		(a.property_data ->> 'id23006')::int,
		(a.property_data ->> 'id23007')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.id23004,
		NEW.id23006,
		NEW.id23007
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_data_video_material_iu_bef() returns trigger
    language plpgsql
as
$$
begin

	-- заполнение полей данными - только INSERT и UPDATE

	-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27469 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27469 as a
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
		(a.property_data ->> 'video_provider')::int,
		(a.property_data ->> 'video_code')::int,
		a.property_data ->> 'video_title',
		a.property_data ->> 'video_footer',
		a.property_data ->> 'video_h_dop',
		a.property_data ->> 'video_description'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.video_provider,
		NEW.video_code,
		NEW.video_title,
		NEW.video_footer,
		NEW.video_h_dop,
		NEW.video_description
	from t27469 as a
	left join t27469 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27469_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP = 'INSERT' or TG_OP = 'UPDATE' ) then
	
		-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27469 as a 
				where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;
	
		-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type 
				from t27469 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
		
			-- Мероприятие
			if _rc.type = 'item_meropriyatiye' then
			
				update t27469_data_meropriyatiye set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_meropriyatiye( idkart ) values( _rc.idkart );
				end if;
				
			-- Расписание
			elsif _rc.type = 'item_raspisaniye' then
			
				update t27469_data_raspisaniye set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_raspisaniye( idkart ) values( _rc.idkart );
				end if;
				
			-- Лектор
			elsif _rc.type = 'item_lektor' then
			
				update t27469_data_lektor set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_lektor( idkart ) values( _rc.idkart );
				end if;
				
			-- Раздаточный материал
			elsif _rc.type = 'item_razdatochnyy_material' then
			
				update t27469_data_razdatochnyy_material set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_razdatochnyy_material( idkart ) values( _rc.idkart );
				end if;
				
			-- Видео-материал
			elsif _rc.type = 'item_video_material' then
			
				update t27469_data_video_material set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_video_material( idkart ) values( _rc.idkart );
				end if;
				
			-- Переменная
			elsif _rc.type = 'item_peremennaya' then
			
				update t27469_data_peremennaya set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_peremennaya( idkart ) values( _rc.idkart );
				end if;
			
			-- Программа 1
			elsif _rc.type = 'item_programma_1' then
			
				update t27469_data_programma_1 set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_1( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 2 html
			elsif _rc.type = 'item_programma_2html' then
			
				update t27469_data_programma_2html set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_2html( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 2 text
			elsif _rc.type = 'item_programma_2text' then
			
				update t27469_data_programma_2text set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_2text( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 3 html
			elsif _rc.type = 'item_programma_3html' then
			
				update t27469_data_programma_3html set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_3html( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 3 table
			elsif _rc.type = 'item_programma_3table' then
			
				update t27469_data_programma_3table set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_3table( idkart ) values( _rc.idkart );
				end if;
			
			-- Документ
			elsif _rc.type = 'item_dokument' then
			
				update t27469_data_dokument set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_dokument( idkart ) values( _rc.idkart );
				end if;
				
			-- Список
			elsif _rc.type = 'item_spisok' then
			
				update t27469_data_spisok set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_spisok( idkart ) values( _rc.idkart );
				end if;
			
			-- Программа 3 table_row
			elsif _rc.type = 'item_programma_3table_row' then
			
				update t27469_data_programma_3table_row set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_3table_row( idkart ) values( _rc.idkart );
				end if;
			
			end if;

		end loop;
		
		return NEW;
	end if;
	
	-- проверка на удаление записи
	if (select count(*) from t27469 as a 
		where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
	
	-- удаление связей
	delete from t27469_children where idkart = OLD.idkart;
	
	delete from t27469_data_meropriyatiye where idkart = OLD.idkart;
	delete from t27469_data_raspisaniye where idkart = OLD.idkart;
	delete from t27469_data_lektor where idkart = OLD.idkart;
	delete from t27469_data_razdatochnyy_material where idkart = OLD.idkart;
	delete from t27469_data_video_material where idkart = OLD.idkart;
	delete from t27469_data_peremennaya where idkart = OLD.idkart;
	delete from t27469_data_dokument where idkart = OLD.idkart;
	
	delete from t27469_data_programma_1 where idkart = OLD.idkart;
	delete from t27469_data_programma_2html where idkart = OLD.idkart;
	delete from t27469_data_programma_2text where idkart = OLD.idkart;
	delete from t27469_data_programma_3html where idkart = OLD.idkart;
	delete from t27469_data_programma_3table where idkart = OLD.idkart;
	
	delete from t27469_data_programma_3html_row where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t27470_data_aktsiya_iu_bef() returns trigger
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

create function elbaza.t27470_data_dokument_iu_bef() returns trigger
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
		a.parent
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.parent
	from t27470 as a
	left join t27470 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27470_data_fayl_iu_bef() returns trigger
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

	select 
		a.dttmcr,
		a.dttmup,
		a.dttmcl,
		a.userid,
		a."name",
		b."name",
		a.description,
		a.parent,
		a.property_data -> 'file_small',
		a.property_data -> 'file_large',
		(a.property_data ->> 'id29091')::int,
		(a.property_data ->> 'landscape')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.file_small,
		NEW.file_large,
		NEW.id29091,
		NEW.landscape
	from t27470 as a
	left join t27470 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27470_data_novost_iu_bef() returns trigger
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
		a.parent,
		a.property_data ->> 'news_description',
		a.property_data -> 'news_image',
		a.property_data ->> 'news_view',
		a.property_data ->> 'news_source_url',
		a.property_data ->> 'news_source',
		(a.property_data ->> 'news_bookmark')::boolean,
		a.property_data ->> 'news_date',
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
		NEW.news_description,
		NEW.news_image,
		NEW.news_view,
		NEW.news_source_url,
		NEW.news_source,
		NEW.news_bookmark,
		NEW.news_date,
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

create function elbaza.t27470_data_otzyv_iu_bef() returns trigger
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
		a.parent,
		a.property_data -> 'reviews_image',
		a.property_data ->> 'reviews_view',
		a.property_data -> 'files2_write',
		a.property_data ->> 'reviews_description',
		a.property_data ->> 'reviews_company',
		a.property_data ->> 'reviews_date',
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
		NEW.reviews_image,
		NEW.reviews_view,
		NEW.files2_write,
		NEW.reviews_description,
		NEW.reviews_company,
		NEW.reviews_date,
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

create function elbaza.t27470_data_sayt_iu_bef() returns trigger
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

create function elbaza.t27470_data_seo_iu_bef() returns trigger
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
		a.parent,
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

create function elbaza.t27470_data_usluga_iu_bef() returns trigger
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
		a.parent,
		a.property_data ->> 'abonement_2',
		a.property_data ->> 'abonement_1',
		(a.property_data ->> 'templ_page')::int,
		a.property_data -> 'files2_data',
		a.property_data ->> 'view',
		a.property_data -> 'files2_image_main',
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29071_list'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29081_list'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id29061_list'),
		pdb_sys_jsonb_to_int_array(a.property_data -> 'id26022_list'),
		a.property_data ->> 'num_sort',
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
		NEW.abonement_2,
		NEW.abonement_1,
		NEW.templ_page,
		NEW.files2_data,
		NEW.view,
		NEW.files2_image_main,
		NEW.id29071_list,
		NEW.id29081_list,
		NEW.id29061_list,
		NEW.id26022_list,
		NEW.num_sort,
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

create function elbaza.t27470_data_vakansia_iu_bef() returns trigger
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
		a.parent,
		a.property_data -> 'vakansia_image',
		a.property_data ->> 'vakansia_view',
		a.property_data ->> 'vakansia_description',
		a.property_data ->> 'vakansia_date',
		a.property_data ->> 'is_published',
		a.property_data ->> 'slug',
		a.property_data ->> 'meta_description',
		a.property_data ->> 'meta_keywords',
		a.property_data -> 'meta_image',
		a.property_data ->> 'meta_title'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.parent,
		NEW.vakansia_image,
		NEW.vakansia_view,
		NEW.vakansia_description,
		NEW.vakansia_date,
		NEW.is_published,
		NEW.slug,
		NEW.meta_description,
		NEW.meta_keywords,
		NEW.meta_image,
		NEW.meta_title
	from t27470 as a
	left join t27470 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27470_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27470 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t27470 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_sayt' then
				update t27470_data_sayt set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27470_data_sayt( idkart ) values( _rc.idkart );
				end if;
			
			elseif _rc.type = 'item_seo' then
				update t27470_data_seo set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_seo (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_fayl' then
				update t27470_data_fayl set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_fayl (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_otzyv' then
				update t27470_data_otzyv set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_otzyv (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_novost' then
				update t27470_data_novost set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_novost(idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_usluga' then
				update t27470_data_usluga set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_usluga (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_aktsiya' then
				update t27470_data_aktsiya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_aktsiya(idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_dokument' then
				update t27470_data_dokument set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_dokument (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_vakansia' then
				update t27470_data_vakansia set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_vakansia (idkart) values (_rc.idkart);
				end if;
			
			end if;
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t27470 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t27470_children where idkart = OLD.idkart;
	delete from t27470_data_sayt where idkart = OLD.idkart;
	delete from t27470_data_seo where idkart = OLD.idkart;
	delete from t27470_data_fayl where idkart = OLD.idkart;
	delete from t27470_data_otzyv where idkart = OLD.idkart;
	delete from t27470_data_novost where idkart = OLD.idkart;
	delete from t27470_data_usluga where idkart = OLD.idkart;
	delete from t27470_data_aktsiya where idkart = OLD.idkart;
	delete from t27470_data_dokument where idkart = OLD.idkart;
	delete from t27470_data_vakansia where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t27471_data_dokument_iu_bef() returns trigger
    language plpgsql
as
$$
begin
	
-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27471 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27471 as a
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
		(a.property_data ->> 'client')::int,
		(a.property_data ->> 'firm')::int,
		a.property_data ->> 'idkart',
		a.property_data ->> 'dokument_dttmcr',
		a.property_data ->> 'dokument_ispl',
		a.property_data -> 'dokument',
		a.property_data -> 'dokument_json'
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW.name,
		NEW."group",
        NEW.description,
		NEW.client,
		NEW.firm,
		NEW.idkart_doc,
		NEW.dokument_dttmcr,
		NEW.dokument_ispl,
		NEW.dokument,
		NEW.dokument_json
	from t27471 as a
	left join t27471 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27471_data_klient_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE

-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t27471 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t27471 as a
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
		upper(left(a.name, 1)),
        (a.property_data ->> 'firm')::int,
        (a.property_data ->> 'client')::int
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW."group",
		NEW.description,
		NEW.starts_with,
        NEW.firm,
        NEW.client
	from t27471 as a
	left join t27471 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;

	return NEW;
	
end;
$$;

create function elbaza.t27471_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
	if ( TG_OP = 'INSERT' or TG_OP = 'UPDATE' ) then
	
		-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27471 as a 
				where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;
	
		-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type 
				from t27471 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
		
			-- Клиент
			if _rc.type = 'item_klient' then
			
				update t27471_data_klient set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27471_data_klient( idkart ) values( _rc.idkart );
				end if;
				
			-- Документ
			elsif _rc.type = 'item_dokument' then
				update t27471_data_dokument set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27471_data_dokument( idkart ) values( _rc.idkart );
				end if;
				
			end if;

		end loop;
		
		return NEW;
	end if;
	
-- 	проверка на удаление записи
	if (select count(*) from t27471 as a 
		where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
	
	-- удаление связей
	
	delete from t27471_data_klient where idkart = OLD.idkart;
	delete from t27471_data_dokument where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.t27471_iud_bef() returns trigger
    language plpgsql
as
$$
declare
	_idkart_letter int;
	_idkart_letter_old int;
	_idkart_alpha int; 
	_starts_with_new text = upper(left(NEW.name, 1)); 
	_starts_with_old text = upper(left(OLD.name, 1)); 
	_klient_idkart int; 
	_children int[];
	_cn int; 
	
begin
	raise 'DSFDS';
	if (NEW.type in ('item_klient', 'item_dokument'))
		and (OLD.name is null or _starts_with_new <> _starts_with_old) then 
		
		if NEW.type = 'item_dokument' then
		-- найти клиента в дереве
			if TG_OP = 'INSERT' then 
				_klient_idkart = NEW.parent;
			else
				with recursive temp1 ( idkart, parent, type) as 
				(
					select idkart, parent, type, name
					from t27471 as a
					where a.idkart = NEW.idkart
					union all
					select a.idkart, a.parent, a.type, a.name
					from t27471 as a
					inner join temp1 as t on t.parent = a.idkart
				)
				select t.idkart into _klient_idkart
				from temp1 as t
				where t.type = 'item_dokument' or t.type = 'item_dokument';
			end if;
			-- найти элемент "по Алфавиту" для контактного лица
			select idkart from t27471 where parent = 
			(select idkart from t27471 where parent = _klient_idkart)
			into _idkart_alpha;
		else
			-- найти элемент "по Алфавиту" для клиента
			select idkart from t27471 where parent = 0 into _idkart_alpha;
		end if;
		
		-- найти новую букву имени в дереве
		select idkart from t27471 where parent = _idkart_alpha and name = _starts_with_new into _idkart_letter; 
		-- найти старую букву имени в дереве
		select idkart from t27471 where parent = _idkart_alpha and name = _starts_with_old into _idkart_letter_old; 
		
		-- если буквы нет в дереве, добавить
		if _idkart_letter is null then
			insert into t27471(parent, name, type, "on") values (_idkart_alpha, _starts_with_new, 'folder_filter', 1) 
			returning idkart into _idkart_letter; 
		end if;
		
		-- если у прежней папки нет других вложенных элементов, удалить
		if (select count(*) from t27471 where parent = _idkart_letter_old) = 1 then 
			delete from t27471 where idkart = _idkart_letter_old; 
		end if; 
		
		-- упорядочивание алфавита
		select array_agg(a.idkart)  into _children
		from 
			(select idkart from t27471
			where dttmcl is null 
			and parent = _idkart_alpha
			order by name) as a; 
		
		select count(*) from t27471_children as a where a.idkart = _idkart_alpha into _cn; 

		if _cn > 0 then 
			update t27471_children set children = _children where idkart = _idkart_alpha; 
		else
			insert into t27471_children( idkart, children ) values ( _idkart_alpha, _children );
		end if;

		-- назначить нового родителя
		NEW.parent = _idkart_letter; 
	end if;
		
	return NEW;
	
end;
$$;

create function elbaza.t30436_data_spisok_iu_bef() returns trigger
    language plpgsql
as
$$
begin

-- заполнение полей данными - только INSERT и UPDATE
-- проверка на отключение
	with recursive temp1 ( lv, parent, "on" ) as 
	(
		select 1, a.parent, a.on
		from t30436 as a
		where a.idkart = NEW.idkart
		union all
		select t.lv+1, a.parent, a.on
		from t30436 as a
		inner join temp1 as t on t.parent = a.idkart
		where a.dttmcl is null 
			and t.on = 1
	)
	select t.on into NEW.on
	from temp1 as t
	order by t.lv desc
	limit 1;
-- получить дерево списка    
         
-- добавление остальных полей
	select 
		a.dttmcr,
		a.dttmup,
		a.dttmcl,
		a.userid,
		a."name",
		a.description
	into 
		NEW.dttmcr,
		NEW.dttmup,
		NEW.dttmcl,
		NEW.userid,
		NEW."name",
		NEW.description
	from t30436 as a
	left join t30436 as b on a.parent = b.idkart
	where a.idkart = NEW.idkart;
    
	return NEW;
	
end;
$$;

create function elbaza.t30436_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;
    _list_id int; 
    _data_filter jsonb = '{}';
    _item_filter jsonb = '{}';
    _property_data jsonb;
    _filter_type text;
    _select_type text;
    _meaning jsonb;
    _condition jsonb;
    _data_types jsonb	 = p30436_list_types();
    _array int;
    
begin
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t30436 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t30436 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
			if _rc.type = 'item_spisok' then
				update t30436_data_spisok set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t30436_data_spisok( idkart ) values( _rc.idkart );
				end if;
			end if;
		end loop;
        
        return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t30436 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t30436_data_spisok where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

create function elbaza.templare_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
begin

	return pdb2_tpl_tree( _value, _name_mod );
	
end;
$$;

create function elbaza.templare_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
begin

	return pdb2_tpl_tree_property( _value, _name_mod );
	
end;
$$;

create function elbaza.xxxx_dadata_client(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_query jsonb;	
begin
    -- сделать задание
    select jsonb_agg(a.query) into _query
    from (
        select jsonb_build_object( 
                    'cmd', 'json',
                    'url', 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/findById/party', 
                    'idkart', a.idkart, 
                    'data', jsonb_build_object( 'query', a.inn, 'count', 299 )
                ) as query        
        FROM t27468_data_klient as a
        where a.dttmcl is null
            and a.inn is not null 
        order by a.ddt_client_date NULLS FIRST, a.idkart
        limit 10
    ) as a;
    -- запустить задание
	if _query is not null then
		perform pdb2_val_task_command( 'dadata.ru', 'cmd', '{command}', _query );
		perform pdb2_val_task_command( 'dadata.ru', 'cmd', '{enabled}', 1 );
	end if;
	return _value;
end;
$$;

create function elbaza.xxxx_dadata_client_callback(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_post jsonb		= pdb2_val_api( '{post}' );

	_cl_js jsonb;
	_idkart integer;
	_inn text;
	_kpp text;
	_ogrn text;
	_ddt_client_hid text; 
	_suggestions jsonb; 

	_config jsonb;
	_query jsonb;
	_cn integer;
	
begin
    if _post #>> '{response,status}' = 'false' then
        return _value;
    else
        _idkart = _post ->>'idkart';
        _suggestions = _post #>'{response,data,suggestions}';

        select trim(a.inn), trim(a.kpp), trim(a.ogrn)
        into 	_inn, _kpp, _ogrn
        from t27468_data_klient as a where a.idkart = _idkart;

-- поиск карточки		
-- ищем у кого есть КПП
        select a.value #> '{data}' into _cl_js
        from jsonb_array_elements( _suggestions ) as a
        where a.value #>> '{data,inn}' = _inn
                and a.value #>> '{data,kpp}' = _kpp
                and (a.value #>> '{data,kpp}') is not null;
-- ищем у кого есть ОГРН
        if _cl_js is null then
            select a.value #> '{data}' into _cl_js
            from jsonb_array_elements( _suggestions ) as a
            where a.value #>> '{data,inn}' = _inn
                    and a.value #>> '{data,ogrn}' = _ogrn
                    and (a.value #>> '{data,ogrn}') is not null
                    and (a.value #>> '{data,kpp}') is null;
        end if;

        if _cl_js is null then
-- у ИП ищем актинвную карточку				
            select a.value #> '{data}' into _cl_js
            from jsonb_array_elements( _suggestions ) as a
            where a.value #>> '{data,inn}' = _inn
                    and (a.value #>> '{data,type}') = 'INDIVIDUAL'
                    and (a.value #>> '{data,state,status}') = 'ACTIVE';						
        end if;

--         _ddt_client_hid = _cl_js #>> '{hid}'; -- подтвержден

--         if _ddt_client_hid is null then   
--             if jsonb_array_length(_suggestions) = 1 then -- если одна запись - то возможно - подтвержден
--                 _cl_js := _suggestions #> '{0,data}';
--             end if;
--         end if;

        update t27468_data_klient set 
            ddt_client_date = now(), ddt_client_json = _cl_js
        where idkart = _idkart;

    end if;

	return _value;
end;
$$;


