create or replace function elbaza.p30436_tool_filter_item(_data jsonb, _alias text) returns text
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

alter function elbaza.p30436_tool_filter_item(jsonb, text) owner to site;

