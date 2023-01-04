create or replace function elbaza.p18133_form(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
-- система	
  	_idkart integer	= pdb2_val_api_text( '{post,idkart}' );
	_json jsonb;
	
begin

-- инициализация переменных
	perform pdb2_mdl_before( _name_mod );
-- данные из таблице t17430_log
	select row_to_json(a)
	into _json
	from (
		select 
			a.link_table,
			a.link_idkart,
			to_char( a.dttmcr, 'dd.mm.yyyy hh24:mi:ss tz' ) as dttmcr,
			b.text as ispl,
			case 
				when a.iud_type = 1 then 'Добавление'
				when a.iud_type = 2 then 'Изменение' 
				when a.iud_type = 3 then 'Удаление'
			end as iud_type
		from t17430_log as a
		left join t20455_select as b on a.userid = b.id
		where a.idkart = _idkart
	) as a;
-- установить
	perform pdb2_val_include_set( _name_mod, '{value}', _json, 'dttmcr', 'iud_type', 'ispl' );
-- данные из таблице лога
	execute format( '
		select row_to_json(a) 
		from (
			select 
				a.idkart as link_idkart,
				''%s'' as link_table,
				to_char( a.dttmcr, ''dd.mm.yyyy hh24:mi:ss tz'' ) as link_dttmcr,
				to_char( a.dttmup, ''dd.mm.yyyy hh24:mi:ss tz'' ) as link_dttmup,
				to_char( a.dttmcl, ''dd.mm.yyyy hh24:mi:ss tz'' ) as link_dttmcl,
				b.text as link_ispl
			from %I as a 
			left join t20455_select as b on a.userid = b.id
			where a.idkart = %s
		) as a
		', _json ->> 'link_table', _json ->> 'link_table', _json ->> 'link_idkart' )
	into _json;
-- установить
	perform pdb2_val_include_set( _name_mod, '{value}', _json, 
			'link_idkart', 'link_table', 'link_dttmcr', 'link_dttmup', 'link_dttmcl', 'link_ispl'
								);
-- данные из таблице t17430_log_fields
	select row_to_json(a)
	into _json
	from (
		select
			jsonb_pretty( a.data_old, 3, 0 ) as json_before,
			jsonb_pretty( a.data_new, 3, 0 ) as json_after
		from (
			select 
				jsonb_object_agg( a.name, a.data_new ) as data_new,
				jsonb_object_agg( a.name, a.data_old ) as data_old
			from t17430_log_fields as a
			where a.id_17430_log = _idkart
		) as a
	) as a;
-- установить
	perform pdb2_val_include_set( _name_mod, '{value}', _json, 'json_before', 'json_after' );

	perform pdb2_mdl_after( _name_mod );
	return null;
	
end;
$$;

alter function elbaza.p18133_form(jsonb, text) owner to developer;

