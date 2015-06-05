drop schema farm_budget_data cascade;
create schema farm_budget_data;
set search_path=farm_budget_data,public;

CREATE TYPE phase_t AS ENUM ('planting', 'annual', 'harvest');

create table unit (
unit varchar(12) primary key,
description text 
);

\COPY unit from units.csv with csv header

create table material (
material text,
unit varchar(12) references unit,
class text,
description text,
primary key(material,unit)
);

\COPY material from materials.csv with csv header

create table operation (
phase phase_t,
operation text,
unit varchar(12) references unit,
description text,
primary key(operation,unit)
);

\COPY operation from operations.csv with csv header


create table production (
production_id serial primary key,
authority varchar(25),
commodity varchar(25), -- foreign key references commodity,
location varchar(12),
phase phase_t,
material text,
unit varchar(12) references unit,
amount float);

create table price (
price_id serial primary key,
material text,
unit varchar(12) references unit,
location varchar(12),
year integer,
authority text,
price float);


create function replace_unit(old varchar(12),new varchar(12)) 
RETURNS varchar(12)
AS $$
update farm_budget_data.production set unit=$2 where unit=$1;
update farm_budget_data.operation set unit=$2 where unit=$1;
update farm_budget_data.material set unit=$2 where unit=$1;
update farm_budget_data.price set unit=$2 where unit=$1;
delete from unit where unit=$1;
select $2;
$$ LANGUAGE SQL;



