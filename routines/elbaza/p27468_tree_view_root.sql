create or replace function elbaza.p27468_tree_view_root(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
    _event text         = pdb2_event_name( _name_mod );
    _include text       = pdb2_event_include( _name_mod );
	_list_id int        = pdb2_val_include_text( _name_mod, 'list', '{value}');
	_placeholder jsonb  = '[]';
    _client_ids int[];
    _cn_all int;
    _cn_ric int;
    _cn_metki int;
    _text_pref_root text;   
    _text_pref_ric text;    
    _text_pref_metki text;  
    _text_pref_kusty text;  
    _root_id int; 
    
begin
    -- при первом открытии страницы, при поиске по тексту и по списку отфильтровать клиентов
    if _event is null or _event = 'refresh' or _event = 'values' and _include in ('find', 'list') then
        if _list_id is null then 
        -- если не выбран список - выборка по всем клиентам
            select _client_ids_out, _cn_all_out, _cn_ric_out, _cn_metki_out
            from p27468_query_all( _name_mod, _name_find)
            into _client_ids, _cn_all, _cn_ric, _cn_metki; 
        else
            -- если выбран список - выборка по отфильтрованным клиентам
            select _client_ids_out, _cn_all_out, _cn_ric_out, _cn_metki_out
            from p27468_query_list( _name_mod, _list_id, _name_find)
            into _client_ids, _cn_all, _cn_ric, _cn_metki; 
        end if; 
        
        -- записать в сессию
        perform pdb2_val_session('p27468_tree', '{client_ids}', _client_ids::text); 
        perform pdb2_val_session('p27468_tree', '{cn_all}', _cn_all); 
        perform pdb2_val_session('p27468_tree', '{cn_ric}', _cn_ric); 
        perform pdb2_val_session('p27468_tree', '{cn_metki}', _cn_metki); 
    else
        _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
        _cn_all = pdb2_val_session_text('p27468_tree', '{cn_all}'); 
        _cn_ric = pdb2_val_session_text('p27468_tree', '{cn_ric}'); 
        _cn_metki = pdb2_val_session_text('p27468_tree', '{cn_metki}'); 
    end if;
    
    if (_list_id is not null or _name_find is not null) and _cn_all = 0 then
        return null;
    end if;
     
    _text_pref_root = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
    _text_pref_ric = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_ric || '</span>' );
    _text_pref_metki = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_metki || '</span>' );
    _text_pref_kusty = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
    
    -- получаем id корня клиентов
	select idkart 
	from t27468 
	where parent = 0 
	and type = 'root_klienti' into _root_id;
	-- по Алфавиту
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_klienti',
                  'text', 'по Алфавиту',
				  'idkart', _root_id
				),
				'text', 'по Алфавиту',
                'text_pref', _text_pref_root,
				'type', 'root_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
	
    -- по РИЦам		
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_filter_klienti',
				  'text', 'по РИЦам'
				),
				'text', 'по РИЦам',
				'type', 'root_filter_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
	
    -- по Меткам 
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_filter_klienti',
				  'text', 'по Меткам'
				),
				'text', 'по Меткам',
				'type', 'root_filter_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
	-- по Кустам	
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', 'root_filter_klienti',
				  'text', 'по Кустам'
				),
				'text', 'по Кустам',
				'type', 'root_filter_klienti',
				'parent', 0,
				'children', case when _cn_all > 0 then 1 end);
                
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

alter function elbaza.p27468_tree_view_root(text, text, text, text, text) owner to site;

