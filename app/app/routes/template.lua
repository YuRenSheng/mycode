local cjson = require("cjson")
local utils = require("app.libs.utils")
local config = require("app.config.config")
local lor = require("lor.index")
local template_model = require("app.model.template")
local src_model = require("app.model.src")
local dim = config.time_dimension 

local template_router = lor:Router()

--增删改公共参数
local check_param = function(req,res,next)
	local act = req.body.act
	local data = req.body.data
	local tb = {"add","del","upd"}

	local user = res.locals --req.session.get("user")
	local author = user.emp_no

	if not act or not utils.str_in_table(act,tb) or not data or data == "" then 
		return res:json({
			rv = 500,
			msg = "act与data不能为空，且act必须在".. cjson.encode(tb) .."内."
		})
	end
	next()
end

--[[ 新增模板  curl -X POST --data '{"act":"add",
    "data":{"name":"shenme","src":"xixis",
    	"content":{"group":"xiaoyu","id":"1"}}}' 
    -H 'Content-type: application/json' http://127.0.0.1:8888/template
--]]
local add_template = function(author,act,data ,req,res,next)
	if act == "add" then
		local name = data.name
		local content = data.content
		local src = data.src

		content = cjson.encode(content) or content
		
		if utils.chk_is_null(name,content,src) then 
			return res:json({
				rv = 501,
				msg = "新增模板必须要有模板名称name,模板内容content,数据源src."
			})
		end

		local result, err = template_model:query_name_exsist(name)
		if result and not err then 
			return res:json({
				rv = 502,
				msg = "该模板名称已经存在，不允许重复."
			})
		end

		local result,err = src_model:query_exists_by_src(src)
		if not result or err then 
			return res:json({
				rv = 530,
				msg = "src无效."
			})
		end

		local result, err = template_model:add_template(name,content,author,src)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = {name = name,
						content = content,
						id = result,
						author = author}
			})
		end

		return res:json({
			rv = 503,
			msg = "模板保存失败."
		})
	end
	next()
end

--[[ 删除模板  curl -X POST --data '{"act":"del","data":{"id":4}' 
	-H 'Content-type: application/json' http://127.0.0.1:8888/template
--]]
local del_template = function(author,act,data ,req,res,next)
	if act == "del" then
		local id = data.id

		if not id or id == "" then 
			return res:json({
				rv = 504,
				msg = "删除模板时，请提供模板id."
			})
		end

		local result, err = template_model:query_id_exsist(id)
		if not result or err then 
			return res:json({
				rv = 505,
				msg = "该模板id不存在,请检查."
			})
		end

		local result ,err = template_model:del_template(id)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = {id = id,
						author = author}
			})
		end

		return res:json({
			rv = 506,
			msg ="删除模板失败."
		})
	end
	next()
end

--[[ 修改模板 curl -X POST --data '{"act":"upd",
	"data":{"id":4,"name":"nicai","content":{"group":"xiaoyu"}}}' 
	-H 'Content-type: application/json' http://127.0.0.1:8888/template
--]]
local upd_template = function(author,act,data ,req,res,next)
	if act == "upd" then
		local id = data.id

		if not id or id == "" then 
			return res:json({
				rv = 507,
				msg = "更新模板，请提供模板id."
			})
		end

		local result, err = template_model:query_id_exsist(id)
		if not result or err then 
			return res:json({
				rv = 508,
				msg = "该模板id不存在,请检查."
			})
		end

		local cnt = 0

	    for k, v in pairs(data) do 
	    	if k ~= "id" then
	    	cnt = cnt + 1 
	    	end 
	    end 

		if  cnt == 0 then
			return res:json({
				rv = 509,
				msg = "更新内容不得为空."
				})
		end

		local match_tb = {['name']='name',['content']='content'}
		local pos_param = ""
		
		for key, val in pairs(data) do
		     	
			local tmp = match_tb[key]
			
			if tmp ~= nil then
	
				if (type(val) == "string") then 
					pos_param = pos_param .. ", " .. tmp .. "= " ..ngx.quote_sql_str(val)
				elseif (type(val) == "table") then
					pos_param = pos_param .. ", " .. tmp .. "= " 
								.. ngx.quote_sql_str(cjson.encode(val))
				else
					pos_param = pos_param .. ", " .. tmp .. "= " .. val
				end

			end
		end

		if (#pos_param == 0) then
			return res:json({
				rv = 510,
				msg = "更新内容未使用指定的键值."
				})
		end
		pos_param = string.sub(pos_param,2)

		local result, err = template_model:upd_template(author,pos_param,id)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = {filter = data,author = author}
			})
		end

		return res:json({
			rv = 511,
			msg = "模板更新失败."
		})
	end
end

template_router:post("",check_param,add_template,del_template,upd_template)

-- 获取下拉框和模板公共参数
local src_param = function(req,res,next)
	local src = req.query.src
	local src_tb = {"src","tem"}

	if not src or not utils.str_in_table(src,src_tb) then 
		return res:json({
			rv = 500,
			msg = "src不能为空，且src必须在".. cjson.encode(src_tb) .."内."
		})
	end
	next()
end

--获取数据源 http://10.132.241.215:8888/template?src=src
local get_datasource = function(src,req,res,next)
	if src == "src" then 
		local result ,err = template_model:query_src_all()
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = result
			})
		end

		return res:json({
			rv = 516,
			msg = "没找到接口数据源."
		})
	end
	next()
end

-- 获取模板	http://10.132.241.215:8888/template?src=tem
local get_template = function(src,req,res,next)
	if src == "tem" then 
		local id = req.query.id

		if not id or id == "" then 
			local result, err = template_model:query_template_all()
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					data = result
				})
			end
			return res:json({
				rv = 513,
				msg = "没有发现模板."
			})
		end

		local result, err = template_model:query_id_exsist(id)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = result
			})
		end
		return res:json({
			rv = 514,
			msg = "没有发现这个id的模板."
		})
		
	end
end

template_router:get("", src_param, get_datasource, get_template)

return template_router