create or replace function elbaza.xxxx_dadata_client(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_query jsonb;	
begin
    -- сделать задание
    select jsonb_agg(a.query) into _query
    from (
        select jsonb_build_object( 
                    'cmd', 'json',
                    'url', 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/findById/party', 
                    'idkart', a.idkart, 
                    'data', jsonb_build_object( 'query', a.inn, 'count', 299 )
                ) as query        
        FROM t27468_data_klient as a
        where a.dttmcl is null
            and a.inn is not null 
        order by a.ddt_client_date NULLS FIRST, a.idkart
        limit 10
    ) as a;
    -- запустить задание
	if _query is not null then
		perform pdb2_val_task_command( 'dadata.ru', 'cmd', '{command}', _query );
		perform pdb2_val_task_command( 'dadata.ru', 'cmd', '{enabled}', 1 );
	end if;
	return _value;
end;
$$;

alter function elbaza.xxxx_dadata_client(jsonb, text) owner to developer;

