#! /usr/bin/make -f

# Until we get our own bower setup, we continue to get other projects by hand.
# We can leave these in the original folder however.

path:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PG.service:=farm-budgets-data
PG:=psql service=${PG.service} --variable=cwd=${path}

include nass.mk

files.csv:=$(shell find . -name files.csv)
auto.csv:=$(shell find . -name units.csv -o -name materials.csv -o -name material_requirements.csv -o -name prices.csv)

production.csv:=$(wildcard ucd/??-[A-Z]*.csv)
yields.csv:=$(wildcard ucd/??-yields.csv)

INFO::
	@echo files.csv:=${files.csv}
	@echo auto.csv:=${auto.csv}
	echo ${production.csv}
	echo ${prices.csv}

import:
	${PG} -f 'sql/farm-budgets-data.sql';
	for c in ${production.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.production (material,location,phase,operation,commodity,unit,amount) from $$c with csv header";\
	 f=`basename $$c .csv | sed -e 's/^...//'`;\
	${PG} -c "update farm_budget_data.production set commodity=upper(trim( both from replace('$$f','_',' '))), filename='$$c' where commodity is null";\
	${PG} -c "update farm_budget_data.production set filename='$$c' where filename is null";\
	done;
	for p in ${prices.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.price (material,location,year,price,unit) from $$p with csv header";\
	${PG} -c "update farm_budget_data.price set filename='$$p' where filename is null";\
	done;
	for p in ${yields.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.yield (commodity,location,unit,value) from $$p with csv header";\
	 ${PG} -c "update farm_budget_data.yield set filename='$$p' where filename is null";\
	done;

export:
	${PG} -f 'sql/export.sql';
	for f in `${PG} --pset=footer -A -t -c "select distinct filename from farm_budget_data.production"`; do\
	 ${PG} -c "\COPY (select distinct material,location,phase,operation,commodity,unit,amount from farm_budget_data.production where filename='$$f' order by phase,material,operation,commodity) to $$f with csv header";\
	done;
	for f in `${PG} --pset=footer -A -t -c "select distinct filename from farm_budget_data.price"`; do\
	 ${PG} -c "\COPY (select material,location,year,price,unit from farm_budget_data.price where filename='$$f' order by material,unit) to $$f with csv header";\
	done;
	for f in `${PG} --pset=footer -A -t -c "select distinct filename from farm_budget_data.yield"`; do\
	 ${PG} -c "\COPY (select commodity,location,unit,value from farm_budget_data.yield where filename='$$f' order by location,commodity,unit) to $$f with csv header";\
	done;
