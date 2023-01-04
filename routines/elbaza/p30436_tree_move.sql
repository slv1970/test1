create or replace function elbaza.p30436_tree_move(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Обновляет таблицу дерева и фильтр списка при перемещении элементов в дереве
-- возможно перемещение папок внутри списка, между списками и папок пользователя
--=================================================================================================

declare 
 	_pdb_userid	integer	= pdb_current_userid(); -- текущий пользователь

  	_idkart integer;     -- id перемещенного элемента
	_parent_new integer; -- id папки куда переместили
	_parent_old integer; -- id папки откуда переместили
 	_children jsonb;     -- список id всех элементов папки, куда переместили элемент (с учетом перемещенного)
	_cn integer;         -- count, для проверки наличия записи в таблице
    _list_id_old int;    -- id списка, откуда переместили элемент
	_list_id_new int;    -- id списка, куда переместили элемент
    
    _item_filter jsonb; 
    _data_filter_old jsonb; -- фильтр списка, из которого переместили элемент
    _data_filter_new jsonb; -- фильтр списка, в который переместили элемент
    _type text;
    
begin
    -- получить переменные
	_idkart = pdb2_val_api_text( '{post,id}' );
	_parent_new = pdb2_val_api_text( '{post,parent}' );
	_children = pdb2_val_api( '{post,children}' );
    
    -- получить родителя, откуда переместили элемент
	select a.parent, a.type from t30436 as a where a.idkart = _idkart into _parent_old, _type;
    -- смена родителя
	update t30436 set dttmup = now(), parent = _parent_new where idkart = _idkart;
    -- проверка записи
	select count(*) from t30436_children as a where a.idkart = _parent_new into _cn;
	if _cn > 0 then
    -- изменить позцию позиции
		update t30436_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_new;
	else
    -- установить позицию
		insert into t30436_children( idkart, children ) values ( _parent_new, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
    
    -- при перемещении самих списков и папок со списками фильтры не меняются, в остальных случаях обновить оба фильтра
    if _type not in ('item_spisok', 'folder_spiski') then
        -- получить id нового списка и его фильтр
        select idkart, data_filter into _list_id_new, _data_filter_new from t30436_data_spisok where userid = _pdb_userid and data_filter ? _parent_new::text;
        
        -- получить id старого списка и его фильтр
        select idkart, data_filter into _list_id_old, _data_filter_old from t30436_data_spisok where userid = _pdb_userid and data_filter ? _parent_old::text;
        
        -- если перемещение внутри списка, обновить родителя
        if _list_id_new = _list_id_old then
            _data_filter_new = pdb_val( _data_filter_new, array[_idkart::text, 'parent'], _parent_new );
            update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new;
        else
        -- если перемещение между списками обновить оба фильтра: удалить перемещенную ветку из старого списка и добавить в новый
            with recursive temp1 ( id, val ) as  -- обновить новый фильтр
            (
                select _idkart::text, _data_filter_old -> _idkart::text
                union all
                select a.key, a.value
                from jsonb_each( _data_filter_old ) as a
                inner join temp1 as t on a.value ->> 'parent' = t.id
            )
            select jsonb_object_agg(a.id, a.val) into _item_filter
            from temp1 as a;
            -- обновить родителя в фильтре
            _item_filter = pdb_val( _item_filter, array[_idkart::text, 'parent'], _parent_new );
            -- добавить в новый фильтр
            _data_filter_new = _data_filter_new || _item_filter; 

            with recursive temp1 ( id ) as -- обновить старый фильтр
            (
                select _idkart::text
                union all
                select a.key
                from jsonb_each( _data_filter_old ) as a
                inner join temp1 as t on a.value ->> 'parent' = t.id
            )
            select jsonb_object_agg( a.key, a.value ) into _data_filter_old
            from jsonb_each( _data_filter_old ) as a
            left join temp1 as t on a.value ->> 'id' = t.id
            where t.id is null;

            -- сохранить старый фильтр
            update t30436_data_spisok set data_filter = _data_filter_old where idkart = _list_id_old;
            -- сохранить новый фильтр
            update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new;
        end if;
	end if;
    
    -- подготвить данные для сокета - обновить родителя	
	if _parent_new = _parent_old then
		perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_new );	
	else
    -- проверка вложенности _parent_old в _parent
        with recursive temp1 ( parent ) as  -- получить всех родителей parent_new
        (	
            select a.parent
            from t30436 as a
            where a.idkart = _parent_new
            union all
            select a.parent
            from t30436 as a
            inner join temp1 as t on a.idkart = t.parent
        )
        select count(*) from temp1 as a
        where a.parent = _parent_old
        into _cn;
        
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_old );
			return;
		end if;
-- проверка вложенности _parent в _parent_old
        with recursive temp1 ( parent ) as 
        (	
            select a.parent
            from t30436 as a
            where a.idkart = _parent_old
            union all
            select a.parent
            from t30436 as a
            inner join temp1 as t on a.idkart = t.parent
        )
        select count(*) from temp1 as a
        where a.parent = _parent_new
		into _cn;
        
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_new );
			return;
		end if;
-- обновить оба родителя 
		perform pdb2_val_page( '{pdb,socket_data,ids}', array[ _parent_new, _parent_old ] );	
	end if;
end;
$$;

alter function elbaza.p30436_tree_move(text, text, text, text) owner to site;

