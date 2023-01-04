create or replace function elbaza.p27468_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_name_tree text		= 'tree';
-- система	
  	_event text			= pdb2_event_name( _name_mod );
-- поле поиска
  	_find_text text;
    _parent text; 
  	_placeholder jsonb;
	_parent_id text; 
	_id text; 
	_name_table text;
	_name_table_children text;
	_idtree integer;
	_cmd_socket jsonb;
	_idkart text; 
	_data jsonb;
	
begin
	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;
  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );
	
-- обработка событий
	if pdb2_event_name() = 'websocket' then
-- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
        
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p27468_tree_view( _name_mod, _name_tree, null, null, a.value )
                    
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a; 
        
		if _cmd_socket is not null then
-- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
-- установить информацию по бланкам - НЕ ПРОРАБОТАНО
			perform p27468_tree_set( _name_mod, _name_tree, _name_table);

		end if;
		
	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );
-- добавить корень дерева				
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
        
        insert into t27468( parent, type, name, "on" )
        select 0, a.value ->> 'type', a.value ->> 'text', 1
        from jsonb_array_elements( _placeholder ) as a
        left join t27468 as b on (a.value ->> 'type') = b.type
        where (a.value ->> 'type') = 'root_klienti' and b.idkart is null;
        
-- установить информацию по бланкам
		perform p27468_tree_set( _name_mod, _name_tree, _name_table);

	elsif _event in ( 'selected', 'opened' ) then

-- установить информацию по бланкам
		perform p27468_tree_set( _name_mod, _name_tree, _name_table);

		return null;
		
	elsif _event = 'refresh' then
-- получить переменые
		_id = pdb2_val_api_text( '{post,id}' );
        _placeholder = p27468_tree_view( _name_mod, _name_tree, null, null, _id );

-- 		_parent_id = pdb2_tree_placeholder_text( _name_mod, 'tree', _id, 1, '{item, id}' );
        
-- -- список веток	 
-- 		_placeholder = p27468_tree_view( _parent_id, null, null );
-- -- ветки
-- 		select jsonb_agg( a.value ) into _placeholder
-- 		from jsonb_array_elements( _placeholder ) as a
-- 		where a.value ->> 'id' = _id;
--         -- получить переменые
-- -- ветки
		perform pdb2_return( _placeholder );
		return null;

	elsif _event = 'children' then
	
-- получить переменые
		_parent_id = pdb2_val_api_text( '{post,parent}' );

		_placeholder = p27468_tree_view( _name_mod, _name_tree, _parent_id, _find_text, null );
        
-- ветки
		perform pdb2_return( _placeholder );
		
--         _value = pdb_func_alert(_value, 'success',  EXTRACT(EPOCH from clock_timestamp() - TRANSACTION_TIMESTAMP())::text);

		return null;
		
	elsif _event = 'create' then

-- добавить ветку
		perform p27468_tree_create( _name_mod, _name_tree, _name_table, _name_table_children );

		return null; 
		
	elsif _event = 'move' then

-- перемешение ветки
		perform p27468_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then
-- переименование ветки
        
		perform p27468_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
        

		return null;

	elsif _event = 'duplicate' then

-- дублировать ветку
		perform p27468_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then

-- удаление ветки
		perform p27468_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );

		return null;

	elsif _event = 'values' then
	
-- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;
    
-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
-- собрать root

	_placeholder = p27468_tree_view( _name_mod, _name_tree, '0', _find_text, null );

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
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

alter function elbaza.p27468_tree(jsonb, text) owner to site;

