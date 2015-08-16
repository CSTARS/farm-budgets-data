create or replace function replace_unit(old varchar(64),new varchar(64))
RETURNS varchar(64)
AS $$
update production set unit=$2 where unit=$1;
update price set unit=$2 where unit=$1;
delete from unit where unit=$1;
select $2;
$$ LANGUAGE SQL;

create or replace function add_replace_unit(old varchar(64),new varchar(64))
RETURNS varchar(64)
AS $$
insert into unit (unit) values ($2);
select replace_unit($1,$2);
$$ LANGUAGE SQL;

create or replace function replace_material(old varchar(64),new varchar(64))
RETURNS varchar(64)
AS $$
update production set material=$2 where material=$1;
update price set material=$2 where material=$1;
delete from material where material=$1;
select $2;
$$ LANGUAGE SQL;

create or replace function add_replace_material(old varchar(64), new varchar(64))
RETURNS varchar(64)
AS $$
insert into material select $2,class,description from material where material=$1;
select replace_material($1,$2);
$$ LANGUAGE SQL;
