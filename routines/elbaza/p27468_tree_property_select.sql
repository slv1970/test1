create or replace function elbaza.p27468_tree_property_select(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
    
begin
    if _name_mod in ('p27468_property_klient_fizlico', 'p27468_property_klient_yurlico')  then
        perform pdb2_val_include( _name_mod, 'id26011', '{pdb,query,where}',
                format( 'id in (select idkart from t19697_data_status as a where a.dttmcl is null and a.ur1_status = 1)' ));
    elseif _name_mod = 'p27468_property_kontaktnoe_lico' then
        perform pdb2_val_include( _name_mod, 'id26011', '{pdb,query,where}',
                format( 'id in (select idkart from t19697_data_status as a where a.dttmcl is null and a.ur2_status = 1)' ));
    end if;
    
	return null;
	
end;
$$;

alter function elbaza.p27468_tree_property_select(jsonb, text) owner to site;

