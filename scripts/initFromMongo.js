var MongoClient = require('mongodb').MongoClient;
var fs = require('fs');

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

    if( !stateCosts[cost.budget] ) stateCosts[cost.budget] = [['item','cost','units']];
    stateCosts[cost.budget].push(
        [cost.item, cost.cost, cost.unit]
    );
}

function readAmounts() {
    amounts.find({}).toArray(function(err, result){
        if( err ) return console.log(err);

        for( var i = 0; i < result.length; i++ ) {
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

    if( !stateCrop[amount.budget] ) stateCrop[amount.budget] = [['item','amount','units']];

    stateCrop[amount.budget].push(
        [amount.item, amount.amount, amount.unit]
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
    for( var key in data ) {
        if( Array.isArray(data[key]) ) {
            writeCsv(dir+key+'.csv', data[key]);
        } else {
            if( !fs.existsSync(dir+key) ) fs.mkdirSync(dir+key);
            writeDir(dir+key+'/', data[key]);
        }
    }
}

function writeCsv(file, arr, key) {
    if( fs.existsSync(file) ) fs.unlinkSync(file);

    for( var i = 0; i < arr.length; i++ ) {
        arr[i] = arr[i].join(',');
    }
    fs.writeFileSync(file, arr.join('\n'), 'utf-8');
}
