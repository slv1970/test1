create or replace function elbaza.p27468_tree_duplicate_copy(_idkart integer, _parent integer) returns integer
    language plpgsql
as
$$
--=================================================================================================
-- Вставляет в таблицу копию исходного элемента и всех дочерних элементов
--=================================================================================================
declare
 	_pdb_userid	integer	= pdb_current_userid(); -- ID текущего пользователя

	_new_parent integer;            -- idkart копии после вставки в таблицу 
	_all_parent integer[];          -- массив idkart всех копий, вложенных в текущего родителя
	
begin
    -- вставить копию текущей записи в таблицу и вернуть idkart
	insert into t27468( userid, parent, type, name, description, property_data )
	select _pdb_userid, COALESCE( _parent, a.parent ), a.type, concat( a.name, ' - копия' ),
		a.description, a.property_data
	from t27468 as a where a.idkart = _idkart
	returning idkart
	into _new_parent;

    -- повторить действие для всех дочерних элементов
	select array_agg( a.new_parent )
	from (
		select p27468_tree_duplicate_copy( a.idkart, _new_parent ) as new_parent
		from t27468 as a
		left join t27468_children as mn on a.parent = mn.idkart
		left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
		where a.dttmcl is null and a.parent = _idkart
		order by srt.sort NULLS FIRST, a.idkart desc
	) as a
	into _all_parent;
	
    -- вернуть idkart копии исходного элемента
	return _new_parent;

end;
$$;

alter function elbaza.p27468_tree_duplicate_copy(integer, integer) owner to site;

