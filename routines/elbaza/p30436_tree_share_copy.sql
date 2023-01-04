create or replace function elbaza.p30436_tree_share_copy(_idkart integer, _parent integer, _list_name text, _pdb_userid integer) returns integer
    language plpgsql
as
$$
--=================================================================================================
-- При нажатии кнопки "Поделиться списком" копирует все элементы списка в таблице дерева под новым
-- userid. Сохраняет в сессии соответствие ключей исходных элементов и их копий
--=================================================================================================
declare
    
	_new_parent integer;    -- idkart копии после вставки
	_all_parent integer[];  -- массив из idkart копий всех элементов текущего родителя
    _idkart_matches jsonb;  -- словарь соответствий idkart исходных элементов и их копий
    
begin

	-- вставить копию записи в таблицу дерева под новым userid
    insert into t30436( userid, parent, type, name, "on", description, property_data )
    select _pdb_userid, COALESCE( _parent, a.parent ), a.type, coalesce(_list_name, a.name),
        a."on", a.description, a.property_data
    from t30436 as a where a.idkart = _idkart
    returning idkart
	into _new_parent;
	
    -- добавить в словарь соответствие старого и нового ключа
    _idkart_matches = pdb2_val_session('p30436_form', '{idkart_matches}');
    if _idkart_matches is null then
        _idkart_matches  =  jsonb_build_object(_idkart, _new_parent);
    else    
        _idkart_matches = _idkart_matches || jsonb_build_object(_idkart, _new_parent);
    end if;
    -- сохранить в сессию
    perform pdb2_val_session('p30436_form', '{idkart_matches}', _idkart_matches);
    
    -- выполнить действие для всех дочерних элементов
    select array_agg( a.new_parent )
    from (
        select p30436_tree_share_copy( a.idkart, _new_parent, null, _pdb_userid) as new_parent
        from t30436 as a
        left join t30436_children as mn on a.parent = mn.idkart
        left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
        where a.dttmcl is null and a.parent = _idkart
        order by srt.sort NULLS FIRST, a.idkart desc
    ) as a
	into _all_parent; 
    
    -- вернуть idkart нового списка
	return _new_parent;

end;
$$;

alter function elbaza.p30436_tree_share_copy(integer, integer, text, integer) owner to site;

