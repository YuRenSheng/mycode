local supper = string.upper
local cjson = require("cjson")
local redis = require("resty.redis")
local random = require ("resty.random").bytes
local rstring = require ("resty.string")
local utils = require("app.libs.utils")
local uuid = require("app.libs.uuid.uuid")
local config = require("app.config.config")
local pwd_secret = require("app.config.config").pwd_secret
local resetpw_config = require("app.config.config").resetpw_config
local lor = require("lor.index")
local user_model = require("app.model.user")
local emp_model = require("app.model.emp")
local template = require ("resty.template")

local red = redis:new()
red:set_timeout(config.redis.timeout)
local timeout = config.redis.timeout
local host = config.redis.connect_config.host
local port = config.redis.connect_config.port
local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size = config.redis.pool_config.pool_size

local resetpw_router = lor:Router()

local unique = uuid()
local secret_val = supper(rstring.to_hex(random(3,true) or random(3)))-- 6位隨機驗證碼  --6位数随机验证码

resetpw_router:get("",function(req,res,next)
	local src = req.query.src
	local no = req.query.no
	local mail = req.query.mail
    local tb = {"apply"} --,"confirm"}

	if not src or not utils.str_in_table(src,tb) or not no
	   or no == "" or not mail or mail == "" then
		return res:json({
			rv = 500,
			msg = "重置密码申请时，src必须在apply内，且no、mail非空."
		})
	end

	local emp_info,err = emp_model:query_by_id(no)
	if not emp_info or err then
		return res:json({
			rv = 503,
			msg = "工號不存在"
		})
	end

	local name = emp_info.name

	local result, err = user_model:query_by_username(no)
	if not result or err then
		return res:json({
			rv = 501,
			msg = "用户名不存在"
		})
	end

	local email = result.mail_notification
	if not email or email == "" or email ~= mail then
		return res:json({
			rv = 502,
			msg = "邮箱信息与用户信息不符，请确认."
		})
	end

	no = supper(no)
	local secret_key = resetpw_config.key_prefix..no.."-"..unique 

	local result, err = red:connect(host,port)
	if not result or err then
        ngx.log(ngx.ERR,"failed to connect: "..err)
        return res:json({
        	rv = 503,
        	msg = "连接redis失败."
        })
    end

    local result,err = red:keys(resetpw_config.key_prefix..no.."-*")
    if not result or result == ngx.null or result == nil or #result ~=1 then 
	    local result,err = red:setex(secret_key,resetpw_config.key_timeout, secret_val)
	    if not result then
	        ngx.log(ngx.ERR,"failed to set key: ", err)
	        return res:json({
	        	rv= 504,
	        	msg = "存储修改密码网页秘钥失败."
	        })
	    end
	else
		secret_key = result[1]
		secret_val = red:get(secret_key)
	end

    ngx.log(ngx.ERR,"set OK:"..secret_key)

    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return res:json({
        	rv = 505,
        	msg = "关闭redis连接失败."
        })
    end

    local http = require("socket.http")
	local ltn12 = require("ltn12")

	local subject = "【智能工廠】重置密碼驗證"
    local view = "/mail_template/mailVerification.html"
    local content_pre = "<p>哎呀，内容加载错误了(〒︿〒)</p> \n "
    local func = template.compile(view)
    local content = func{
                          emp_name = name or no,
                          current_time = os.date("%Y-%m-%d %H:%M:%S"),
                          verify_code = secret_val
                        } or content_pre

	local request_body = cjson.encode{
		token = config.smtp_token,
		data = {
			rcpts = {mail},
			subject = subject,
			content = content
		}
	}
	local response_body = {}

	local result, code, response_headers = http.request{
	  url = config.smtp_sv.url,
	  method = "POST",
	  headers =
	    {
	        ["Content-Type"] = "application/json";
	        ["Content-Length"] = #request_body;
	    },
	    source = ltn12.source.string(request_body),
	    sink = ltn12.sink.table(response_body),
	}

	ngx.log(ngx.ERR,result)  -- 1
	ngx.log(ngx.ERR,code)  -- 200
	local res_body = cjson.encode(response_body)

	if result and code == 200 then
		ngx.log(ngx.ERR,cjson.encode(response_body)) --返回结果
		return res:json({
			rv = 200,
			msg = "success",
			data = {username = no,
					secret_key = secret_key,
					verify_code = secret_val,
					res = "邮件 to "..mail .. "发送成功."}
		})
	end

	return res:json({
		rv = 506,
		msg = res_body
	})
end)

resetpw_router:get("/check",function(req, res, next)
    local src = req.query.src

    if src == "emp_no" then 

        local emp_no = req.query.no

        if not emp_no or emp_no == "" then
            return res:json({
                rv = 504,
                msg = "工号不得为空."
            })
        end

        emp_no = supper(emp_no)
        local result, err = emp_model:query_by_id(emp_no)
        local isExist = false
        if result and not err then
            isExist = true
        end

        if isExist == false then
            return res:json({
                rv = 505,
                msg = "工号不存在，请检查."
            })
        end

        local result, err = emp_model:query_user_by_emp_no(emp_no)
        local isExist = false
        if result and not err then
            isExist = true
        end

        if isExist == false then
            return res:json({
                rv = 506,
                msg = "该工号沒有系統權限."
            })
        end

        local result, err = emp_model:query_empinfo_by_emp_no(emp_no)
        local isExist = false
        if result and not err then
            isExist = true
        end

        if isExist == false then
            return res:json({
                rv = 507,
                msg = "无员工信息."
            })
        else 
            return res:json({
                rv = 200,
                msg = result.res
            })
        end
    else
       return res:json({
                rv = 508,
                msg = "请指定正确的src."
            }) 
    end
end)

-- 验证码输入后验证
resetpw_router:get("/verify",function(req,res,next)
	local src = req.query.src
	local key = req.query.key
	local code = req.query.code

	if not src or src ~= "verification"
		or not key or key =="" or not code or code == "" then
		return res:json({
			rv = 513,
			msg = "src、key、code不能为空，且src为verification."
		})
	end

	local result, err = red:connect(host,port)
	if not result or err then
        ngx.log(ngx.ERR,"failed to connect: "..err)
        return res:json({
        	rv = 507,
        	msg = "连接redis失败."
        })
    end

    local result ,err = red:ttl(key)
    local rescode , err = red:get(key)
    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return res:json({
        	rv = 508,
        	msg = "关闭redis连接失败."
        })
    end

    if not result or err or result <= 0 then
    	return res:json({
    		rv = 509,
    		msg = "链接超时."
    	})
    end

    if not rescode or err or rescode ~= code then
    	return res:json({
    		rv = 517,
    		msg = "验证码错了."

      })
    end

    return res:json({
    	rv = 200,
    	msg = "success",
    	data = {expire = result,
    			key = key,
    			code = code}
    })
end)

resetpw_router:post("",function(req,res,next)
	local src = req.body.src
	local data = req.body.data

	if not src or src ~= "reset" or not data or data == "" then
		return res:json ({
			rv = 510,
			msg = "src与data不能为空，且src必须为reset."
		})
	end

	local username = data.no
	local password = data.password
	local key = data.key

	if not username or username == "" or not password or password == ""
		 or not key or key == "" then
		return res:json({
			rv = 511,
			msg = "no、password、key不能为空."
		})
	end

	local emp_no = utils.string_split(key,"-")[2]
	ngx.log(ngx.ERR,emp_no)
	if username ~= emp_no then 
		return res:json({
			rv = 520,
			msg = "工號與key對應工號不一致，請檢查."
		})
	end

	password = utils.encode(password .. "#" .. pwd_secret)
	local result, err = user_model:update_pwd(username, password)

	if not result or err then
		return res:json({
			rv = 512,
			msg = "修改密码失败."
		})
	end

	local result, err = red:connect(host,port)
	if not result or err then
        ngx.log(ngx.ERR,"failed to connect: "..err)
        return res:json({
        	rv = 512,
        	msg = "连接redis失败."
        })
    end

    local exists ,err = red:exists(key)

    if exists == 1 then
    	local del,err = red:del(key)
	    if del ~=1 or err then
			return res:json({
				rv = 516,
				msg = "删除失败."
			})
		end
	end

	local ok, erro = red:set_keepalive(max_idle_timeout,pool_size)
	if not ok or erro then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return res:json({
        	rv = 517,
        	msg = "关闭redis连接失败."
        })
    end

	return res:json({
		rv = 200,
		msg = "success",
		data = {username = username}
	})

end)

return resetpw_router
