create or replace function elbaza.p27468_tree_view(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- Определяет тип элемента и вызывает соответствующую функцию -- 
-- Иерархия типов элементов дерева:
-- root_klienti(по Алфавиту) -> folder_klienti(А, Б..) -> item_klient_fizlico/yurlico(Клиент) -> folder_klient(Конт.лица) -> folder_klient(по Алфавиту) -> folder_klient (А, Б..) ->item_kontaktnoe_lico(по Алфавиту) -> folder_kontaktnoe_lico/item_telefon/item_pochta/item_rebenok
-- root_filter_klienti(по РИЦам) -> folder_filter_klienti(РИЦ_X) -> folder_filter_klienti(А,Б..) -> item_klient_fizlico/yurlico(Клиент)
-- root_filter_klienti(по Меткам) -> folder_filter_klienti(Метка_X) -> folder_filter_klienti(А,Б..) -> item_klient_fizlico/yurlico(Клиент)
-- root_filter_klienti(по Кустам) -> folder_filter_klienti(Основные) -> folder_filter_klienti(А,Б..) -> item_klient_fizlico/yurlico(Клиент)
--=======================================================================================--

	_type text;
    
begin	
    
    _type = pdb2_tree_placeholder_text(_name_mod, _name_tree, coalesce(_id, _parent_id), 0, '{data, type}'); 
    
    if  _type is null then 
    -- корневые элементы дерева (папки по Алфавиту, по РИЦам, по Меткам, по Кустам)
        return p27468_tree_view_root(_name_mod, _name_tree, _parent_id, _name_find, null); 
    elseif _type = 'root_klienti' then
    -- вложения папки "по Алфавиту"
        return p27468_tree_view_root_klienti(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'item_klient_yurlico' then
    -- вложения элемента - Клиент юр. лицо
        return p27468_tree_view_klient_yurlico(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'item_klient_fizlico' then 
    -- вложения элемента - Клиент физ.лицо
        return p27468_tree_view_klient_fizlico(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'folder_klienti' then 
    -- вложения папки с первой буквой наименования клиента 
        return p27468_tree_view_folder_klienti(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'folder_klient' then
    -- вложения папки "Контактные лица", по Алфавиту" и буквы алфавита для контактных лиц
        return p27468_tree_view_folder_klient(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif  _type = 'root_filter_klienti' then  
    -- вложения корневого фильтра "по РИЦам", "по Меткам", "по Кустам" и папок "Филиалы", "Кусты"
        return p27468_tree_view_root_filter(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif  _type = 'folder_filter_klienti' then  
    -- вложения папок для РИЦ, Меток
        return p27468_tree_view_folder_filter_klienti(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    elseif _type = 'folder_filter_klient' then 
    -- вложения для фильтр контактных лиц "по Состоянию", "по Меткам"
        return p27468_tree_view_folder_filter_klient(_name_mod, _name_tree, _parent_id, _name_find, _id); 
    else
    -- контактные лица, телефон, email и др. папки, вложенные в контактное лицо
        return p27468_tree_view_kontaktnie_lica(_name_mod, _name_tree, _parent_id, _name_find, _id);
    end if;
    
	return null;
    
--     реализация через таблицу связей (не оптимально из-за слишком большого количества записей)    
--     if _id is not null then
--         select jsonb_agg( a ) into _placeholder
--         from (
--             select 
--                 a.idkart as id,
--                 b.idkart as parent, 
--                 c.name as "text", 
--                 c.type as "type",
--                 case when (select count(*) from t27468_structure as d where d.parent_id = a.child_id) > 0 then 1 end as children
--             from t27468_structure as a
--             inner join t27468_structure as b on a.parent_id = b.child_id
--             inner join t27468 as c on a.child_id = c.idkart
--             where c.dttmcl is null and a.idkart = _id::int 
--         ) as a;
--     elseif _name_find is null then
--         for _rc in 
--             select b.idkart as id, 
--                    a.idkart as parent, 
--                    c.idkart as idkart, 
--                    c.name as "text", 
--                    c.type as "type", 
--                    count(*) as count 
--             from t27468_structure as a
--             inner join t27468_structure as b on a.child_id = b.parent_id
--             inner join t27468 as c on b.child_id = c.idkart
--             left join t27468 as d on d.parent = b.child_id
--             where c.dttmcl is null 
--             and a.idkart = _parent_id::int
--             group by c.idkart, b.idkart, a.idkart
--             order by c.name
--         loop
--             if  _rc.type = 'root_klienti' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по РИЦам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_ric || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по Меткам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_metki || '</span>' );
--             elseif _rc.type  = 'root_filter_klienti' and _rc.text = 'по Кустам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_kusty || '</span>' );
--             end if;

--             _placeholder = _placeholder || 
--                   jsonb_build_object(
--                       'id', _rc.id,
--                       'parent', _rc.parent,
--                       'text', _rc.text,
--                       'type', _rc.type,
--                       'text_pref', _text_pref,
--                       'children', case when _rc.count > 0 or _rc.type ~* 'root%' then 1 end);
--         end loop;
--     else
--         for _rc in 
--             select b.idkart as id, 
--                    a.idkart as parent, 
--                    c.idkart as idkart, 
--                    c.name as "text", 
--                    c.type as "type", 
--                    count(*) as count 
--             from t27468_structure as a
--             inner join t27468_structure as b on a.child_id = b.parent_id
--             inner join t27468 as c on b.child_id = c.idkart
--             left join t27468_structure as d on d.parent_id = b.child_id
--             where c.dttmcl is null 
--             and a.idkart = _parent_id::int
--             and case when c.type in ('item_klient_fizlico', 'item_klient_yurlico') then c.idkart = any(_client_ids) 
--                      when c.type in ('folder_klienti', 'folder_klient') then c.name = left(upper(_name_find),1) 
--                      else true end
--             group by c.idkart, b.idkart, a.idkart
--             order by c.name
--         loop
--             if  _rc.type = 'root_klienti' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_all || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по РИЦам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_ric || '</span>' );
--             elseif  _rc.type = 'root_filter_klienti' and _rc.text = 'по Меткам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_metki || '</span>' );
--             elseif _rc.type  = 'root_filter_klienti' and _rc.text = 'по Кустам' then
--                 _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn_kusty || '</span>' );
--             end if;

--             _placeholder = _placeholder || 
--                   jsonb_build_object(
--                       'id', _rc.id,
--                       'parent', _rc.parent,
--                       'text', _rc.text,
--                       'type', _rc.type,
--                       'text_pref', _text_pref,
--                       'children', case when _rc.count > 0 or _rc.type ~* 'root%' then 1 end);
--         end loop;
--     end if;
    
--     return _placeholder; 

end;
$$;

alter function elbaza.p27468_tree_view(text, text, text, text, text) owner to site;

