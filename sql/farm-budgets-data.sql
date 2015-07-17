drop schema farm_budget_data cascade;
create schema farm_budget_data;
set search_path=farm_budget_data,public;

CREATE TYPE phase_t AS ENUM ('planting', 'annual', 'harvest');

-- The units of measure should be as listed here: http://unitsofmeasure.org/ucum.html
-- If they are not, then a description needs to be provided.
-- See if we can poach this. https://github.com/jmandel/ucum.js

create table unit (
unit varchar(64) primary key,
description text 
);

\COPY unit(unit,description) from units.csv with csv header

create table material (
material text,
unit varchar(64) references unit,
class text,
description text,
primary key(material,unit)
);

\COPY material from materials.csv with csv header

create table operation (
phase phase_t,
operation text,
unit varchar(64) references unit,
description text,
primary key(operation,unit)
);

\COPY operation from operations.csv with csv header

create table production (
production_id serial primary key,
filename text,
authority varchar(25),
commodity varchar(25), -- foreign key references commodity,
location varchar(12),
phase phase_t,
material text,
unit varchar(64) references unit,
amount float);

create table price (
price_id serial primary key,
filename text,
material text,
unit varchar(64) references unit,
location varchar(12),
year integer,
authority text,
price float);

create table change (
type text,
old text,
new text
);

create or replace function replace_unit(old varchar(64),new varchar(64)) 
RETURNS varchar(64)
AS $$
insert into farm_budget_data.change (type,old,new) values ('unit',$1,$2);
update farm_budget_data.production set unit=$2 where unit=$1;
update farm_budget_data.operation set unit=$2 where unit=$1;
update farm_budget_data.material set unit=$2 where unit=$1;
update farm_budget_data.price set unit=$2 where unit=$1;
delete from unit where unit=$1;
select $2;
$$ LANGUAGE SQL;

create or replace function add_replace_unit(old varchar(64),new varchar(64))
RETURNS varchar(64)
AS $$
insert into farm_budget_data.unit (unit) values ($2);
select replace_unit($1,$2);
$$ LANGUAGE SQL;


create or replace function replace_material(old varchar(64),new varchar(64)) 
RETURNS varchar(64)
AS $$
insert into farm_budget_data.change (type,old,new) values ('material',$1,$2);
update farm_budget_data.production set unit=$2 where unit=$1;
update farm_budget_data.operation set unit=$2 where unit=$1;
update farm_budget_data.material set unit=$2 where unit=$1;
update farm_budget_data.price set unit=$2 where unit=$1;
delete from unit where unit=$1;
select $2;
$$ LANGUAGE SQL;

