create or replace function elbaza.p27472_tab(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );

	_from text;
	_fields jsonb;
	_where text[];
	_tab text;
	_tmp jsonb;
	_date_create timestamptz = 'today';
	_filter_val text 	= pdb2_val_include_text( 'p27472_table', 'filter', '{value}' ); -- id выбранного фильтра
	_filter jsonb;  -- json для фильтров
	_status_s int[];  -- массив для статусов
    _idkart jsonb;

begin
    if pdb2_val_api_text( '{post, awdId}' ) = 6::text then
        update t29567
        set group_id = 1,
        dttmup = now()
        where group_id = 2
        and page = 1;
        perform pdb_func_alert( _value, 'success', 'История очищена' );
    end if;
	
	update t29567 
    set group_id = 1,
    dttmup = now()
    WHERE group_id = 2 
    and dttmup::date <> current_date
    and idispl = _pdb_userid
    and page = 1
    and dttmcl is null;
    
	-- Инициализация переменных
	perform pdb2_mdl_before( _name_mod );
	
    
	-- Получение всех фильтров
	SELECT json_agg(obj.val) INTO _tmp
	FROM (
		SELECT jsonb_build_object(
			'text', child.group_name,
			'children', child.children 
		)  AS val
		FROM (
			SELECT array_agg(b.value) AS children, b.group_name AS group_name 
			FROM (
                (SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 1  -- для определенной страницы
                and a.group_id = 1
                order by a.idkart)
                union all
				(SELECT jsonb_build_object(
					'id', a.idkart,
					'text', a.filter_name) AS value,
					d.group_name AS group_name
				FROM t29567 AS a
				LEFT JOIN t29567_groups d ON d.idkart = a.group_id
				WHERE a.dttmcl is null
				and a.idispl = _pdb_userid  -- для определенного юзера
				and a.page = 1  -- для определенной страницы
                and ((a.group_id = 2) or (a.group_id = 3 and (a.dttmcr::date = current_date)))
                order by a.idkart)
			) AS b 		
			GROUP BY b.group_name
		) AS child
	) as obj;
    
        
    perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', null );
	perform pdb2_val_include( _name_mod, 'filter', '{placeholder}', _tmp );
    
	
    --raise '%', _tmp;
    
	--raise '%', pdb2_val_include_text( _name_mod, 'table', '{pdb, includes, find}');
    
	-- Получение данных для определенного фильтра
	if _filter_val is not null then
        
		select jsonb_build_object(
			'list_name', a.filter_name,
			'date_start', a.date_start,
			'date_end', a.date_end,
            'phone_address_to', a.phone_address_to,
			'phone_address_from', a.phone_address_from,
			'time_start', a.time_start,
			'time_end', a.time_end,
			'id21311', a.id21311,
			'id21301', a.id21301,
            'group', a.group_id
		) as val
		into _filter
		from t29567 as a
		where a.idkart::text = _filter_val
		and dttmcl is null;
        
        if (_filter ->> 'group')::int = 1 then
            update t29567
            set group_id = 2,
            dttmup = now()
            where idkart::text = _filter_val;
        end if;
        
        if _filter is not null then
            if (_filter ->> 'group')::int = 3 then
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
                perform pdb2_val_include( _name_mod, 'filter', '{value}', (_filter ->> 'list_name'));
                --raise '%', pdb2_val_include_text( _name_mod, 'filter', '{data}');
            else 
                perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', null);
            end if;
        else
            insert into t29567 (idispl, filter_name, group_id, page)
            values (_pdb_userid, _filter_val, 3, 1);
            perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
        end if;
        
	end if;

	
	_tab = pdb2_val_include_text( _name_mod, 'tabs', '{value}' );
		
	if _tab = '1' then
		-- Выберутся все записи
	elsif _tab = '2' then
		-- Исходящие:
		_where = _where || format( 'b.idkart = 18' );
	elsif _tab = '3' then
		-- Входящие:
		_where = _where || format( 'b.idkart = 20' );
	end if;
    
    -- Дата "От"
    if (_filter ->> 'group')::int <> 3 then
        if (_filter ->> 'date_start') is not null then 
            _where = _where || format( 'a.time_start::date >= %L', (_filter ->> 'date_start')::date );
        end if;
        -- Дата "До"
        if (_filter ->> 'date_end') is not null then 
            _where = _where || format( 'a.time_end::date <= %L', (_filter ->> 'date_end')::date );
        end if;
        -- Телефон
        if (_filter ->> 'phone_address_to') is not null then 
            _where = _where || format( 'a.number_called ilike ''%%%s%%''', (_filter ->> 'phone_address_to') );
        end if;
        -- Сообщение
        if (_filter ->> 'phone_address_from') is not null then 
            _where = _where || format( 'a.number_who_called ilike ''%%%s%%''', (_filter ->> 'phone_address_from') );
        end if;
        -- Статус сообщения
        if (_filter ->> 'time_start') is not null then 
            _where = _where || format( 'extract(epoch from (a.time_end - a.time_start)) >= %L', (_filter ->> 'time_start') );
        end if;
        if (_filter ->> 'time_end') is not null then 
            _where = _where || format( 'extract(epoch from (a.time_end - a.time_start)) >= %L', (_filter ->> 'time_end') );
        end if;
        -- Исполнитель
        if (_filter ->> 'id21311') is not null then 
            _where = _where || format( 'a.userid = %L', (_filter ->> 'id21311') );
        end if;
        -- Подраздедение
        if (_filter ->> 'id21301') is not null then 
            _where = _where || format( 'podr.idkart = %L', (_filter ->> 'id21301') );
        end if;
    end if;
    
	-- Неудалённые записи
	_where = _where || format( 'a.dttmcl is null' );
	-- За сегодня
	--_where = _where || format( 'a.dttmcr >= ''%s''::date', _date_create );
	-- Созданные текущим пользователем
	--_where = _where || format( 'a.userid = %s', _pdb_userid ); -- пока отключила

	-- Выбирает данные
	_from = format(		
		'SELECT
			a.idkart,
			b.name as type,
			b.idkart as type_idkart,
			to_char(a.time_start, ''DD.MM.YYYY HH24:MI:SS'') AS time_start,
			to_char(a.time_end, ''DD.MM.YYYY HH24:MI:SS'') AS time_end,
			ROUND(EXTRACT(EPOCH FROM a.time_end))-ROUND(EXTRACT(EPOCH FROM a.time_start)) AS duration,
			a.number_called,
			a.number_who_called,
			c.user_name as fio
		FROM t27472 AS a
		LEFT JOIN t19391 AS b ON a.type = b.idkart
		LEFT JOIN t20455_data AS c ON a.subscriber = c.idkart
        left join t20175_data_podrazdeleniye as podr on a.userid = podr.userid
	');

	-- Подготовка списка полей
	_fields = jsonb_build_array(
		jsonb_build_object( 'text', 'type', 'sort', 'type' ),
		jsonb_build_object( 'text', 'time_start', 'sort', 'time_start' ),
		jsonb_build_object( 'text', 'time_end', 'sort', 'time_end' ),
		jsonb_build_object( 'text', 'duration', 'sort', 'duration', 'align', '''center''' ),
		jsonb_build_object( 'text', 'number_called', 'sort', 'number_called' ),
		jsonb_build_object( 'text', 'number_who_called', 'sort', 'number_who_called' ),
		jsonb_build_object( 'text', 'fio', 'sort', 'fio' ),
		jsonb_build_object( 'align', '''center''', 'includes', array['dropdown'] )
	);
				
	-- Инициализация таблицы
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,from}', _from );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,query,where}', _where );
	perform pdb2_val_include( _name_mod, 'table', '{pdb,table,fields}', _fields );
--============================================================================================================
	perform  pdb2_mdl_after( _name_mod );
	return null;

end;
$$;

alter function elbaza.p27472_tab(jsonb, text) owner to site;

