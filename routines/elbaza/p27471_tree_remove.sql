create or replace function elbaza.p27471_tree_remove(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_idkart integer;
	_id text;
  	_parent text;
  	_idkart_old integer;
	_id_old text;
	_parent_id text;
	_placeholder_data jsonb;
    _data jsonb;
    _placeholder jsonb;
    _tree_idkart text;
	_reload text[];
    _cmd_socket jsonb;
    _find_text text;
    _tx_id text;
    _tx_parent text;
begin
    _tree_idkart = pdb2_val_api_text( '{post,id}' );
	_data = pdb2_tree_placeholder( _name_mod, 'tree', _tree_idkart, 4, '{data}' );
    _tx_id = pdb2_val_api_text( '{post,id}' );
	_tx_parent = pdb2_val_api_text( '{post,parent}' );
-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
    _placeholder_data = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, null);
	_idkart = _placeholder_data #>> '{data, idkart}';
	_parent_id = _placeholder_data #>> '{item, parent}';
    perform p27471_tree_view_root(_parent_id, null, null); 
-- удаление ветки
    execute format( 'update %I set dttmcl = now() where idkart = $1;', _name_table)
	using _idkart;

	_id_old = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	
	if _id = _id_old then
-- убрать позицию
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
	end if;
-- установить информацию по бланкам
 	perform p27471_tree_set( _name_mod, _name_tree, _name_table, null );

    --raise '%, %', _name_mod, _name_tree;
    _placeholder = p27471_tree_view( '0', _find_text, null );
-- установить корень дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{data,root_id}', 0 );
-- загрузить список дерева	
	perform pdb2_val_include( _name_mod, _name_tree, '{placeholder}', _placeholder );
-- проверка списка 
	if _placeholder is null or _placeholder = '[]' then
-- убрать позицию	
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
-- скрыть дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{hide}', 1 );
-- открыть подсказку
		perform pdb2_val_include( _name_mod, 'no_find', '{hide}', null );
	end if;    
    
    _id = _parent_id;
    _parent_id = pdb2_tree_placeholder_text( _name_mod, 'tree', _id, 4, '{item, id}' );
-- список веток	 
    _placeholder = p27471_tree_view( _parent_id, null, null );
-- ветки
    select jsonb_agg( a.value ) into _placeholder
    from jsonb_array_elements( _placeholder ) as a
    where a.value ->> 'id' = _id;

    perform pdb2_return( _placeholder );
    perform pdb2_event_module();
    
    perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );
    --raise '%', _data;
    if _data ->> 'type' = 'root_firma' then
    
         perform pdb2_val_include( _name_mod, 'idkart', '{var}', null );
		 perform pdb2_mdl_before( _name_mod );
		 --_idkart = pdb2_val_include_text( _name_mod, 'idkart', '{var}' );
-- запросить root папок
		--_value = lk_27102_tree_view( _value, _mod_tree, null, null, null ); 
		_placeholder = p27471_tree_view( _parent_id, null, null );
        --raise '%', _placeholder;
-- найти позицию - root_appeal
		select a.value ->> 'id' into _id
		from jsonb_array_elements( _placeholder ) as a
		where a.value ->> 'type' = 'root_firma';
        
        --raise '%', _id;
-- перезагрузить дерево 			
		perform pdb2_val_include( _name_mod, 'tree', '{task}',
							  array[ 
									jsonb_build_object( 'cmd', 'reload_id', 'data', 
											array[
												_tx_parent
											]
									)
							  ]
						);			
-- получить список элементов			
		--_value = lk_27102_tree_view( _value, _mod_tree, _id, null, null ); 
		perform pdb2_return( _placeholder );
        
--         _data = pdb2_tree_placeholder( _name_mod, 'tree', _tree_idkart, 4, null ) ->> 'item';
-- 	    _placeholder = p27471_tree_view( _data ->> 'parent', null, null );
        
        
        
--         select jsonb_agg( a.value ) into _placeholder
--         from jsonb_array_elements( _placeholder ) as a
--         where a.value #>> '{type}' <> 'folder_filter2';
        
--         perform pdb2_tree_placeholder( _name_mod, 'tree', _placeholder );
-- 		_placeholder = pdb2_val_include( _name_mod, 'tree', '{placeholder}' );
--         --raise '%, %', _data, _placeholder;
--         select array_agg( a.value ->> 'id' ) into _reload
--         from jsonb_array_elements( _placeholder ) as a;
--         --raise '%', _reload;
--         perform pdb2_val_include( _name_mod, 'tree', '{task}',
--                                   array[ 
--                                         jsonb_build_object( 'cmd', 'reload_id', 'data', _reload )
--                                   ]
--                                                 );
--         perform pdb2_return( _placeholder );
        --raise '%', pdb2_val_include_text(_name_mod, 'tree', '{task}');
    end if;
 
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
    _id = _placeholder #>> '{0, id}';
	-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _id ); 
-- установить информацию по бланкам
	perform p27471_tree_set( _name_mod, _name_tree, _name_table , null); 
-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );
-- новая ветка
-- [{"id": "370d78db3b9ea91dee16a5c35e3c1cd5", "text": "Клиент (Физическое лицо)", "type": "item_klient_fizlico", "theme": 5, "parent": "53eccdc70435c519f15f1fff958f4971", "children": 1}]
    perform pdb2_return( _placeholder );
end;
$$;

alter function elbaza.p27471_tree_remove(text, text, text, text) owner to site;

