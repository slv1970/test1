create or replace function elbaza.p30436_list_types() returns jsonb
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

alter function elbaza.p30436_list_types() owner to site;

