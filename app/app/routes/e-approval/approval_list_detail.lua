local cjson = require("cjson")
local utils = require("app.libs.utils")
local lor = require("lor.index")
local approval_model = require("app.model.approval_lm")
local attach_model = require("app.model.attachments")

local list_detail_router = lor:Router()

list_detail_router:get("",function(req,res,next)
	local src = req.query.src
	local form_id = req.query.form_id

	if utils.chk_is_null(src,form_id) or src ~= "task" then
		return res:json({
			rv = 500,
			msg = "src和form_id不能为空，且src必须等于task."
		})
	end

	local approval_type,err = approval_model:query_approval_type_by_id(form_id)
	if err then
		return res:json({
			rv = 501,
			msg = "数据库错误："..err
		})
	end

	approval_type = approval_type or ngx.null

	local apply_info ,err = approval_model:query_apply_info_by_id(form_id)
	if err then
		return res:json({
			rv = 502,
			msg = "数据库错误："..err
		})
	end

	apply_info = apply_info or ngx.null

	local approval_person,err = approval_model:query_approve_person_by_id(form_id)
	if err then
		return res:json({
			rv = 503,
			msg = "数据库错误："..err
		})
	end

	approval_person = approval_person or ngx.null

	local attachments,err = attach_model:query_attachment_by_form_id(form_id)
	if err then
		return res:json({
			rv = 504,
			msg = "数据库错误："..err
		})
	end

	attachments = attachments or ngx.null

	local apply_log,err = approval_model:query_apply_log_by_id(form_id)
	if err then
		return res:json({
			rv = 505,
			msg = "数据库错误："..err
		})
	end

	apply_log = apply_log or ngx.null

	local approval_detail,err =
	      approval_model:query_approval_flow_detail_by_id(form_id)
	if err then
		return res:json({
			rv = 506,
			msg = "数据库错误："..err
		})
	end

	approval_detail = approval_detail or ngx.null

	return res:json({
		rv = 200,
		type = "N",
		msg = "success",
		data = {approval_type = approval_type,
				apply_info = apply_info,
				approval_person = approval_person,
				attachments = attachments,
				apply_log = apply_log,
				approval_detail = approval_detail
		}
	})
end)

return list_detail_router
