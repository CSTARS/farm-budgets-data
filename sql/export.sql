-- Method for exporting the data.
\COPY change to change.csv with csv header
\COPY (select unit,description from farm_budget_data.unit order by unit) to units.csv with csv header
\COPY (select * from farm_budget_data.material order by material,unit ) to materials.csv with csv header
\COPY (select * from  farm_budget_data.operation order by operation) to operations.csv with csv header
