create or replace function elbaza.p27468_tree_duplicate(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Дублирует элемент дерева и всю ветку данного элемента. 
--=================================================================================================
declare
  	_idkart integer;	    -- ID нового элемента (копии) из таблицы дерева
 	_after_idkart integer;  -- ID дублируемого элемента из таблицы дерева 
	_parent_idkart integer; -- parent дублируемого элемента из таблицы дерева
	_id text; 		 		-- ID нового элемента в дереве
	_after_id text;	 		-- ID дублируемого элемента в дереве
	_parent_id text; 		-- parent дублируемого элемента в дереве
	_children jsonb; 		-- children элементы внутри папки _parent_id
  	_placeholder jsonb = '[]';	-- placeholder для новой записи
	_cn integer;			-- count для проверки наличия записи
	_name text;				-- название нового элемента
	_type text; 			-- тип нового элемента
	_after text;			
	_children_arr int[];
    
begin
	
	-- получить переменые
	_parent_id = pdb2_val_api_text( '{post,parent}' ); 
	_children = pdb2_val_api( '{post,children}' );		
	_after_id = pdb2_val_api_text( '{post,id}' );
	
	_parent_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
	_after_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _after_id, 0, '{data, idkart}' );
	-- создает дубликат записи в таблице и возвращает его idkart
	_idkart = p27468_tree_duplicate_copy( _after_idkart, null ); 
	-- получает название и тип нового элемента
	select type, name from t27468 where idkart = _idkart into _type, _name;
	-- формирует ветку для нового элемента
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', _type,
                  'text', _name,
				  'idkart', _idkart
				),
				'text', _name,
				'type', _type,
				'parent', _parent_id,
				'theme', 5);
	-- преобразует id placeholderа и сохраняет его данные 			
	_placeholder = pdb2_tree_placeholder( 'p27468_tree', 'tree', _placeholder );
 	-- получает преобразованный id - уникальный id в дереве
	_id = _placeholder #>> '{0, id}';
    -- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected, 0}', _id );

	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    
    
	-- превращает массив ключей children в дереве, в массив idkart 
    select array_agg(pdb2_tree_placeholder_text( _name_mod, _name_tree, a.value, 0,  '{data, idkart}' )::int )
    from jsonb_array_elements_text(_children) as a
    into _children_arr;

	-- проверка записи
	execute format ('select count(*) from %I as a where a.idkart = $1', _name_table_children)
    using _parent_idkart into _cn; 
    
	if _cn > 0 then
	-- изменить позцию позиции
        execute format( 'update %I set children = $1 where idkart = $2;', _name_table_children )
		using _children_arr, _parent_idkart;
	else
	-- установить позицию
        execute format( 'insert into %I( idkart, children ) values ( $1, $2 );', _name_table_children )
		using _parent_idkart, _children_arr;
	end if;
    
	-- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table);
	-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );	
	-- новая ветка
	perform pdb2_return( _placeholder );
	
end;
$$;

alter function elbaza.p27468_tree_duplicate(text, text, text, text) owner to site;

