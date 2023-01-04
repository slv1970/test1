create or replace function elbaza.p30436_update_list(_idkart integer, _type text) returns void
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

alter function elbaza.p30436_update_list(integer, text) owner to site;

