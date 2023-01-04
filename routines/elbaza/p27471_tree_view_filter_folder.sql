create or replace function elbaza.p27471_tree_view_filter_folder(_parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Возвращает placeholder папки фильтра
--=======================================================================================--
	_placeholder jsonb = '[]';
    _parent_id text;
    _parent_idkart int;
begin
	_parent_id = pdb2_val_api_text( '{post, parent}' ); 
	_parent_idkart = pdb2_tree_placeholder( 'p27471_tree', 'tree', _parent_id, 0, '{data, idkart}');
    
    select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter',
				  'folder', 'folder_filter',
				  'text', a.letter,
                  'parent', a.parent
				) as id,
				a.letter as "text", 
				'folder_filter' as "type",
				_parent_id as parent,
				1 as children 
			from (
                select distinct a.letter, t27471.parent
				from elbaza.t27468_data_klient as a -- соединяем с таблицей "Базы клиентов"
                join elbaza.t27471_data_dokument on a.idkart = t27471_data_dokument.client -- соединяем с таблицей документов, где связь - id клиента - клиента в документе
                join elbaza.t27471 on t27471_data_dokument.idkart = t27471.idkart -- соединяем с общей таблицей Документов для получения родителя
				where a.dttmcl is null
                and t27471_data_dokument.dttmcl is null
                and t27471.dttmcl is null
                and t27471.parent = _parent_idkart
                and (_name_find is null or t27471_data_dokument.name ilike  concat( '%', _name_find, '%' )) -- поиск
				order by a.letter, t27471.parent -- сортировка по букве алфавита
			) as a
        ) as a;
    
	
	_placeholder = pdb2_tree_placeholder( 'p27471_tree', 'tree', _placeholder );
	
	return _placeholder;

end;
$$;

alter function elbaza.p27471_tree_view_filter_folder(text, text, text) owner to site;

