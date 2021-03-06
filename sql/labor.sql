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

delete from farm_budget_data.price 
where material in ('oes452091','oes452092','oes533032') 
and year=2009;

insert into price (material,units,location,year,authority,price)
select
'oes452091','hr',county,2009,'unk',avg_hourly_pay*1.3
from farm_budget_data.unknown_labor
union
select
'oes452092','hr',county,2009,'unk',avg_hourly_pay
from farm_budget_data.unknown_labor
union
select
'oes533032','hr',county,2009,'unk',avg_hourly_pay*1.3
from farm_budget_data.unknown_labor;

