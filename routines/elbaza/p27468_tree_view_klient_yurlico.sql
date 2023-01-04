create or replace function elbaza.p27468_tree_view_klient_yurlico(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
--=======================================================================================--
-- Возвращает placeholder ветки клиента-юрлица
--=======================================================================================--
declare
	_placeholder jsonb = '[]';
	_placeholder_data jsonb;
	_idkart int; 
    _text text;
    _client_id int;
    _cn int;
    
begin
	
    if _id is not null then 
		-- если передан _id собирает возвращает в placeholder данного клиента
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
 		_client_id = _placeholder_data #>> '{data, idkart}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		
		select jsonb_agg( a ) into _placeholder
		from (
            select
                _id as id,
                a.name as "text", 
                a.type as "type",
                _parent_id as parent,
                1 as children,
                case when a.on = 1 then null else 5 end as theme
			from t27468 as a
			where  idkart = _client_id
        ) as a;
        
        -- записать в сессию и получить уникальный ключ в дереве
	    return  _placeholder ;
    end if;
        
    -- получить ID клиента
    _client_id	= pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}'); 

    -- посчитать количество контактных лиц у клиента
    select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id;
    
    -- контактные лица
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_klient',
          'text', 'Контактные лица'
        ),
        'text', 'Контактные лица',
        'type', 'folder_klient',
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'parent', _parent_id,
        'children', case when _cn > 0 then 1 end); 

    -- посчитать количество филиалов у клиента
    select count(*) into _cn from t27468_data_klient 
    where dttmcl is null and idkart <> _client_id
    and inn = (select inn from t27468_data_klient where dttmcl is null and idkart = _client_id);

    -- филиалы
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_filter_klient',
          'text', 'Филиалы'
        ),
        'text', 'Филиалы',
        'type', 'folder_filter_klient',
        'parent', _parent_id,
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'children',  case when _cn > 0 then 1 end);

    -- посчитать количество кустов
    select count(*) into _cn from t27468_data_klient as a 
    where a.dttmcl is null and a.id24001_brush = _client_id;
    
    -- кусты
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_filter_klient',
          'text', 'Кусты'
        ),
        'text', 'Кусты',
        'type', 'folder_filter_klient',
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'parent', _parent_id,
        'children', case when _cn > 0 then 1 end);
    
    -- записать в сессию и получить уникальный ключ в дереве
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

alter function elbaza.p27468_tree_view_klient_yurlico(text, text, text, text, text) owner to site;

