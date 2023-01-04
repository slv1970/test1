create or replace function elbaza.p27468_tree_view_klient_fizlico(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder ветки клиента-физлица
--=======================================================================================--
	_placeholder jsonb      = '[]'; -- возвращаемое значение
	_placeholder_data jsonb;        -- данные placeholder-а из сессии
	_client_id int;                 -- ID клиента
	_text text;                     -- название элемента в дереве
    _cn int;                        -- количество
    
begin
    -- если передан _id собирает возвращает в placeholder данного клиента
	if _id is not null then 
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
 		_client_id = _placeholder_data #>> '{data, idkart}'; 
 		_parent_id = _placeholder_data #>> '{item, parent}'; 
		
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
			where dttmcl is null
            and idkart = _client_id
        ) as a;
        
        -- записать в сессию и присвоить уникальный ключ
	    return _placeholder;
    end if;
    
    -- получить ID клиента
    _client_id	= pdb2_tree_placeholder(_name_mod, _name_tree, _parent_id, 0, '{data, idkart}'); 
    
    -- посчитать количество контактных лиц у клиента
    select count(*) into _cn from t27468 where dttmcl is null and parent = _client_id; 
    
    -- собрать placeholder для клиента (физическое лицо)
    _placeholder = _placeholder || jsonb_build_object(
        'id', jsonb_build_object(
          'type', 'folder_klient',
          'text', 'Контактные лица'
        ),
        'text', 'Контактные лица',
        'type', 'folder_klient',
        'parent', _parent_id,
        'text_pref', case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end,
        'children', case when _cn > 0 then 1 end);
    
    -- записать в сессию и присвоить уникальный ключ
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
	

end;
$$;

alter function elbaza.p27468_tree_view_klient_fizlico(text, text, text, text, text) owner to site;

