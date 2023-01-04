create or replace function elbaza.templare_tree_property(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
begin

	return pdb2_tpl_tree_property( _value, _name_mod );
	
end;
$$;

alter function elbaza.templare_tree_property(jsonb, text) owner to developer;

