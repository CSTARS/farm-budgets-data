"use strict";
var walk=require('walk')
  , config = require('config')
  , csv = require('csv')
  , pgservice = require('pgservice')
  , pg = require('pg')
  , fs =require('fs')
  , sys=require('sys')
  , exec=require('child_process').exec
  , path=require('path')
  , opts={followLinks: false, filters:['sql','.git','ext','node_modules']}
  , walker
  , pg_db
  ;

function puts (error,stdout,stderr) { console.log(stdout) }

function filesReader(root, fileStat, next) {
    var fn=fileStat.name;
    if (fn.match(/^files.csv$/)) {
	var data = fs.readFileSync(path.join(root,fn));
	csv.parse(data,function(err,data){
	    for (var i=1; i<data.length;i++) {
		console.log('in',data[i]);
		pg_db.query('insert into foo (filename,type,location,year,commodity) VALUES($1,$2,$3,$4,$5)',data[i],function(err,result) {
		    if(err) { console.log(data[i]); throw err; }
		    console.log(fn,result);
		});
	    }
	    console.log('Parsed',data);
	    next()});	
    } else {
	next();
    }
}

function csvReader(root, fileStat, next) {
  var fn=fileStat.name;
  if (fn.match(/^(materials|material_requirements|prices|units).csv$/)) {
    console.log(fn, root, path.resolve(root,fn));
  }
  next();
}

function errorsHandler(root, nodeStatsArray, next) {
  nodeStatsArray.forEach(function (n) {
    console.error("[ERROR] " + n.name)
    console.error(n.error.message || (n.error.code + ": " + n.error.path));
  });
  next();
}

function filesEnd() {
  console.log("all files.csv");
  var walker=walk.walk('.',opts);
  walker.on("file",csvReader);
  walker.on("errors",errorsHandler);
  walker.on("end",allEnd);
}

function allEnd() {
  console.log("all done");
}


function walkit(db) {
    walker=walk.walk('.',{followLinks: false, filters:['sql','.git','ext','node_modules']})
    walker.on("file",filesReader);
    walker.on("errors",errorsHandler);
    walker.on("end",filesEnd);
}

pgservice({service:"farm-budgets-data"},function(err,connect) {
    console.log(connect);
    pg.connect(connect,function(err,client,done) {
	if(err) {
	    return console.error('error fetching client from pool', err);
	}
	pg_db=client;
	client.query('SELECT $1::int AS number', ['1'], function(err, result) {
	    done();
	    walkit(client);
	    if(err) {
		return console.error('error running query', err);
	    }
	    console.log(result.rows[0].number);
	});
    });
});

