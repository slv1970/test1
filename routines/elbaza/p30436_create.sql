create or replace function elbaza.p30436_create(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
-- система	
 	_pdb_userid	integer	= pdb_current_userid();

  	_idkart integer;
  	_placeholder jsonb;
 	_after text;

	_parent integer;
	_type text; 
	_name text;
 	_children jsonb;

 	_types jsonb;
	_cn integer;
	_list_id int;
    _data_filter jsonb;
    _root_id int; 
    _root_type text; 
    _root_name text; 
    
begin
    -- если тип -- список, создать фильтр
    -- иначе -- получить фильтр
    -- добавить элемент фильтр
    -- сохранить фильтр
    
-- информация по дереву
	_types = pdb2_val_include( _name_mod, _name_tree, '{data,types}' );		
-- получить переменые
	_parent = pdb2_val_api_text('{post,parent}');
	_type = pdb2_val_api_text( '{post,type}' );
	_children = pdb2_val_api( '{post,children}' );
	_after = pdb2_val_api_text( '{post,after}' );
 -- установить имя по умолчанию		
	_name = pdb_val_text( _types, array[_type,'text'] );
-- добавить ветку
	insert into t30436( parent, type, name, userid ) values( _parent, _type, _name, _pdb_userid) returning idkart
	into _idkart;
    
    if _type = 'item_spisok' then
        -- при создании списка сформировать фильтр для списка
        select idkart, name, type into _root_id, _root_name, _root_type from t30436 where parent = 0 and type = 'root_spiski';
        
        _data_filter = jsonb_build_object(
                    _root_id, jsonb_build_object(
                           'id', _root_id,
                           'name', _root_name,
                           'type', _root_type,
                           'parent', 0,
                           'on', 1),
                    _idkart, jsonb_build_object(
                            'id', _idkart,
                            'name', _name,
                            'type', _type,
                            'parent', _root_id)
                    );
        -- сохранить фильтр
        update t30436_data_spisok set data_filter = _data_filter where idkart = _idkart;
    elseif _type <> 'folder_spiski' then
        -- при создании элементов списка, добавить в фильтр новый элемент
        -- получить id списка в котором создан элемент и его фильтр
        select idkart, data_filter into _list_id, _data_filter from t30436_data_spisok where userid = _pdb_userid and data_filter ? _parent::text;
        -- добавить новый элемент в фильтр
        _data_filter = _data_filter || jsonb_build_object(_idkart, 
                        jsonb_build_object('id', _idkart,
                                           'name', _name,
                                           'type', _type,
                                           'parent', _parent));
        -- сохранить фильтр
        update t30436_data_spisok set data_filter = _data_filter where idkart = _list_id;
    end if;
    
-- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _idkart );
-- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
-- проверка записи
	select count(*) from t30436_children as a where a.idkart = _parent into _cn;
	if _cn > 0 then
-- изменить позцию позиции
		update t30436_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent;
	else
-- установить позицию
		insert into t30436_children( idkart, children ) values ( _parent, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
-- получить новую ветку		
	_placeholder = pdb2_tpl_tree_view( null, null, _idkart, _name_table, _name_table_children );
-- установить информацию по бланкам
	perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );	
-- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent );
-- новая ветка

	perform pdb2_return( _placeholder );

end;
$$;

alter function elbaza.p30436_create(text, text, text, text) owner to site;

