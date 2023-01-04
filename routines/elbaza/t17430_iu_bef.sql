create or replace function elbaza.t17430_iu_bef() returns trigger
    language plpgsql
as
$$
begin
 
 	if NEW.name is null then
		NEW.name = NEW.link_table;
	end if;

	return NEW;
	
end;
$$;

alter function elbaza.t17430_iu_bef() owner to developer;

