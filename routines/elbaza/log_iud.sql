create or replace function elbaza.log_iud() returns trigger
    language plpgsql
as
$$
declare
	_idkart bigint;
	
begin

	if TG_OP='INSERT' then
-- запись 	
		insert into t17430_log( userid, link_table, link_idkart, iud_type )
		values ( pdb_current_userid(), TG_TABLE_NAME, NEW.idkart, 1 )
		returning idkart into _idkart;
-- поля
		insert into t17430_log_fields( id_17430_log, name, data_new )
		select _idkart, a.key, a.value
		from json_each( row_to_json( NEW ) ) as a;
		
		return NEW;
		
	elsif TG_OP='UPDATE' then
-- запись 	
		insert into t17430_log( userid, link_table, link_idkart, iud_type )
		values ( pdb_current_userid(), TG_TABLE_NAME, NEW.idkart, 2 )
		returning idkart into _idkart;
-- поля
		insert into t17430_log_fields( id_17430_log, name, data_new, data_old )
		select _idkart, a.key, a.value, b.value
		from json_each( row_to_json( NEW ) ) as a
		inner join json_each( row_to_json( OLD ) ) as b on a.key = b.key
		where concat( '-', a.value ) <> concat( '-', b.value );

		return NEW;

	end if;
	
-- запись 	
	insert into t17430_log( userid, link_table, link_idkart, iud_type )
	values ( pdb_current_userid(), TG_TABLE_NAME, OLD.idkart, 3 )
	returning idkart into _idkart;
-- поля
	insert into t17430_log_fields( id_17430_log, name, data_old )
	select _idkart, a.key, a.value
	from json_each( row_to_json( OLD ) ) as a;

	return OLD;
end;
$$;

comment on function elbaza.log_iud() is 'Логирование таблиц';

alter function elbaza.log_iud() owner to developer;

