create or replace function elbaza.p30436_tool_filter_client(_data jsonb, _alias_filter text, _alias_table text) returns text
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

alter function elbaza.p30436_tool_filter_client(jsonb, text, text) owner to site;

