local smatch = string.match
local sfind = string.find
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local utils = require("app.libs.utils")
local redis = require("resty.redis")
local cjson = require("cjson")
local config = require("app.config.config")
local emp_model = require("app.model.emp")
local emp_photo_dir = require("app.config.config").emp_photo_config.dir
local emp_photo_path = require("app.config.config").emp_photo_config.path
local emp_photo_default = require("app.config.config").emp_photo_config.default
local red = redis:new()

red:set_timeout(config.redis.timeout)

local timeout = config.redis.timeout
local host = config.redis.connect_config.host
local port = config.redis.connect_config.port

local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size = config.redis.pool_config.pool_size

local function is_login(req)
    local user
    if req.session then
        user =  req.session.get("user")
        ngx.log(ngx.ERR,"user: ",cjson.encode(user))
        if     user        and user.username and user.userid
           and user.emp_no and user.dept_code then
            return true, user
        end
    end

    return false, nil
end

local function ttl_redis_key(key)

	local ok, err = red:connect(host,port)
	if not ok or err then
		return nil, err;
	end

	local ttl, err = red:ttl(key)
	local  ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return nil, err
    end

    return ttl , err
end

local function check_in_white_list(requestPath, whitelist)

	--检查请求地址是否在白名单中
    local in_white_list = false

    if requestPath == "/" then
    	in_white_list = true
    else
	    for i, v in ipairs(whitelist) do
	    	local match, err = smatch(requestPath, v)
	        if match then
	            in_white_list = true
	            break
	        end
	    end
	end

	return in_white_list
end

local function check_is_app_path(requestPath)

	local is_app_path = "^/app/v1/"
	return smatch(requestPath, is_app_path)
end

local function check_is_exists_token(token)

	local is_exsist = (token and token ~= "")
	-- 有token,继续
	if is_exsist then
		local ttl, err = ttl_redis_key(token)
		if ttl > 0 and not err then
			return true
		end
	end

	return false
end

local function get_redis_val(key)  -- emp_no
	local ok, err = red:connect(host,port)
	if not ok or err then
		return nil, err;
	end

	local val, err = red:get(key)
	local  ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        return nil, err
    end

    ngx.log(ngx.ERR,val)
    local emp_no = cjson.decode(val).emp_no or cjson.decode(val).emp_info.no
    ngx.log(ngx.ERR," emp_no:", emp_no );
    return emp_no, err
end

local function set_session(emp_no)
	ngx.log(ngx.ERR," emp_no:", emp_no );
	local result,err =  emp_model:query_userinfo_by_emp_no(emp_no)
	if not result or err then
		local msg = "没有该员工信息，请确认."
		return nil,err or msg
	end

	local emp_photo_1 = emp_photo_dir..ssub(emp_no,1,4)..'/'..emp_no..'.JPG'
    local emp_photo_2 = emp_photo_dir..ssub(emp_no,1,4)..'/'..emp_no..'.jpg'
    ngx.log(ngx.ERR, emp_photo_1)
    ngx.log(ngx.ERR, emp_photo_2)

    local emp_photo = emp_photo_default
    local file, err = io.open(emp_photo_1)

    if file and not err then
        emp_photo = emp_photo_path..ssub(emp_no,1,4)..'/'..emp_no..'.JPG'
        io.close(file)
    else
        local file1, err = io.open(emp_photo_2)
        if file1 and not err then
            emp_photo = emp_photo_path..ssub(emp_no,1,4)..'/'..emp_no..'.jpg'
            io.close(file1)
        end
    end

    local user =
	{
		 	username = result.login,
            userid = result.id,
            emp_no = result.no,
            emp_name = result.name,
            dept_code = result.dept_code,
            position = result.position,
            photo = emp_photo,
            create_time = os.date("%Y-%m-%d %H:%M:%S") or ""
	}

	return user,nil
end

local function check_login(whitelist)
	return function(req, res, next)

		--检查请求地址是否在白名单中
		local requestPath = req.path

	    local in_white_list = check_in_white_list(requestPath, whitelist)
		local is_app = check_is_app_path(requestPath)  -- is_web就是APP
		local islogin, user = is_login(req)

		ngx.log(ngx.ERR,"in_white_list:",in_white_list," is_app:",is_app,
					    " islogin:",islogin ,"path:",requestPath);
		--在白名单内，直接访问
	    if in_white_list then
        	res.locals.login = islogin
        	res.locals.username = user and user.username
        	res.locals.emp_no = user and user.emp_no
        	res.locals.emp_name = user and user.emp_name
        	res.locals.position = user and user.position
        	res.locals.dept_code = user and user.dept_code
        	res.locals.userid = user and user.userid
        	res.locals.create_time = user and user.create_time
        	res.locals.photo = user and user.photo
        	ngx.log(ngx.ERR,"in_white_list",islogin)
            next()
	    else
			if is_app then
				--不在白名单内，且是APP页面
				local token = req.query.token or req.body.token
				local is_exsits_token = check_is_exists_token(token)

				ngx.log(ngx.ERR, "is_exsits_token:",is_exsits_token,
								 " token:", token )

				if is_exsits_token then
			        local emp_no,err = get_redis_val(token)
			        ngx.log(ngx.ERR," emp_no:", emp_no )

			        if utils.chk_is_null(emp_no) or err then
			            res:json({
			              rv = 406,
			              msg = "token没有工号."
			            })
			        end

			        user_01,err = set_session(emp_no)
			        if not user_01 or err then
			            res:json({
			              rv = 402,
			              msg = err ..",该操作需要先登录."
			              })
			        end
			        ngx.log(ngx.ERR,cjson.encode(user_01))
			        req.session.set("user",user_01)
			        res.locals.login = true
			        res.locals.username = user_01.username
			        res.locals.emp_no = user_01.emp_no
			        res.locals.emp_name = user_01.emp_name
			        res.locals.dept_code = user_01.dept_code
					res.locals.userid = user_01.userid
					res.locals.create_time = user_01.create_time
					res.locals.photo = user_01.photo
					res.locals.position = user_01.position
					next()
				else
					if token == config.app_root_token then
						next()
					else
						res:json({
		    				rv = 401,
		    				msg = "该操作需要先登录."
		    			})
		    		end
				end
			else
				 --不在白名单内，且是web页面有session
				 --[[
		        if islogin then
		        	res.locals.login = true
		        	res.locals.username = user.username
		        	res.locals.emp_no = user.emp_no
		        	res.locals.emp_name = user.emp_name
		        	res.locals.position = user.position
		        	res.locals.dept_code = user.dept_code
					res.locals.userid = user.userid
					res.locals.create_time = user.create_time
					res.locals.photo = user.photo
		            next()
		        else
		        	--]]
		        	-- 没有session,看是否有token
	        	local mail_token = req.query.mail_token or req.body.mail_token
				local is_exsits_token = check_is_exists_token(mail_token)
				local simu_emp_no = req.query.simulation_employee_no or
				                    req.body.simulation_employee_no

				local is_exists_simulation = not utils.chk_is_null(simu_emp_no)
				ngx.log(ngx.ERR,"is_exsits_token:", is_exsits_token,
								" mail_token:", mail_token );

				-- 如果存在，取出工号，填充session，不存在直接报错
				if is_exsits_token or is_exists_simulation then
					local user_01, err
					ngx.log(ngx.ERR,"is_exsits_token:",is_exsits_token,
						            "is_exists_simulation:",is_exists_simulation)
					if is_exsits_token then
						local emp_no,err = get_redis_val(mail_token)
						ngx.log(ngx.ERR," emp_no:", emp_no )

						if not emp_no or err then
							res:json({
	        					rv = 406,
	        					msg = "token没有工号."
	        				})
						end

						user_01,err = set_session(emp_no)
						if not user_01 or err then
							res:json({
	        					rv = 402,
	        					msg = err ..",该操作需要先登录."
	        				})
						end
						ngx.log(ngx.ERR,cjson.encode(user_01))
						req.session.set("user",user_01)
					else
						user_01,err = set_session(simu_emp_no)
						if not user_01 or err then
							res:json({
	        					rv = 402,
	        					msg = err ..",该操作需要先登录."
	        				})
						end
					end

					res.locals.login = true
		        	res.locals.username = user_01.username
		        	res.locals.emp_no = user_01.emp_no
		        	res.locals.emp_name = user_01.emp_name
		        	res.locals.dept_code = user_01.dept_code
					res.locals.userid = user_01.userid
					res.locals.create_time = user_01.create_time
					res.locals.photo = user_01.photo
					res.locals.position = user_01.position

					ngx.log(ngx.ERR,cjson.encode(res.locals))
					next()

				elseif islogin then
		        	res.locals.login = true
		        	res.locals.username = user.username
		        	res.locals.emp_no = user.emp_no
		        	res.locals.emp_name = user.emp_name
		        	res.locals.position = user.position
		        	res.locals.dept_code = user.dept_code
					res.locals.userid = user.userid
					res.locals.create_time = user.create_time
					res.locals.photo = user.photo
		            next()
	        	else
		        	if sfind(req.headers["Accept"], "application/json") then
		        		res:json({
		        			success = 400,
		        			msg = "该操作需要先登录."
		        		})
		        	else
		            	res:redirect("/auth/login")
		            end
		        end
		    --    end
		    end
	    end
	end
end




return check_login
