create or replace function elbaza.t17430_log_iu() returns trigger
    language plpgsql
as
$$
declare 
	_parent integer;
begin

	if (select count(*) from t17430 as a where a.link_table = NEW.link_table and a.type = 'item_tablitsa' ) = 0 then
		select a.idkart into _parent
		from t17430 as a
		where a.dttmcl is null
			and a.type = 'root_tablitsa';
		insert into t17430( parent, type, "on", name, link_table )
		values ( _parent, 'item_tablitsa', 1, NEW.link_table, NEW.link_table );
	end if;

	return NEW;
	
end;
$$;

alter function elbaza.t17430_log_iu() owner to developer;

