local pairs = pairs
local ipairs = ipairs
local smatch = string.match
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local cjson = require("cjson")
local utils = require("app.libs.utils")
local pwd_secret = require("app.config.config").pwd_secret
local lor = require("lor.index")
local user_model = require("app.model.user")
local emp_model = require("app.model.emp")
local emp_photo_dir = require("app.config.config").emp_photo_config.dir
local emp_photo_path = require("app.config.config").emp_photo_config.path
local emp_photo_default = require("app.config.config").emp_photo_config.default

local auth_router = lor:Router()

auth_router:get("/login", function(req, res, next)
    res:render("login")
end)

auth_router:get("/check",function(req, res, next)
    local src = req.query.src

    if src == "username" then  
        local username = req.query.no
       
        if not username or username == "" then
           return res:json({
                rv = 500,
                msg = "用户名不得为空."
            })
        end 

        local pattern = "^[a-zA-Z][0-9a-zA-Z_]+$"
        local match, err = smatch(username, pattern)
        local username_len = slen(username)

        if username_len<3 or username_len>50 then
            return res:json({
                rv = 501,
                msg = "用户名长度应为3~50位."
            })
        end

        if not match then
           return res:json({
                rv = 502,
                msg = "用户名只能输入字母、下划线、数字，必须以字母开头."
            })
        end

        local result, err = user_model:query_by_username(username)
        local isExist = false
        if result and not err then
            isExist = true
        end

        if isExist == true then
            return res:json({
                rv = 503,
                msg = "用户名已被占用，请修改."
            })
        else 
            return res:json({
                rv = 200,
                msg = "用戶名認證OK."
            })
        end
   elseif src == "employ" then 

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

        if isExist == true then
            return res:json({
                rv = 506,
                msg = "该工号已绑定其他账号."
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

auth_router:get("/sign_up", function(req, res, next)
    res:render("register")
end)

auth_router:post("/sign_up", function(req, res, next)
    local username = utils.trim(req.body.username) 
    local password = utils.trim(req.body.password)
    local emp_no = utils.trim(req.body.employ)
    local email = req.body.email

    if   not username or username == ""
      or not password or password == ""
      or not emp_no   or emp_no == ""
      or not email    or email == "" or not smatch(email,"@") then
        return res:json({
            rv = 509,
            msg = "用户名、密码、工号和邮箱地址不得为空,且邮箱地址必须带@."
        })
    end

    emp_no = supper(emp_no)

    local pattern = "^[a-zA-Z][0-9a-zA-Z_]+$"
    local match, err = smatch(username, pattern)

    local username_len = slen(username)
    local password_len = slen(password)

    if username_len<3 or username_len>50 then
        return res:json({
            rv = 510,
            msg = "用户名长度应为3~50位."
        })
    end

    if not match then
       return res:json({
            rv = 511,
            msg = "用户名只能输入字母、下划线、数字，必须以字母开头."
        })
    end

    local result, err = user_model:query_by_username(username)
    local isExist = false
    if result and not err then
        isExist = true
    end

    if isExist == true then
        return res:json({
            rv = 512,
            msg = "用户名已被占用，请修改."
        })
    end

    --判斷用戶名是否爲工號
    local result ,err = emp_model:query_by_id(username)
    if result and not err then 
        ngx.log(ngx.ERR,result.no,"-------",emp_no)
        if result.no ~= emp_no then
            return res:json({
                rv = 522,
                msg = "注冊的用戶名爲工號，且與注冊工號不一致，請檢查."
            })
        end
    end

    if password_len<6 or password_len>50 then
        return res:json({
            rv = 513,
            msg = "密码长度应为6~50位."
        })
    end

    local result, err = emp_model:query_by_id(emp_no)
    local isExist = false
    if result and not err then
        isExist = true
    end

    if isExist == false then
        return res:json({
            rv = 514,
            msg = "工号不存在，请检查."
        })
    end

    local result, err = emp_model:query_user_by_emp_no(emp_no)
    local isExist = false
    if result and not err then
        isExist = true
    end

    if isExist == true then
        return res:json({
            rv = 515,
            msg = "该工号已绑定其他账号."
        })
    else
        password = utils.encode(password .. "#" .. pwd_secret)

        local result, err = user_model:new(username, password, email)
        if result and not err then 

            local result,err = user_model:new_user_emp_relation(username, emp_no)
            if result and not err then
                return res:json({
                    rv = 200,
                    msg = "注册成功."
                })  
            else
                return res:json({
                    rv = 516,
                    msg = "注册失败."
                }) 
            end
        else 
          return res:json({
                    rv = 517,
                    msg = "注册失败."
                }) 
        end
    end
end)

auth_router:get("/resetpw",function(req,res,next)
    res:render("forgetPw")
end)

auth_router:post("/login", function(req, res, next)
    local username = req.body.username 
    local password = req.body.password

    local result,err = user_model:query_by_username(username)
    local isExist = false
    if result and not err then
        isExist = true
    end

    if isExist == false then
        return res:json({
            rv = 518,
            msg = "用户名未注册."
        })
    end
   
    local result, err = user_model:query_active_by_username(username)
    local isExist = false
    if result and not err then
        isExist = true
    end

    if isExist == false then
        return res:json({
            rv = 519,
            msg = "用户未激活."
        })
    end

    if not username or not password or username == "" or password == "" then
        return res:json({
            rv = 520,
            msg = "用户名和密码不得为空."
        })
    end

    local isExist = false
    local userid = 0
    local emp_no = 0

    password = utils.encode(password .. "#" .. pwd_secret)

    local result, err = user_model:query(username, password)

    local user = {}
    local dept_code,position,emp_name
    if result and not err then
        if result and #result == 1 then
            isExist = true
            user = result[1] 
            userid = user.id
            username = user.login
            emp_no = user.emp_no

            local dept_info, err = user_model:query_dept_by_emp(emp_no)
            if dept_info and not err then 
                dept_code =    dept_info[1].dept_extra_code 
                            or dept_info[1].dept_code 
                position = dept_info[1].position
                emp_name = dept_info[1].name
            else
                return res:json({
                    rv = 522,
                    msg = "该员工无部门信息"
                })
            end
        end
    else
        isExist = false
    end

    if isExist == true then
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
        
        
        req.session.set("user", {
            username = username,
            userid = userid,
            emp_no = emp_no,
            emp_name = emp_name,
            dept_code = dept_code,
            position = position,
            photo = emp_photo,
            create_time = user.create_time or ""
        })
        ngx.log(ngx.ERR,cjson.encode(req.session.get("user")));
        return res:json({
            rv = 200,
            msg = "登录成功."
        })
    else
        return res:json({
            rv = 521,
            msg = "用户名或密码错误，请检查!"
        })
    end
end)


auth_router:get("/logout", function(req, res, next)
    res.locals.login = false
    res.locals.username = ""
    res.locals.emp_no = ""
    res.locals.emp_name = ""
    res.locals.dept_code = ""
    res.locals.photo = ""
    res.locals.userid = 0
    res.locals.current_id = ""  -- current page_id
    res.locals.current_index = 0  -- current page_code
    res.locals.create_time = ""  
    res.locals.position = ""
    req.session.destroy()
    res:redirect("/")
end)

auth_router:get("/success", function(req,res,next)
    res:render("success")
end)


return auth_router

