create or replace function elbaza.p27471_tree_create(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
-- система	
 	_pdb_userid	integer	= pdb_current_userid();

  	_placeholder jsonb = '[]';
 	_after text;

	_type text; 
	_name text;
 	_children jsonb;
	
 	_types jsonb;
	_cn integer;
	_idkart int; 		-- ID созданного элемента в таблице t27471
	_parent_idkart int; -- ID родителя в таблице t27471
	_id text;			-- ID элемента в дереве
	_parent_id text;	-- ID родителя в дереве
	_placeholder_data jsonb;
    _parent text;
begin
    _types = pdb2_val_include( _name_mod, _name_tree, '{data,types}' );	
-- получить переменые 
	_parent_id = pdb2_val_api_text( '{post, parent}' ); 
	_parent_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id, 0, '{data, idkart}');
	_type = pdb2_val_api_text( '{post, type}' ); 
	_after = pdb2_val_api_text( '{post, after}' );
-- установить имя по умолчанию		
	_name = pdb_val_text( _types, array[_type,'text'] );
-- добавить ветку
	insert into t27471( parent, type, name, userid ) values( _parent_idkart, _type, _name, _pdb_userid ) 
	returning idkart into _idkart;
-- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    
-- проверка записи
	select count(*) from t27471_children as a where a.idkart = _parent_idkart into _cn; 
	
	_children = pdb2_val_api( '{post,children}' );
	
	-- получает jsonb-массив idkart для children элементов
	select jsonb_agg(pdb2_tree_placeholder_text( 'p27471_tree', 'tree', a.value, 0,  '{data, idkart}' ) )
	from jsonb_array_elements_text(_children) as a
	into _children;
	
	if _cn > 0 then
-- изменить позцию позиции
		update t27471_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_idkart;
	else
-- установить позицию
		insert into t27471_children( idkart, children ) values ( _parent_idkart, pdb_sys_jsonb_to_int_array( _children ));
	end if;
-- получить новую ветку	 
	_placeholder = _placeholder || jsonb_build_object(
				'id', jsonb_build_object(
				  'type', _type,
				  'idkart', _idkart
				),
				'text', _name,
				'type', _type,
				'parent', _parent_id,
				'children', case when _type in ('item_dokument') then 1 end,
				'theme', 5);
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

alter function elbaza.p27471_tree_create(text, text, text, text) owner to site;

