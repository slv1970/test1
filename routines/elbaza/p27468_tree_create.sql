create or replace function elbaza.p27468_tree_create(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Создает элемент дерева клиентов, обновляет таблицу сортировки дерева
--=================================================================================================
declare 
-- система	
 	_pdb_userid	integer	= pdb_current_userid(); -- текущий пользователь

  	_placeholder jsonb = '[]';                  -- placeholder для нового элемента дерева
 	_after text;                                

	_type text;         -- тип элемента в дереве
	_name text;         -- имя элемента в дереве
 	_types jsonb;       -- типа элементов дерева и их данные    
	_cn integer;        -- count, для проверки наличия элемента
	_id text;			-- ID элемента в дереве (в виде ключа)
	_parent_id text;	-- ID родителя в дереве (в виде ключа)
    _idkart int; 		-- idkart созданного элемента в таблице дерева
	_parent_idkart int; -- idkart родителя в таблице дерева
 	_children jsonb;     -- массив ID дочерних элементов папки, в которой создается элемент
	_children_arr int[]; -- массив idkart дочерних элементов в виде int[]

begin
    -- информация по дереву
	_types = pdb2_val_include( _name_mod, _name_tree, '{data,types}' );	
    -- ID родителя в дереве (в виде уникального ключа)
	_parent_id = pdb2_val_api_text( '{post, parent}' ); 
    -- idkart родителя в таблице дерева 
	_parent_idkart = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' ) ;
	-- тип элемента в дереве
	_type = pdb2_val_api_text( '{post, type}' ); 
    -- дочерние элементы папки, в которой создается новый элемент
    _children = pdb2_val_api( '{post,children}' );
	_after = pdb2_val_api_text( '{post, after}' );
    
    -- установить имя по умолчанию		
	_name = pdb_val_text( _types, array[_type,'text'] );
    
    -- добавить ветку
	execute format('insert into %I( parent, type, name, userid ) values( $1, $2, $3, $4 ) returning idkart;', _name_table)
	using _parent_idkart, _type, _name, _pdb_userid
	into _idkart;
    
    -- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    
    -- клиенты и контактные лица упорядочиваются автоматически
    if _type not in ('item_klient_fizlico', 'item_klient_yurlico', 'item_kontaktnoe_lico') then
        
        -- превращает jsonb-массив из id в дереве в int-массив из idkart в таблице дерева
        select array_agg(pdb2_tree_placeholder_text( _name_mod, _name_tree, a.value, 0,  '{data, idkart}' )::int )
        from jsonb_array_elements_text(_children) as a
        into _children_arr;
        
        execute format('select count(*) from %I as a where a.idkart = $1', _name_table_children) 
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
    end if;
    
    -- получить новую ветку	 
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', _type,
                  'text', _name,
				  'idkart', _idkart
				),
				'text', _name,
				'type', _type,
				'parent', _parent_id,
				'children', case when _type in ('item_klient_fizlico', 'item_klient_yurlico') then 1 end,
				'theme', 5);
                
	-- преобразовать id и сохранить данные в сессии
	_placeholder = pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );
    
 	-- получить id в дереве
    _id = _placeholder #>> '{0, id}';
    
	-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _id );
	
    -- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table); 
    
    -- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id );
    
    -- новая ветка
	perform pdb2_return( _placeholder );

end;
$$;

alter function elbaza.p27468_tree_create(text, text, text, text) owner to site;

