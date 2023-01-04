create or replace function elbaza.p27471_tree_view(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Определяет тип элемента и вызывает соответствующую функцию -- 
-- Иерархия типов элементов дерева:
-- root_firma (Фирма) -> folder_filter (Папка фильтра) -> item_klient (Клиент) -> item_dolument (Документ)
--=======================================================================================--

	_pdb_userid integer	= pdb_current_userid();
	_placeholder jsonb;
	_type text;
	
begin  
	-- тип элемента в дереве
	_type = pdb2_tree_placeholder_text('p27471_tree', 'tree', coalesce(_id, _parent_id), 0, '{data, type}'); 
    if _type is null then 
		return p27471_tree_view_root(_parent_id, _name_find, _id); 
    elseif _type = 'root_firma' then 
        return p27471_tree_view_filter_folder(_parent_id, _name_find, _id);
    elseif _type = 'folder_filter' then 
        return p27471_tree_view_filter_folder2(_parent_id, _name_find, _id);
    elseif _type = 'folder_filter2' then 
        return p27471_tree_view_klient(_parent_id, _name_find, _id);
    elseif _type = 'item_klient' then
        return p27471_tree_view_dokument(_parent_id, _name_find, _id);
	end if;
    
	return null;
end;
$$;

alter function elbaza.p27471_tree_view(text, text, text) owner to site;

