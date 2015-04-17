var MongoClient = require('mongodb').MongoClient;
var fs = require('fs');
var fips = require('./fips.json');

var data = {}, costs, amounts;
var dir = __dirname+'/../data/';
var database;

MongoClient.connect('mongodb://localhost:27017/farmBudgets', function(err, db) {
  if( err ) return console.log(err);

  database = db;
  costs = db.collection('costs');
  amounts = db.collection('amounts');

  readCosts();
});

// prep fips
var tmp = {};
for( var i = 0; i < fips.length; i++ ) {
  tmp[fips[i][0]] = fips[i];
}
fips = tmp;

function readCosts() {
    costs.find({}).toArray(function(err, result){
        if( err ) return console.log(err);

        for( var i = 0; i < result.length; i++ ) {
            addCost(result[i]);
        }

        readAmounts();
    });
}

function addCost(cost) {
    if( !data[cost.state] ) {
        data[cost.state] = {
            county : {},
            zipcode : {},
            costs : {},
            amounts : {}
        };
    }

    var stateCosts = data[cost.state].costs;

    if( !stateCosts[cost.budget] ) stateCosts[cost.budget] = [['price_id','item','location','year','auth_id','price','unit']];
    stateCosts[cost.budget].push(
        ['', cost.item, fips[cost.state][2], '', 'UCD', cost.cost, cost.unit]
    );
}

function readAmounts() {
    amounts.find({}).toArray(function(err, result){
        if( err ) return console.log(err);

        for( var i = 0; i < result.length; i++ ) {
            if( result[i].crop && result[i].crop.indexOf('/') > -1 ) {
                result[i].crop = result[i].crop.replace(/\//,'and');
            }
            addAmount(result[i]);
        }

        writeFs();
    });
}

function addAmount(amount) {
    if( !data[amount.state] ) {
        data[amount.state] = {
            county : {},
            zipcode : {},
            costs : {},
            amounts : {}
        };
    }

    var stateAmounts = data[amount.state].amounts;
    if( !stateAmounts[amount.crop] ) stateAmounts[amount.crop] = {};

    var stateCrop = stateAmounts[amount.crop]

    if( !stateCrop[amount.budget] ) stateCrop[amount.budget] = [['budget_id', 'commodity', 'location', 'phase', 'material', 'unit', 'amount']];

    stateCrop[amount.budget].push(
        ['', amount.item, fips[amount.state][2], '', '', amount.unit, amount.amount]
    );
}

function writeFs() {
    console.log(data);
    console.log(dir);

    writeDir(dir, data);

    database.close();
    console.log('done');
}

function writeDir(dir, data) {
  if( !fs.exists(dir+'UCD') ) fs.mkdirSync(dir+'UCD');
  dir = dir+'UCD';

  for( var state in data ) {
    var filename = state.replace(/\s/g,'_')+'-costs.csv';
    writeCsv(dir+'/'+filename, data[state].costs.default);

    for( var crop in data[state].amounts ) {
      var filename = state.replace(/\s/g,'_')+'-'+crop.replace(/\s/g,'_');

      writeCsv(dir+'/'+filename+'.csv', data[state].amounts[crop].default);
    }
  }
}

function writeCsv(file, arr) {
    if( fs.existsSync(file) ) fs.unlinkSync(file);

    for( var i = 0; i < arr.length; i++ ) {
        arr[i] = arr[i].join(',');
    }
    fs.writeFileSync(file, arr.join('\n'), 'utf-8');
}
