create or replace function elbaza.p27468_tree_view_root_filter(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
    _text text; 
	_placeholder jsonb  = '[]';
	_client_ids int[];  -- ID отфильтрованных клиентов по списку или по полю для поиска. Если данные список и поиск пустые, равно null
    _cn int;            -- count, для подсчета количества
    _cn_all int;        -- count all, для подсчета количества
    _placeholder_data jsonb;
    _type text;
    _folder text;
    _id_object jsonb;
    _idkart int;
    _text_pref text;
    
begin
    -- получить массив ID отфильтрованных клиентов
    _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 

    if _id is not null then 
        -- получить данные placeholder-а по id
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
        -- получить ID родителя
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
        -- получить название элемента в дереве
		_text = _placeholder_data #>> '{data, text}'; 
        -- получить тип элемента в дереве
        _type = _placeholder_data #>> '{data, type}'; 
        
		-- сформировать jsonb-массив из одного элемента
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
                1 as children
        ) as a; 
        
        return _placeholder;
    end if;
    
    _text = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );

    -- placeholder для корневой папки "по РИЦам". Собирает все РИЦы, которые есть у клиентов
	if _text = 'по РИЦам' then
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', COALESCE( b.text, '- нет -' ), 
				  'idkart', b.id,
				  'folder', 'ric'
				) as id,
				COALESCE( b.text, '- нет -' ) as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				case when count(*) > 0 then 1 end as children,
                case when count(*) > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || count(*) || '</span>' ) end as text_pref
			from t27468_data_klient as a 
            left join v18207_data_ritz_select as b on a.id21324 = b.id
			where a.dttmcl is null and b.dttmcl is null
            and (_client_ids is null or a.idkart = any(_client_ids))
			group by b.id, b.text 
            order by b.text
        ) as a; 
    -- placeholder для корневой папки "по Меткам". Собирает все метки, которые есть у клиентов
	elseif _text = 'по Меткам' then
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', a.text, 
				  'idkart', a.id,
				  'folder', 'metka'
				) as id,
				a.text as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
                case when a.count > 0 then 1 end as children,
                case when a.count > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || a.count || '</span>' ) end as text_pref
			from (
				select b.id, COALESCE( b.text, '- нет -' ) as text, count(*) as count
				from (
					select unnest( COALESCE( id29222_list, array[-1] )) as id29222
					from t27468_data_klient
                    where dttmcl is null and (_client_ids is null or idkart = any(_client_ids))
                ) as a
                left join v19638_data_metka_select as b on b.id = a.id29222
                where b.dttmcl is null 
                group by b.id, b.text
                order by b.text
            ) as a
        ) as a; 
        
    -- placeholder для корневой папки "по Кустам". Создает 2 папки "Основные" и "Связанные". 
	elseif _text = 'по Кустам' then
        select count(*), count(id24001_brush) into _cn_all, _cn from t27468_data_klient where dttmcl is null and (_client_ids is null or idkart = any(_client_ids));

        _placeholder = _placeholder || jsonb_build_object(
                'id', jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', 'Основные', 
				  'folder', 'kust_main'
				),
				'text', 'Основные',
				'type', 'folder_filter_klienti',
				'parent', _parent_id,
				'children', case when _cn_all - _cn > 0 then 1 end,
                'text_pref', case when _cn_all - _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">', _cn_all - _cn, '</span>' ) end);
	
            _placeholder = _placeholder || jsonb_build_object(
                'id', jsonb_build_object(
				  'type', 'folder_filter_klienti',
                  'text', 'Связанные', 
				  'folder', 'kust_related'
				),
				'text', 'Связанные',
				'type', 'folder_filter_klienti',
				'parent', _parent_id,
				'children', case when _cn > 0 then 1 end,
                'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">', _cn, '</span>' ) end);

    end if;
    
	-- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
	

end;
$$;

alter function elbaza.p27468_tree_view_root_filter(text, text, text, text, text) owner to site;

