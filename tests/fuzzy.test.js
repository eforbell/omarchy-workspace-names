const fs = require('fs');
const vm = require('vm');
let source = fs.readFileSync('Fuzzy.js', 'utf8').replace(/^\.pragma library\s*/, '');
const ctx = {}; vm.createContext(ctx); vm.runInContext(source, ctx);
const rows = [
  {id: 1, name: 'browser research', monitor: 'DP-1'},
  {id: 2, name: 'homeSource bug 123', monitor: 'eDP-1'},
  {id: 3, name: 'mail', monitor: 'DP-1'}
];
function equal(actual, expected, message) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) throw new Error(`${message}: ${JSON.stringify(actual)} != ${JSON.stringify(expected)}`);
}
equal(ctx.filter('bug123', rows).map(x => x.id), [2], 'fuzzy subsequence');
equal(ctx.filter('home', rows).map(x => x.id), [2], 'prefix within workspace label');
equal(ctx.filter('3', rows).map(x => x.id), [3,2], 'workspace number');
equal(ctx.filter('', rows).map(x => x.id), [1,2,3], 'empty query keeps order');
equal(ctx.filter('nope', rows), [], 'non-match');
console.log('fuzzy tests: ok');
