create or replace function elbaza.p30436_tool_filter_table(_data jsonb, _parent text) returns text
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

alter function elbaza.p30436_tool_filter_table(jsonb, text) owner to site;

