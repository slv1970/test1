create or replace function elbaza.p27467_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );

	_tree_mod text;
	_tree_inc text;
	_tree_view text;
	_tree_idkart integer;
	_tree_b_submit integer;
	_name_table text;
	_name_table_children text;

begin

	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );

	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_tree_idkart = pdb2_val_session_text( _tree_mod, '{idkart}' );
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
	-- установить таблицу на изменение
	perform pdb2_val_include( _name_mod, 'b_submit', '{pdb,record,table}', _name_table );
	-- определение активного окна
	if _tree_view = _name_mod then
		perform pdb2_val_module( _name_mod, '{hide}', null );
	else
		-- если модуль скрыт - выход
		return null;
	end if;
	-- позиция в дереве
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _tree_idkart );
	-- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then
		-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
		-- обновить дерево
 		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', pdb2_tpl_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
									]
							);
		-- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _tree_idkart );	
						
		_tree_b_submit = 0;

	end if;

	if _tree_b_submit = 0 then
		
		-- получить данные	
		perform pdb_mdl_before_v( _value, _name_mod );
		-- показать		
		perform pdb2_val_include( _name_mod, 'b_edit', '{hide}', null );

	else
		-- показать	
		perform pdb2_val_include( _name_mod, 'b_cancel', '{hide}', null );				
		perform pdb2_val_include( _name_mod, 'b_submit', '{hide}', null );
		
	end if;
	-- установить состояние
	perform pdb2_val_include( _name_mod, 'b_submit', '{value}', _tree_b_submit );
	
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

alter function elbaza.p27467_tree_property(jsonb, text) owner to site;

