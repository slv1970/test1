create or replace function elbaza.p27468_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
--=================================================================================================
-- Отображает модуль "Свойства объекта" для выделенного элемента дерева
--=================================================================================================
declare 
	_include text			= pdb2_event_include( _name_mod ); -- название инклюда, вызвавшего событие
	_event text				= pdb2_event_name( _name_mod ); -- название события

	_tree_mod text;     -- название модуля дерева
	_tree_inc text;     -- название инклюда дерева
	_tree_view text;    -- название модуля свойства
	_idkart integer;    -- idkart выделенного элемента в таблице дерева
	_tree_b_submit integer; -- значение кнопки b_submit
	_name_table text;   -- название таблицы дерева
	_name_table_children text; -- название таблицы сортировки дерева
	_id text;           -- ID выделенного элемента в дереве (в виде ключа)
	_parent_id text;    -- ID родителя выделенного элемента в дереве
	_tmp_arr text[];
    _data jsonb;
    
begin
    -- получить данные по дереву
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );
    
    -- получить данные по свойству
	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_id = pdb2_val_session_text( _tree_mod, '{id}' );
	_idkart = pdb2_tree_placeholder_text( 'p27468_tree', 'tree', _id, 0, '{data, idkart}');
    
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
		_id = pdb2_val_include_text( _tree_mod, _tree_inc, '{selected,0}' );
    -- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
    -- обновить дерево
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', p27468_tree_view( _tree_mod, _tree_inc, null, null, _id ) ),
                                        jsonb_build_object( 
									  		'cmd', 'reload_parent',
									  		'data', array[_id] )
									]
							);
    -- подготвить данные для сокета - обновить родителя	
		perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	
						
		_tree_b_submit = 0;

	elseif _event = 'values' then
        _tree_b_submit = 2;
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
	
    perform p27468_tree_property_select(_value, _name_mod); 
        
    if _name_mod in ('p27468_property_klient_yurlico', 'p27468_property_klient_fizlico') then
        
        _data = pdb2_val_include( _name_mod, 'find_client','{value,json,data}' );
        if _data is not null then	
            perform pdb2_val_include( _name_mod, 'inn','{value}', _data -> 'inn' );
            perform pdb2_val_include( _name_mod, 'kpp','{value}', _data -> 'kpp' );
            perform pdb2_val_include( _name_mod, 'ogrn','{value}', _data -> 'ogrn' );
            perform pdb2_val_include( _name_mod, 'nm','{value}', _data #> '{name,short_with_opf}' );
            perform pdb2_val_include( _name_mod, 'nm_full','{value}', _data #> '{name,full_with_opf}' );
            perform pdb2_val_include( _name_mod, 'dir_position', '{value}', _data #> '{management,post}' );
            perform pdb2_val_include( _name_mod, 'dir_name','{value,text}', _data #> '{management,name}' );
            perform pdb2_val_include( _name_mod, 'dt_address_legal','{value}', 
                        jsonb_build_object( 'json', _data #> '{address}', 'text', _data #>> '{address,value}' ));
        end if;

        _data = pdb_val_include( _value, _name_mod, 'find_bic', '{value,json}' );
        
        if _data is not null then
            perform pdb2_val_include( _name_mod, 'bank_bic','{value}', _data #> '{data,bic}' );
            perform pdb2_val_include( _name_mod, 'bank_cor_account','{value}', _data #> '{data,correspondent_account}' );
            perform pdb2_val_include( _name_mod, 'bank_name','{value}', _data -> 'unrestricted_value' );
        end if;
    end if;
    
	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

alter function elbaza.p27468_tree_property(jsonb, text) owner to site;

