create or replace function elbaza.load_users(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
begin

-- добавление новых пользователей
	insert into t20455( uuid_pdb, idkart, dttmcr, dttmup, dttmcl, access_owner, "on", 
        name, description, property_data, data_hash, contract_data )
    select a.uuid_pdb, a.idkart, a.dttmcr, a.dttmup, a.dttmcl, a.access_owner, a.on, 
        concat( a.user_code, ' - ', a.user_name ), a.user_description, a.user_data, 
        a.data_hash, a.contract_data
	from pdb2_user_list() as a
	left join t20455 as b on a.idkart = b.idkart
	where b.idkart is null;
-- изменение данных пользователя
	update t20455 set
        uuid_pdb = a.uuid_pdb,
		dttmcr = a.dttmcr, 
		dttmup = a.dttmup,
		dttmcl = a.dttmcl,
		access_owner = a.access_owner,
		"on" = a.on,
		name = concat( a.user_code, ' - ', a.user_name ),
		description = a.user_description,
		property_data = a.user_data,
		data_hash = a.data_hash,
        contract_data = a.contract_data
	from pdb2_user_list() as a
	where a.idkart = t20455.idkart
		and a.data_hash <> t20455.data_hash;
		
	return null;
	
end;
$$;

alter function elbaza.load_users(jsonb, text) owner to developer;

