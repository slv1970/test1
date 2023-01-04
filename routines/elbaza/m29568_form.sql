create or replace function elbaza.m29568_form(_value jsonb, _name_mod text) returns jsonb
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

alter function elbaza.m29568_form(jsonb, text) owner to site;

