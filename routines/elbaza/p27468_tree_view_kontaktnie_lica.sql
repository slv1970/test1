create or replace function elbaza.p27468_tree_view_kontaktnie_lica(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
	_rc record;
	_placeholder jsonb = '[]';
    _placeholder_data jsonb = '[]';

	_parent_idkart int; 
    _idkart int;
    _cn_all int;
    _cn_catalog int;
    _text text;
    _type text;
    
begin
	if _id is not null then
		_placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		_idkart = _placeholder_data #>> '{data, idkart}' ;
        
        -- добавить ветку		
		select jsonb_agg( a ) into _placeholder
		from (
            select
                _id as id,
                a.name as "text", 
                _type as "type",
                _parent_id as parent,
                case when a.on = 1 then null else 5 end as theme,
                case when (select count(*) from t27468 where dttmcl is null and parent = _idkart) > 0 then 1 end as children
			from t27468 as a
			where dttmcl is null 
            and idkart = _idkart
        ) as a;
        
        return _placeholder; 
	end if; 
    
	_parent_idkart = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, idkart}' );
    
	create local temp table _tmp_pdb2_tpl_tree_view(
		sort serial, idkart integer, "name" text, "type" text, parent integer, "on" integer
	) on commit drop;

	insert into _tmp_pdb2_tpl_tree_view( idkart, "name", "type", "parent", "on" )
	select a.idkart, a.name, a.type, a.parent, a.on
	from t27468 as a
	left join t27468_children as mn on a.parent = mn.idkart
	left join unnest( mn.children ) WITH ORDINALITY as srt(idkart,sort) on a.idkart = srt.idkart
	where a.dttmcl is null 
		and (
			_idkart is null and a.parent = _parent_idkart or a.idkart = _idkart
		)
	order by srt.sort NULLS FIRST, a.idkart desc;
    
    for _rc in
	
		select a.idkart, a.name, a.type, a.parent, a.on
		from _tmp_pdb2_tpl_tree_view as a
		order by a.sort
	loop
        -- условие поиска
		with recursive temp1( idkart ) as 
		(
			select a.idkart
			from t27468 as a
			where a.dttmcl is null and a.idkart = _rc.idkart
			union
			select a.idkart
			from t27468 as a
			inner join temp1 on temp1.idkart = a.parent
			where a.dttmcl is null
		)
		select count(*), max( case when a.idkart <> _rc.idkart or b.type ~~* '%filter%' then 1 end )
		from temp1 as a 
		inner join t27468 as b on a.idkart = b.idkart
		into _cn_all, _cn_catalog;
        
        -- ветка по условию поиска не подходит
		continue when _cn_all = 0;
        
        -- добавить ветку		
		_placeholder = _placeholder || 
				jsonb_build_object(
					'id', jsonb_build_object('type', _rc.type, 'text', _rc.name, 'idkart', _rc.idkart),
 					'parent', _parent_id,
 					'text', _rc.name,
 					'type', _rc.type,
					'children', _cn_catalog,
					'theme', case when _rc.on = 1 then null else 5 end
				);

	end loop;
    
	drop table _tmp_pdb2_tpl_tree_view;
    
    -- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

alter function elbaza.p27468_tree_view_kontaktnie_lica(text, text, text, text, text) owner to site;

