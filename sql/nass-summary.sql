create extension file_fdw;
CREATE SERVER nass_summary_server FOREIGN DATA WRAPPER file_fdw;

set search_path=farm_budget_data,public;

\set csv :cwd :nassdir /county_adc.csv

drop foreign table county_adc;
create foreign table county_adc (
fips char(5),
adc char(6),
state text,
agdistrict text,
county text)
SERVER nass_summary_server 
OPTIONS (format 'csv', header 'true', 
filename :'csv',
delimiter ',', null '');

--alter foreign table county_adc OPTIONS (set filename :'csv_ca');


drop foreign table commodity_harvest;
create foreign table commodity_harvest (
commodity text,
location varchar(12),
year integer,
irrigated integer,
non_irr integer,
total integer)
SERVER nass_summary_server 
OPTIONS (format 'csv', header 'true', 
filename :'csv',
delimiter ',', null '');

\set csv :cwd :nassdir /commodity_harvest.csv
alter foreign table commodity_harvest OPTIONS (set filename :'csv');

drop foreign table commodity_yield;
create foreign table commodity_yield (
commodity text,
location varchar(12),
year integer,
unit text,
irrigated float,
non_irr float,
unspecified float)
SERVER nass_summary_server 
OPTIONS (format 'csv', header 'true', 
filename :'csv',
delimiter ',', null '');

\set csv :cwd :nassdir /commodity_yield.csv
alter foreign table commodity_yield OPTIONS (set filename :'csv');

-- \set csv :cwd :nassdir /cmz_commodity_total_harvest.csv

-- create foreign table cmz_commodity_total_harvest (
-- commodity text,
-- location varchar(12),
-- year integer,
-- irrigated integer,
-- non_irr integer,
-- total integer)
-- SERVER nass_summary_server 
-- OPTIONS (format 'csv', header 'true', 
-- filename :'csv',
-- delimiter ',', null '');

-- alter foreign table cmz_commodity_total_harvest OPTIONS (set filename :'csv');
