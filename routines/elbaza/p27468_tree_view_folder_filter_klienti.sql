create or replace function elbaza.p27468_tree_view_folder_filter_klienti(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder клиентов, подпадающих под выбранный РИЦ или Метку или Куст --
--=======================================================================================--
	_placeholder jsonb = '[]';  -- результат функции 
	_placeholder_data jsonb;    -- данные placeholderа
    _folder text;
	_ric_id int;            -- ID РИЦа
	_metka_id int;          -- ID метки
	_letter text;           -- начало названия (1 буква) для фильтра
	_double_letter text;    -- начало названия (2 буквы) для фильтра
	_client_ids int[];      -- ID клиентов, отфильтрованных по списку или по полю для поиска
    _parent_folder text;    -- папка-родитель
    _kust_main boolean;     -- кусты-основные 
    _kust_related boolean;  -- кусты-связанные
    _cn int;                -- count
    _type text;
    _text text;
    _text_pref text;
    
begin
    _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
    
    if _id is not null then 
		-- если передан _id возвращает placeholder с данной буквой
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
		_text = _placeholder_data #>> '{data, text}'; 
        _type = _placeholder_data #>> '{data, type}'; 
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		_folder = _placeholder_data #>> '{data, folder}';
        
        -- сформировать условия для запроса
        if _folder = 'ric' then
            _ric_id = _placeholder_data #>> '{data, idkart}';
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null 
            and (_ric_id is null and id21324 is null or id21324 = _ric_id) 
            and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        elseif _folder = 'metka' then 
            _metka_id = _placeholder_data #>> '{data, idkart}';
            select count(*) into _cn from t27468_data_klient where dttmcl is null 
            and (_metka_id is null and id29222_list is null or _metka_id = any(id29222_list)) 
            and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        elseif _folder = 'kust_main' then
            _kust_main = true;
            select count(*) into _cn from t27468_data_klient where dttmcl is null and id24001_brush is null and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        elseif _folder = 'kust_related' then
            _kust_related = true;
            select count(*) into _cn from t27468_data_klient where dttmcl is null and id24001_brush is not null and (_client_ids is null or idkart = any(_client_ids)); 
            _text_pref = concat( '&nbsp;&nbsp;<span class="badge badge-success">' || _cn || '</span>' );
        end if;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
				case when _cn is null or _cn > 0 then 1 end as children,
                case when _cn > 0 then _text_pref end as text_pref
        ) as a; 
        
        return _placeholder;
    end if;
    
    _placeholder_data = pdb2_tree_placeholder(_name_mod, 'tree', _parent_id, 0, null); 
    _folder = _placeholder_data #>> '{data, folder}';

	-- папка для отдельного РИЦа. Собирает начало названий всех клиентов, соответствующих данному РИЦ 
	if _folder = 'ric' then
		_ric_id = _placeholder_data #>> '{data, idkart}' ;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id)
				order by a.letter
			) as a
        ) as a;
	-- папка для отдельной метки. Собирает начало названий всех клиентов, соответствующих данной метке 
	elseif _folder = 'metka' then
		_metka_id = _placeholder_data #>> '{data, idkart}' ;
        
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list))
				order by a.letter
			) as a
        ) as a;
	-- папка "Основные" для куста. Собирает начало названий всех клиентов, являющихся основными 
	elseif _folder = 'kust_main' then
    
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and a.id24001_brush is null
				order by a.letter
			) as a
        ) as a;
    -- папка "Связанные" для куста. Собирает начало названий всех клиентов, являющихся связанными
	elseif _folder = 'kust_related' then
    
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				jsonb_build_object(
				  'type', 'folder_filter_klienti',
				  'text', a.letter,
				  'folder', 'letter'
				) as id,
				a.letter as "text", 
				'folder_filter_klienti' as "type",
				_parent_id as parent,
				1 as children 
			from (
				select distinct letter 
				from t27468_data_klient as a
				where a.dttmcl is null
                and (_client_ids is null or a.idkart = any(_client_ids))
				and a.id24001_brush is not null
				order by a.letter
			) as a
        ) as a;		
    -- папка с 1 буквой. Собирает всех клиентов соответствющего РИЦ, метки или куста названия которых начинаются с выбранной буквы 
	elseif _folder = 'letter'  then
        -- получить название буквы для фильтрации
        _letter = _placeholder_data #>> '{data, text}';
        
        -- получить данные по ближайшему фильтру
        _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 1, '{data}' );
        
        -- определить тип папки родителя (РИЦ, Метка, Основной или Связанный куст)
        _parent_folder = _placeholder_data ->> 'folder';
        
        -- сформировать условия для запроса
        if _parent_folder = 'ric' then
            _ric_id = _placeholder_data ->> 'idkart';
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null 
            and (_ric_id is null and id21324 is null or id21324 = _ric_id);
        elseif _parent_folder = 'metka' then 
            _metka_id = _placeholder_data ->> 'idkart';
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null 
            and (_metka_id is null and id29222_list is null or _metka_id = any(id29222_list)); 
        elseif _parent_folder = 'kust_main' then
            _kust_main = true;
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null and id24001_brush is null; 
        elseif _parent_folder = 'kust_related' then
            _kust_related = true;
            select count(*) into _cn from t27468_data_klient 
            where dttmcl is null and id24001_brush is not null; 
        end if;
        
        -- если записей больше 300, добавить фильтр по 2 букве. Иначе вывести клиентов
        if _cn <= 300 then  
            -- сформировать jsonb-массив из клиентов
            select jsonb_agg( a ) into _placeholder
            from (
                select 
                    jsonb_build_object(
                        'type', a.type,
                        'text', a.name,
                        'idkart', a.idkart
                    ) as id,
                    a.name as "text", 
                    a.type as "type",
                    _parent_id as parent,
                    1 as children,
                    case when a.on = 1 then null else 5 end as theme
                from t27468_data_klient as a
                where a.dttmcl is null
                and a.letter = _letter
                and (_client_ids is null or a.idkart = any(_client_ids))
                and (_parent_folder <> 'ric' or (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id))
                and (_parent_folder <> 'metka' or (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list)))
                and (_kust_main is null or a.id24001_brush is null)
                and (_kust_related is null or a.id24001_brush is not null)
                order by a.name
            ) as a;
        else
            -- сформировать jsonb-массив из папок с 2 буквами
            select jsonb_agg( a ) into _placeholder
            from (
                select 
                    jsonb_build_object(
                        'type', 'folder_filter_klienti',
                        'text', a.double_letter,
                        'folder', 'double_letter'
                    ) as id,
                    a.double_letter as "text", 
                    'folder_klienti' as "type",
                    _parent_id as parent,
                    1 as children 
                from (
                    select distinct double_letter
                    from t27468_data_klient as a
                    where a.dttmcl is null
                    and a.letter = _letter
                    and (_client_ids is null or idkart = any(_client_ids))
                    and (_parent_folder <> 'ric' or (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id))
                    and (_parent_folder <> 'metka' or (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list)))
                    and (_kust_main is null or a.id24001_brush is null)
                    and (_kust_related is null or a.id24001_brush is not null)
                    order by double_letter
                ) as a
            ) as a;
        end if;
    -- папка с 2 буквами. Собирает всех клиентов соответствющего РИЦ, метки или куста названия которых начинаются с выбранных букв
    elseif _folder = 'double_letter' then
        -- получить название буквы для фильтрации
        _double_letter = _placeholder_data #>> '{data, text}';
        -- получить данные по ближайшему фильтру
        _placeholder_data = pdb2_tree_placeholder( _name_mod, _name_tree, _parent_id, 2, '{data}' );
        -- определить тип папки родителя (РИЦ, Метка, Основной или Связанный куст)
        _parent_folder = _placeholder_data ->> 'folder';
        -- сформировать условия для запроса
        if _parent_folder = 'ric' then
            _ric_id = _placeholder_data ->> 'idkart';
        elseif _parent_folder = 'metka' then 
            _metka_id = _placeholder_data ->> 'idkart';
        elseif _parent_folder = 'kust_main' then
            _kust_main = true;
        elseif _parent_folder = 'kust_related' then
            _kust_related = true;
        end if;
        
        -- сформировать jsonb-массив из клиентов
        select jsonb_agg( a ) into _placeholder
        from (
            select 
                jsonb_build_object(
                    'type', a.type,
                    'text', a.name,
                    'idkart', a.idkart
                ) as id,
                a.name as "text", 
                a.type as "type",
                _parent_id as parent,
                1 as children,
                case when a.on = 1 then null else 5 end as theme
            from t27468_data_klient as a
            where a.dttmcl is null 
            and a.double_letter = _double_letter
            and (_client_ids is null or a.idkart = any(_client_ids))
            and (_parent_folder <> 'ric' or (_ric_id is null and a.id21324 is null or a.id21324 = _ric_id))
            and (_parent_folder <> 'metka' or (_metka_id is null and a.id29222_list is null or _metka_id = any(a.id29222_list)))
            and (_kust_main is null or a.id24001_brush is null)
            and (_kust_related is null or a.id24001_brush is not null)
            order by a.name
        ) as a;
	end if;
	
    -- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

alter function elbaza.p27468_tree_view_folder_filter_klienti(text, text, text, text, text) owner to site;

