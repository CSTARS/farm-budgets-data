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
reported boolean,
irrigated_acres float,
total_acres float,
total_production float,
unit text
)
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

drop foreign table commodity_county_yield;
create foreign table commodity_county_yield (
commodity text,
unit text,
fips varchar(12),
adc varchar(12),
state varchar(12),
yield float,
county_yield float,
ad_yield float,
st_yield float,
st_irrigated float,
st_partial float,
st_none float
)
SERVER nass_summary_server 
OPTIONS (format 'csv', header 'true', 
filename :'csv',
delimiter ',', null '');

\set csv :cwd :nassdir /commodity_harvest.csv
alter foreign table commodity_harvest OPTIONS (set filename :'csv');



drop foreign table commodity_price;
create foreign table commodity_price (
commodity text,
location varchar(12),
year integer,
unit text,
price float )
SERVER nass_summary_server 
OPTIONS (format 'csv', header 'true', 
filename :'csv',
delimiter ',', null '');

\set csv :cwd :nassdir /commodity_price.csv
alter foreign table commodity_price OPTIONS (set filename :'csv');

drop foreign table commodity_list;
create foreign table commodity_list (
commodity text,
harvest boolean,
yield boolean,
price boolean )
SERVER nass_summary_server 
OPTIONS (format 'csv', header 'true', 
filename :'csv',
delimiter ',', null '');

\set csv :cwd :nassdir /commodity_list.csv
alter foreign table commodity_list OPTIONS (set filename :'csv');

