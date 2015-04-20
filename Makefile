#! /usr/bin/make -f

# Until we get our own bower setup, we continue to get other projects by hand.
# We can leave these in the original folder however.

path:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PG:=psql -d nass --variable=cwd=${path}


nass-summary:=nass-summary-0.1-alpha

${nass-summary}:version:=v0.1-alpha
${nass-summary}:tgz:=v0.1-alpha.tar.gz
${nass-summary}:git:=https://github.com/CSTARS/nass-summary/archive/
${nass-summary}:${tgz}
	[[ -f ${tgz} ]] || wget ${git}/${tgz};\
	tar -xzf ${tgz};

nass-summary-tables:
	${PG} --variable='nassdir=${nass-summary}' -f sql/nass-summary.sql


production.csv:=$(wildcard data/UCD/??-[A-Z]*.csv)
production:
	${PG} -f 'sql/production.sql';
	for c in ${production.csv}; do\
	 ${PG} -c "\COPY farm_budget_data.production (authority,material,location,phase,commodity,unit,amount) from $$c with csv header";\
	 f=`basename $$c .csv | sed -e 's/^...//'`;\
	${PG} -c "update farm_budget_data.production set commodity=upper(trim( both from replace('$$f','_',' '))) where commodity is null";\
	done;


