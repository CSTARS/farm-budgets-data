#! /usr/bin/make -f

# Until we get our own bower setup, we continue to get other projects by hand.
# We can leave these in the original folder however.

path:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PG.service:=farm-budgets-data

PG:=psql service=${PG.service} --variable=cwd=${path}

# This key is not included, you need to get one yourself, the
# JM - Looks like you can get a key from here: http://quickstats.nass.usda.gov/api
#    file should look like:
#    usda.key:=[your key here]
include usda.key

info:
	@echo USDA KEY : ${usda.key}

nass-summary:=nass-summary-0.6-alpha

${nass-summary}:version:=v0.6-alpha
${nass-summary}:tgz:=v0.6-alpha.tar.gz
${nass-summary}:git:=https://github.com/CSTARS/nass-summary/archive/
${nass-summary}:${tgz}
	[[ -f ${tgz} ]] || wget ${git}/${tgz};\
	tar -xzf ${tgz};

nass-summary-tables: ${nass-summary}
	${PG} --variable='nassdir=${nass-summary}' -f sql/nass-summary.sql

nass.csv:=$(patsubst %,nass/%.csv,county_adc land_rent \
	commodity_harvest commodity_county_yield \
        commodity_yield commodity_list)

.PHONY:nass.csv

nass.csv:${nass.csv} nass/commodity_price.csv nass/commodity_avg_price.csv

${nass.csv}:nass/%.csv:${nass-summary}
	cp ${nass-summary}/$*.csv $@


production.csv:=$(wildcard ucd/??-[A-Z]*.csv)
prices.csv:=$(wildcard ucd/??-prices.csv)

commodities:=HAY HAY+%26+HAYLAGE HAYLAGE GRASSES\
BARLEY BEANS CANOLA CORN LENTILS OATS POTATOES WHEAT SUGARBEETS

stats:=PRICE+RECEIVED YIELD PRODUCTION AREA+HARVESTED WATER+APPLIED

states:=CA WA ID MT OR

usda.get=http://quickstats.nass.usda.gov/api/api_GET?key=${usda.key}&format=JSON&freq_desc=ANNUAL

empty:=
space:=${empty} ${empty}
comma:=,

usda.states:=$(subst ${space},&,$(patsubst %,state_alpha=%,${states}))
usda.com:=$(subst ${space},&,$(patsubst %,commodity_desc=%,${commodities}))
usda.stats:=$(subst ${space},&,$(patsubst %,statisitccat_desc=%,${stats.harvest}))

columns:=year commodity_desc statisticcat_desc county_code source_desc \
	unit_desc prodn_practice_desc freq_desc asd_desc \
	domain_desc util_practice_desc Value reference_period_desc \
	class_desc asd_code agg_level_desc state_ansi domaincat_desc \
	state_fips_code group_desc

jq.col:=$(subst ${space},${comma},$(patsubst %,.%,${columns}))

potatoes.json:
	curl "${usda.get}&${usda.states}&${usda.stats}&commodity_desc=POTATOES&year__GE=2007" > $@

price.json:
	curl "${usda.get}&${usda.states}&${usda.com}&statisticcat_desc=PRICE+RECEIVED&year__GE=2007" > $@

yield.json:
	curl "${usda.get}&${usda.states}&${usda.com}&statisticcat_desc=YIELD&year__GE=2007" > $@

production.json:
	curl "${usda.get}&${usda.states}&${usda.com}&statisticcat_desc=PRODUCTION&year__GE=2007" > $@ > $@

area.json:
	curl "${usda.get}&state_alpha=CA&${usda.com}&statisticcat_desc=AREA+HARVESTED&year__GE=2007" > $@
	curl "${usda.get}&state_alpha=ID&${usda.com}&statisticcat_desc=AREA+HARVESTED&year__GE=2007" >> $@
	curl "${usda.get}&state_alpha=MT&${usda.com}&statisticcat_desc=AREA+HARVESTED&year__GE=2007" >> $@
	curl "${usda.get}&state_alpha=OR&${usda.com}&statisticcat_desc=AREA+HARVESTED&year__GE=2007" >> $@
	curl "${usda.get}&state_alpha=WA&${usda.com}&statisticcat_desc=AREA+HARVESTED&year__GE=2007" >> $@

nass/commodity_avg_price.csv nass/commodity_price.csv:nass/%.csv:
	${PG} -c '\COPY (select * from farm_budget_data.$*) to $@ with csv header'

potatoes.csv price.csv area.csv production.csv yield.csv:%.csv:%.json
	jq --raw-output '.data | .[] | [${jq.col}] | @csv' < $< > $@

test:
	for c in ${commodities}; do \
	  curl "${usda.get}&${usda.states}&commodity_desc=$$c&year__GE=2012" > $$c.json;\
	done

import:
	${PG} -f 'sql/farm-budgets-data.sql';
	for c in ${production.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.production (authority,material,location,phase,commodity,unit,amount) from $$c with csv header";\
	 f=`basename $$c .csv | sed -e 's/^...//'`;\
	${PG} -c "update farm_budget_data.production set commodity=upper(trim( both from replace('$$f','_',' '))) where commodity is null";\
	done;
	for p in ${prices.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.price (material,location,year,authority,price,unit) from $$p with csv header";\
	done;
