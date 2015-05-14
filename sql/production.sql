set search_path=farm_budget_data,public;

CREATE TYPE phase_t AS ENUM ('planting', 'annual', 'harvest');

drop table if exists production;
create table production (
production_id serial primary key,
authority varchar(25),
commodity varchar(25), -- foreign key references commodity,
location varchar(12),
phase phase_t,
material text,
unit text,
amount float);

drop table if exists price;
create table price (
price_id serial primary key,
material text,
units varchar(12),
location varchar(12),
year integer,
authority text,
price float);

create or replace function fix_production() RETURNS boolean AS $$

with x(old,nass) as (VALUES
('ALFALFA','HAY'),
('BEAS, DRY EDIBLE','BEANS'),
('CORN GRAINS','CORN'),
('CORN SILAGE','CORN'),
('DRY BEANS','BEANS'),
('FESCUE SEED','GRASSES'),
('GRASS AND HAY','HAY & HAYLAGE'),
('GRASSHAY','HAY & HAYLAGE'),
('LENTIL','LENTILS'),
('ORCHARD GRASS','GRASSES'),
('ORCHARD GRASS SEED','GRASSES'),
('RYEGRASS SEED','GRASSES'),
('SPRING WHEAT','WHEAT'),
('SUDANGRASS','GRASSES'),
('SUGAR BEET','SUGARBEETS'),
('SUGAR BEETS','SUGARBEETS'),
('WINTER WHEAT','WHEAT')
)

update farm_budget_data.production set commodity=x.nass from x where commodity=old;
update farm_budget_data.production set phase='annual' where phase is null;

select true;

$$ LANGUAGE SQL;

