create or replace function elbaza.p27468_query_list(_name_mod text, _list_id integer, _name_find text, OUT _client_ids_out integer[], OUT _cn_all_out integer, OUT _cn_ric_out integer, OUT _cn_metki_out integer) returns record
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

alter function elbaza.p27468_query_list(text, integer, text, out integer[], out integer, out integer, out integer) owner to site;

