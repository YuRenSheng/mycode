local xpcall = xpcall
local traceback = debug.traceback
local ngx_time = ngx.time
local Session = require("resty.session")
local cjson = require('cjson')
-- Mind:
-- base on 'lua-resty-session'
-- this is the default `session` middleware which uses storage `cookie`
-- you're recommended to define your own `session` middleware.
-- you're strongly recommended to set your own session.secret

-- usage example:
--    app:get("/session/set", function(req, res, next)
--        local k = req.query.k
--        local v = req.query.v
--        if k then
--            req.session.set(k,v)
--            res:send("session saved: " .. k .. "->" .. v)
--        else
--            res:send("null session key")
--        end
--    end)
--
--    app:get("/session/get/:key", function(req, res, next)
--        local k = req.params.key
--        if not k then
--            res:send("please input session key")
--        else
--            res:send("session data: " .. req.session.get(k))
--        end
--    end)
--
--    app:get("/session/destroy", function(req, res, next)
--        req.session.destroy()
--    end)
local session_middleware = function(config)
    config = config or {}

    if config.refresh_cookie ~= false then
        config.refresh_cookie = false
    end

    if not config.timeout or type(config.timeout) ~= "number" then
        config.timeout = 3600 -- default session timeout is 3600 seconds
    end

    if not config.secret then
        config.secret = config.session_secret
    end

    return function(req, res, next)
        local config = config or {}
        config.storage = config.storage or "redis" -- default is “cookie”
        --local session = Session.new(config)
        --session.secret = config.secret

        
        req.session = {

            set = function(key, value)
                
                local s = Session:start(config)
                --s.secret = config.secret
                s.data[key] = value
                
                s.cookie.persistent = true
                s.cookie.lifetime = config.timeout
                s.expires = ngx_time() + config.timeout
                s:save()
               -- ngx.log(ngx.ERR, "session_data:", cjson.encode(s.storage)," config.s:", config.storage )

            end,
            
            refresh = function() 
                local s = Session:start(config)
                s.cookie.persistent = true
                s.expires = ngx_time() + config.timeout
                s.cookie.lifetime = config.timeout
                s:save() 
            end,
            
            get = function(key)
            
                local s = Session:open(config)
                s.cookie.persistent = true
                s.cookie.lifetime = config.timeout
                s.expires = ngx_time() + config.timeout
                  -- ngx.log(ngx.ERR, "session_data:", cjson.encode(s.storage)," config.s:", config.storage )
                return s.data[key]
            end,

            destroy = function()
                local s = Session.start(config)
                s:destroy()
            end
        }

        local e, ok
        ok = xpcall(function() 
            if config and config.refresh_cookie == true then
                req.session.refresh()
            end
        end, function()
            e = traceback()
        end)

        if not ok then
            ngx.log(ngx.ERR, "[session middleware]refresh cookie error, ", e)
        end

        next()
    end
end

return session_middleware
