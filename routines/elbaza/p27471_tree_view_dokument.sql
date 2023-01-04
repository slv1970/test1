create or replace function elbaza.p27471_tree_view_dokument(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder документа
--=======================================================================================--
	_placeholder jsonb = '[]';
	_idkart int; -- id родительского элемента (id клиента)
	_parent_id text; -- id родителя
    _parent_idkart int; -- родитель родителя
	
begin
    _parent_id = pdb2_val_api_text( '{post, parent}' ); 
	_parent_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id, 0, '{data, parent}');
    _idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, idkart}' );
    
    -- Собирает placeholder для документа
    select jsonb_agg( a ) into _placeholder
    from (
        select 
            jsonb_build_object(
              'type', 'item_dokument',  
              'idkart', a.idkart,
              'dttmcr', a.dttmcr,
              'userid', a.userid,
              'property_data', t27471.property_data
            ) as id,
            a.name as "text", 
            'item_dokument' as "type",
            _parent_id as parent,
            1 as children,
            case when a.on = 1 then null else 5 end as theme
        from t27471_data_dokument as a
        join t27471 on a.idkart = t27471.idkart
        where a.dttmcl is null
        and t27471.dttmcl is null
        and t27471.parent = _parent_idkart   -- родитель равен клиенту
        and a.client = _idkart  -- client равен id родителя
        and (_name_find is null or a.name ilike  concat( '%', _name_find, '%' )) -- поиск
    ) as a;
    
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );

	return _placeholder;

end;
$$;

alter function elbaza.p27471_tree_view_dokument(text, text, text) owner to site;

