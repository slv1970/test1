create or replace function elbaza.p27468_filter_data(_client_id integer, _filter_data jsonb) returns boolean
    language plpgsql
as
$$
declare
	_kd text;
	
	_ddt_client_json jsonb	= _filter_data -> 'ddt_client_json';
	_ddt_adr_json jsonb		= _filter_data -> 'ddt_adr_json';
	
-- поля в таблице
	_type text;
	_opf text;
	_state text;
	_okved text;
	_okveds text[];
	_employee integer;
	_tax text;
	_founders text[];
	_managers text[];
	_capital numeric;
	_income numeric;
	_expense numeric;
	_debt numeric;
	_penalty numeric;
	_smb text;
	_id21324 integer;
	_adr text[];
	_id202_find integer;
	_id24001_brush integer;
	_client_id_find int;
    
begin
	
	_type = _ddt_client_json #>> '{type}';
	if _type is not null then 
		select a.kd into _kd from t_klient_type as a
		where a.kd = _type;
		if _kd is null then
			insert into t_klient_type( kd, nm )
			values( _type, 
					case
				   		when _type = 'LEGAL' 		then 'юридическое лицо'
						when _type = 'INDIVIDUAL'	then 'индивидуальный предприниматель'
				   end );
		end if;
	end if;
    
	_opf = _ddt_client_json #>> '{opf,code}';
	if _opf is not null then
		select a.kd into _kd from t_klient_okpf as a
		where a.kd = _opf;
		if _kd is null then
			insert into t_klient_okpf( kd, nm )
			values( _opf, _ddt_client_json #>> '{opf,full}' );
		end if;
	end if;
    
	_state = _ddt_client_json #>> '{state,status}';
	if _state is not null then
		select a.kd into _kd from t_klient_state as a
		where a.kd = _state;
		if _kd is null then
			insert into t_klient_state( kd, nm )
			values( _state, 
						case
						when _state = 'ACTIVE' 			then 'действующая'
						when _state = 'LIQUIDATING'		then 'ликвидируется'
						when _state = 'LIQUIDATED'		then 'ликвидирована'
						when _state = 'REORGANIZING'	then 'в процессе присоединения к другому юрлицу, с последующей ликвидацией'
						end
				  );
		end if;
	end if;
    
	if jsonb_typeof( _ddt_client_json #> '{okveds}' ) = 'array' then 
		insert into t_klient_okveds( kd, nm ) 
        select a.kd, a.nm
		from (
			select a.value ->> 'code' as kd, a.value ->> 'name' as nm
			from jsonb_array_elements( _ddt_client_json #> '{okveds}' ) as a
		) as a 
		left join t_klient_okveds as b on a.kd = b.kd
		where b.kd is null;
	end if;
	
	if jsonb_typeof( _ddt_client_json #> '{okveds}' ) = 'array' then 
		select array_agg(a.value ->> 'code') into _okveds
		from jsonb_array_elements( _ddt_client_json #> '{okveds}' ) as a;
	end if;	
    
	_okved = _ddt_client_json #>> '{okved}';
	_employee = _ddt_client_json #>> '{employee_count}';
	_tax = COALESCE( (_ddt_client_json #>> '{finance,tax_system}'), 'OSN' );
    
	if _tax is not null then 
		select a.kd into _kd from t_klient_tax as a where a.kd = _tax;		
		if _kd is null then
			insert into t_klient_tax( kd, nm )
			values( _tax, 
					case
						when _tax = 'ENVD' then 'единый налог на вмененный доход'
						when _tax = 'ESHN' then 'единый сельскохозяйственный налог'
						when _tax = 'SRP'  then 'система налогообложения при выполнении соглашений о разделе продукции'
						when _tax = 'USN'  then 'упрощенная система налогообложения'
						when _tax = 'OSN'  then 'не указана (общая система налогообложения)'			   		
					end
				  );
		end if;
	end if;
    
	if jsonb_typeof( _ddt_client_json #> '{founders}' ) = 'array' then 
		select array_agg( concat( a.value #>> '{fio,source}', a.value ->> 'inn' ) ) into _founders
		from jsonb_array_elements( _ddt_client_json #> '{founders}' ) as a;
	end if;
    
	if jsonb_typeof( _ddt_client_json #> '{managers}' ) = 'array' then 
		select array_agg( concat( a.value #>> '{fio,source}', a.value ->> 'inn' ) ) into _managers
		from jsonb_array_elements( _ddt_client_json #> '{managers}' ) as a;
	end if;
    
	_capital = _ddt_client_json #>> '{capital,value}';
	_income = _ddt_client_json #>> '{finance,income}';
	_expense = _ddt_client_json #>> '{finance,expense}';
	_debt = _ddt_client_json #>> '{finance,debt}';
	_penalty = _ddt_client_json #>> '{finance,penalty}';
	_smb = _ddt_client_json #>> '{documents,smb,category}';
    
	if _smb is not null then 
		select a.kd into _kd from t_klient_smb as a
		where a.kd = _smb;
		if _kd is null then
			insert into t_klient_smb( kd, nm )
			values( _smb, _ddt_client_json #>> '{documents,smb,type}' );
		end if;
	end if;
	
    -- адреса
	_adr = array[ 
				_ddt_adr_json #>> '{data,region_fias_id}',		-- регион
				_ddt_adr_json #>> '{data,area_fias_id}',		-- район в регоне
				_ddt_adr_json #>> '{data,city_fias_id}',		-- город
				_ddt_adr_json #>> '{data,city_district_fias_id}',-- район города
				_ddt_adr_json #>> '{data,settlement_fias_id}',	-- населенный пункт
				_ddt_adr_json #>> '{data,street_fias_id}'		-- улица
				];
				
	_okveds = array_remove( _okveds, null ); 
	_founders = array_remove( _founders, null ); 
	_managers = array_remove( _managers, null ); 
	_adr = array_remove( _adr, null ); 
    
	update t27468_data_klient_filter set
		vr_type = _type,
		vr_opf = _opf,
		vr_state = _state,
		vr_okveds = _okveds,
		vr_tax = _tax,
		vr_founders = _founders,
		vr_managers = _managers,
		vr_capital = _capital,
		vr_income = _income,
		vr_expense = _expense,
		vr_debt = _debt,
		vr_penalty = _penalty,
		vr_smb = _smb,
		vr_adr = _adr,
		vr_okved = _okved,
		vr_check = (_filter_data ->> 'vr_check')::integer
	where client_id = _client_id
	returning client_id into _client_id_find;
	
	if _client_id_find is null then 
		insert into t27468_data_klient_filter(
				client_id, vr_type, vr_opf, vr_state, vr_okveds, vr_employee, vr_tax, vr_founders, vr_managers, vr_capital,
				vr_income, vr_expense, vr_debt, vr_penalty, vr_smb,  vr_adr, vr_okved, vr_check )
		values (
				_client_id, _type, _opf, _state, _okveds, _employee, _tax, _founders, _managers, _capital,
				_income, _expense, _debt, _penalty, _smb,  _adr, _okved,  (_filter_data ->> 'vr_check')::integer );
	end if;
	
	return true;
	
end;
$$;

alter function elbaza.p27468_filter_data(integer, jsonb) owner to site;

