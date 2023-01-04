create or replace function elbaza.p27468_tree_move(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Перемещает элемент в дереве
--=================================================================================================
declare 
  	_idkart integer; 			-- idkart перемещаемого элемента из таблицы t27468
	_parent_idkart_new integer; -- parent перемещаемого элемента из таблицы t27468 после перемещения
	_parent_idkart_old integer; -- parent перемещаемого элемента из таблицы t27468 до перемещения
	_parent_id_new text; 		-- ID папки, в который перемещается элемент
	_parent_id_old text;        -- ID папки, из которой перемещается элемент
    _cn integer;                -- count, для проверки наличия записи
	_id text; 					-- ID перемещаемого элемента в дереве
 	_children jsonb;			-- массив id children-элементов для parent
-- 	select * from elbaza.t27468 where idkart =  74045;
begin
	-- получает ID перемещаемого элемента в дереве
	_id = pdb2_val_api_text( '{post,id}' );
	-- получает ID родителя в дереве, куда перемещается элемент  
	_parent_id_new = pdb2_val_api_text( '{post,parent}' );
    -- получает ID родителя в дереве, из которого перемещается элемент
 	_parent_id_old = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _id, 0, '{item, parent}' );
	-- получает jsonb-массив из children элементов, куда перемещается элемент 
	_children = pdb2_val_api( '{post,children}' );
	-- получает idkart перемещаемого элемента
	_idkart = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _id, 0, '{data, idkart}' );
	-- получает idkart родителя, куда перемещается элемент
	_parent_idkart_new = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _parent_id_new, 0, '{data, idkart}' );
	-- получает jsonb-массив idkart для children элементов
	select jsonb_agg(pdb2_tree_placeholder_text( 'p27468_tree', 'tree', a.value, 0, '{data, idkart}' )) 
	from jsonb_array_elements_text(_children) as a
	into _children;
	-- получает idkart родителя, откуда перемещается элемент
	select a.parent from t27468 as a where a.idkart = _idkart 
	into _parent_idkart_old; 

	-- смена родителя
	update t27468 set dttmup = now(), parent = _parent_idkart_new where idkart = _idkart;
	
	-- проверка записи
	select count(*) from t27468_children as a where a.idkart =_parent_idkart_new 
	into _cn;
	if _cn > 0 then
    -- изменить позцию позиции
		update t27468_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent_idkart_new;
	else
    -- установить позицию
		insert into t27468_children( idkart, children ) values ( _parent_idkart_new, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
    -- подготвить данные для сокета - обновить родителя	
	if _parent_idkart_new = _parent_idkart_old then
		perform pdb2_val_page( '{pdb,socket_data,ids}', _parent_id_new );	
	else
    -- проверка вложенности _parent_idkart_old в _parent_idkart_new
			with recursive temp1 ( parent ) as 
			(	
				select a.parent
				from t27468 as a
				where a.idkart = _parent_idkart_new
				union all
				select a.parent
				from t27468 as a
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
				from t27468 as a
				where a.idkart = _parent_idkart_old
				union all
				select a.parent
				from t27468 as a
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

alter function elbaza.p27468_tree_move(text, text, text, text) owner to site;

