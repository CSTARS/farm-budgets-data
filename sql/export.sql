-- Method for exporting the data.
\COPY (select unit,description from farm_budget_data.unit order by unit) to units.csv with csv header
\COPY (select distinct material,class,description from farm_budget_data.material order by material ) to materials.csv with csv header
\COPY (select * from  farm_budget_data.operation order by operation) to operations.csv with csv header
