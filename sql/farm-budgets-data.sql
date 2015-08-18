drop schema "farm-budgets-data" cascade;
create schema "farm-budgets-data";
set search_path="farm-budgets-data",public;

create type import_return_t as (
  filename text,
  "table" text,
  count bigint
);


create table units (
  filename text,
  unit text,
  label text
);

\COPY units(unit,label) from units.csv with csv header
update units set filename='units.csv';

create table farms (
  filename text,
  farm text,
  location text,
  commodity text,
  size text,
  unit text
);

create table materials (
    filename text,
    material text,
    unit text,
    class text,
    description text
);

\COPY materials(material,class,description) from materials.csv with csv header
update materials set filename='materials.csv';

create table material_requirements (
  filename text,
  material text,
  requires text,
  amount float,
  unit text
);

  create table schedule (
    filename text,
    start date,
    duration interval,
    operation text,
    yield float,
    unit text
  );

  create table operations (
    filename text,
    operation text,
    material text,
    amount float,
    unit varchar(64),
    note text
  );

create table price_lists (
  filename text,
  prices text,
  location text,
  year integer
);

  create table prices (
    filename text,
    material text,
    price float,
    unit varchar(64)
  );


create or replace view budget_as_json as
with
pr as (
  select array_to_json(array_agg(
    row_to_json((select r from (select material,price,unit) as r))
    ),true) as prices
  from prices p
),
mr as (
  select material,array_to_json(array_agg(
    row_to_json((select r from (select requires as material,amount,unit) as r))
  ),true) as requires
  from material_requirements mr group by material
),
m as (
  select array_to_json(array_agg(
    row_to_json((select r from (select material,unit,class,description,requires) as r))
    ),true) as materials
  from materials left join mr using (material)
),
ml as (
  select filename,operation,array_to_json(array_agg(
    row_to_json((select r from (select material,amount,unit,note) as r))
  ),true) as materials
  from operations group by filename,operation
),
ops as (
  select filename,array_to_json(array_agg(
    row_to_json((select r from (select operation,materials) as r))
  ),true) as operations
  from ml group by filename
),
s as (
  select filename,array_to_json(array_agg(
    row_to_json((select r from (select start,duration,operation,yield,unit) as r))
  ),true) as schedule
  from schedule
  group by filename
),
f as (
  select array_to_json(array_agg(
    row_to_json((select r from (select farm,location,commodity,size,unit,operations,schedule) as r))
  ),true) as farm
from farms f join
s on (array_to_string(ARRAY[f.filename,f.farm],'/')=s.filename)
join ops on (array_to_string(ARRAY[f.filename,f.farm],'/')=ops.filename)
)
select
row_to_json((select r from (select farm,materials,prices) as r),true)
  as budget
from f,m,pr;


create or replace function import_authority(base text,authority text)
returns setof import_return_t AS
$$
declare
auth_fn text;
authfile_fn text;
vals text;
myfile RECORD;
farmfile_fn text;
farm_fn text;
price_fn text;
begin

-- COPY Authority files
select into auth_fn array_to_string(ARRAY[base,authority],'/');

foreach authfile_fn in ARRAY
ARRAY['farms','materials','material_requirements','price_lists']
LOOP
select into vals
string_agg(column_name,',' order by ordinal_position)
from information_schema.columns
where table_schema='farm-budgets-data' and
table_name=authfile_fn and
column_name != 'filename';

EXECUTE 'copy ' || authfile_fn ||'('|| vals || ') from '
 || quote_literal(array_to_string(ARRAY[auth_fn,authfile_fn||'.csv'],'/'))
 || ' with csv header';

EXECUTE 'update ' || authfile_fn
 || ' set filename='
 || quote_literal(authority)
 || ' where filename is null';
END LOOP;

-- Add in Prices
FOR myfile in select prices from price_lists where filename=authority
LOOP
price_fn := quote_literal(array_to_string(ARRAY[auth_fn,myfile.prices],'/'));
select into vals
string_agg(column_name,',' order by ordinal_position)
from information_schema.columns
where table_schema='farm-budgets-data' and
table_name='prices' and
column_name != 'filename';

EXECUTE 'copy prices ('|| vals || ') from '
 || price_fn
 || ' with csv header';
EXECUTE 'update prices set filename='
 || quote_literal(authority||'/'||myfile.prices)
 || ' where filename is null';
END LOOP;

-- Add In Farms
FOR myfile in select farm from farms where filename=authority
LOOP
foreach farmfile_fn in ARRAY ARRAY['schedule','operations']
LOOP
farm_fn=array_to_string(ARRAY[auth_fn,myfile.farm],'/');
select into vals
string_agg(column_name,',' order by ordinal_position)
from information_schema.columns
where table_schema='farm-budgets-data' and
table_name=farmfile_fn and
column_name != 'filename';

EXECUTE 'copy ' || farmfile_fn ||'('|| vals || ') from '
 || quote_literal(array_to_string(ARRAY[farm_fn,farmfile_fn||'.csv'],'/'))
 || ' with csv header';
EXECUTE 'update ' || farmfile_fn
 || ' set filename='
 || quote_literal(authority||'/'||myfile.farm)
 || ' where filename is null';
END LOOP;
END LOOP;

return query
select filename,'farms' as table,count(*)
from farms where filename=authority
group by filename
union
select filename,'materials',count(*)
from materials where filename=authority
group by filename
union
select filename,'material_requirements',count(*)
from material_requirements where filename=authority
group by filename
union
select filename,'price_lists',count(*)
from price_lists where filename=authority
group by filename
union
select prices,'prices' as table,count(*)
from price_lists l join prices p on (l.prices=p.filename)
where l.filename=authority
group by prices
union
select p.filename,'schedule' as table,count(*)
from farms f join schedule p
on (array_to_string(ARRAY[f.filename,f.farm],'/')=p.filename)
where f.filename=authority
group by p.filename
union
select p.filename,'operations' as table,count(*)
from farms f join operations p
on (array_to_string(ARRAY[f.filename,f.farm],'/')=p.filename)
where f.filename=authority
group by p.filename
;
end
$$ LANGUAGE plpgsql;
