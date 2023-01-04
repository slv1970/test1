create or replace function elbaza.p27468_tree_view_folder_klienti(_name_mod text, _name_tree text, _parent_id text, _name_find text, _id text) returns jsonb
    language plpgsql
as
$$
declare
--=======================================================================================--
-- возвращает placeholder для папки с первой буквой наименования клиента 
--=======================================================================================--
	_placeholder jsonb = '[]';  -- возвращаемое значение
    _placeholder_data jsonb;    -- данные Placeholder-а из сессии
    _folder text;               -- папка в дереве
	_letter text;               -- начало названия (1 буквf)
	_double_letter text;        -- начало названия (2 буквы)
	_client_ids int[];          -- массив ID клиентов, отфильтрованных по списку или полю для поиска
    _cn int;                    -- count
    _text text;                 -- название элемента в дереве
    _type text;                 -- тип элемента в дереве
    
begin
    -- сформировать placeholder по id. Возвращает папку с одной буквой или с двумя буквами
	if _id is not null then 
        -- получить данные placeholder-а по id
		_placeholder_data = pdb2_tree_placeholder(_name_mod, _name_tree, _id, 0, null); 
        -- получить название элемента в дереве
		_text = _placeholder_data #>> '{data, text}'; 
        -- получить тип элемента в дереве
        _type = _placeholder_data #>> '{data, type}'; 
        -- получить ID родителя
 		_parent_id = _placeholder_data #>>  '{item, parent}'; 
		-- сформировать jsonb-массив из одного элемента
		select jsonb_agg( a ) into _placeholder
		from (
			select 
				_id as id,
				_text as "text", 
				_type as "type",
				_parent_id as parent,
				1 as children
        ) as a; 
        
        return _placeholder;
    end if;
    
    _folder = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, folder}' ); 
    
    -- сформировать placeholder из клиентов, наименование которых начинается с выбранной буквы. 
    if _folder = 'letter' then
        -- получить букву, по которой нужно отфильтровать клиентов
        _letter = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );
        -- получить массив ID отфильтрованных клиентов (по списку и полю для поиска)
        _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
        -- посчитать количество клиентов, названия которых начинаются на данную букву
        select count(*) into _cn from t27468_data_klient where dttmcl is null and letter = _letter;
        
        -- проверка условия для доп. фильтрации по 2 букве
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
                order by a.name
            ) as a;
        else
            -- сформировать jsonb-массив из папок с 2 буквами
            select jsonb_agg( a ) into _placeholder
            from (
                select 
                    jsonb_build_object(
                        'type', 'folder_klienti',
                        'text', a.double_letter,
                        'folder', 'double_letter'
                    ) as id,
                    a.double_letter as "text", 
                    'folder_klienti' as "type",
                    _parent_id as parent,
                    1 as children 
                from (
                    select distinct double_letter
                    from t27468_data_klient
                    where dttmcl is null
                    and letter = _letter
                    and (_client_ids is null or idkart = any(_client_ids))
                    order by double_letter
                ) as a
            ) as a;
        end if;
        
    -- сформировать placeholder для папки из 2 букв. Собирает всех клиентов, наименование которых начинается с данных букв
    elseif _folder = 'double_letter' then
        -- получить буквы, по которой нужно отфильтровать клиентов
        _double_letter = pdb2_tree_placeholder_text( _name_mod, _name_tree, _parent_id, 0, '{data, text}' );
        -- получить массив ID отфильтрованных клиентов (по списку и полю для поиска)
        _client_ids = pdb2_val_session_text('p27468_tree', '{client_ids}'); 
        
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
            order by a.name
        ) as a;
	end if; 
    
    -- записать в сессию и сформирвоать уникальный ключ для дерева
	return pdb2_tree_placeholder( _name_mod, _name_tree, _placeholder );

end;
$$;

alter function elbaza.p27468_tree_view_folder_klienti(text, text, text, text, text) owner to site;

