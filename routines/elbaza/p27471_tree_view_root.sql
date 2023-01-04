create or replace function elbaza.p27471_tree_view_root(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder фирм
--=======================================================================================--
	_placeholder jsonb = '[]';
    _parents int[];
    
begin
    -- Собирает placeholder для фирм
    if _name_find is not null then
        select 
            ARRAY_AGG(a.parent)
        into _parents
        from elbaza.t27471 as a
        left join elbaza.t27471_data_dokument on a.idkart = t27471_data_dokument.idkart
        where a.dttmcl is null
        and t27471_data_dokument.dttmcl is null
        and ( _name_find is null or t27471_data_dokument.name ilike concat( '%', _name_find, '%' )); -- поиск
        
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                jsonb_build_object(
                  'type', a.type,
                  'idkart', a.idkart
                ) as id,
                a.name as "text", 
                a.type as "type",
                a.parent as parent,
                1 as children 
            from t27471 as a
            where parent = 0
            and idkart = any(_parents)
            and dttmcl is null
        ) as a; 
    else
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                jsonb_build_object(
                  'type', a.type,
                  'idkart', a.idkart
                ) as id,
                a.name as "text", 
                a.type as "type",
                a.parent as parent,
                1 as children 
            from t27471 as a
            where parent = 0
            and dttmcl is null
        ) as a; 
    end if;
        
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
    return _placeholder;
end;
$$;

alter function elbaza.p27471_tree_view_root(text, text, text) owner to site;

