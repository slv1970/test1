create or replace function elbaza.p30436_tree_view(_parent integer, _name_find text, _idkart integer, _name_table text, _name_table_children text) returns jsonb
    language plpgsql
as
$$
--=================================================================================================
-- Формирует placeholder из дочерних элементов выбранного родителя. 
-- При передаче параметра idkart формирует объект data с параметрами для task-а 
-- _parent - idkart родителя в таблице дерева
-- _name_find - текст в поле для поиска
-- _idkart - idkart элемента в таблице дерева
--=================================================================================================
declare
    _pdb_userid	integer	= pdb2_current_userid(); -- текущий пользователь
	_rc record;
	_placeholder jsonb[]; -- placeholder с массивом всех дочерних элементов текущего элемента
	_cn_all integer;      -- количество вложенных элементов 
	_cn_catalog integer;  -- 1 - у элемента есть вложенные элементы, null - нет
	
begin
    -- создать временную таблицу для хранения записей
	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;
    
    -- получает все дочерние элементы для parent, и вставляет их во временную таблицу
    -- если передан idkart вставляет в таблицу элемент с указанным idkart
    -- показывает только элементы, созданные текущим пользователем либо корневую папку, если таких элементов нет 
    insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
    select a.idkart, a.name, a.type, a.parent, a.on
    from t30436 as a
    left join t30436_children as mn on a.parent = mn.idkart
    left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
    where a.dttmcl is null 
        and (a.userid = _pdb_userid or a.parent = 0)
        and (
            _idkart is null and ( a.parent = _parent or _parent = 0 and a.parent = 0 )
            or a.idkart = _idkart
        )
    order by srt.sort NULLS FIRST, a.idkart desc; 
    
    -- для всех элементов во временной таблице, собирает idkart его ветки в дереве
    -- ищет элементы, у которых наименование совпадает с _name_find (если оно не null)
    -- формирует placeholder если количество вложенных элементов > 0
	for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
		
	loop
        -- условие поиска
        with recursive temp1( idkart, ok ) as 
        (
            select a.idkart,
                case when 
                    _name_find is null or 
                    a.name ~* _name_find and a.type not like '%folder%'
                then true end
            from t30436 as a
            where a.dttmcl is null and a.idkart = _rc.idkart
            union
            select a.idkart,
                case when 
                    temp1.ok = true or 
                    a.name ~* _name_find and a.type not like '%folder%'
                then true end
            from t30436 as a
            inner join temp1 on temp1.idkart = a.parent
            where a.dttmcl is null
        )
        select count(*), max( case when a.idkart <> _rc.idkart then 1 end )
        from temp1 as a where a.ok = true
		into _cn_all, _cn_catalog;
				
        -- ветка по условию поиска не подходит
		continue when _cn_all = 0;
        -- добавить ветку		
		_placeholder = _placeholder || 
				jsonb_build_object(
					'id', _rc.idkart,
 					'parent', _rc.parent,
 					'text', _rc.name,
 					'type', _rc.type,
					'children', _cn_catalog,   
					'theme', case when _rc.on = 1 then null else 5 end  -- выделяет красным
				);

	end loop;
	
	drop table _tmp_pdb2_tpl_tree_view; 
					
	return to_jsonb( _placeholder );

end;
$$;

alter function elbaza.p30436_tree_view(integer, text, integer, text, text) owner to site;

