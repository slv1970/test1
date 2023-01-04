create or replace function elbaza.__t20455_iu_bef() returns trigger
    language plpgsql
as
$$
begin
-----------------------___________________________________

---==========================================================
	NEW.cache_data2 = md5(
		concat( 
			NEW.idkart, NEW.dttmcr, NEW.dttmup, NEW.dttmcl, NEW.userid, NEW.parent, NEW.type, NEW.on, NEW.name, NEW.description, NEW.property_data
		)
	);
	return NEW;
	
end;
$$;

alter function elbaza.__t20455_iu_bef() owner to developer;

