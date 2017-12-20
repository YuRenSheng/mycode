--- 业务路由管理
local userRouter = require("app.routes.user")
local authRouter = require("app.routes.auth")
local layoutRouter = require("app.routes.layout")
local deptRouter = require("app.routes.dept")
--local attendantRouter = require("app.routes.attendance")
local settingsRouter = require("app.routes.settings")
local statRouter = require("app.routes.stat")
local resetpwRouter = require("app.routes.resetpw")
local templateRouter = require("app.routes.template")
local app_authRouter = require("app.routes.app.v1.auth")
local app_activityRouter = require("app.routes.app.v1.activity")
local app_employeeRouter = require("app.routes.app.v1.employee")
local app_positionRouter = require("app.routes.app.v1.position")
local app_versionRouter = require("app.routes.app.v1.version_control")
local app_navRouter = require("app.routes.app.v1.nav")

local approval_listdRouter = require("app.routes.e-approval.approval_list_detail")
local approval_requestRouter = require("app.routes.e-approval.approval_request")

local approval_Router = require("app.routes.e-approval.approval")

local approval_listRouter = require("app.routes.e-approval.approval_list")
local approval_templatesRouter = require("app.routes.e-approval.approval_templates")
local approval_basicinfoRouter = require("app.routes.e-approval.approval_basic")
local web_employeeRouter = require("app.routes.employee")


local uploadRouter = require("app.routes.upload")
local errorRouter = require("app.routes.error")
local menu_config = require("app.config.config").menu

local test = require("app.model.test")
local cjson = require("cjson")

return function(app)

    local options_func = function(req,res,next)
     	return res:json({
                rv = 200,
                msg = "success"
            })
      end

    app:options("/organization",options_func);
    app:options("/layout",options_func);
    app:options("/layout/position",options_func);
    app:options("/layout/file",options_func);
    app:options("/layout/place",options_func);
    app:options("/stat",options_func);
    app:options("/stat/dept",options_func);
    app:options("/approval/request/upload",options_func);
    app:options("/approval/request",options_func);
    app:options("/approval",options_func);
    app:options("/approval/list/detail",options_func);
    app:options("/approval/basicinfo",options_func);
    app:options("/approval/templates",options_func);

    app:use("/auth", authRouter())  -- 登录/注册
    app:use("/layout",layoutRouter()) -- 部门分布页面
    app:use("/organization",deptRouter())-- 组织架构
    app:use("/stat",statRouter())--概况/组织分布

    app:use("/resetpw",resetpwRouter())--重置密码
    app:use("/settings",settingsRouter()) -- 設置頁面
    app:use("/template",templateRouter())--数据展示模板制定

    app:use("/app/v1/auth",app_authRouter()) -- app登录
    app:use("/app/v1/employee",app_employeeRouter())
    app:use("/app/v1/activity",app_activityRouter())-- 前台点到
    app:use("/app/v1/position",app_positionRouter())
    app:use("/app/v1/version",app_versionRouter())
    app:use("/app/v1/nav",app_navRouter())--app導航

    app:use("/approval/list",approval_listRouter())
    app:use("/approval/basicinfo",approval_basicinfoRouter())
    app:use("/approval/templates",approval_templatesRouter())
    app:use("/approval/list/detail",approval_listdRouter())
    app:use("/approval",approval_Router())
    app:use("/approval/request",approval_requestRouter())
    app:use("/employee",web_employeeRouter())

    app:use("/upload", uploadRouter())

    app:get("/uploadtest",function(req, res, next)
        res:render("uploadtest")
    end )

    -- simple router: render html, visit "/" or "/?name=foo&desc=bar
    app:get("/", function(req, res, next)

        local user = req.session.get("user")

        if not user then
            res:redirect("/auth/login")
        end

        local userid = user.userid
        local current_index = user.current_index

        if not userid then
            res:redirect("/auth/login")
        end

        -- 判断是否点击侧边菜单
        local page_id = req.query.page_id
        local group_id = "ssas03"
        local page_code = "welcome"
        local page_name = "概况"
        local sub_page_name = nil
        local is_exsist = not (page_id == nil or page_id == "")

        if not is_exsist then
            local current_id = user.current_id;
            is_exsist = not (current_id == nil or current_id == "")
            page_id = is_exsist and current_id or nil;
        end

        if is_exsist then
            -- 假装config取值
            for _,v1 in ipairs(menu_config.group) do
                if v1.id == page_id then
                    page_code = v1.page
                    page_name = v1.name
                    group_id = v1.id
                elseif v1.items then
                    for _,v2 in ipairs(v1.items) do
                        if v2.id == page_id then
                            page_code = v2.page
                            page_name = v1.name
                            sub_page_name = v2.name
                            group_id = v1.id
                        end
                    end
                end
            end
         -- session 中没有页面ID时，获取当前页面id，并重新存取session
        elseif not current_index then
            page_id = "ssas03"
        end

        user.current_id = page_id
        user.current_index = page_code
        user.creat_time = os.date("%Y-%m-%d %H:%M:%S")

        req.session.set("user",user)

        local Title = menu_config.project
    -- session 中有页面时
        local data = {menu = menu_config,
                      group_id = group_id,
                      page_id = page_id,
                      page_name = page_name,
                      Title = Title..'-'.. page_name ..
                             (sub_page_name and '-'..sub_page_name or ''),
                      sub_page_name = sub_page_name
        }

        --如果找不到对应的渲染页面,就默认用dev.html
        if (user.current_index ==nil or user.current_index =="") then
            user.current_index = "dev"
        end

        res:render(user.current_index, data)
    end)

    -- group router: 对以`/user`开始的请求做过滤处理
    app:use("/user", userRouter())
end
