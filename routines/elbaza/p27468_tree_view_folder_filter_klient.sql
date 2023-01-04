create or replace function elbaza.p27468_tree_view_folder_filter_klient(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder контактных лиц, отфильтрованных по статусу или по меткам
--=======================================================================================--
	_text text; 
	_placeholder jsonb = '[]';
	_client_id int;
	_status_id int; 
	_metka_id int; 
    _inn text;
    _id24001_brush int;
    _placeholder_data jsonb;
    _type text;
    _folder text;
    _cn int;
    
begin
    if _id is not null then 
		-- если передан _id возвращает placeholder с данной буквой
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
        _parent_id = _placeholder_data #>>  '{item, parent}'; 
        -- добавить подсчет количества
        if _text = 'Филиалы' then
            _client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _id, 1, '{data, idkart}' );

            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null and idkart <> _client_id
            and inn = (select inn from t27468_data_klient where dttmcl is null and idkart = _client_id);

        elseif _text = 'Кусты' then
            _client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _id, 1, '{data, idkart}' );
            
            select count(*) into _cn from t27468_data_klient as a 
            where a.dttmcl is null and a.id24001_brush = _client_id;
            
        end if;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
                case when _cn > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) end as text_pref,
				case when _cn is null or _cn > 0 then 1 end as children
        ) as a; 
        
        return _placeholder;
    end if;
    
    _text = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' ) ;

	if _text = 'по Состоянию' then
		-- Собирает placeholder для папки "по Состоянию" (фильтр контактных лиц)
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 2, '{data, idkart}' );
		
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_klient',
                  'text', a.text, 
				  'idkart', a.id,
				  'folder', 'status'
				) as id,
				a.text as "text", 
				'folder_klient' as "type",
				_parent_id as parent,
                case when a.count > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || a.count || '</span>' ) end as text_pref,
				case when a.count > 0 then 1 end as children 
			from (
				select c.id, COALESCE( c.text, '- нет -' ) as text, count(*) as count
				from t27468_data_kontaktnoe_lico as a 
 				inner join t27468 as b on b.idkart = a.idkart
                left join v19697_status_select as c on a.id26011 = c.id
				where a.dttmcl is null and b.dttmcl is null and c.dttmcl is null
				and b.parent = _client_id
				group by c.id, c.text 
			) as a
        ) as a;
			
	elseif _text = 'по Меткам' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 2, '{data, idkart}' );
        
        
        select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_klient',
                  'text', a.text, 
				  'idkart', a.id,
				  'folder', 'metka'
				) as id,
				a.text as "text", 
				'folder_klient' as "type",
				_parent_id as parent,
                case when a.count > 0 then concat( '&nbsp;&nbsp;<span class="badge badge-success">' || a.count || '</span>' ) end as text_pref,
				case when a.count > 0 then 1 end as children 
			from (
				select c.id, COALESCE( c.text, '- нет -' ) as text, count(*) as count
				from (
					select unnest( COALESCE( a.id29222_list, array[-1] )) as id29222
					from t27468_data_kontaktnoe_lico as a
					inner join t27468 as b on a.idkart = b.idkart
					where a.dttmcl is null and b.dttmcl is null and b.parent = _client_id
                ) as a
				left join v19638_data_metka_select as c on c.id = a.id29222
				where c.dttmcl is null
				group by c.id, c.text
                order by c.text
            )  as a
        ) as a;  
    elseif _text = 'Филиалы' then
        _client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 1, '{data, idkart}' );
        select inn into _inn from t27468_data_klient where idkart = _client_id; 

        select jsonb_agg( a )  into _placeholder
        from (
            select 
                jsonb_build_object(
                  'type', b.type,
                  'text', b.name,
                  'idkart', b.idkart
                ) as id,
                b.name as "text", 
                b.type as "type",
                _parent_id as parent,
                concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) as text_pref,
                1 as children,
               case when b.on = 1 then null else 5 end as theme
            from t27468_data_klient a
            inner join t27468 as b on a.idkart = b.idkart
            where a.dttmcl is null and b.dttmcl is null
            and a.inn = _inn and a.idkart <> _client_id
        ) as a;
            
	elseif _text = 'Кусты' then
		_client_id = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 1, '{data, idkart}' );
        
		select jsonb_agg( a )  into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', b.type,
                  'text', b.name,
				  'idkart', b.idkart
				) as id,
				b.name as "text", 
				b.type as "type",
				_parent_id as parent,
                concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' ) as text_pref,
				1 as children,
               case when b.on = 1 then null else 5 end as theme
			from t27468_data_klient a
			inner join t27468 as b on a.idkart = b.idkart
			where a.dttmcl is null and b.dttmcl is null
			and a.id24001_brush = _client_id
        ) as a;  
    
    end if;
	
	return pdb2_tree_placeholder( 'p27468_tree', 'tree', _placeholder );

end;
$$;

alter function elbaza.p27468_tree_view_folder_filter_klient(text, text, text, text, text) owner to site;

