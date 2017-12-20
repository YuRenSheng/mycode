local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")
local lor = require("lor.index")
local dept_model = require("app.model.dept")
local dept_router = lor:Router()

dept_router:get("",function(req,res,next)
	local src = req.query.src
	local tb = {"org"}
	if not src or src == "" or not utils.str_in_table(src,tb) then 
		return res:json({
			rv = 500,
			msg = "src不得为空,且数据必须在org内."
		})
	end

	if src == "org" then 
		local dept_code = req.query.code

		if not dept_code or dept_code == "" then 
			return res:json({
				rv = 501,
				msg = "部门代码不得为空."
			})
		end

		local result, err = dept_model:query_dept_exists_by_dept(dept_code)
		
		if result and not err then
			local result, err = dept_model:query_org_by_dept(dept_code)
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					data = result
				})
			end
			return res:json({
				rv = 502,
				msg = "查询出错."
			})
		else
			return res:json({
				rv = 503,
				msg = "部门代码不存在."
			})
		end
	end
end)

dept_router:post("",function(req,res,next)
	local src = req.body.act
	local data = req.body.data
	local tb = {"add","upd","del"}
	if not src or src == "" or not data or data =="" 
		or not utils.str_in_table(src,tb) then 
		return res:json({
			rv = 504,
			msg = "act、data不得为空,且act数据必须在add、upd、del内."
		})
	end

	if src == "del" then 
		local dept_code = utils.trim(data.code)
		if not dept_code or dept_code == "" then 
			return res:json({
				rv = 505,
				msg = "删除部门时必须要有部门代码."
			})
		end

		local result, err = dept_model:query_dept_type_by_code(dept_code)
		if result and not err then
			return res:json({
				rv = 506,
				msg = "该部门为基础部门,不允许删除."
			})
		end

		local result, err = dept_model:query_emp_dept_extra_exists(dept_code)
		if result and not err then 
			return res:json({
				rv = 507,
				msg = "该部门正在使用,不能删除."
			})
		end


		local result, err = dept_model:query_min_dept_extra_by_code(dept_code)
		if result and not err then 
			return res:json({
				rv = 508,
				msg = "该部门还有子级部门，请先删除子级部门."
			})
		end

		local result, err = dept_model:del_dept_extra(dept_code)
		if result and not err then 
			local filter = {}
			filter.dept_code = dept_code
			return res:json({
				rv =200, 
				msg = "success",
				data = filter
			})
		else 
			return res:json({
				rv = 509,
				msg = "删除失败."
			})
		end
	end	


	if src == "add" then
		local parent_dept_code = utils.trim(data.parent_code) 
		local dept_code = utils.trim(data.code)
		local dept_name = utils.trim(data.name)
        
		if not parent_dept_code or parent_dept_code == "" 
		    or not dept_code or dept_code == "" 
		    or not dept_name or dept_name == "" then
		  	return res:json({
		  		rv = 510,
		  		msg = "新增部门的父级代码、代码和名称不得为空."
		  	})
		end

		local result,err = dept_model:query_min_dept_by_parent(parent_dept_code)
		local isExist = false

		if result and not err then
			isExist = true
		end

		if isExist == true then
			return res:json({
				rv = 511,
				msg = "当前部门是基础部门,且有子级部门,不能再进行拆分."
			})
		end

		local result, err = dept_model:query_dept_exists_by_dept(dept_code)
		if result and not err then 
			return res:json({
				rv = 512,
				msg = "该部门代码已被使用."
			})
		end 

		local result, err = dept_model:query_dept_exists_by_name(dept_name)
		if result and not err then 
			return res:json({
				rv = 513,
				msg = "该部门名称已被使用."
			})
		end

		local result,err = dept_model:add_extra_dept(parent_dept_code,
													 dept_code,dept_name)
		if  result and not err then 
			local result,err = dept_model:query_add_result(parent_dept_code,
														   dept_code,dept_name)
			if result and not err then
				return res:json({
					rv = 200,
					msg = "success",
					data = result
				})
			end
			return res:json({
				rv = 514,
				msg = "未查询到新建信息."
			})
		else
			return res:json({
				rv = 515,
				msg = "新建部门失败."
			})
		end
	end

	if src == "upd" then

		local dept_code = utils.trim(data.code)
		local dept_name = utils.trim(data.name)
	
		if not dept_code or dept_code == "" or not dept_name or dept_name == "" then 
			return res:json({
				rv = 516,
				msg = "更新部门内容时必须要有部门代码和部门名称."
			})
		end

		local code = utils.trim(data.new_code)
		local name = utils.trim(data.new_name)

		local result, err = dept_model:query_dept_type_by_code(dept_code)
		local isExist = false
		if result and not err then 
			isExist = true
		end

		if isExist == true then 
			return res:json({
				rv = 517,
				msg = "该部门为基础部门,不允许更新."
			})
		end

		local result, err = dept_model:query_emp_dept_extra_exists(dept_code)
		if result and not err then 
			return res:json({
				rv = 518,
				msg = "该部门正在使用,不能更新."
			})
		end

		if code and code ~= "" and #code ~=0 then
			local result, err = dept_model:query_dept_exists_by_dept(code)
			if result and not err then 
				return res:json({
					rv = 519,
					msg = "该部门代码已被使用."
				})
			end 
		end

		if name and name ~= "" and #name ~= 0  then
			local result, err = dept_model:query_dept_exists_by_name(name)
			if result and not err then 
				return res:json({
					rv = 520,
					msg = "该部门名称已被使用."
				})
			end
		end

		local cnt = 0

		for k, v in pairs(data) do 
	    	if k ~= "code" or k ~= "name"  then
	    	cnt = cnt + 1 
	    	end 
	    end 

		if  cnt == 0 then
			return res:json({
				rv = 521,
				msg = "更新内容不得为空."
			})
		end

		local match_tb = {['new_code']='code',['new_name']='name'}
		local param = utils.upd_param(data,match_tb)

		if param == "" then 
			return res:json({
				rv = 522,
				mag = "更新内容未使用指定的键值."
			})
		end

		local result, err = dept_model:upd_dept_extra(dept_code,dept_name,param)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = data
			})
		else
			return res:json({
				rv = 523,
				msg = "更新失败."
			})
		end
	end
end)

return dept_router