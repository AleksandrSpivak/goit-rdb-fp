/* 1. Завантажте дані:
Створіть схему pandemic у базі даних за допомогою SQL-команди.
Оберіть її як схему за замовчуванням за допомогою SQL-команди.
Імпортуйте дані за допомогою Import wizard так, як ви вже робили це у темі 3.
infectious_cases.csv
Продивіться дані, щоб бути у контексті.
*/

create schema if not exists pandemic;

use pandemic;

select count(*) from infectious_cases;
-- при імпорті оригінального файлу втрачається близько 30% даних. 
-- Це не зв'язано з розміром буфера, скоріше з форматуванням даних в самому csv файлі. 
-- При розбитті файлу на дві частини по 5000 строк (приблизно) втрачається та сама кількість даних
-- Якщо в csv файлі спочатку додати Null в порожні комірки, то імпортується 10521 строк - повні дані

-- Огляд даних
select * from infectious_cases;


/* 2. Нормалізуйте таблицю infectious_cases до 3ї нормальної форми. 
Збережіть у цій же схемі дві таблиці з нормалізованими даними.
*/

-- створюємо таблицю з країнами та їх кодами
create table if not exists countries (
    id INT auto_increment primary key,
    Country_name VARCHAR(255),
    Country_code VARCHAR(10),
    unique (Country_name, Country_code)
);

-- створюємо таблицю для решти інформації
create table if not exists infectious_cases_normalized (
    Id INT auto_increment primary key,
    Year INT,
    Number_yaws INT,
    polio_cases INT,
    cases_guinea_worm INT,
    Number_rabies INT,
    Number_malaria INT,
    Number_hiv INT,
    Number_tuberculosis INT,
    Number_smallpox INT,
    Number_cholera_cases INT,
    country_id INT,
    foreign key (country_id) references countries(id)
);

-- заповнюємо таблицю з країнами та кодами країн
insert into countries (Country_name, Country_code)
select distinct Entity, Code
from infectious_cases;

-- Перевірка
select * from countries;
select count(*) from countries;

-- заповнюємо таблицю з рештою інформації
insert into infectious_cases_normalized (Year, Number_yaws, polio_cases, cases_guinea_worm, Number_rabies, Number_malaria, Number_hiv, Number_tuberculosis, Number_smallpox, Number_cholera_cases, country_id)
SELECT ic.Year, ic.Number_yaws, ic.polio_cases, ic.cases_guinea_worm, ic.Number_rabies, ic.Number_malaria, ic.Number_hiv, ic.Number_tuberculosis, ic.Number_smallpox, ic.Number_cholera_cases, c.id
FROM infectious_cases ic
JOIN countries c ON ic.Entity = c.Country_name AND ((ic.Code IS NULL AND c.Country_code IS NULL) OR ic.Code = c.Country_code);

-- перевірка
select * from infectious_cases_normalized;
select count(*) from infectious_cases_normalized;


/* 3. Проаналізуйте дані:
Для кожної унікальної комбінації Entity та Code або їх id порахуйте середнє, мінімальне, максимальне значення та суму 
для атрибута Number_rabies.
Врахуйте, що атрибут Number_rabies може містити порожні значення ‘’ — вам попередньо необхідно їх відфільтрувати.
Результат відсортуйте за порахованим середнім значенням у порядку спадання.
Оберіть тільки 10 рядків для виведення на екран. */

select country_id, avg(Number_rabies), min(Number_rabies), max(Number_rabies), sum(Number_rabies) from infectious_cases_normalized
where Number_rabies is not Null
group by country_id
order by avg(Number_rabies) desc
limit 10;


/* 4. Побудуйте колонку різниці в роках.
Для оригінальної або нормованої таблиці для колонки Year побудуйте з використанням вбудованих SQL-функцій:
атрибут, що створює дату першого січня відповідного року,
Наприклад, якщо атрибут містить значення ’1996’, то значення нового атрибута має бути ‘1996-01-01’.
атрибут, що дорівнює поточній даті,
атрибут, що дорівнює різниці в роках двох вищезгаданих колонок.
Перераховувати всі інші атрибути, такі як Number_malaria, не потрібно.
*/

select 
Year, 
cast(concat(Year, '-01-01') as date) as First_January,
curdate() as Current_data,
timestampdiff(YEAR, cast(concat(Year, '-01-01') as date), CURDATE()) as Year_Difference
from infectious_cases;


/* 5. Побудуйте власну функцію. Створіть і використайте функцію, що будує такий же атрибут, як і в попередньому завданні: 
функція має приймати на вхід значення року, а повертати різницю в роках між поточною датою та датою, 
створеною з атрибута року (1996 рік → ‘1996-01-01’).
*/

drop function if exists N_of_years;

delimiter //
create function N_of_years (y YEAR)
returns INT
reads sql data
deterministic

begin
	declare result INT;
    set result = timestampdiff(YEAR, cast(concat(y, '-01-01') as date), curdate());
    return result;
end//

delimiter ;

select year, N_of_years(year) from infectious_cases;

