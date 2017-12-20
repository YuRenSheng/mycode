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

local position_router =  lor:Router()

position_router:get("",function(req,res,next)
	local dept_code = req.query.dept_code 

	if utils.chk_is_null(dept_code) then 
		return res:json({
			rv = 514,
			msg = "dept_code不能为空."
		})
	end

	local result, err = dept_model:query_dept_exists_by_dept(dept_code)

	if not result or err then 
		return res:json({
			rv = 515,
			msg = "没有这个部门代码."
		})
	end

	local result, err = dept_model:query_position_by_dept_code(dept_code)
	if result and not err then
		return res:json({
			rv=200,
			msg = "success",
			data = result,
			type = "M"
		})
	end

	return res:json({
		rv = 516,
		msg = "没有部门信息."
	})
end)

return position_router