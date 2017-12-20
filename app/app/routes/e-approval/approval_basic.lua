local pairs = pairs
local ipairs = ipairs
local smatch = string.match
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local sfind = string.find
local supper = string.upper
local cjson = require("cjson")
local lor = require("lor.index")
local utils = require("app.libs.utils")
local pwd_secret = require("app.config.config").pwd_secret
local approval_basic = require("app.model.approval_basic_if")
local approval_user = require("app.model.user")
local emp_model = require("app.model.emp")

local approval_basic_router = lor:Router()

approval_basic_router:get("",function(req,res,next)

	local function checkdata(table_data)
		if table_data ~= nil then
			return table_data
		else
			return ngx.null
		end
	end

	local src = req.query.src
	local emp_no = utils.trim(supper(req.query.emp_no))

	if src ~= "query_info" then
		return res:json({
				msg = "請檢查訪問的鏈接地址！",
				rv = 501
			})
	end

	if src == "query_info" then
		if utils.chk_is_null(emp_no) then
			return res:json({
					msg = "傳入工號為空！",
					rv = 502
				})
		else
			local basic_info,err = approval_basic:check_empno(emp_no)
			return res:json({
					msg = "查詢工號信息成功！",
					rv = 200,
					data = checkdata(basic_info)
				})
		end
	end
end)


approval_basic_router:post("",function(req,res,next)

	local action = req.body.action
	local emp_no = utils.trim(supper(req.body.data.emp_no))
	local emp_name = req.body.data.emp_name
	local dept_code = req.body.data.dept_code
	local dept_name = req.body.data.dept_name
	local phone = req.body.data.phone
	local email = req.body.data.email
	local position = req.body.data.position
	local note = req.body.data.note
	local password = string.reverse(emp_no)

	if action ~= "insert_info" then
		return res:json({
				msg = "請檢查訪問的鏈接地址！",
				rv = 501
			})
	end

	if utils.chk_is_null(note) then
		note = ""
	end

	if action == "insert_info" then
		if utils.chk_is_null(emp_no,emp_name,dept_code,dept_name,phone,position,email)
		or not smatch(email,"@") then
			return res:json({
					msg = "傳入的參數錯誤！",
					rv = 502
				})
		end
		--检查工号和邮箱是否重复
		local result,err = approval_basic:check_empno(emp_no) -- 只检查主管表
		local result1,err = approval_basic:isexist_email(email)

		if result1 ~= nil then
			return res:json({
					msg = "該郵箱已存在！",
					rv = 503,
					data = ngx.null
				})
		end

		if result ~= nil then
			return res:json({
					msg = "該主管工號已存在！",
					rv = 503,
					data = ngx.null
				})
		end

		password = utils.encode(password .. "#" .. pwd_secret)
		local pos = sfind(email,"@",1)
		local login = ssub(email,1,pos-1)..ssub(password,2,6)
		local basic_info = approval_basic:write_basicinfo(emp_no,emp_name,
							dept_code,dept_name,phone,email,position,note)

		--只检查工号是否已注册，没注册自动注册？
		local result,err = approval_user:query_by_username(emp_no)

		if  not result and not err then
			local newuser,err1 = approval_basic:new(emp_name,login,password,email)
			local newuser_emp,err2 = approval_user:new_user_emp_relation(login,emp_no)
			local newuser_active,err3 = approval_user:update_user_active(login)
		else
			local update_email,err = approval_basic:update_email(email,emp_no)
		end

 		--判断工号是否存在,不在，插入emp_dept_extra
		local result,err = approval_user:query_dept_by_emp(emp_no)

		if not result and not err then
			local newemp,err4 = emp_model:add_approval_person_to_emp_extra(emp_no,
			                     emp_name,dept_code,position)
		end
		return res:json({
				msg = "數據寫入成功！",
				rv = 200
			})
	end
end)

return approval_basic_router
