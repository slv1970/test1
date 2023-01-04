create or replace function elbaza.p27468_tree_rename(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
declare 
  	_id text;       -- ID элемента в дереве
	_idkart int;    -- idkart в таблице дерева
	_name text;     -- новое название элемента
    
begin

-- получить переменые
	_id = pdb2_val_api_text( '{post,id}' );
	_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _id, 0, '{data, idkart}' );
 	_name = pdb2_val_api_text( '{post,text}' );
-- смена текста
	execute format( 'update %I set dttmup = now(), name = $1 where idkart = $2 returning name;', _name_table )
	using _name, _idkart into _name;

-- установить информацию по бланкам
	perform p27468_tree_set( _name_mod, _name_tree, _name_table );		
-- новое имя ветки 	
    perform pdb2_return( to_jsonb( _name ) );
-- подготвить данные для сокета - обновить id	
    perform pdb2_val_include( _name_mod, _name_tree, '{task}',
                          array[ 
                                jsonb_build_object( 
                                    'cmd', 'reload_parent',
                                    'data', array[_id] )
                            ]
                    );

    perform pdb2_val_page( '{pdb,socket_data,ids}', _id );	

end;
$$;

alter function elbaza.p27468_tree_rename(text, text, text, text) owner to site;

