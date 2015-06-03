set search_path=farm_budget_data,public;

drop table if exists usda_raw cascade;
create table usda_raw (
year text,
commodity_desc text,
statisticcat_desc text,
county_code text,
source_desc text,
unit_desc text,
prodn_practice_desc text,
freq_desc text,
asd_desc text,
domain_desc text,
util_practice_desc text,
Value text,
reference_period_desc text,
class_desc text,
asd_code text,
agg_level_desc text,
state_ansi text,
domaincat_desc text,
state_fips_code text,
group_desc text);

\COPY usda_raw from price.csv with csv
\COPY usda_raw from yield.csv with csv
\COPY usda_raw from area.csv with csv
\COPY usda_raw from production.csv with csv

create or replace view commodity_price as 
select 
 state_fips_code as location,year,
 commodity_desc||
 CASE WHEN (class_desc='ALL CLASSES') THEN '' 
 ELSE ', '||class_desc END ||
 CASE WHEN (util_practice_desc='ALL UTILIZATION PRACTICES') THEN '' 
 ELSE ', '||util_practice_desc END as commodity,
 to_number(value,'99999D99')::decimal(10,2) as price,
 unit_desc as unit 
from usda_raw 
where statisticcat_desc='PRICE RECEIVED' and 
domain_desc='TOTAL' and 
prodn_practice_desc='ALL PRODUCTION PRACTICES' and 
freq_desc='ANNUAL' and 
agg_level_desc='STATE' 
and not value ~ '([D|NA|S])'
order by 1,2;

create or replace view commodity_avg_price as 
select 
 location,commodity,avg(price)::decimal(10,2) as price,
 unit
from commodity_price
group by location,commodity,unit
order by 1,2;

