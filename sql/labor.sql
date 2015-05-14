create table farm_budget_data.unknown_labor (
county char(5),
area_fips text,
own_code text,
industry_code text,
agglvl_code text,
size_code text,
year integer,
qtr text,
disclosure_code text,
area_title text,
own_title text,
industry_title text,
agglvl_title text,
size_title text,
annual_avg_estabs_count text,
annual_avg_emplvl text,
total_annual_wages float,
taxable_annual_wages float,
annual_contributions float,
annual_avg_wkly_wage float,
avg_annual_pay float,
avg_hourly_pay float,
lq_disclosure_code text,
lq_annual_avg_estabs_count float,
lq_annual_avg_emplvl float,
lq_total_annual_wages float,
lq_taxable_annual_wages float,
lq_annual_contributions float,
lq_annual_avg_wkly_wage float,
lq_avg_annual_pay float);

\COPY unknown_labor from data/unknown/labor.csv with csv header

create table farm_budget_data.labor as 
select
'oes452091' as material,
fips as location,
'unk' as authority,
avg_hourly_pay as price,
'hr' as unit
from 
union
select
'oes452091' as material,
fips as location,
'unk' as authority,
avg_hourly_pay as price,
'hr' as unit

