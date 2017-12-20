local pairs = pairs
local ipairs = ipairs
local sfind = string.find
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local cjson = require("cjson")
local redis = require("resty.redis")
local utils = require("app.libs.utils")
local lor = require("lor.index")
local config = require("app.config.config")
local user_model = require("app.model.user")
local emp_model = require("app.model.emp")
local dept_model = require("app.model.dept")

local red = redis:new()

red:set_timeout(config.redis.timeout)

local timeout = config.redis.timeout
local host = config.redis.connect_config.host
local port = config.redis.connect_config.port

local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size = config.redis.pool_config.pool_size

local auth_router = lor:Router()

auth_router:post("/login",function(req,res,next)

	local card_no = req.body.card_no
	local mac = req.body.mac
	local ip = req.body.ip 
	local os_type = req.body.os_type  -- android / ios

	local os_ver = req.body.os_ver or ""
	local app_ver = req.body.app_ver or ""
	local imei = req.body.imei or ""
	local meid = req.body.meid or ""
	local tb = {"android","ios"}
	
	local res_info = {}

	local data = {  card_no = card_no,
					mac = mac,
					ip = ip,
					os_type = os_type,
					os_ver = os_ver,
					app_ver = app_ver,
					imei = imei,
					meid = meid	}

	-- os_ver  app_ver imei meid 
	if    not card_no or card_no == "" 
	   or not mac     or mac == "" 
	   or not ip      or ip == "" 
	   or not os_type or not utils.str_in_table(os_type,tb) then 
		return res:json({
			rv = 501,
			msg = "card_no卡号、mac、ip、os_type系统型号不能为空，且在android、ios内."
		})
	end

	local result,err = emp_model:query_empinfo_by_emp_card(card_no)

	local is_exsist = false
	if result and not err then 
		is_exsist = true
	end

	if is_exsist == false then 
		data.status = 0
		local err_info = "该卡号没有对应员工记录."
		local ok = auth_router:add_login_log(data,err_info)

		return res:json({
			rv = 502,
			msg = err_info
		})
	end

	local dept_code = result.dept_code
	local emp_count = 0
	local dept_emp,err = emp_model:query_count_emp_by_dept_code(dept_code)
	if dept_emp and not err then 
		emp_count = #dept_emp
	end 

	local emp_info, err = emp_model:query_empinfo_by_emp_card(card_no)
	local is_exsist = false
	local position = emp_info.position
	if emp_info and not err and position ~= "無" and position ~= "无" then 
		is_exsist = true
	end

	if is_exsist == false then 
		data.status = 0
		local err_info = "没有职位，请确认是否有权限."
		local ok = auth_router:add_login_log(data,err_info)

		return res:json({
			rv = 503,
			msg = err_info
		})
	end

	emp_info.count = emp_count
	data.status = 1
	local err_info = ""
	local ok = auth_router:add_login_log(data,err_info)
    
--获取卡号刷新token
	local refresh_token ,err = auth_router:get_redis_key(card_no.."_refresh")
--无卡号刷新token，直接生成新的refresh_token
	if not refresh_token or refresh_token == ngx.null or err then
		local refresh_token_info = auth_router:make_refresh_token(data,emp_info)
	    if refresh_token_info.rv == 200 then 
	    	refresh_token = refresh_token_info.token
	    else
	    	return res:json(refresh_token_info)
	    end
	end

-- 获取卡号token
	local token, err = auth_router:get_redis_key(card_no)
-- 无卡号token，直接生成新的token
	if not token or token == ngx.null or err then
		token = auth_router:make_token(data,emp_info)
	    res_info = token;
	    res_info.refresh_token = refresh_token
		res_info.data = { emp_info = emp_info };
	--	return res:json({
	--		rv = 420,
	--		msg = "token过期了，请重新登录"
	--	})


	--	ngx.log(ngx.ERR,"not token:",token)
-- 有卡号token，检查token内容mac地址是否一致
	else 
		local token_val_str, err = auth_router:get_redis_key(token)
		ngx.log(ngx.ERR,"token:", token,"val: ", token_val_str)
		local token_val = cjson.decode(token_val_str)
		local mac_addr = token_val.device_info.mac
		local ttl ,err = auth_router:ttl_redis_key(token)
		res_info.iat = os.time()

	-- mac地址不一致时，生成新token，删除旧的token(所有token)
		if mac ~= mac_addr or ttl < 300 then 
			ngx.log(ngx.ERR,"not mac:",mac ," ",mac_addr," ttl: ",ttl)
			local del_token ,err = auth_router:del_redis_key(token)

			local del_refresh_token,err = auth_router:del_redis_key(refresh_token)
			local new_refresh_token = auth_router:make_refresh_token(data,emp_info)
			if new_refresh_token.rv == 200 then 
		    	refresh_token = new_refresh_token.token
		    else
		    	return res:json(new_refresh_token)
		    end

			local new_token = auth_router:make_token(data,emp_info)
			if new_token.rv == 200 then 
    			res_info = new_token;
    			res_info.refresh_token = refresh_token
				res_info.data = { emp_info = emp_info };
    		end
		else
	-- mac一致时，直接取现有token
			res_info.rv = 200
			res_info.msg = "success"
			res_info.exp = res_info.iat + ttl
			res_info.token = token
			res_info.refresh_token = refresh_token
			res_info.data = { emp_info = emp_info }
			res_info.type = "S"
		end
	end	
	return res:json(res_info)
end)

function auth_router:add_login_log(data,err_info)
	ngx.log(ngx.ERR,cjson.encode(data))
	local sdata = " "
	local ddata = " "
	for key,val in pairs(data) do
		sdata = sdata .. key .. ","
		if type(val) == "string" then
			ddata = ddata .. "'"..val .. "',"
		else
			ddata = ddata ..val .. ","
		end
	end

	sdata = sdata .. "err_info "
	ddata = ddata .. "'"..err_info.."'"

	ngx.log(ngx.ERR,sdata)
	local result, err = user_model:add_app_login_log(sdata,ddata)

	return true
end

function auth_router:get_redis_key(key)
	local ok, err = red:connect(host,port)
	if not ok or err then
		return nil, err;
	end

	local token, err = red:get(key)

	local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return nil, err
    end

    return token , err
end

function auth_router:del_redis_key(token)
	local ok, err = red:connect(host,port)
	if not ok or err then
		return nil, err;
	end

	local token, err = red:del(token)

	local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return nil, err
    end

    return token , err
end

function auth_router:ttl_redis_key(token)
	local ok, err = red:connect(host,port)
	if not ok or err then
		return nil, err;
	end

	local token, err = red:ttl(token)

	local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return nil, err
    end

    return token , err
end

function auth_router:make_token(data,emp_info)
	local time = os.time()
	-- token 

	local token_str =utils.encode(data.card_no .. data.mac ..data.ip .. data.os_type .. time)

	local result, err = red:connect(host,port)
	if not result or err then
		return { rv  = 504,
        		 msg = "连接redis失败."}
	end

	--emp_info.data = data

	local result1, err = red:setex(data.card_no,3600*24,token_str)
	local result2, err = red:setex(token_str,3600*24, cjson.encode({emp_info=emp_info , device_info=data}))
	if not result1 or not result2 or err then
        return {
        	rv  = 505,
        	msg = "存储token失败." }
    end

    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return {
        	rv = 506,
        	msg = "关闭redis连接失败." }
    end

    return {
    		rv = 200,
    		token = token_str,
    		iat = time,
    		exp = time+3600,
			msg ="success" }
end

--refresh_token
function auth_router:make_refresh_token(data,emp_info)
	local time = os.time()
	-- token 

	local token_str =utils.encode(data.card_no .. data.mac ..data.ip .. data.os_type .. time.."refresh")

	local result, err = red:connect(host,port)
	if not result or err then
		return { rv  = 512,
        		 msg = "连接redis失败."}
	end

	local card_refresh = data.card_no .. "_refresh"

	local result1, err = red:setex(card_refresh,2592000,token_str)
	local result2, err = red:setex(token_str,2592000, cjson.encode({emp_info=emp_info , device_info=data}))
	if not result1 or not result2 or err then
        return {
        	rv  = 513,
        	msg = "存储token失败." }
    end

    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return {
        	rv = 514,
        	msg = "关闭redis连接失败." }
    end

    return {
    		rv = 200,
    		token = token_str,
    		iat = time,
    		exp = time+2592000,
			msg ="success" }
end

-- access_token刷新
auth_router:post("/refresh_token",function(req,res,next)
	local token = req.body.token 

	local result, err = red:connect(host,port)
	if not result or err then
		return { rv  = 507,
        		 msg = "连接redis失败."}
	end

	local token_val_str, err = red:get(token)

	local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return {
        	rv = 508,
        	msg = "关闭redis连接失败." }
    end

	if not token_val_str or token_val_str == ngx.null or err then 
		return res:json({
			rv = 509,
			msg = "token过期了，请重新登录."
		})
	end

	local token_val = cjson.decode(token_val_str)

	local result = auth_router:make_token(token_val.device_info,token_val.emp_info)
    
    if result.rv == 200 then 
    	return res:json(result)
    end
end)

-- refresh_token刷新
auth_router:post("/token_refresh",function(req,res,next)
	local token = req.body.refresh_token 

	local result, err = red:connect(host,port)
	if not result or err then
		return { rv  = 515,
        		 msg = "连接redis失败."}
	end

	local token_val_str, err = red:get(token)

	local result1, err = red:del(token)
--	local result2, err = red:del(card_no.."_refresh") --等会改
	if not result1 or err then
        return {
        	rv  = 516,
        	msg = "刪除token失败." }
    end

	local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return {
        	rv = 517,
        	msg = "关闭redis连接失败." }
    end

	if not token_val_str or token_val_str == ngx.null or err then 
		return res:json({
			rv = 518,
			msg = "token过期了，请重新登录."
		})
	end

	local token_val = cjson.decode(token_val_str)

	--生成access_token
	local result = auth_router:make_token(token_val.device_info,token_val.emp_info)
	--生成refresh_token
	local refresh_token
	local refresh_token_info = auth_router:make_refresh_token(token_val.device_info,token_val.emp_info)
    if refresh_token_info.rv == 200 then 
    	refresh_token = refresh_token_info.token
    else
    	return res:json(refresh_token_info)
    end

    if result.rv == 200 then 
    	result.refresh_token = refresh_token
    	return res:json(result)
    end

    return res:json(result)
end)

auth_router:post("/logout",function(req,res,next)
	local token = req.body.token 

	if not token or token == "" then
		return res:json({
			rv = 510,
			msg = "token 不能为空."
		})
	end

	local result, err = red:connect(host,port)
	if not result or err then
		return { rv  = 511,
        		 msg = "连接redis失败."}
	end

	local card_no = ""

	local token_val_str, err = red:get(token)
	if token_val_str and token_val_str ~= ngx.null and not err then 
		local token_val = cjson.decode(token_val_str)
		card_no = token_val.emp_info.card_no
	else
		return res:json({
			rv = 200,
			msg = "success"
		})
	end

	local result1, err = red:del(token)
	local result2, err = red:del(card_no)
	if not result1 or not result2 or err then
        return {
        	rv  = 512,
        	msg = "刪除token失败." }
    end

    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return {
        	rv = 513,
        	msg = "关闭redis连接失败." }
    end

    return res:json({
			rv = 200,
			msg = "success"
	})
end)

return auth_router