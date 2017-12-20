local pairs = pairs
local ipairs = ipairs
local smatch = string.match
local slen = string.len
local supper = string.upper
local ssub = string.sub
local cjson = require("cjson")
local utils = require("app.libs.utils")
local pwd_secret = require("app.config.config").pwd_secret
local lor = require("lor.index")
local random = require "resty.random".bytes
local rstring = require "resty.string"
local template = require ("resty.template")
-- local uuid = require("app.libs.uuid.uuid")
local config = require("app.config.config")
local redis = require("resty.redis")
local user_model = require("app.model.user")

local red = redis:new()
red:set_timeout(config.redis.timeout)
local timeout = config.redis.timeout
local host = config.redis.connect_config.host
local port = config.redis.connect_config.port
local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size = config.redis.pool_config.pool_size

local settings_router = lor:Router()

local function set_secret(res,userid,email) -- 在redis中設置密鑰的存在時間和驗證碼的時間

    local result,err = red:connect(host,port) -- 連接redis
    if not result or err then
      ngx.log(ngx.ERR,"failed to connect redis:"..err)
      return res:json({
        rv = 513,
        msg = "連接redis失敗!"
      })
    end

    --綁定key值及值的失效時間
    local secret_key = userid .. config.key_prefix_code .. email or "" -- 密鑰
    local secret_value
    local exists,err = red:get(secret_key)
    ngx.log(ngx.ERR,exists)
    if not exists or exists == ngx.null then
      secret_value = supper(rstring.to_hex(random(3,true) or
                                                 random(3)))-- 6位隨機驗證碼
      ngx.log(ngx.ERR,"------------------secret_value:"..secret_value)
      local result,err = red:setex(secret_key,config.key_timeout_code,
                                   secret_value..email)
      if not result or err then
        ngx.log(ngx.ERR,"failed to setex:"..err)
        return res:json({
          rv = 514,
          msg = "綁定密鑰及郵箱對應關係失敗!"
        })
      end
      ngx.log(ngx.ERR,"success to bind!")
    else
      secret_value = ssub(red:get(secret_key),0,6)
      ngx.log(ngx.ERR,"------------------secret_value:"..secret_value)
    end

    local ok,err = red:set_keepalive(max_idle_timeout,pool_size) -- 限制最大連接時間和存儲大小
    if not ok or err then
      ngx.log(ngx.ERR,"failed to close redis:"..err)
      return res:json({
        rv = 513,
        msg = "關閉redis失敗!"
      })
    end

    ngx.log(ngx.ERR,"------------------secret_key:"..secret_key)
    ngx.log(ngx.ERR,"------------------secret_value:"..secret_value)
    return secret_key,secret_value
end

local function send_verify(res,user,email,secret_key,secret_value)

    ngx.log(ngx.ERR,"------------------secret_key:"..secret_key)
    ngx.log(ngx.ERR,"------------------secret_value:"..secret_value)
    local http = require("socket.http")
    local ltn12 = require("ltn12")  -- lua自帶filter功能

    local subject = "【智能工廠】郵箱變更驗證"
    local view = "/mail_template/mailVerification.html"
    local content_pre = "<p>哎呀，内容加载错误了(〒︿〒)</p> \n "
    local func = template.compile(view)
    local content = func{
                          emp_name = user.emp_name,
                          current_time = os.date("%Y-%m-%d %H:%M:%S"),
                          verify_code = secret_value
                        } or content_pre

    local request_body = cjson.encode{
      token = config.smtp_token,
      data = {
        rcpts = {email},  --收件人
        subject = subject,
        content = content
      }
    }

    local response_body = {}

    local result,code,response_headers = http.request{
      url = config.smtp_sv.url,
      method = "POST",
      headers =
        {
          ["Content-Type"] = "application/json",
          ["Content-Length"] = #request_body
        },
        source = ltn12.source.string(request_body), -- 返回請求體的內容
        sink = ltn12.sink.table(response_body) -- 指定response_body來存儲sink數組的內容
    }
    ngx.log(ngx.ERR,result) -- 發送請求成功result為1
    ngx.log(ngx.ERR,code) -- 響應碼為200

    local res_body = cjson.encode(response_body)
    if result and code == 200 then
      return res:json({
        rv = 200,
        msg = "郵件發送成功!",
        data = {
          -- secret_key = secret_key,
          -- secret_value = secret_value,
          res = "郵件已成功發送至"..email
        }
      })
    end

    return res:json({  -- response_body的报错信息
      rv = 505,
      msg = res_body
    })
end

settings_router:get("/security/send_email",function(req,res,next)-- 發送驗證碼

    local user = res.locals
    local userid = tonumber(user.userid)

    local src = req.query.src
    local email = req.query.email

    if not src or src ~= "send_email" or not email or not smatch(email,"@") then
      return res:json({
        rv = 502,
        msg = "src參數不對或email不對!"
      })
    end

    if not user then
      return res:json({
        rv = 501,
        msg = "請登錄後再進行操作!"
      })
    end

    local users,err = user_model:query_by_id(userid)
    if not users or err then
      return res:json({
        rv = 503,
        msg = "該用戶信息不存在!"
      })
    end

    if users.mail_notification == email then
      return res:json({
        rv = 503,
        msg = "新郵箱與舊郵箱不能一致!"
      })
    end

    local secret_key,secret_value = set_secret(res,userid,email) -- 設置密鑰
    send_verify(res,user,email,secret_key,secret_value) -- 發送驗證碼
end)

settings_router:get("/security/verify_psw",function(req,res,next) -- 驗證密碼
    local user = res.locals
    local userid = tonumber(user.userid)

    local src = req.query.src
    local psw = req.query.psw

    if not src or src ~= "verify_psw" then
      return res:json({
        rv = 502,
        msg = "請檢查訪問鏈接!"
      })
    end

    if not user then
      return res:json({
        rv = 501,
        msg = "請登錄後再進行操作!"
      })
    end

    local users,err = user_model:query_by_id(userid)
    if not users or err then
      return res:json({
        rv = 503,
        msg = "沒有該用戶的信息!"
      })
    end

    if users.hashed_password ~= utils.encode(psw .. "#" .. pwd_secret) then
      return res:json({
        rv = 504,
        msg = "密碼錯誤!"
      })
    end

    return res:json({
      rv = 200,
      msg = "驗證密碼成功!"
    })
end)

settings_router:post("/security/verify_edit",function(req,res,next)

    local action = req.body.action
    local secret_value = supper(req.body.data.secret_value)
    local email = req.body.data.email
    ngx.log(ngx.ERR,"------------------------secret_value:"..secret_value)
    local user = res.locals
    local userid = tonumber(user.userid)
    local secret_key = userid .. config.key_prefix_code .. email or "" -- 密鑰
    ngx.log(ngx.ERR,"------------------------secret_key:"..secret_key)

    local users,err = user_model:query_by_id(userid)
    if not users or err then
      return res:json({
        rv = 503,
        msg = "沒有該用戶的信息!"
      })
    end

    if email == users.mail_notification then
      return res:json({
        rv = 503,
        msg = "新舊郵箱不能一致!"
      })
    end

    if not action or action ~= "verify_edit" or
       not secret_value or secret_value == "" then
      return res:json({
        rv = 502,
        msg = "訪問連接錯誤或驗證碼为空!"
        })
    end

    local result,err = red:connect(host,port)
    if not result or err then
      ngx.log(ngx.ERR,"failed to connect redis:"..err)
      return res:json({
        rv = 513,
        msg = "連接redis失敗!"
      })
    end

    local surplus_time,err = red:ttl(secret_key) -- 獲取密鑰剩餘時間
    local verify_code,err = red:get(secret_key) -- 獲取驗證碼

    ngx.log(ngx.ERR,"------------------------surplus_time:"..surplus_time)
    ngx.log(ngx.ERR,"------------------------verify_code:"..verify_code)

    if not surplus_time or err or surplus_time <= 0 then
      return res:json({
        rv = 506,
        msg = "驗證碼已失效!"
      })
    end

    if not verify_code or err or verify_code ~= secret_value..email then
      return res:json({
        rv = 507,
        msg = "驗證碼錯誤!"
      })
    end

    local success,err = user_model:update_email(email,userid)
    if not success or err then
      return res:json({
        rv = 503,
        msg = "修改郵箱發生錯誤!"
      })
    else
      local success,err = red:del(secret_key) -- 修改成功後刪除緩存
      if not success or err then
        return res:json({
          rv = 513,
          msg = "刪除redis緩存的鍵值失敗!"
        })
      end
    end

    local ok,err = red:set_keepalive(max_idle_timeout,pool_size) -- 限制最大連接时间和存儲大小
    if not ok or err then
      ngx.log(ngx.ERR,"failed to close redis:"..err)
      return res:json({
        rv = 513,
        msg = "關閉redis失敗!"
      })
    end

    return res:json({
      rv = 200,
      msg = "修改郵箱成功!"
    })
end)

settings_router:post("/security/change_psw",function(req,res,next)

    local user = res.locals
    local userid = tonumber(user.userid)
    local username = user.username

    local action = req.body.action
    local old_psw = req.body.data.old_psw
    local new_psw = req.body.data.new_psw

    if not user then
        return res:json({
          rv = 501,
          msg = "請登錄後再進行操作!"
          })
    end

    if not action or action ~= "change_psw" then
      return res:json({
        rv = 502,
        msg = "請檢查訪問鏈接!"
      })
    end

    if new_psw == old_pwd then
      return res:json({
        rv = 503,
        msg = "新舊密碼不能一致!"
      })
    end

    local password_len = slen(new_psw)
    if password_len<6 or password_len>50 then
        return res:json({
          rv = 503,
          msg = "密码长度应为6~50位!"
          })
    end

    local users,err = user_model:query_by_id(userid)
    if not users or err then
        return res:json({
          rv = 502,
          msg = "沒有該用戶的信息!"
          })
    end

    local psw = users.hashed_password
    if not old_psw or utils.encode(old_psw .. "#" .. pwd_secret) ~= psw then
      return res:json({
        rv = 503,
        msg = "輸入的舊密碼不正確!"
      })
    end

    new_psw = utils.encode(new_psw .. "#" .. pwd_secret)
    local success = user_model:update_pwd(username,new_psw)
    if success then
      return res:json({
        rv = 200,
        msg = "修改密碼成功!"
      })
    else
      return res:json({
        rv = 503,
        msg = "修改密碼失敗!"
      })
    end
end)

settings_router:get("/userinfo/query",function(req,res,next)

    local user = res.locals

    if not user then
      return res:json({
        rv = 501,
        msg = "請登錄後再進行操作!"
      })
    end

    local emp_no = utils.trim(supper(user.emp_no))
    local photo = user.photo

    local src = req.query.src

    if not src or src ~= "query" then
        return res:json({
          rv = 502,
          msg = "請檢查訪問鏈接!"
        })
    end

    local users,err = user_model:query_userinfo_by_emp_no(emp_no)
    if users ~= nil then
        return res:json({
          rv = 200,
          msg = "查詢用戶信息成功!",
          data = users,
          photo = photo
        })
    else
      return res:json({
        rv = 503,
        msg = "查詢用戶信息出錯!"
      })
    end
end)

settings_router:post("/userinfo/edit",function(req,res,next)

    local user = res.locals
    local userid = tonumber(user.userid)

    local action = req.body.action
    local sex = req.body.data.sex
    local extension = req.body.data.extension
    local phone = req.body.data.phone

    if utils.chk_is_null(sex) then
      sex = ""
    end

    if utils.chk_is_null(extension) then
      extension = ""
    end

    if utils.chk_is_null(phone) then
      phone = ""
    end

    if not action or action ~= "edit" then
      return res:json({
        rv = 502,
        msg = "請檢查訪問鏈接!"
      })
    end

    if not user then
      return res:json({
        rv = 501,
        msg = "請登錄後再進行操作!"
      })
    end

    local success = user_model:update_userinfo(sex,extension,phone,userid)
    if success then
      return res:json({
        rv = 200,
        msg = "修改個人信息成功!"
      })
    else
      return res:json({
        rv = 503,
        msg = "修改個人信息失敗!"
      })
    end
end)
return settings_router
