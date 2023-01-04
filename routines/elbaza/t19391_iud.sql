create or replace function elbaza.t19391_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP = 'INSERT' or TG_OP = 'UPDATE' ) then
	
		-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t19391 as a 
				where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;
	
		-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t19391 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
			if _rc.type = 'item_sms_gateway' then
			
				update t19391_data_sms_gateway set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_sms_gateway( idkart ) values( _rc.idkart );
				end if;
		
		
			elsif _rc.type = 'item_sertifikat' then
			
				update t19391_data_sertifikat set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_sertifikat( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_usluga' then
			
				update t19391_data_usluga set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_usluga( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_kvalifikatsiya' then
			
				update t19391_data_kvalifikatsiya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_kvalifikatsiya( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_metki' then
			
				update t19391_data_utm_metki set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_metki( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_promokod' then
			
				update t19391_data_promokod set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_promokod( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_normativ' then
			
				update t19391_data_normativ set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_normativ( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_call_type' then
			
				update t19391_data_call_type set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_call_type( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_source' then
			
				update t19391_data_utm_source set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_source( idkart ) values( _rc.idkart );
				end if;

			elsif _rc.type = 'item_utm_medium' then
			
				update t19391_data_utm_medium set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_medium( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_campaign' then
			
				update t19391_data_utm_campaign set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_campaign( idkart ) values( _rc.idkart );
				end if;
				
			elsif _rc.type = 'item_utm_content' then
			
				update t19391_data_utm_content set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_content( idkart ) values( _rc.idkart );
				end if;

			elsif _rc.type = 'item_utm_term' then
			
				update t19391_data_utm_term set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_term( idkart ) values( _rc.idkart );
				end if;

			elsif _rc.type = 'item_utm_metki' then
			
				update t19391_data_utm_metki set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t19391_data_utm_metki( idkart ) values( _rc.idkart );
				end if;
				
			end if;

		end loop;
		
		return NEW;
	end if;
	
	-- проверка на удаление записи
	if (select count(*) from t19391 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
	
	-- удаление связей
	delete from t19391_children where idkart = OLD.idkart;
	delete from t19391_data_sertifikat where idkart = OLD.idkart;
	delete from t19391_data_usluga where idkart = OLD.idkart;
	delete from t19391_data_kvalifikatsiya where idkart = OLD.idkart;
	delete from t19391_data_utm_metki where idkart = OLD.idkart;
	delete from t19391_data_promokod where idkart = OLD.idkart;
	delete from t19391_data_normativ where idkart = OLD.idkart;
	delete from t19391_data_call_type where idkart = OLD.idkart;
	delete from t19391_data_utm_source where idkart = OLD.idkart;
	delete from t19391_data_utm_medium where idkart = OLD.idkart;
	delete from t19391_data_utm_campaign where idkart = OLD.idkart;
	delete from t19391_data_utm_content where idkart = OLD.idkart;
	delete from t19391_data_utm_term where idkart = OLD.idkart;
	delete from t19391_data_sms_gateway where idkart = OLD.idkart;

	return OLD;
end;
$$;

alter function elbaza.t19391_iud() owner to developer;

