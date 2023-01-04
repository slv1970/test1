create or replace function elbaza.t27471_iud_bef() returns trigger
    language plpgsql
as
$$
declare
	_idkart_letter int;
	_idkart_letter_old int;
	_idkart_alpha int; 
	_starts_with_new text = upper(left(NEW.name, 1)); 
	_starts_with_old text = upper(left(OLD.name, 1)); 
	_klient_idkart int; 
	_children int[];
	_cn int; 
	
begin
	raise 'DSFDS';
	if (NEW.type in ('item_klient', 'item_dokument'))
		and (OLD.name is null or _starts_with_new <> _starts_with_old) then 
		
		if NEW.type = 'item_dokument' then
		-- найти клиента в дереве
			if TG_OP = 'INSERT' then 
				_klient_idkart = NEW.parent;
			else
				with recursive temp1 ( idkart, parent, type) as 
				(
					select idkart, parent, type, name
					from t27471 as a
					where a.idkart = NEW.idkart
					union all
					select a.idkart, a.parent, a.type, a.name
					from t27471 as a
					inner join temp1 as t on t.parent = a.idkart
				)
				select t.idkart into _klient_idkart
				from temp1 as t
				where t.type = 'item_dokument' or t.type = 'item_dokument';
			end if;
			-- найти элемент "по Алфавиту" для контактного лица
			select idkart from t27471 where parent = 
			(select idkart from t27471 where parent = _klient_idkart)
			into _idkart_alpha;
		else
			-- найти элемент "по Алфавиту" для клиента
			select idkart from t27471 where parent = 0 into _idkart_alpha;
		end if;
		
		-- найти новую букву имени в дереве
		select idkart from t27471 where parent = _idkart_alpha and name = _starts_with_new into _idkart_letter; 
		-- найти старую букву имени в дереве
		select idkart from t27471 where parent = _idkart_alpha and name = _starts_with_old into _idkart_letter_old; 
		
		-- если буквы нет в дереве, добавить
		if _idkart_letter is null then
			insert into t27471(parent, name, type, "on") values (_idkart_alpha, _starts_with_new, 'folder_filter', 1) 
			returning idkart into _idkart_letter; 
		end if;
		
		-- если у прежней папки нет других вложенных элементов, удалить
		if (select count(*) from t27471 where parent = _idkart_letter_old) = 1 then 
			delete from t27471 where idkart = _idkart_letter_old; 
		end if; 
		
		-- упорядочивание алфавита
		select array_agg(a.idkart)  into _children
		from 
			(select idkart from t27471
			where dttmcl is null 
			and parent = _idkart_alpha
			order by name) as a; 
		
		select count(*) from t27471_children as a where a.idkart = _idkart_alpha into _cn; 

		if _cn > 0 then 
			update t27471_children set children = _children where idkart = _idkart_alpha; 
		else
			insert into t27471_children( idkart, children ) values ( _idkart_alpha, _children );
		end if;

		-- назначить нового родителя
		NEW.parent = _idkart_letter; 
	end if;
		
	return NEW;
	
end;
$$;

alter function elbaza.t27471_iud_bef() owner to site;

