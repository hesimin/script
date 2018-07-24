#!/usr/bin/env node

// 你传的参数是从第 2 个开始的，在执行的时候是使用 ./test.js xxx，其中xxx为第二个参数
const [node, path, ...argv] = process.argv;

console.log("args: "+ argv);

let cur = process.cwd();
console.log('current dir: '+ cur);

// ============================
var fs = require("fs");

var fn=".gitignore";

var data = fs.readFileSync(fn);

console.log(data.toString());


console.log("准备打开文件！");
fs.open(fn, 'r+', function(err, fd) {
    if (err) {
        return console.error(err);
    }
    console.log("文件打开成功！");
});


process.exit(0);