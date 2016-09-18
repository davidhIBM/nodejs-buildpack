Plugin = require("./plugin.js");
path = require('path')
fs = require('fs')

var filename = module.filename;
var defenderDir = filename.slice(0,filename.lastIndexOf(path.sep)+1 );
var name = filename.slice(filename.lastIndexOf(path.sep)+1, filename.length -3);
console.log('blueSecure plugin '+name+' started');

process.stdin.resume();
process.stdin.setEncoding('utf8');

var data = "";

process.stdin.on('data', function(chunk) {
    data += chunk;
});

process.stdin.on('end', function() {
    var app = JSON.parse(data);
    //console.log (app);
    var info = process.env.VCAP_APPLICATION;
    if (info) {
        info = JSON.parse(info);
        app.appId = info.application_id;
        app.uris = info.uris;
    }
    app.platform = "NodeJS";
    app.id = "pkgv_action";
    console.log(app.url)
    buildPackEmitterr  = new Plugin.Emitter (app.url, 'image/pkg');
    buildPackEmitterr.reset(app.sid)
    //console.log(JSON.stringify(result));
    buildPackEmitterr.memo(app, function(pkgv_action) {
       console.log("Got action " + pkgv_action);
       console.log(defenderDir + "action.txt");
       fs.writeFile(defenderDir + "action.txt", pkgv_action +"\n", function() {
           console.log(defenderDir + 'action.txt was written');
       });
    });
});

