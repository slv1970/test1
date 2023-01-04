create or replace function elbaza.p27471_tree_set(_name_mod text, _name_tree text, _name_table text, _id text) returns void
    language plpgsql
as
$$
declare 
	_id_old text; 
	_idkart int; -- idkart элемента в таблице t27471
	_idkart_old int; -- старый idkart
	_type text; 
	_mod_property text;
	_data jsonb;
	
begin
-- установить информацию по выделенной ветки
	_id = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	_data = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, '{data}' );
	_type = _data ->> 'type';
	_idkart = _data ->> 'idkart'; 
    
 	if _type is not null then
		_mod_property = pdb2_val_include_text( _name_mod, _name_tree, array[ 'pdb','action','visible_module', _type] );
	end if;
	if _mod_property is null then
		_mod_property = pdb2_val_include_text( _name_mod, _name_tree, array[ 'pdb','action','visible_module',''] );
	end if;
-- обработка бланка
	if _mod_property is not null then
-- убрать автомат	
		perform pdb2_val_include( _name_mod, _name_tree, array[ 'pdb','action','visible_module'], null );
-- запомнитьв сессии данные для бланка
		perform pdb2_val_module( _mod_property, '{hide}', null );
		perform pdb2_val_session( _name_mod, '{view}', _mod_property );
		_id_old = pdb2_val_session_text( _name_mod, '{id}' );
		if _id = _id_old then
		else
			perform pdb2_val_session( _name_mod, '{id}', _id );
			perform pdb2_val_session( _name_mod, '{b_submit}', 0 );
		end if;
	end if;
end;
$$;

alter function elbaza.p27471_tree_set(text, text, text, text) owner to site;

