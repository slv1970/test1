create or replace function elbaza.p17430_tree_property(_value jsonb, _name_mod text) returns jsonb
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

	_from text;
	_fields jsonb;
	_where text[];
	_link_table text;
	_link_idkart integer;

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
									  		'data', p17430_tree_view( null, null, _tree_idkart, _name_table, _name_table_children ) ) 
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

-- ===================================================
-- обработка данных
	if _tree_b_submit <> 0 then
		perform pdb2_val_include( _name_mod, 'limit_obyekt_logirovaniya', '{value}', 
					pdb2_val_include( _name_mod, 'limit_obyekt_logirovaniya', '{placeholder}' ) 
								);
	end if;

	if _name_mod = 'p17430_property_obyekt_logirovaniya' then
-- условия
		select 
			a.link_table, a.link_idkart
		into 
			_link_table, _link_idkart
		from t17430 as a
		where a.idkart = _tree_idkart;
		_where = _where || format( 'link_table = %L', _link_table );
		_where = _where || format( 'link_idkart = %L', _link_idkart );
-- формирование запроса
		_from = format('select 
							a.idkart,
							a.dttmcr,
							to_char( a.dttmcr, ''dd.mm.yyyy hh24:mi:ss tz'' ) as dttmcr_fmt,
							b.text as user_name,
					   		a.iud_type,
					   		case 
					   			when a.iud_type = 1 then ''Добавление'' 
					   			when a.iud_type = 2 then ''Изменение'' 
					   			when a.iud_type = 3 then ''Удаление''
					   		else 
					   			''-'' 
					   		end as iud_type_fmf
						from t17430_log as a
					   	left join t20455_select as b on a.userid = b.id
					   ' );
-- подготовка список полей
	_fields = jsonb_build_array(
			jsonb_build_object( 'text', 'idkart', 'sort', 'idkart' ),
			jsonb_build_object( 'text', 'dttmcr_fmt', 'sort', 'dttmcr' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'iud_type_fmf', 'sort', 'iud_type' ),
			jsonb_build_object( 'align', '''center''', 'includes', array['dropdown'] )
		);
-- инициализация таблицы
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,query,from}', _from );
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,query,where}', _where );
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,table,fields}', _fields );
		perform pdb2_val_include( _name_mod, 'log_table', '{pdb,query,order_by}', 'idkart desc' );

	end if;
-- ===================================================

	perform pdb2_mdl_after( _name_mod );

	return null;
	
end;
$$;

alter function elbaza.p17430_tree_property(jsonb, text) owner to developer;

