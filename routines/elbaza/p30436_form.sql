create or replace function elbaza.p30436_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
    _pdb_userid integer	= pdb_current_userid();

	_b_submit integer	= pdb2_val_include_text( _name_mod, 'b_submit', '{var}' );
	_event text			= pdb2_event_name( _name_mod );
	_include text		= pdb2_event_include( _name_mod );

	_list_name text;            
	_list_name_new text;       

	-- id выбранного названия списка
    _data_filter_old jsonb;
    _data_filter_new jsonb = '{}';
    _filter_id int;
    _filter_parent int; 
    _list_id_new int; 
    _rc record;
    _idkart_matches jsonb;
    _list_id int = pdb2_val_include_text('p30436_property_spisok', 'idkart', '{var}');
    _users jsonb = pdb2_val_include_text(_name_mod, 'users', '{value}');
    
begin 
    -- Инициализация переменных
	perform pdb2_mdl_before( _name_mod );
    
	-- Получает название выбранного шаблона по id для вставки в поля с названием шаблона:
	select a.name into _list_name
	from t30436_data_spisok as a
	where a.idkart = _list_id;
	-- Прописывает название шаблона письма в поля
	perform pdb2_val_include( _name_mod, 'list_name', '{value}', _list_name );

	if _event is null then
	    perform pdb2_val_include( _name_mod, 'list_name_new', '{value}', _list_name );
    end if;
    
	if _event = 'submit' then
    
		-- Получает выбранные значения из полей:
		_list_name = pdb2_val_include_text( _name_mod, 'list_name', '{value}' );    -- оригинальное название списка
		
		_list_name_new = COALESCE(                                                   -- выходное название списка
			pdb2_val_include_text( _name_mod, 'list_name_new', '{value}'), _list_name
		);
        -- получить фильтр для добавления к скопированному списку
        select data_filter into _data_filter_old from t30436_data_spisok where idkart = _list_id; 
        
        for _rc in select * from unnest(pdb_sys_jsonb_to_int_array(_users)) as usr
        loop
            perform pdb2_val_session('p30436_form', '{idkart_matches}', null);
            -- сохранить копию и получить id скопированной записи
            _list_id_new = p30436_tree_share_copy( _list_id, null, _list_name_new, _rc.usr);
            
            _idkart_matches = pdb2_val_session('p30436_form', '{idkart_matches}'); 
            
            for _rc in 
                select a.key, a.value from jsonb_each(_data_filter_old) as a
                order by a.key 
            loop
                if _rc.value ->> 'type' = 'root_spiski' then
                    _data_filter_new = jsonb_build_object(_rc.key, _rc.value);
                else
                    _filter_id = coalesce(_idkart_matches ->> _rc.key::text, _rc.key::text); 
                    _filter_parent = coalesce(_idkart_matches ->> (_rc.value ->> 'parent'), (_rc.value ->> 'parent')); 
                    _rc.value = pdb_val(_rc.value, array['id'], _filter_id);
                    _rc.value = pdb_val(_rc.value, array['parent'], _filter_parent);
                    _data_filter_new = _data_filter_new || jsonb_build_object(_filter_id, _rc.value);
                end if;
            end loop;
            update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new; 
        end loop;
    
        perform pdb2_val_function( 'message', 'share_success', 1 ); 
    end if;
         
	perform pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

alter function elbaza.p30436_form(jsonb, text) owner to site;

