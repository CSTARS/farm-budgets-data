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
item text,
unit varchar(12),
location varchar(12),
year integer,
authority text,
price float);


create or replace function fix_production() RETURNS boolean AS $$
create temp table commodity_xwalk (
 old varchar(25),
 nass varchar(25));

insert into commodity_xwalk (old,nass) VALUES
('ALFALFA','HAY'),
('BEAS, DRY EDIBLE','BEANS'),
('CORN GRAINS','CORN'),
('CORN SILAGE','CORN'),
('DRY BEANS','BEANS'),
('FESCUE SEED','HAYLAGE'),
('GRASS AND HAY','HAY & HAYLAGE'),
('GRASSHAY','HAY & HAYLAGE'),
('LENTIL','LENTILS'),
('ORCHARD GRASS','HAY & HAYLAGE'),
('ORCHARD GRASS SEED','HAY & HAYLAGE'),
('RYEGRASS SEED','HAY & HAYLAGE'),
('SPRING WHEAT','WHEAT'),
('SUDANGRASS','HAY & HAYLAGE'),
('SUGAR BEET','SUGARBEETS'),
('SUGAR BEETS','SUGARBEETS'),
('WINTER WHEAT','WHEAT');

update production set commodity=nass from commodity_xwalk c where commodity=old;

update production set phase='annual' where phase is null;

select true;

$$ LANGUAGE SQL;

