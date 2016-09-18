var request = require('request');


function Receiver(srv, rp, memos_cb, sid, rp_type) {
	var me = this;	
        if (!rp_type) rp_type = 'RP';
	var firstMemo = 0;
	var url = srv+'/v1/'+rp_type+'/'+rp;
	this.maxMemos = 128;
	this.maxDelay = 30000;
        this.limit = 32;
	
	this.start = function() {
		me.stopped = false;
		function once() {
			if (!me.stopped) {
				me._get(once);
			}			
		}
		once();
	}
	
	this.stop = function() {
		me.stopped = true;
	}
	
	this._get = function (complete) {
		var req = {
			      url: url 
			    , method: 'GET'
			    , json: true
			    , headers: { 
			         'Content-Type': 'application/json'
			       , 'X-Limit': me.limit
			       , 'X-First': me.firstMemo
			       , 'X-Last':  me.firstMemo + me.maxMemos - 1
			       , 'X-Delay': me.maxDelay
			      }
			}
                if (sid) req.headers['X-Sid'] = sid;
                console.log(url);
		request(req, function (error, resp, memo) {
			if (!error && resp.statusCode == 200) {
				var next = parseInt(resp.headers['x-next']);
				var sver = parseInt(resp.headers['x-sver']);
                                if (sver != me.sver) {
                                    me.sver = sver;
                                    console.log('server restarted');
                                    me.firstMemo = 0;
                                    if (memos_cb) memos_cb();
                                } else {
   					if (!isNaN(next)) {
				        	me.firstMemo = next;
				        }
                                	if (memos_cb) memos_cb(memo);
                        	}
		        	//console.log(memo);
                                complete();
		    } else {
                        console.log('request fail')
		    	if (error) console.log(error);
		    	else console.log(resp.statusCode);
		    	setTimeout(complete, 30000);
		    }
		});
	}

} 

function SidReceiver(srv, rp, sid, memos_cb, rp_type) {
	var me = this;	
        if (!rp_type) rp_type = 'RP';
	var url = srv+'/v1/'+rp_type+'/'+rp;
	this.maxDelay = 30000;
        this.limit = 16;
	
	this.start = function() {
		me.stopped = false;
		function once() {
			if (!me.stopped) {
				me._get(once);
			}			
		}
		once();
	}
	
	this.stop = function() {
		me.stopped = true;
	}
	
	this._get = function (complete) {
		var req = {
			      url: url 
			    , method: 'GET'
			    , json: true
			    , headers: { 
			         'Content-Type': 'application/json'
			       , 'X-Sid': sid
			       , 'X-Limit': me.limit
			       , 'X-Delay': me.maxDelay
			      }
			}
                console.log(url);
		request(req, function (error, resp, memo) {
			if (!error && resp.statusCode == 200) {
				var sver = parseInt(resp.headers['x-sver']);
                                if (sver != me.sver) {
                                    me.sver = sver;
                                    console.log('server restarted');
                                    if (memos_cb) memos_cb();
                                } else {
                               	    if (memos_cb) memos_cb(memo);
                        	}
		        	//console.log(memo);
			        complete();		        
		    } else {
                        console.log('request fail')
		    	if (error) console.log(error);
		    	else console.log(resp.statusCode);
		    	setTimeout(complete, 30000);
		    }
		});
	}

} 

function Emitter(srv, rp) {
	var me = this;	
        //get the build pack directory according to local file path ( this file location).
	var filename = module.filename;
	var defenderDir = filename.slice(0,filename.lastIndexOf(path.sep)+1 );
	var url = srv+'/v1/RP/'+rp;
	this.maxDelay = 3000;
        this.reset = function (sid) {
                console.log(' -- Delete --------------------------------- <<< ');
                console.log(req);
                var req = {
                              url: url
                            , method: 'DELETE'
                            , headers: {
                                 'Content-Type': 'application/json'
                               , 'X-Sid': sid
                              }
                        }
                console.log(req);
                request(req, function (error, resp, body) {
                    console.log(' -- Delete --------------------------------- >>> ');
                    if (error) {
						console.log(error);
                        return;
                    }
                    console.log(' -- Delete Success: ' + resp.statusCode);
                    //console.log('Emitter success');
                });
        }
        this.memo = function (obj, callback) {
		var req = {
			      url: url 
			    , method: 'PUT'
			    , json: obj
			    , headers: { 
			         'Content-Type': 'application/json'
			       , 'X-Delay': me.maxDelay
			      }				
			}
                request(req, function (error, resp, body) {
                    if (error) {
						console.log(error);
                        return;
                    }
					if (resp.statusCode < 200  &&  resp.statusCode > 299){
						console.log(' -- respond: ' + resp.statusCode);
						if (body) {
							console.log(body);
							return;
                        }
					}
                    console.log(' -- Success: ' + resp.statusCode);
                    if (body) {
                        //body = JSON.stringify(body);
                        console.log(body);
                        if (callback) callback(body)
                    }
                    //console.log('Emitter success');
                });
        }
}


function Enforcer(srv, rp) {
	var url = srv+'/v1/ERP/'+rp;
	this.clear = function (sid) {
		var req = {
			      url: url 
			    , method: 'DELETE'
			    , headers: { 
			         'X-Sid': sid
                               }
			}
                console.log(req)
		request(req, function (error, resp, body) {
                   console.log(resp.statusCode);
                   console.log(body);
		   if (error) console.log(error);
		});
	}
	this.memo = function (obj, sid) {
		var req = {
			      url: url 
			    , method: 'PUT'
			    , json: obj
			    , headers: { 
			          'Content-Type': 'application/json'
			        , 'X-Sid': sid
			      }				
			}
                console.log(req)
		request(req, function (error, resp, body) {
			if (error || resp.statusCode !== 200) {
		    	if (error) console.log(error);
		    	else console.log(resp.statusCode);
		    	return;
		    }
	    	//console.log('Emitter success'); 
		});
	}
}
function Reporter(srv, rp) {
	var url = srv+'/v1/RRP/'+rp;
	this.memo = function (obj) {
		var req = {
			      url: url 
			    , method: 'PUT'
			    , json: obj
			    , headers: { 
			        	   'Content-Type': 'application/json'
			      }				
			}
		request(req, function (error, resp, body) {
		    if (error || resp.statusCode !== 200) {
		    	if (error) console.log(error);
		    	else console.log(resp.statusCode);
		    	return;
		    }
		});
	}
}


module.exports = {
			  Emitter:Emitter
			, Receiver:Receiver
			, SidReceiver:SidReceiver
			, Reporter:Reporter
			, Enforcer:Enforcer
		};
