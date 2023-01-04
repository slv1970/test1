create or replace function elbaza.p20455_tab(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_from text;
	_fields jsonb;
	_where text[];
	_tabs text;
			
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
-- формирование условий
	_where = _where || format( 'a.dttmcl is null' );

	_tabs = pdb2_val_include_text( _name_mod, 'tabs', '{value}' );
	if _tabs = '3' then
		_where = _where || format( 'a.on is null' );
	else
		_where = _where || format( 'a.on = 1' );
	end if;

-- формирование запроса
	_from = format('select 
						a.idkart,
				   		a.user_name
					from t20455_data as a
					' );
-- подготовка список полей
	_fields = jsonb_build_array(
			jsonb_build_object( 'html', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'html', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'text', 'user_name', 'sort', 'user_name' ),
			jsonb_build_object( 'align', '''right''', 'includes', array['dropdown'] )
		);
			
-- инициализация таблицы
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,from}', _from );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,where}', _where );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,table,fields}', _fields );

	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

alter function elbaza.p20455_tab(jsonb, text) owner to developer;

