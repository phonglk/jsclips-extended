
const peg = require("pegjs");
const fs = require('fs');
const path = require('path');
const prettyjson = require('prettyjson');
const execSync = require('child_process').execSync;

function run(){
  const grammar = fs.readFileSync(path.join(__dirname, './workspace/grammar.pegjs')).toString();
  let parser;
  try {
    parser = peg.generate(grammar);
  } catch (e) {
    return console.log('Failed to parse grammar' + e.message);
  }
  const rule = fs.readFileSync(path.join(__dirname, './workspace/test.rule')).toString();
  try {
    const out = parser.parse(rule);
    console.log(prettyjson.render(out));
  } catch (e) {
    const eobj = {
      [e.name] : e.message,
    }
    if (e.location) {
      Object.assign(eobj, {
        line: e.location.start.line,
        column: e.location.start.column
      });
    }
    console.log(prettyjson.render(eobj));
  }
}

function watch() {
  let TARGET_PATH = path.join(__dirname, './workspace');
  fs.watch(TARGET_PATH, {recursive: true}, (eventType, filename) => {
    console.log(`\n>>> ${filename}\n`);
    run();
  });
  run();
}

watch();