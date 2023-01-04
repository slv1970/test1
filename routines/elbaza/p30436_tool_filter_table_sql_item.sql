create or replace function elbaza.p30436_tool_filter_table_sql_item(_condition integer, _filter_type text, _alias text, _select_type text, _array boolean, _val jsonb) returns text
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

alter function elbaza.p30436_tool_filter_table_sql_item(integer, text, text, text, boolean, jsonb) owner to site;

