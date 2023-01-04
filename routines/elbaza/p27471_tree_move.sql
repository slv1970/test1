create or replace function elbaza.p27471_tree_move(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_idkart integer; 			-- idkart перемещаемого элемента из таблицы t27471
	_parent_idkart_new integer; -- parent перемещаемого элемента из таблицы t27471 после перемещения
	_parent_idkart_old integer; -- parent перемещаемого элемента из таблицы t27471 до перемещения
    _client_idkart_old integer;
    _client_idkart_new integer;
	_cn integer;
	
	_id text; 					-- ID перемещаемого элемента в дереве
	_parent_id_new text; 		-- ID папки, в который перемещается элемент
	_parent_id_old text; 
 	_children jsonb;			-- массив id children-элементов для parent
	
begin
	-- получает ID перемещаемого элемента в дереве
	_id = pdb2_val_api_text( '{post,id}' );
	-- получает ID родителя в дереве, куда перемещается элемент  
	_parent_id_new = pdb2_val_api_text( '{post,parent}' );
 	_parent_id_old = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{item, parent}' );
	-- получает jsonb-массив из children элементов, куда перемещается элемент 
	_children = pdb2_val_api( '{post,children}' );
	-- получает idkart перемещаемого элемента
	_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, null ) #>> '{data, idkart}';
	-- получает idkart родителя, куда перемещается элемент
	_client_idkart_new = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id_new, 0, null ) #>> '{data, idkart}';
    _parent_idkart_new = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id_old, 0, null ) #>> '{data, parent}';
    
    --raise '%, %', _parent_idkart_new, _client_idkart_new;
	-- получает jsonb-массив idkart для children элементов
	select jsonb_agg(pdb2_tree_placeholder( 'p27471_tree', 'tree', a.value, 0, null ) #>> '{data, idkart}') 
	from jsonb_array_elements_text(_children) as a
	into _children;
	-- получает idkart родителя, откуда перемещается элемент
	select a.parent, t27471_data_dokument.client
    from t27471 as a 
    join t27471_data_dokument on a.idkart = t27471_data_dokument.idkart
    where a.idkart = _idkart 
	into _parent_idkart_old, _client_idkart_old; 
    --raise '%, %',  _client_idkart_old, _client_idkart_new;
	-- смена родителя
	update t27471 set dttmup = now(), parent = _client_idkart_new where idkart = _idkart;
    update t27471_data_dokument set dttmup = now(), client = _client_idkart_new where idkart = _idkart;
	
	-- проверка записи
	select count(*) from t27471_children as a where a.idkart =_parent_idkart_new 
	into _cn;

	if _cn > 0 then
-- изменить позцию позиции
		update t27471_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_idkart_new;
	else
-- установить позицию
		insert into t27471_children( idkart, children ) values ( _parent_idkart_new, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
-- подготвить данные для сокета - обновить родителя	
	if _parent_idkart_new = _parent_idkart_old then
		perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_new );	
	else
-- проверка вложенности _parent_idkart_old в _parent_idkart_new
			with recursive temp1 ( parent ) as 
			(	
				select a.parent
				from t27471 as a
				where a.idkart = _parent_idkart_new
				union all
				select a.parent
				from t27471 as a
				inner join temp1 as t on a.idkart = t.parent
			)
			select count(*) from temp1 as a
			where a.parent = _parent_idkart_old
			into _cn;
			
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_old );
			return;
		end if;
-- проверка вложенности _parent_idkart_new в _parent_idkart_old
			with recursive temp1 ( parent ) as 
			(	
				select a.parent
				from t27471 as a
				where a.idkart = _parent_idkart_old
				union all
				select a.parent
				from t27471 as a
				inner join temp1 as t on a.idkart = t.parent
			)
			select count(*) from temp1 as a
			where a.parent = _parent_idkart_new
			into _cn;
			
		if _cn > 0 then
			perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_new );
			return;
		end if;
-- обновить оба родителя 
		perform pdb2_val_page( '{pdb,socket_data,ids}', array[ _parent_id_new, _parent_id_old ] );
			
	end if;
	
end;
$$;

alter function elbaza.p27471_tree_move(text, text, text, text) owner to site;

