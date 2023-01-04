create or replace function elbaza.p30436_tree_duplicate_copy(_idkart integer, _parent integer, _name_table text, _name_table_children text) returns integer
    language plpgsql
as
$$
--=================================================================================================
-- Вставляет в таблицу копию исходного элемента и всех дочерних элементов, сохраняет в сессии  
-- соответствие ключей исходных элементов и их копий
--=================================================================================================

declare
    _pdb_userid integer = pdb_current_userid(); -- id текущего пользователя
    
	_new_parent integer;    -- idkart копии после вставки в таблицу 
	_all_parent integer[];  -- массив idkart всех копий, вложенных в текущего родителя
    _idkart_matches jsonb;  -- словарь соответствий всех исходных idkart и копий
    
begin
	-- вставить копию текущей записи в таблицу и вернуть idkart
    insert into t30436( userid, parent, type, name, description, property_data )
    select _pdb_userid, COALESCE( _parent, a.parent ), a.type, concat( a.name, ' - копия' ),
        a.description, a.property_data
    from t30436 as a where a.idkart = _idkart
    returning idkart
	into _new_parent;
	
    -- добавить в словарь пару ключ-значение
    _idkart_matches = pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}');
    if _idkart_matches is null then
        _idkart_matches  =  jsonb_build_object(_idkart, _new_parent);
    else    
        _idkart_matches = _idkart_matches || jsonb_build_object(_idkart, _new_parent);
    end if;
    -- сохранить в сессии
    perform pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}', _idkart_matches);
    
    -- повторить действие для всех дочерних элементов
    select array_agg( a.new_parent )
    from (
        select p30436_tree_duplicate_copy( a.idkart, _new_parent, _name_table, _name_table_children) as new_parent
        from t30436 as a
        left join t30436_children as mn on a.parent = mn.idkart
        left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
        where a.dttmcl is null and a.parent = _idkart
        order by srt.sort NULLS FIRST, a.idkart desc
    ) as a
	into _all_parent; 
	
    -- вернуть idkart копии исходного элемента
	return _new_parent;

end;
$$;

alter function elbaza.p30436_tree_duplicate_copy(integer, integer, text, text) owner to site;

