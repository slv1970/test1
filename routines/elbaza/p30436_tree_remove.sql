create or replace function elbaza.p30436_tree_remove(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Удаляет элемент в дереве и удаляет всю его ветку в фильтре списка
--=================================================================================================
declare 
 	_pdb_userid	integer	= pdb_current_userid(); -- текущий пользователь

  	_idkart integer; -- idkart удаленного элемента в таблице дерева   
  	_parent integer; -- parent удаленного элемента в таблице дерева 
  	_idkart_old integer; -- id выделенного элемента в дереве
    _list_id int;   -- список в котором находится удаленный элемент дерева
    _data_filter jsonb; -- фильтр списка
    
begin
    -- получить переменые
	_idkart = pdb2_val_api_text( '{post,id}' );
    -- удаление ветки
	update t30436 set dttmcl = now() where idkart = _idkart returning parent into _parent;
    -- получить id выделенного элемента в дереве
	_idkart_old = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	if _idkart = _idkart_old then -- если удаляется выделенный элемент
    -- убрать позицию
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
	end if;
    
    -- получить id списка
    select idkart, data_filter into _list_id, _data_filter from t30436_data_spisok where userid = _pdb_userid and data_filter ? _idkart::text;
    
    -- удалить из фильтра ветку
    with recursive temp1 ( id ) as 
    (
        select _idkart::text
        union all
        select a.key
        from jsonb_each( _data_filter ) as a
        inner join temp1 as t on a.value ->> 'parent' = t.id
    )
    select jsonb_object_agg( a.key, a.value ) into _data_filter
    from jsonb_each( _data_filter ) as a
    left join temp1 as t on a.value ->> 'id' = t.id
    where t.id is null;
    
    -- обновить список
    update t30436_data_spisok set data_filter = _data_filter where idkart = _list_id;
    
    -- установить информацию по бланкам
	perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
    -- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent );	
		
end;
$$;

alter function elbaza.p30436_tree_remove(text, text, text, text) owner to site;

