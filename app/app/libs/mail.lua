local config = require("app.config.config")
local http = require("socket.http")
local ltn12 = require("ltn12") 
local utils = require("app.libs.utils")
local uuid = require("app.libs.uuid.uuid")
local cjson = require("cjson")
local redis = require("resty.redis")
local uuid = require("app.libs.uuid.uuid")
local random = require "resty.random".bytes
local filedir = require("app.config.config").upload_files.dir

local red = redis:new()
red:set_timeout(config.redis.timeout)
local timeout = config.redis.timeout
local host = config.redis.connect_config.host
local port = config.redis.connect_config.port
local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size = config.redis.pool_config.pool_size
local delay = 2

local _M = {}

function _M.make_approval_token(emp_no,form_id)

	if utils.chk_is_null(emp_no,form_id) then
		msg = "emp_no,form_id不能为空."
		return 501,nil,msg
	end

	local token = "approval-"..uuid()

	local result, err = red:connect(host,port)
	if not result or err then
        ngx.log(ngx.ERR,"failed to connect: "..err)
        return 502,nil,err
    end

    local val = cjson.encode({emp_no = emp_no,
    						form_id = form_id})

    ngx.log(ngx.ERR,"set val OK:"..val)

    local result, err = red:setex(token,86400,val)
    if not result then
        ngx.log(ngx.ERR,"failed to set key: ", err)
        return 503,nil,err
    end

    ngx.log(ngx.ERR,"set OK:"..token)

    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return 504,nil,err
    end

    return 200,token,"sucess"
end

return _M