create or replace function elbaza.p30436_tree(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
--=================================================================================================
-- Формирует дерево для списков и обрабатывает его события
--=================================================================================================

declare 
	_name_tree text		= 'tree'; -- название инклюда дерева
    -- система	
  	_event text			= pdb2_event_name( _name_mod ); -- событие модуля
    -- поле поиска
  	_find_text text;

  	_placeholder jsonb; -- placeholder для дерева
 	_parent integer;    -- родитель элемента в дереве
	
	_name_table text;   -- название таблицы, в котором хранится структура дерева
	_name_table_children text;  -- название таблицы, в котором хранится информация о сортировке
	_idtree integer;    -- id элемента в дереве
	_cmd_socket jsonb;  -- команды для сокета
    _type text;         -- тип элемента в дереве

begin
    -- получить название таблицы дерева
 	_name_table = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table}' );
	if _name_table is null then
		raise 'В дереве не заполнена ветка {pdb,table}!';
	end if;
    -- получить название таблицы сортировки
	_name_table_children = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,table_children}' );
	if _name_table_children is null then
		raise 'В дереве не заполнена ветка {pdb,table_children}!';
	end if;
    -- получить название инклюда для поиска
	_find_text = pdb2_val_include_text( _name_mod, _name_tree, '{pdb,find_text}' );
	if _find_text is null then
		raise 'В дереве не заполнена ветка {pdb,find_text}!';
	end if;
    -- получить текст поиска
  	_find_text = pdb2_val_include_text( _name_mod, _find_text, '{value}' );
    
    -- обработка событий
	if pdb2_event_name() = 'submit' then
        _idtree = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' ); -- получить id выделенного элемента в дереве
        select type into _type from t30436 where idkart = _idtree;  -- получить тип выделенного элемента в дереве
        if _type <> 'folder_spiski' then                            
            perform p30436_update_list( _idtree, _type ); -- обновить список
        end if;
    elseif pdb2_event_name() = 'websocket' then 
    -- собрать команды	
		_cmd_socket = '[]'::jsonb || pdb2_val_api( '{HTTP_REQUEST,data,ids}' );
		select jsonb_agg( a.cmd ) into _cmd_socket
		from (
			select 
				jsonb_build_object( 
					'cmd', 'update_id',
					'data', p30436_tree_view( null, null, a.value::integer, _name_table, _name_table_children )
				) as cmd
			from jsonb_array_elements_text( _cmd_socket ) as a
		) as a;		
		if _cmd_socket is not null then
            -- обновить дерево
			perform pdb2_val_include( _name_mod, _name_tree, '{task}', to_jsonb( _cmd_socket ) );
            -- установить информацию по бланкам - НЕ ПРОРАБОТАНО
            -- perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		end if;
    end if;
    
    if _event = 'create' then
        -- добавить ветку
		perform p30436_create( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
		
	elsif _event = 'move' then
        -- перемешение ветки
		perform p30436_tree_move( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
			
	elsif _event = 'rename' then

        -- переименование ветки
		perform pdb2_tpl_tree_rename( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event = 'duplicate' then

        -- дублировать ветку
		perform p30436_tree_duplicate( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;

	elsif _event in ('delete', 'remove') then
        -- удаление ветки
		perform p30436_tree_remove( _name_mod, _name_tree, _name_table, _name_table_children );
		return null;
    
	elsif _event is null then
		perform pdb2_val_session( '_action_tree_', '{mod}', _name_mod );
		perform pdb2_val_session( '_action_tree_', '{inc}', _name_tree );
		perform pdb2_val_session( '_action_tree_', '{table}', _name_table );
		perform pdb2_val_session( '_action_tree_', '{table_children}', _name_table_children );

        -- добавить корень дерева	
		_placeholder = pdb2_val_include( _name_mod, _name_tree, '{placeholder}' );
		execute format( '
			insert into %I( parent, type, name, "on" )
			select 0, a.value ->> ''type'', a.value ->> ''text'', 1
			from jsonb_array_elements( $1 ) as a
			left join %I as b on (a.value ->> ''type'') = b.type
			where (a.value ->> ''type'') like ''root_%%'' and b.idkart is null;', _name_table, _name_table )
		using _placeholder;
		
        -- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );

	elsif _event in ( 'selected', 'opened' ) then

        -- установить информацию по бланкам
		perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
		return null;
		
	elsif _event = 'refresh' then
	
        -- получить переменые
		_parent = pdb2_val_api_text( '{post,id}' );
        -- список веток		
		_placeholder = p30436_tree_view( null, null, _parent, _name_table, _name_table_children );
        -- ветки
		perform pdb2_return( _placeholder );
		return null;
		
	elsif _event = 'children' then
	
        -- получить переменые
		_parent = pdb2_val_api_text( '{post,parent}' );
        -- список веток		
		_placeholder = p30436_tree_view( _parent, _find_text, null, _name_table, _name_table_children );
        -- ветки
		perform pdb2_return( _placeholder );
		return null;

	elsif _event = 'values' then
	
        -- пересоздать дерево
		perform pdb2_val_include( _name_mod, _name_tree, '{data,clear}', 1 );

	end if;

    -- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
    -- собрать root
	_placeholder = p30436_tree_view( 0, _find_text, null, _name_table, _name_table_children );
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

alter function elbaza.p30436_tree(jsonb, text) owner to site;

