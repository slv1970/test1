create or replace function elbaza.p27471_tree_view_klient(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder ветки клиента
--=======================================================================================--
	_placeholder jsonb = '[]';
	_parent_id text;
    _parent_idkart int;
    _starts_with text;
	
begin
     _parent_id = pdb2_val_api_text( '{post, parent}' ); 
     _parent_idkart = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, parent}');
     _starts_with = pdb2_tree_placeholder_text( 'p27471_tree', 'tree', _parent_id, 0, '{data, text}' );  -- буква родительского элемента, с которой начинается название клиента
     
    -- Собирает placeholder для клиента 
    select jsonb_agg( a ) into _placeholder
    from (
        select 
            jsonb_build_object(
              'type', 'item_klient',  
              'idkart', a.idkart,
              'text', a.name,
              'parent', a.parent
            ) as id,
            a.name as "text", 
            1 as "on",
            'item_klient' as "type",
            _parent_id as parent,
            1 as children
        from 
        (
            select distinct a.name, a.idkart, t27471.parent
            from elbaza.t27468_data_klient as a -- соединяем с таблицей "Базы клиентов"
            join elbaza.t27471_data_dokument on t27471_data_dokument.client = a.idkart -- соединяем с таблицей документов, где связь - id клиента - клиента в документе
            join elbaza.t27471 on t27471_data_dokument.idkart = t27471.idkart
            where a.dttmcl is null
            and t27471_data_dokument.dttmcl is null
            and t27471.dttmcl is null
            and a.double_letter = _starts_with  -- буква в "Базе клиентов" равна букве род элемента
            and t27471.parent = _parent_idkart
            and (_name_find is null or t27471_data_dokument.name ilike  concat( '%', _name_find, '%' )) -- поиск
        ) as a
    ) as a;
    
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );

	return _placeholder;

end;
$$;

alter function elbaza.p27471_tree_view_klient(text, text, text) owner to site;

