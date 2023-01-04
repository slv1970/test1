create or replace function elbaza.p30436_tree_duplicate(_name_mod text, _name_tree text, _name_table text, _name_table_children text) returns void
    language plpgsql
as
$$
--=================================================================================================
-- Дублирует элемент дерева и всю ветку данного элемента. При дублировании списка - дублирует также
-- его фильтр. При дублировании другого элемента, обновляет фильтр списка
--=================================================================================================
declare
 	_pdb_userid	integer	= pdb2_current_userid(); -- текущий пользователь
 	_after integer;     -- idkart исходного элемента
    _idkart integer;    -- idkart копии
  	_placeholder jsonb;	-- placeholder для нового элемента дерева
	_parent integer;    -- папка, в которой находится исходный элемент
	_children jsonb;    -- все элементы папки, в которой находится исходный элемент
	_cn integer;        -- count, для проверки наличия элемента в таблице
    _data_filter_old jsonb; -- фильтр списка в котором находится исходный элемент
    _data_filter_new jsonb = '{}'; -- новый фильтр списка с копиями
    _data_filter_item jsonb;
    _type text;         -- тип исходного элемента
    _list_id_new int;   -- id нового списка (при дублировании списка)
    _rc record;         
    _idkart_matches jsonb; -- словарь соответствий после дублирования (idkart_исходн. : idkart_копии)
    _filter_id text;    -- id для фильтра
    _filter_parent text; -- parent для фильтра
    
begin
-- получить переменые
	_parent = pdb2_val_api_text( '{post,parent}' );
 	_children = pdb2_val_api( '{post,children}' );
	_after = pdb2_val_api_text( '{post,id}' );
    -- дублировать запись
    -- очистить сессию, для сохранения соответствий между id оригинала и дубликата
    perform pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}', null);
    -- сохранить копию и получить id скопированной записи
    _idkart = p30436_tree_duplicate_copy( _after, null, _name_table, _name_table_children );
    -- соответствия id (id_оригинала : id_копии) 
    _idkart_matches = pdb2_val_session('p30436_tree_duplicate', '{idkart_matches}');
    
    -- получить фильтр исходного элемента
    select data_filter into _data_filter_old from t30436_data_spisok where userid = _pdb_userid and data_filter ? _after::text;
    -- получить тип исходного элемента
    select type into _type from t30436 where idkart = _idkart; 
    
    -- сформировать новый фильтр для копии
    if _type = 'item_spisok' then
        _list_id_new = _idkart; 
        -- получить все значения из старого фильтра, обновив id и parent на новые
        for _rc in 
            select a.key, a.value from jsonb_each(_data_filter_old) as a
            order by a.key 
        loop
            if _rc.value ->> 'type' = 'root_spiski' then
                _data_filter_new = jsonb_build_object(_rc.key, _rc.value);
            else
                _filter_id = coalesce(_idkart_matches ->> _rc.key::text, _rc.key::text); 
                _filter_parent = coalesce(_idkart_matches ->> (_rc.value ->> 'parent'), (_rc.value ->> 'parent')); 
                _rc.value = pdb_val(_rc.value, array['id'], _filter_id);
                _rc.value = pdb_val(_rc.value, array['parent'], _filter_parent);
                _rc.value = pdb_val(_rc.value, array['on'], null);
                _data_filter_new = _data_filter_new || jsonb_build_object(_filter_id, _rc.value);
            end if;
        end loop;
    elseif _type ~* 'item' then
        -- при дублировании элементов списка, добавить текущий фильтр копию этого элемента
        _list_id_new = (select idkart from t30436_data_spisok where userid = _pdb_userid and data_filter ? _after::text);
        _data_filter_new = _data_filter_old || jsonb_build_object(_idkart, pdb_val(_data_filter_old -> _after::text, array['id'], _idkart)); 
    end if;
    -- сохранить новый фильтр
    update t30436_data_spisok set data_filter = _data_filter_new where idkart = _list_id_new; 
    -- установка позиции в дереве
	perform pdb2_val_include( _name_mod, _name_tree, '{selected,0}', _idkart );
    -- смена позиции у родителя
	if _after is not null then
		_children = replace( _children::text, concat( '"', _after, '"'), 
				concat( '"', _after, '","', _idkart, '"' ) )::jsonb;		
	end if;
    -- проверка записи
	select count(*) from t30436_children as a where a.idkart = _parent into _cn;
    
	if _cn > 0 then
    -- изменить позцию позиции
		update t30436_children set children = pdb_sys_jsonb_to_int_array( _children ) where idkart = _parent;
	else
    -- установить позицию
		insert into t30436_children( idkart, children ) values ( _parent, pdb_sys_jsonb_to_int_array( _children ) );
	end if;
    -- получить новую ветку		
	_placeholder = p30436_tree_view( null, null, _idkart, _name_table, _name_table_children );	
    -- установить информацию по бланкам
	perform pdb2_tpl_tree_set( _name_mod, _name_tree, _name_table );
    -- подготвить данные для сокета - обновить родителя	
	perform pdb2_val_page( '{pdb,socket_data,ids}', _parent );	
    -- новая ветка
	perform pdb2_return( _placeholder );
	
end;
$$;

alter function elbaza.p30436_tree_duplicate(text, text, text, text) owner to site;

