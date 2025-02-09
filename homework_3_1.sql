--Таблица "заявка"
create table bid (
	id serial primary key, 
	product_type varchar(50),
	client_name varchar(100),
	is_company boolean,
	amount numeric(12,2)
);

insert into bid (product_type, client_name, is_company, amount) values
('credit', 'Petrov Petr Petrovich', false, 1000000),
('credit', 'Coca cola', true, 100000000),
('deposit', 'Soho bank', true, 12000000),
('deposit', 'Kaspi bank', true, 18000000),
('deposit', 'Miksumov Anar Raxogly', false, 500000),
('debit_card', 'Miksumov Anar Raxogly', false, 0),
('credit_card', 'Kipu Masa Masa', false, 5000),
('credit_card', 'Popova Yana Andreevna', false, 25000),
('credit_card', 'Miksumov Anar Raxogly', false, 30000),
('debit_card', 'Saronova Olga Olegovna', false, 0);

--Скрипт №1 - Распределение заявок по продуктовым таблицам
--Создать скрипт, который будет: 
--1. Создавать таблицы на основании таблицы bid:
--Имя таблицы должно быть основано на типе продукта + является ли он компанией
--Если такая таблица уже есть, скрипт не должен падать!
--Например:
--для записи где product_type = credit, is_company = false будет создана таблица:
--person_credit, с колонками: id (новый id), client_name, amount
--для записи где product_type = credit, is_company = true:
--company_credit, с колонками: id (новый id), client_name, amount


--2. Копировать заявки в соответствующие таблицы c помощью конструкции:
--2.1 Для вставки значений можно использовать конструкцию
--insert into (col1, col2)
--select col1, col2
--from [наименование таблицы]
--2.2 Для исполнения динамического запроса с параметрами можно использовать конструкцию
--execute '[текст запроса]' using [значение параметра №1], [значение параметра №2].
--Пример:
--execute 'select * from product where product_type = $1 and is_company = $2' using 'credit', false;


-- Решение с занятия

do $$
	declare
		bid_row record;
	begin
	 	for bid_row in (
		 	select distinct product_type, is_company,  
			 case when is_company then 'company_' else 'person_' end || product_type as "t_name"
			 from bid
			 ) 
			 loop		 
			 	--  raise notice 't_name : %', bid_row.t_name;
				execute 'create table ' || bid_row.t_name || ' (id serial primary key, client_name varchar(50), amount numeric (12, 2))'; 
				execute 'insert into '|| bid_row.t_name || '(client_name, amount)'
				|| 'select client_name, amount from bid where product_type = ''' || bid_row.product_type 
				|| ''' and is_company = ' || bid_row.is_company;
		end loop;	
	end;
$$;


select * from company_credit
--Скрипт №2 - Начисление процентов по кредитам за день
--Создать скрипт, который:
--1. Создаст(если нет) таблицу credit_percent для начисления процентов по кредитам: имя клиента, сумма начисленных процентов
--2. Имеет переменную - базовая кредитная ставка со значением "0.1" 
--3. Возьмет значения из таблиц person_credit и company_credit и вставит их в credit_percent:
-- необходимо выбрать client_name клиента и (сумму кредита * базовую ставку) / 365 для компаний
-- необходимо выбрать client_name клиента и (сумму кредита * (базовую ставку + 0.05) / 365 для физ лиц
--4. Печатает на экран общую сумму начисленных процентов в таблице

drop table company_credit, company_deposit, person_credit, person_credit_card, person_debit_card, person_deposit;


do $$
	declare 
	   base_rate numeric (12,2) := 0.1;
	   person_rate numeric (12,2) := base_rate + 0.05;
	   days_in_year int := 365;
		begin			
			create table if not exists credit_percent (client_name varchar(50), percent_sum numeric(12,2));
			insert into credit_percent (client_name, percent_sum)						
						select client_name, amount * person_rate/days_in_year
						from person_credit					
						union all
						select client_name, amount * base_rate/days_in_year 
						from company_credit;
			raise notice 'Общая сумма начисленных процентов по кредиту - %', (select sum (percent_sum) from credit_percent);
		end;
$$;

delete from credit_percent;
select * from credit_person;
--Скрипт №3 - Разделение ответственности. 
--Менеджеры компаний, должны видеть только заявки компаний.
--Создать view которая отображает только заявки компаний

create view company_bid as (
	select * 
	from bid 
	where is_company = true);

select * from company_bid;
