create or replace function elbaza.t27469_iud() returns trigger
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
			if (select count(*) from t27469 as a 
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
				select a.idkart, a.type 
				from t27469 as a
				inner join temp1 as t on t.idkart = a.parent
				where a.dttmcl is null 
			)
			select t.idkart, t.type
			from temp1 as t
		loop
		
			-- Мероприятие
			if _rc.type = 'item_meropriyatiye' then
			
				update t27469_data_meropriyatiye set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_meropriyatiye( idkart ) values( _rc.idkart );
				end if;
				
			-- Расписание
			elsif _rc.type = 'item_raspisaniye' then
			
				update t27469_data_raspisaniye set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_raspisaniye( idkart ) values( _rc.idkart );
				end if;
				
			-- Лектор
			elsif _rc.type = 'item_lektor' then
			
				update t27469_data_lektor set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_lektor( idkart ) values( _rc.idkart );
				end if;
				
			-- Раздаточный материал
			elsif _rc.type = 'item_razdatochnyy_material' then
			
				update t27469_data_razdatochnyy_material set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_razdatochnyy_material( idkart ) values( _rc.idkart );
				end if;
				
			-- Видео-материал
			elsif _rc.type = 'item_video_material' then
			
				update t27469_data_video_material set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_video_material( idkart ) values( _rc.idkart );
				end if;
				
			-- Переменная
			elsif _rc.type = 'item_peremennaya' then
			
				update t27469_data_peremennaya set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_peremennaya( idkart ) values( _rc.idkart );
				end if;
			
			-- Программа 1
			elsif _rc.type = 'item_programma_1' then
			
				update t27469_data_programma_1 set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_1( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 2 html
			elsif _rc.type = 'item_programma_2html' then
			
				update t27469_data_programma_2html set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_2html( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 2 text
			elsif _rc.type = 'item_programma_2text' then
			
				update t27469_data_programma_2text set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_2text( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 3 html
			elsif _rc.type = 'item_programma_3html' then
			
				update t27469_data_programma_3html set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_3html( idkart ) values( _rc.idkart );
				end if;
				
			-- Программа 3 table
			elsif _rc.type = 'item_programma_3table' then
			
				update t27469_data_programma_3table set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_3table( idkart ) values( _rc.idkart );
				end if;
			
			-- Документ
			elsif _rc.type = 'item_dokument' then
			
				update t27469_data_dokument set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_dokument( idkart ) values( _rc.idkart );
				end if;
				
			-- Список
			elsif _rc.type = 'item_spisok' then
			
				update t27469_data_spisok set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_spisok( idkart ) values( _rc.idkart );
				end if;
			
			-- Программа 3 table_row
			elsif _rc.type = 'item_programma_3table_row' then
			
				update t27469_data_programma_3table_row set idkart = idkart 
				where idkart = _rc.idkart
				returning idkart into _iddata;

				if _iddata is null then
					insert into t27469_data_programma_3table_row( idkart ) values( _rc.idkart );
				end if;
			
			end if;

		end loop;
		
		return NEW;
	end if;
	
	-- проверка на удаление записи
	if (select count(*) from t27469 as a 
		where a.dttmcl is null and a.parent = OLD.idkart ) != 0 then
		raise 'Удалить нельзя - есть вложенные объекты!';
	end if;
	
	-- удаление связей
	delete from t27469_children where idkart = OLD.idkart;
	
	delete from t27469_data_meropriyatiye where idkart = OLD.idkart;
	delete from t27469_data_raspisaniye where idkart = OLD.idkart;
	delete from t27469_data_lektor where idkart = OLD.idkart;
	delete from t27469_data_razdatochnyy_material where idkart = OLD.idkart;
	delete from t27469_data_video_material where idkart = OLD.idkart;
	delete from t27469_data_peremennaya where idkart = OLD.idkart;
	delete from t27469_data_dokument where idkart = OLD.idkart;
	
	delete from t27469_data_programma_1 where idkart = OLD.idkart;
	delete from t27469_data_programma_2html where idkart = OLD.idkart;
	delete from t27469_data_programma_2text where idkart = OLD.idkart;
	delete from t27469_data_programma_3html where idkart = OLD.idkart;
	delete from t27469_data_programma_3table where idkart = OLD.idkart;
	
	delete from t27469_data_programma_3html_row where idkart = OLD.idkart;
	
	return OLD;
end;
$$;

alter function elbaza.t27469_iud() owner to site;

