local pairs = pairs
local ipairs = ipairs
local supper = string.upper
local cjson = require("cjson")
local lor = require("lor.index")
local utils = require("app.libs.utils")

local approval_templates = require("app.model.approval_templates_if")

local approval_templates_router = lor:Router()

approval_templates_router:get("",function(req,res,nest)

	local function checkdata(table_data) --判断输出的table是否为空来确定抛出的内容
		if table_data ~= nil then
			return table_data
		else
			return ngx.null
		end
	end

	local user = res.locals
	local promoter = utils.trim(supper(user.emp_no))

	local src = req.query.src
	local typeid = tonumber(req.query.typeid)
	local templates_id = tonumber(req.query.templates_id)
	local templates_name = req.query.templates_name

	local src_tb = {"query","query_detail","query_exists"}

	if not utils.str_in_table(src,src_tb) then
		return res:json({
				rv = 501,
				msg = "請檢查訪問的鏈接地址！"
			})
	end

	if src == "query" then
		if utils.chk_is_null(promoter) then
			return res:json({
				rv = 502,
				msg = "用戶未登錄！"
			})
		end

		if utils.chk_is_null(typeid) then
			return res:json({
				rv = 502,
				msg = "類型參數不正確！"
			})
		end

		local result,err = approval_templates:find_templates(promoter,typeid)
		return res:json({
				rv = 200,
				data = checkdata(result),
				msg = "查詢模板列表成功！"
			})
	end

	if src == "query_detail" then
		if utils.chk_is_null(templates_id) then
			return res:json({
				rv = 502,
				msg = "未獲取到模板！"
			})
		end

		local result,err = approval_templates:find_templates_detail(templates_id)
		return res:json({
				rv = 200,
				data = checkdata(result),
				msg = "查詢模板詳情成功！"
			})
	end

	if src == "query_exists" then
		if utils.chk_is_null(templates_name) then
			return res:json({
				rv = 502,
				msg = "模板名不能為空！"
			})
		end

		local success = approval_templates:find_templates_exists(
																					templates_name,promoter,typeid)
		if not success then
			return res:json({
				rv = 200,
				msg = "該模板名可用!"
			})
		else
			return res:json({
				rv = 503,
				msg = "該模板名已存在!"
			})
		end
	end
end)

approval_templates_router:post("",function(req,res,nest)

	local user = res.locals
	local promoter = utils.trim(supper(user.emp_no))

	local action = req.body.action
	local templates_id = tonumber(req.body.data.templates_id)
	local templates_name = req.body.data.templates_name
	local typeid = tonumber(req.body.data.typeid)
	local approval_flow = req.body.data.approval_flow

	if utils.chk_is_null(promoter) then
		return res:json({
			rv = 501,
			msg = "請檢查用戶是否登錄！"
		})
	end

	local action_tb = {"insert_templates","update_templates","delete_templates"}

	if not utils.str_in_table(action,action_tb) then
		return res:json({
				rv = 501,
				msg = "請檢查訪問的鏈接地址！"
			})
	end

	if action == "insert_templates" then
		if #approval_flow == 0 then
			return res:json({
				rv = 502,
				msg = "參數不完整！"
			})
		end

		for i = 1,#approval_flow do
			if utils.chk_is_null(tonumber(approval_flow[i].order_item),
								utils.trim(supper(approval_flow[i].approve_empno)),
								approval_flow[i].approve_empname,
								approval_flow[i].approve_dept,approval_flow[i].approve_email,
								tonumber(approval_flow[i].approval_activity_id)) then
					return res:json({
						rv = 502,
						msg = "簽核流程存在為空字段!"
					})
			end
		end

		if utils.chk_is_null(templates_name,typeid) then
			return res:json({
				rv = 502,
				msg = "模板名或模板类型为空!"
			})
		end

		local result,err = approval_templates:write_templates(
																				templates_name,promoter,typeid)

		if result ~= nil then
			local parent_id = tonumber(result)
			for i = 1,#approval_flow do
				local result1,err = approval_templates:write_templates_detail(
						parent_id,tonumber(approval_flow[i].order_item),
						utils.trim(supper(approval_flow[i].approve_empno)),
						approval_flow[i].approve_empname,
						approval_flow[i].approve_dept,approval_flow[i].approve_email,
						tonumber(approval_flow[i].approval_activity_id))
			end
			return res:json({
				rv = 200,
				msg = "寫入模板成功！"
			})
		else
			return res:json({
				rv = 503,
				msg = "寫入失敗！"
			})
		end
	end

	if action == "update_templates" then
		if #approval_flow == 0 then
			return res:json({
				rv = 502,
				msg = "參數不完整！"
			})
		end

		for i = 1,#approval_flow do
			if utils.chk_is_null(tonumber(approval_flow[i].order_item),
								utils.trim(supper(approval_flow[i].approve_empno)),
								approval_flow[i].approve_empname,
								approval_flow[i].approve_dept,approval_flow[i].approve_email,
								tonumber(approval_flow[i].approval_activity_id)) then
					return res:json({
						rv = 502,
						msg = "簽核流程存在為空字段!"
					})
			end
		end

		if utils.chk_is_null(templates_name,typeid,templates_id) then
			return res:json({
				rv = 502,
				msg = "模板id,模板名或模板类型为空!"
			})
		end

		local result,err = approval_templates:alter_templates(
																						templates_name,typeid,templates_id)
		local result1,err = approval_templates:delete_templates_detail(templates_id)

		if result then
			for i = 1,#approval_flow do
				local result1,err = approval_templates:write_templates_detail(
						templates_id,tonumber(approval_flow[i].order_item),
						utils.trim(supper(approval_flow[i].approve_empno)),
						approval_flow[i].approve_empname,
						approval_flow[i].approve_dept,approval_flow[i].approve_email,
						tonumber(approval_flow[i].approval_activity_id))
			end
			return res:json({
				rv = 200,
				msg = "修改模板成功!"
			})
		else
			return res:json({
				rv = 503,
				msg = "修改失敗!"
			})
		end
	end

	if action == "delete_templates" then
		local result,err = approval_templates:delete_templates(templates_id)
		local result1,err = approval_templates:delete_templates_detail(templates_id)

		if result and result1 then
			return res:json({
				rv = 200,
				msg = "刪除模板成功！"
			})
		else
			return res:json({
				rv = 503,
				msg = "刪除失敗！"
			})
		end
	end
end)

return approval_templates_router
