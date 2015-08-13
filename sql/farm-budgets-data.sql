drop schema farm_budget_data cascade;
create schema farm_budget_data;
set search_path=farm_budget_data,public;

CREATE TYPE csvtype_t AS ENUM (
  'materials','material_requirements','prices'
  'phases','phase_requirements'
  );
-- The units of measure should be as listed here: http://unitsofmeasure.org/ucum.html
-- If they are not, then a description needs to be provided.
-- See if we can poach this. https://github.com/jmandel/ucum.js
create table files (
  filename text primary key,
  type csvtype_t,
  location text,
  year integer,
  commodity text
);

create table units (
unit varchar(64) primary key,
description text
);

\COPY unit(unit,description) from units.csv with csv header

create table materials (
material text primary key,
class text,
description text
);

\COPY material from materials.csv with csv header

create table phase_requirements (
phase phase_t,
operation text,
unit varchar(64) references unit,
description text,
primary key(operation,unit)
);
-- many phase requirements

create table yield (
  filename text,
  commodity varchar(25),
  location varchar(12),
  unit varchar(64) references unit,
  value float
);
-- Many yields.

create table production (
production_id serial primary key,
filename text,
authority varchar(25),
commodity varchar(25), -- foreign key references commodity,
location varchar(12),
phase phase_t,
operation text,
material text references material,
unit varchar(64) references unit,
amount float
);

create table price (
price_id serial primary key,
filename text,
material text references material,
unit varchar(64) references unit,
location varchar(12),
year integer,
authority text,
price float);

create or replace function replace_unit(old varchar(64),new varchar(64))
RETURNS varchar(64)
AS $$
update farm_budget_data.production set unit=$2 where unit=$1;
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
update farm_budget_data.production set material=$2 where material=$1;
update farm_budget_data.price set material=$2 where material=$1;
delete from farm_budget_data.material where material=$1;
select $2;
$$ LANGUAGE SQL;

create or replace function add_replace_material(old varchar(64), new varchar(64))
RETURNS varchar(64)
AS $$
insert into farm_budget_data.material select $2,class,description from farm_budget_data.material where material=$1;
select replace_material($1,$2);
$$ LANGUAGE SQL;
