create or replace function elbaza.p27474_tab(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare
	_pdb_userid integer	= pdb2_current_userid();
	_include text	 	= pdb2_event_include( _name_mod );
	_event text 		= pdb2_event_name( _name_mod );
	_filter_val text 	= pdb2_val_include_text( 'p27474_table', 'filter', '{value}' ); -- id выбранного фильтра
	_from text;
	_fields jsonb;
	_where text[];
	_tab text;  -- табы
	_tmp json;  -- json для всех фильтров
	_filter jsonb;  -- json для фильтров
	_status_s int[];  -- массив для статусов
    _idkart jsonb;
    _button int         = pdb2_val_include_text( _name_mod, 'button', '{value}' );
begin
    if pdb2_val_api_text( '{post, awdId}' ) = 6::text then
        update t29567
        set group_id = 1,
        dttmup = now()
        where group_id = 2
        and page = 2;
        perform pdb_func_alert( _value, 'success', 'История очищена' );
    end if;
    
    update t29567 
    set group_id = 1,
    dttmup = now()
    WHERE group_id = 2 
    and dttmup::date <> current_date
    and idispl = _pdb_userid
    and page = 2
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
				and a.page = 2  -- для определенной страницы
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
				and a.page = 2  -- для определенной страницы
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
			'phone', a.phone_address_from,
			'sms_message', a.message,
			'status', a.status::int[],
			'gateway', a.gateway,
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
            values (_pdb_userid, _filter_val, 3, 2);
            perform pdb2_val_include( _name_mod, 'table', '{pdb, includes, find}', 'filter');
        end if;
        
	end if;

    
	-- Табы
	_tab = pdb2_val_include_text( _name_mod, 'tabs', '{value}' );
	
	if _tab = '1' then
		-- Выберутся все записи
	elsif _tab = '2' then
		-- Исходящие:
		_where = _where || format( 'tp.idkart = 29' );
	elsif _tab = '3' then
		-- Входящие:
		_where = _where || format( 'tp.idkart = 28' );
	end if;
	
	-- Фильтры:
	-- Дата "От"
    if (_filter ->> 'group')::int <> 3 then
        if (_filter ->> 'date_start') is not null then 
            _where = _where || format( 'a.dttmcr >= %L', (_filter ->> 'date_start') );
        end if;
        -- Дата "До"
        if (_filter ->> 'date_end') is not null then 
            _where = _where || format( 'a.dttmcr <= %L', (_filter ->> 'date_end') );
        end if;
        -- Телефон
        if (_filter ->> 'phone') is not null then 
            _where = _where || format( 'a.sms_phone ilike ''%%%s%%''', (_filter ->> 'phone') );
        end if;
        -- Сообщение
        if (_filter ->> 'sms_message') is not null then 
            _where = _where || format( 'a.sms_message ilike ''%%%s%%''', (_filter ->> 'sms_message') );
        end if;
        _status_s = (select array_agg( a.value::integer ) 
                     from jsonb_array_elements_text( (_filter ->> 'status')::jsonb ) as a); -- массив статусов
        -- Статус сообщения
        if (_filter ->> 'status') is not null then 
            _where = _where || format( 'st.idkart = any( %L )',(_status_s));
        end if;
        -- Шлюз сообщения
        if (_filter ->> 'gateway') is not null then 
            _where = _where || format( 'gw.idkart = %L', (_filter ->> 'gateway') );
        end if;
        -- Исполнитель
        if (_filter ->> 'id21311') is not null then 
            _where = _where || format( 'a.id21311 = %L', (_filter ->> 'id21311') );
        end if;
        -- Подраздедение
        if (_filter ->> 'id21301') is not null then 
            _where = _where || format( 'a.id21301 = %L', (_filter ->> 'id21301') );
        end if;
    end if;
	
	-- Неудалённые записи
	_where = _where || format( 'a.dttmcl is null' );

	-- Выбирает данные
	_from = format(		
		'select
			a.idkart,
			tp.name as sms_type,
			st.name as sms_status,
			a.dttmcr,
			to_char(a.dttmcr, ''dd.mm.yy HH24:MI:SS'') as sms_datatime_fmt,
			a.sms_phone,
			a.sms_message,
			gw.name as sms_gateway
		from t27474 as a
		left join t19391_data_email_type as tp on a.sms_type = tp.idkart
		left join t19391_data_email_status as st on a.sms_status = st.idkart
		left join t19391_data_sms_gateway as gw on a.sms_gateway = gw.idkart
	');
	
	-- Подготовка списка полей
	_fields = jsonb_build_array(
		jsonb_build_object( 'text', 'sms_type', 'sort', 'sms_type' ),
		jsonb_build_object( 'text', 'sms_status', 'sort', 'sms_status' ),
		jsonb_build_object( 'text', 'sms_datatime_fmt', 'sort', 'sms_datatime_fmt' ),
		jsonb_build_object( 'text', 'sms_phone', 'sort', 'sms_phone' ),
		jsonb_build_object( 'text', 'sms_message', 'sort', 'sms_message' ),
		jsonb_build_object( 'text', 'sms_gateway', 'sort', 'sms_gateway' ),
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

alter function elbaza.p27474_tab(jsonb, text) owner to site;

