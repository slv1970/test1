create or replace function elbaza.p27468_tree_view_folder_klient(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder для папок "Контактные лица", по Алфавиту" и буквы алфавита внутри клиента
--=======================================================================================--
	_placeholder jsonb = '[]';
	_placeholder_data jsonb; 
	_text text;          -- папка в дереве
    _folder text;        -- папка в дереве
    _type text;	        -- тип элемента в дереве
	_starts_with text;	-- начало имени контактного лица
	_client_id int;     -- ID клиента
	_metka_id int;      -- ID метки
	_status_id int;     -- ID статуса
	_inn text; 
    _id24001_brush int;
    _cn int;
    _text_pref text;
    _cn_catalog int;
    
begin
    -- если передан ID элемента дерева, сформировать placeholder для этой папки
	if _id is not null then 
		_placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
		_folder = _placeholder_data #>> '{data, folder}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
        
        if _text = 'Контактные лица' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 1, '{data, idkart}'); 
            select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
        
        elseif _text = 'по Алфавиту' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 2, '{data, idkart}'); 
            select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
        
        elseif _folder = 'metka' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 3, '{data, idkart}'); 
            _metka_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, '{data, idkart}'); 
            select count(*) into _cn 
            from t27468_data_kontaktnoe_lico as a
            inner join t27468 as b on a.idkart = b.idkart
            where a.dttmcl is null and b.dttmcl is null and b.parent = _client_id
            and (_metka_id is null or _metka_id = any(a.id29222_list));
        
        elseif _folder = 'status' then
            _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 3, '{data, idkart}'); 
            _status_id = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, '{data, idkart}'); 
            select count(*) into _cn 
            from t27468_data_kontaktnoe_lico as a
            inner join t27468 as b on a.idkart = b.idkart
            where a.dttmcl is null and b.dttmcl is null and b.parent = _client_id
            and (_status_id is null or _status_id = _status_id);
        
        elseif _folder = 'letter' then
            select count(*) into _cn 
            from t27468_data_kontaktnoe_lico as a where a.starts_with = _text; 
        end if;
        
        if _cn > 0 and (_folder is null or _folder <> 'letter') then
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        end if;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
                _text_pref as text_pref,
				case when _cn > 0 then 1 end as children
        ) as a; 
        
    	return _placeholder;
    end if;
    
    _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 0, null); 
    _text = _placeholder_data #>> '{data, text}';
    _folder = _placeholder_data #>> '{data, folder}'; 

	-- Папка "Контактные лица" клиента
	if _text = 'Контактные лица' then
        _client_id = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 1, '{data, idkart}'); 
		select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
        _placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'folder_klient', 
				  'text', 'по Алфавиту'
				),
				'text', 'по Алфавиту',
				'type', 'folder_klient',
				'parent', _parent_id,
                'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
				'children', case when _cn > 0 then 1 end);
				
		_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'folder_filter_klient',
				  'text', 'по Состоянию'
				),
				'text', 'по Состоянию',
				'type', 'folder_filter_klient',
				'parent', _parent_id,
				'children', case when _cn > 0 then 1 end);
            
		_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'folder_filter_klient',
				  'text', 'по Меткам'
				),
				'text', 'по Меткам',
				'type', 'folder_filter_klient',
				'parent', _parent_id,
				'children', case when _cn > 0 then 1 end);
    	
	-- Папка "по Алфавиту" для отображения списка контактных лиц 
	elseif _text = 'по Алфавиту' then
		-- Получает ID клиента
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 2, '{data, idkart}' );
        -- Собирает placeholder для папки "по Алфавиту" 
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_klient',
				  'text', a.starts_with,
                  'folder', 'letter'
				) as id,
				a.starts_with as "text", 
				'folder_klient' as "type",
				_parent_id as parent,
				1 as children
			from (
					select distinct starts_with
					from t27468_data_kontaktnoe_lico as a
					inner join t27468 b on b.idkart = a.idkart
					where a.dttmcl is null and b.dttmcl is null
					and b.parent = _client_id
            ) as a
        ) as a;
        
	-- Папка с первой буквой имени контактного лица
	elseif _folder = 'letter' then
		-- Получает ID клиента
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 3, '{data, idkart}' );
		-- Получает первую букву имени контактного лица
        _starts_with = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );
		-- Собирает placeholder для папки с первой буквой имени контактного лица
        select jsonb_agg( a ) into _placeholder
		from (
              select
				jsonb_build_object(
				  'type', b.type,
                  'text', b.name,
				  'idkart', b.idkart
				) as id,
				b.name as "text", 
				b.type as "type",
				_parent_id as parent,
				case when count(c.idkart) > 0 then 1 end as children,
				case when b.on = 1 then null else 5 end as theme
			from t27468_data_kontaktnoe_lico as a
            inner join t27468 as b on a.idkart = b.idkart
            left join t27468 as c on a.idkart = c.parent
			where a.dttmcl is null and b.dttmcl is null
            and b.parent = _client_id
			and a.starts_with = _starts_with
            group by b.idkart
			order by b.name
        ) as a; 
	-- Статус контактного лица
	elseif _folder = 'status' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 3, '{data, idkart}' );
		_status_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
        
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', b.type,
                  'text', b.name,
				  'idkart', b.idkart
				) as id,
				b.name as "text", 
				b.type as "type",
				_parent_id as parent,
				case when count(c.idkart) > 0 then 1 end as children,
                case when b.on = 1 then null else 5 end as theme
			from t27468_data_kontaktnoe_lico a
			inner join t27468 b on a.idkart = b.idkart
            left join t27468 as c on a.idkart = c.parent
			where a.dttmcl is null and b.dttmcl is null
			and b.parent = _client_id
			and (_status_id is null and a.id26011 is null or a.id26011 = _status_id)
            group by b.idkart
            order by b.name
        ) as a; 
   -- Метка контактного лица
	elseif _folder = 'metka' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 3, '{data, idkart}' );
		_metka_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
		
        select jsonb_agg( a )  into _placeholder
		from (
			select
				jsonb_build_object(
				  'type', b.type,
                  'text', a.name,
				  'idkart', a.idkart
				) as id,
				a.name as "text", 
				b.type as "type",
				_parent_id as parent,
				case when count(c.idkart) > 0 then 1 end as children,
                case when a.on = 1 then null else 5 end as theme
            from t27468_data_kontaktnoe_lico a
            inner join t27468 b on a.idkart = b.idkart
            left join t27468 c on a.idkart = c.parent
            where a.dttmcl is null and b.dttmcl is null
            and b.parent = _client_id
            and (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list))
            group by a.idkart, b.type 
            order by a.name
        ) as a;
	end if;
    
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
	

end;
$$;

alter function elbaza.p27468_tree_view_folder_klient(text, text, text, text, text) owner to site;

