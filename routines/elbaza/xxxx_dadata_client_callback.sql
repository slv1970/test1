create or replace function elbaza.xxxx_dadata_client_callback(_value jsonb, _name_mod text) returns jsonb
    language plpgsql
as
$$
declare 
	_post jsonb		= pdb2_val_api( '{post}' );

	_cl_js jsonb;
	_idkart integer;
	_inn text;
	_kpp text;
	_ogrn text;
	_ddt_client_hid text; 
	_suggestions jsonb; 

	_config jsonb;
	_query jsonb;
	_cn integer;
	
begin
    if _post #>> '{response,status}' = 'false' then
        return _value;
    else
        _idkart = _post ->>'idkart';
        _suggestions = _post #>'{response,data,suggestions}';

        select trim(a.inn), trim(a.kpp), trim(a.ogrn)
        into 	_inn, _kpp, _ogrn
        from t27468_data_klient as a where a.idkart = _idkart;

-- поиск карточки		
-- ищем у кого есть КПП
        select a.value #> '{data}' into _cl_js
        from jsonb_array_elements( _suggestions ) as a
        where a.value #>> '{data,inn}' = _inn
                and a.value #>> '{data,kpp}' = _kpp
                and (a.value #>> '{data,kpp}') is not null;
-- ищем у кого есть ОГРН
        if _cl_js is null then
            select a.value #> '{data}' into _cl_js
            from jsonb_array_elements( _suggestions ) as a
            where a.value #>> '{data,inn}' = _inn
                    and a.value #>> '{data,ogrn}' = _ogrn
                    and (a.value #>> '{data,ogrn}') is not null
                    and (a.value #>> '{data,kpp}') is null;
        end if;

        if _cl_js is null then
-- у ИП ищем актинвную карточку				
            select a.value #> '{data}' into _cl_js
            from jsonb_array_elements( _suggestions ) as a
            where a.value #>> '{data,inn}' = _inn
                    and (a.value #>> '{data,type}') = 'INDIVIDUAL'
                    and (a.value #>> '{data,state,status}') = 'ACTIVE';						
        end if;

--         _ddt_client_hid = _cl_js #>> '{hid}'; -- подтвержден

--         if _ddt_client_hid is null then   
--             if jsonb_array_length(_suggestions) = 1 then -- если одна запись - то возможно - подтвержден
--                 _cl_js := _suggestions #> '{0,data}';
--             end if;
--         end if;

        update t27468_data_klient set 
            ddt_client_date = now(), ddt_client_json = _cl_js
        where idkart = _idkart;

    end if;

	return _value;
end;
$$;

alter function elbaza.xxxx_dadata_client_callback(jsonb, text) owner to developer;

