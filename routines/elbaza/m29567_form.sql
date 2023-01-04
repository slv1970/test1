create or replace function elbaza.m29567_form(_value jsonb, _name_mod text) returns jsonb
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

alter function elbaza.m29567_form(jsonb, text) owner to site;

