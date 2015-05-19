#! /usr/bin/make -f

# Until we get our own bower setup, we continue to get other projects by hand.
# We can leave these in the original folder however.

path:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PG:=psql -d nass --variable=cwd=${path}


nass-summary:=nass-summary-0.5-alpha

${nass-summary}:version:=v0.5-alpha
${nass-summary}:tgz:=v0.5-alpha.tar.gz
${nass-summary}:git:=https://github.com/CSTARS/nass-summary/archive/
${nass-summary}:${tgz}
	[[ -f ${tgz} ]] || wget ${git}/${tgz};\
	tar -xzf ${tgz};

nass-summary-tables: ${nass-summary}
	${PG} --variable='nassdir=${nass-summary}' -f sql/nass-summary.sql

nass.csv:=$(patsubst %,nass/%.csv,county_adc land_rent commodity_harvest commodity_yield commodity_price commodity_list)

.PHONY:nass.csv

nass.csv:${nass.csv}

${nass.csv}:nass/%.csv:${nass-summary}
	cp ${nass-summary}/$*.csv $@


production.csv:=$(wildcard data/UCD/??-[A-Z]*.csv)
prices.csv:=$(wildcard data/UCD/??-prices.csv)

import:
	${PG} -f 'sql/production.sql';
	for c in ${production.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.production (authority,material,location,phase,commodity,unit,amount) from $$c with csv header";\
	 f=`basename $$c .csv | sed -e 's/^...//'`;\
	${PG} -c "update farm_budget_data.production set commodity=upper(trim( both from replace('$$f','_',' '))) where commodity is null";\
	done;
	${PG} -c "select farm_budget_data.fix_production();";
	for p in ${prices.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.price (material,location,year,authority,price,units) from $$p with csv header";\
	done;


