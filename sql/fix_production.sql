set search_path=farm_budget_data,public;

create function fix_production() RETURNS integer AS $$
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
select 1;

$$ LANGUAGE SQL;
