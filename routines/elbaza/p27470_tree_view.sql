create or replace function elbaza.p27470_tree_view(_parent integer, _name_find text, _idkart integer, _name_table text, _name_table_children text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb_current_userid();
	_rc record;
	_placeholder jsonb[];
	_cn_all integer;
	_cn_catalog integer;
begin
-- item_filtr - показывает только текущего пользователя

	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;

	execute format( '
		insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
		select a.idkart, a.name, a.type, a.parent, a.on
		from %I as a
		left join %I as mn on a.parent = mn.idkart
		left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
		where a.dttmcl is null 
			and (
				$1 is null and ( a.parent = $2 or $2 = 0 and a.parent = 0 )
				or a.idkart = $1 
			)
			and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
		order by srt.sort NULLS FIRST, a.idkart desc', _name_table, _name_table_children, _pdb_userid )
	using _idkart, _parent;
	
	for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
		
	loop
-- условие поиска
		execute format( '
			with recursive temp1( idkart, ok ) as 
			(
				select a.idkart,
					case when 
						$2 is null or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				where a.dttmcl is null and a.idkart = $1
				union
				select a.idkart,
					case when 
						temp1.ok = true or 
						a.name ~* $2 and a.type not like ''%%folder%%''
					then true end
				from %I as a
				inner join temp1 on temp1.idkart = a.parent
				where a.dttmcl is null
					and (a.type <> ''item_filtr'' or a.type = ''item_filtr'' and a.userid = %L)
			)
			select count(*), max( case when a.idkart <> $1 then 1 end )
			from temp1 as a 
			inner join %I as b on a.idkart = b.idkart
			where a.ok = true
					   ;', _name_table, _name_table, _pdb_userid, _name_table )
		using _rc.idkart, _name_find
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
					'theme', case when _rc.on = 1 then null else 5 end
				);

	end loop;
	
	drop table _tmp_pdb2_tpl_tree_view;
	
	return to_jsonb( _placeholder );

end;
$$;

alter function elbaza.p27470_tree_view(integer, text, integer, text, text) owner to site;

