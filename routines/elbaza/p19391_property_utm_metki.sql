create or replace function elbaza.p19391_property_utm_metki(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_include text			= pdb2_event_include( _name_mod );
	_event text				= pdb2_event_name( _name_mod );
	_idkart integer			= pdb2_val_include_text( _name_mod, 'idkart', '{var}' );
	
	_utm_link text;
	_utm_source text;
	_utm_medium text;
	_utm_campaign text;
	_utm_content text;
	_utm_term text;
	_utm_term_cond text;
	_utm_content_cond text;
	_symbol text = '?';
	_result text;
	_result_short text;
	_tree_inc text;
	_name_table text;
	_name_table_children text;
	_tree_view text;
	_tree_idkart integer;
	_tree_mod text;
	_tree_b_submit integer;
	
begin
	_tree_mod = pdb2_val_session_text( '_action_tree_', '{mod}' );
	_tree_inc = pdb2_val_session_text( '_action_tree_', '{inc}' );
	_name_table = pdb2_val_session_text( '_action_tree_', '{table}' );
	_name_table_children = pdb2_val_session_text( '_action_tree_', '{table_children}' );
	
	_tree_view = pdb2_val_session_text( _tree_mod, '{view}' );
	_tree_idkart = pdb2_val_session_text( _tree_mod, '{idkart}' );
	_tree_b_submit = pdb2_val_session_text( _tree_mod, '{b_submit}' );
	
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
	
        -- собираем данные инклудов
		_utm_link = pdb2_val_include_text( _name_mod, 'utm_link', '{value}' );
		_utm_source = pdb2_val_include_text( _name_mod, 'utm_source', '{value}' );
		_utm_medium = pdb2_val_include_text( _name_mod, 'utm_medium', '{value}' );
		_utm_campaign = pdb2_val_include_text( _name_mod, 'utm_campaign', '{value}' );
		_utm_content = pdb2_val_include_text( _name_mod, 'utm_content', '{value}' );
		_utm_term = pdb2_val_include_text( _name_mod, 'utm_term', '{value}' );

        -- Проверяем, есть ли в ссылке вхождение - маркер модалки
		if substring( _utm_link from 'dynamic-box'::text ) is not null then
 		    _symbol = '&';
 		end if;

        -- Обработка необяз-го параметра utm_content
		if _utm_term = '' or _utm_content is null then
			_utm_content_cond = null;
		else
			_utm_content_cond = concat('&utm_content=', _utm_content);
		end if;
		
		-- Обработка необяз-го параметра utm_term
		if _utm_term = '' or _utm_term is null then
			_utm_term_cond = null;
		else
			_utm_term_cond = concat('&utm_term=', _utm_term);
		end if;
		
		_result = concat(
			_utm_link, 
			_symbol, 
			'utm_source=', _utm_source, 
			'&utm_medium=', _utm_medium, 
			'&utm_campaign=', _utm_campaign, 
			_utm_content_cond, 
			_utm_term_cond 
		);
		
		perform pdb2_val_include( _name_mod, 'utm_result', '{value}', _result );
		
		-- Получение сокращённой ссылки
		_result_short = concat('https://grant.respectrb.ru/click/?short=', _idkart);
		perform pdb2_val_include( _name_mod, 'utm_result_short', '{value}', _result_short);

	
-- сохранить данные		
		perform pdb_mdl_before_s( _value, _name_mod );
		
-- обновить дерево
		perform pdb2_val_include( _tree_mod, _tree_inc, '{task}',
								  array[ jsonb_build_object( 
									  		'cmd', 'update_id',
									  		'data', pdb2_tpl_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
									]
							);
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

alter function elbaza.p19391_property_utm_metki(jsonb, text) owner to site;

