create or replace function elbaza.p140031_info(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
-- система	
  	_id text	    = pdb2_val_api_text( '{post,idkart}' );
	_idkart text     = pdb2_tree_placeholder( 'p27471_tree', 'tree', _id, 0, '{data, idkart}');
  	_table text		= pdb2_val_api_text( '{post,table}' );
	_json jsonb;
	_dt timestamp with time zone;
	_user_name text;
	
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );

	execute format( 'select row_to_json(a) from %I as a where a.idkart = %L', _table, _idkart )
	into _json;
	
	select a.text into _user_name
--	from v20455_select as a
	from v20455_data_select as a
	where a.id = (_json->> 'userid')::integer;
	
	perform pdb2_val_include( _name_mod, 'idkart', '{value}', _idkart );
	perform pdb2_val_include( _name_mod, 'table', '{value}', _table );
	_dt = _json->> 'dttmcr';	
	perform pdb2_val_include( _name_mod, 'dttmcr', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmup';	
	perform pdb2_val_include( _name_mod, 'dttmup', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	_dt = _json->> 'dttmcl';	
	perform pdb2_val_include( _name_mod, 'dttmcl', '{value}', to_char( _dt, 'dd.mm.yyyy hh24:mi:ss tz' ) );
	perform pdb2_val_include( _name_mod, 'ispl', '{value}', _user_name );

	perform pdb2_val_include( _name_mod, 'json', '{value}', jsonb_pretty( _json, 4, 0 ) );

	perform pdb2_mdl_after( _name_mod );
	return null;

	
end;
$$;

alter function elbaza.p140031_info(jsonb, text) owner to site;

