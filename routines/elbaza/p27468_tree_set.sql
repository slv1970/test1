create or replace function elbaza.p27468_tree_set(_name_mod text, _name_tree text, _name_table text) returns void
    language plpgsql
as
$$
declare 
	_id text;       -- уникальный ID выделенного элемента в дереве
	_id_old text;   -- уникальный ID предыдущего элемента, хранящийся в сессии
	_type text;     -- тип выделенного элемента в дереве
	_mod_property text; -- название модуля, выделенного элемента в дереве
    
begin
-- установить информацию по выделенной ветки
	_id = pdb2_val_include_text( _name_mod, _name_tree, '{selected,0}' );
	_type = pdb2_tree_placeholder_text( _name_mod,_name_tree, _id, 0, '{data, type}' );
    
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

alter function elbaza.p27468_tree_set(text, text, text) owner to site;

