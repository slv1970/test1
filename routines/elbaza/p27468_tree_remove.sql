create or replace function elbaza.p27468_tree_remove(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_idkart integer;
	_id text;
  	_parent integer;
  	_idkart_old integer;
	_id_old text;
	_parent_id text;
	_placeholder_data jsonb;
    
begin

-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
    _placeholder_data = pdb2_tree_placeholder( 'p27468_tree', 'tree', _id, 0, null);
	_idkart = _placeholder_data #>> '{data, idkart}';
	_parent_id = _placeholder_data #>> '{item, parent}';
    
-- удаление ветки
    execute format( 'update %I set dttmcl = now() where idkart = $1;', _name_table)
	using _idkart;

	_id_old = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
    
	if _id = _id_old then
-- убрать позицию
		perform pdb2_val_include( _name_mod, _name_tree, '{selected}', null );
	end if;
-- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table );
-- подготвить данные для сокета - обновить родителя	
-- 	perform pdb2_val_page( '{pdb,socket_data,ids}',_parent_id );	
		
end;
$$;

alter function elbaza.p27468_tree_remove(text, text, text, text) owner to site;

