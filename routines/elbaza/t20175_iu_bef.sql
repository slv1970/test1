create or replace function elbaza.t20175_iu_bef() returns trigger
    language plpgsql
as
$$
begin
 
 	if NEW.type = 'item_sotrudnik' and NEW.property_data ->> 'fio' is not null then
		select concat( a.text, ' ('|| (NEW.property_data ->> 'dolzhnost') || ')' ) into NEW.name
		from v20455_data_select as a
		where a.id = (NEW.property_data ->> 'fio')::integer;
	end if;
	
	return NEW;
end;
$$;

alter function elbaza.t20175_iu_bef() owner to developer;

