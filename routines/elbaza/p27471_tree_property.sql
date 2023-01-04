create or replace function elbaza.p27471_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );

	_tree_mod text;
	_tree_inc text;
	_tree_view text;
	_idkart integer;
	_tree_b_submit integer;
	_name_table text;
	_name_table_children text;
	_id text;
	_parent_id text;
    _name text;
	_desc text;
begin
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );
	
	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_id = pdb2_val_session_text( _tree_mod, '{id}' );
	_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, idkart}');
--  {"data": {"type": "item_klient", "idkart": 222}, "item": {"id": "5cf857ff528063d017a7301ebc5e746b", "parent": "71b4b01d45ba1e3378c19cc45e00c75e"}}
-- 	{"data": {"type": "item_dokument", "idkart": 223}, "item": {"id": "80f24d89cb793ec46f2dcc71a753742e", "parent": "71b4b01d45ba1e3378c19cc45e00c75e"}}
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
	perform pdb2_val_include( _name_mod, 'idkart', '{var}', _idkart );
-- обработка события
	if _event = 'action' then
	
		if _include = 'b_edit' then			
			_tree_b_submit = 2;
		elsif _include = 'b_cancel' then
			_tree_b_submit = 0;
		end if;
		
	elsif _event = 'submit' then
		_id = pdb2_val_include_text( 'p27471_tree', 'tree', '{selected,0}' );
-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
-- обновить дерево
 		
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', p27471_tree_view( null, null, _id ) ),
                                        jsonb_build_object( 
									  		'cmd', 'reload_parent',
									  		'data', array[_id] )
									]
							);
			  
-- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	
						
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
    
    if _name_mod in ('p27471_property_klient') then
        _name = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, text}');
        perform pdb2_val_include( _name_mod, 'name', '{value}', _name );
        perform pdb2_val_include( _name_mod, 'on', '{value}', 1 );
    end if;
    
    if _name_mod in ('p27471_property_dokument') then
        --raise '%', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data}');
        perform pdb2_val_include( _name_mod, 'idkart', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, idkart}') );
        perform pdb2_val_include( _name_mod, 'dokument_ispl', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, userid}') );
        perform pdb2_val_include( _name_mod, 'dokument_dttmcr', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, dttmcr}') );
        perform pdb2_val_include( _name_mod, 'dokument_json', '{value}', pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _id, 0, '{data, property_data}') );
    end if;
	perform pdb2_mdl_after( _name_mod );
    return null;
	
end;
$$;

alter function elbaza.p27471_tree_property(jsonb, text) owner to site;

