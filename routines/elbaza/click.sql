create or replace function elbaza.click(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 

--	объявляем переменные
	_idkart integer		= pdb_val_api_text(_value, '{get,short}');
	_post jsonb			= pdb_val_api(_value, null);
	_utm text;

begin

--	получаем данные из GET
	select property_data ->> 'utm_result'
	into _utm
	from t19391
	where idkart = _idkart;
	
	if _idkart is not null and _utm is not null then
		insert into link_transitions (utm_idkart, headers_data)
		values (_idkart, _post);
	else
		return pdb_return( _value, 301, 'https://grant.respectrb.ru');
	end if;
		
-- end показать info
	return pdb_return( _value, 302, _utm);

end;
$$;

alter function elbaza.click(jsonb, text) owner to site;

