return function(text)

	return function(req, res, next)

	    res:set_header('X-Powered-By', text)
	    res:set_header('Access-Control-Allow-Origin','*') -- 跨域调试用
	    res:set_header('Access-Control-Allow-Methods','GET, POST, OPTIONS')
	    res:set_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')

	    res:set_header('If-Modified-Since','0');
	    res:set_header('Cache-Control','no-cache');
	    --res:set_header('Access-Control-Allow-Origin',ngx.req.get_headers()["Origin"]) -- 跨域调试用
	    --res:set_header('Access-Control-Allow-Methods','GET, POST, OPTIONS')
	    --res:set_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')

		--res:set_header('Access-Control-Allow-Headers','x-requested-with');
		--res:set_header('Access-Control-Max-Age','86400');  
		--res:set_header('Access-Control-Allow-Credentials','true');
		--res:set_header('Access-Control-Allow-Headers','x-requested-with,content-type');
		--res:set_header('Access-Control-Allow-Headers','Origin, No-Cache, X-Requested-With, If-Modified-Since, Pragma, Last-Modified, Cache-Control, Expires, Content-Type, X-E4M-With');

		next()
	end

end
