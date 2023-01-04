create or replace function elbaza.p27468_tree_view_root_klienti(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
	_placeholder jsonb = '[]';
    _placeholder_data jsonb; 
	_type text;
	_idkart int; 
	_client_ids int[];
    _text text;
    _cn_all int;
    _text_pref_root text;
    _clients_all boolean;
    _cn int;
    
begin
   _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 

    -- формирование placeholder-а по id для папки "по Алфавиту". Возвращает папку "по Алфавиту"
    if _id is not null then
        _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, null ); 
        -- получить ID родителя
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
        -- получить название элемента в дереве
		_text = _placeholder_data #>> '{data, text}'; 
        -- получить тип элемента в дереве
        _type = _placeholder_data #>> '{data, type}'; 
        -- получить количество всех клиентов
        select count(*) into _cn_all from t27468_data_klient where dttmcl is null and (_client_ids is null or idkart = any(_client_ids));
        -- добавить количество клиентов к названию
        _text_pref_root = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
        
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                _id as id,
                _text as "text", 
                _type as "type",
                _parent_id as parent,
                case when _cn_all > 0 then 1 end as children,
                _text_pref_root as text_pref
        ) as a;
        
        return _placeholder;
    end if;

    -- формирование placeholder-а для папки "по Алфавиту". Собирает буквы алфавита, с которых начинаются названия клиентов
    
    select jsonb_agg( a ) into _placeholder
    from (
        select 
            jsonb_build_object(
              'type', 'folder_klienti',
              'text', a.letter,
              'folder', 'letter'
            ) as id,
            a.letter as "text", 
            'folder_klienti' as "type",
            _parent_id as parent,
            1 as children 
        from (
            select distinct letter
            from t27468_data_klient as a
            where a.dttmcl is null 
            and (_client_ids is null or a.idkart = any(_client_ids))
            order by a.letter
        ) as a
    ) as a;
    
    -- записывает в сессию и формирует уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

alter function elbaza.p27468_tree_view_root_klienti(text, text, text, text, text) owner to site;

