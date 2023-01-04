create or replace function elbaza.t27470_iud() returns trigger
    language plpgsql
as
$$
declare
	_iddata integer;
	_rc record;

begin
 
	if ( TG_OP='INSERT' or TG_OP='UPDATE' ) then
-- проверка на закрытие записи
		if NEW.dttmcl is not null then
			if (select count(*) from t27470 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
				raise 'Закрыть нельзя - есть вложенные объекты!';
			end if;
		end if;		
-- обновить текущую запись и вложенные записи
		for _rc in 
			with recursive temp1 ( idkart, "type" ) as 
			(
				select NEW.idkart, NEW.type
				union all
				select a.idkart, a.type from t27470 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop

			if _rc.type = 'item_sayt' then
				update t27470_data_sayt set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27470_data_sayt( idkart ) values( _rc.idkart );
				end if;
			
			elseif _rc.type = 'item_seo' then
				update t27470_data_seo set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_seo (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_fayl' then
				update t27470_data_fayl set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_fayl (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_otzyv' then
				update t27470_data_otzyv set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_otzyv (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_novost' then
				update t27470_data_novost set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_novost(idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_usluga' then
				update t27470_data_usluga set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_usluga (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_aktsiya' then
				update t27470_data_aktsiya set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_aktsiya(idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_dokument' then
				update t27470_data_dokument set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_dokument (idkart) values (_rc.idkart);
				end if;
			elseif _rc.type = 'item_vakansia' then
				update t27470_data_vakansia set idkart = idkart where idkart = _rc.idkart
				returning idkart into _iddata;
				
				if _iddata is null then
					insert into t27470_data_vakansia (idkart) values (_rc.idkart);
				end if;
			
			end if;
		end loop;
		
		return NEW;
	end if;
-- проверка на удаление записи
	if (select count(*) from t27470 as a where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
-- удаление связей
	delete from t27470_children where idkart = OLD.idkart;
	delete from t27470_data_sayt where idkart = OLD.idkart;
	delete from t27470_data_seo where idkart = OLD.idkart;
	delete from t27470_data_fayl where idkart = OLD.idkart;
	delete from t27470_data_otzyv where idkart = OLD.idkart;
	delete from t27470_data_novost where idkart = OLD.idkart;
	delete from t27470_data_usluga where idkart = OLD.idkart;
	delete from t27470_data_aktsiya where idkart = OLD.idkart;
	delete from t27470_data_dokument where idkart = OLD.idkart;
	delete from t27470_data_vakansia where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t27470_iud() owner to site;

