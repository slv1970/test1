create or replace function elbaza.p27468_query_all(_name_mod text, _name_find text, OUT _client_ids_out integer[], OUT _cn_all_out integer, OUT _cn_ric_out integer, OUT _cn_metki_out integer) returns record
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

alter function elbaza.p27468_query_all(text, text, out integer[], out integer, out integer, out integer) owner to site;

