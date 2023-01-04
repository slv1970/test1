create or replace function elbaza.p27471_tree_rename(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_id text;
	_idkart int;
	_name text;
    
begin

-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
	_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, idkart}' );
 	_name = pdb2_val_api_text( '{post,text}' );
-- смена текста
	update t27471 set dttmup = now(), name = _name where idkart =_idkart 
	returning name into _name;
-- установить информацию по бланкам
	perform p27471_tree_set( _name_mod, _name_tree, _name_table, null );		
-- новое имя ветки 	
	perform pdb2_return( to_jsonb( _name ) );
-- подготвить данные для сокета - обновить id	
    

 	perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	

end;
$$;

alter function elbaza.p27471_tree_rename(text, text, text, text) owner to site;

