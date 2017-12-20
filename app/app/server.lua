local string_find = string.find
local lor = require("lor.index")
local router = require("app.router")


local config = require("app.config.config")
local whitelist = config.whitelist
local emp_photo_config = config.emp_photo_config
local view_config = config.view_config
local upload_config = config.upload_config

local app = lor()



-- 模板配置
app:conf("view enable", true)
app:conf("view engine", view_config.engine)
app:conf("view ext", view_config.ext)
app:conf("view layout", "")
app:conf("views", view_config.views)

-- session和cookie支持，如果不需要可注释以下配置
 --local mw_cookie = require("lor.lib.middleware.cookie")
--local mw_session = require("lor.lib.middleware.session")
local mw_session = require("app.middleware.session")
--app:use(mw_cookie())
app:use(mw_session({
    timeout = 3600, -- default session timeout is 3600 seconds
    secret = config.session_secret,
    storage = "redis"
}))

-- 自定义中间件1: 注入一些全局变量供模板渲染使用
local mw_inject_version = require("app.middleware.inject_app_info")
app:use(mw_inject_version())

-- 自定义中间件2: 设置响应头
--    res:set_header("X-Powered-By", "Lor framework")
--    next()
--end)

local powered_by_middleware = require("app.middleware.powered_by")
-- filter: add response header
app:use(powered_by_middleware('Lor Framework'))


local check_login_middleware = require("app.middleware.check_login")
local uploader_middleware = require("app.middleware.uploader")

-- intercepter: login or not
app:use(check_login_middleware(whitelist))
-- uploader
app:use(uploader_middleware({
    dir = upload_config.dir
}))

router(app) -- 业务路由处理

-- 错误处理插件，可根据需要定义多个
app:erroruse(function(err, req, res, next)
    ngx.log(ngx.ERR, err)

    if req:is_found() ~= true then
        if string_find(req.headers["Accept"], "application/json") then
            res:status(404):json({
                rv = 404,
                msg = "404! sorry, not found."
            })
        else
            res:status(404):send("404! sorry, not found. " .. (req.path or ""))
        end
    else
        if string_find(req.headers["Accept"], "application/json") then
            res:status(500):json({
                rv = 500,
                msg = "500! unknown error."
            })
        else
            res:status(500):send("unknown error")
        end
    end
end)

return app
