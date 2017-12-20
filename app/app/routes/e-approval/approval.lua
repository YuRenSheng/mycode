local cjson = require("cjson")
local utils = require("app.libs.utils")
local approve = require("app.routes.e-approval.approval_func")
local lor = require("lor.index")
local approval_model = require("app.model.approval_lm")
local emp_model = require("app.model.emp")

local approval_router = lor:Router()

approval_router:get("",function(req,res,next)
	local src = req.query.src
	local form_id = req.query.form_id

	if utils.chk_is_null(src,form_id) or src ~= "reject" then
		return res:json({
			rv = 500,
			msg = "src和form_id不能为空，且src必须等于reject."
		})
	end


	local result, err = approval_model:query_approval_pre_log_by_id(form_id)
	if not result or err then
		return res:json({
			rv = 501,
			msg = "没有历史信息."
		})
	end

	return res:json({
		rv = 200,
		msg = "success",
		data = result
	})
end)

approval_router:get("/:form_id",function(req,res,next)
	--form_info
	local form_id = req.params.form_id
	if not form_id or form_id == "" then
		return res:json({
			rv = 500,
			msg = "form_id不能为空."
		})
	end

	-- res:set_header('If-Modified-Since','0');
	-- res:set_header('Cache-Control','no-cache');

	ngx.log(ngx.ERR,res.locals.emp_no)
	ngx.log(ngx.ERR,form_id)
	local emp_no = res.locals.emp_no --当前登录人
	local approve_person_no --当前审核人
	local promoter  -- 承办人
	local approve_person_log_no = {} --历史审核人

	--找表单信息
	local apply_info ,err = approval_model:query_apply_info_by_id(form_id)
	if not apply_info or err then
		return res:json({
			rv = 501,
			msg = "没有表单信息."
		})
	end
	promoter = apply_info.promoter

	-- 找当前审核人信息
	local approve_person,err = approval_model:query_approve_person_by_id(form_id)
	if approve_person and not err then
		approve_person_no = approve_person.approve_empno or nil
	end

	--找历史审核人信息
	local approval_log ,err = approval_model:query_apply_log_by_id(form_id)
	if approval_log and not err then
		for i=1,#approval_log,1 do
			if approval_log[i].order_item ~= 0 then
				table.insert(approve_person_log_no,approval_log[i].approve_empno)
			end
		end
	end
--ngx.log(ngx.ERR,cjson.encode(approve_person_log_no))
--ngx.log(ngx.ERR,"status: ",status,", emp_no: ",emp_no," ,promoter: ",promoter)

	local status = apply_info.status
	-- status = 3
	if status == 3 then
		--查看页面
		if utils.str_in_table(emp_no,approve_person_log_no) or emp_no == promoter then

			return res:render("review_form",{form_id = form_id,
											emp_no = emp_no})
		end
	end

	--申请中
	if status == 1 then
		-- 登录人为承办人
		if emp_no == promoter then
			--可修改的查看页面
			return res:render("edit_form",{form_id = form_id,
											emp_no = emp_no})
		end

		-- 登录人在历史审核人中
		if utils.str_in_table(emp_no,approve_person_log_no) then
			--查看页面
			return res:render("review_form",{form_id = form_id,
											emp_no = emp_no})
		end
	end

	--审核中
	if status == 2 then
		--登录人为当前审核人
		if emp_no == approve_person_no then
			--审核页面
			-- return res:render("layout")
			return res:render("sign_form",{form_id = form_id,
											emp_no = emp_no})
		end

		--登录人为历史签核人或者承办人
		if utils.str_in_table(emp_no,approve_person_log_no) or emp_no == promoter then
			--查看页面
			return res:render("review_form",{form_id = form_id,
											emp_no = emp_no})
		end
	end

	-- 登录人什么都不是
	return res:json({
		rv = 502,
		msg = "您没有该表单操作权限."
	})
end)

approval_router:post("",function(req,res,next)
	local src = req.body.src
	local data = req.body.data

	local src_table = {"pass","refuse"}
	if utils.chk_is_null(src,data) or  not utils.str_in_table(src,src_table) then
		return res:json({
			rv = 541,
			msg = "src和data不能为空，且src必须在pass,refuse内"
		})
	end

	local form_id = data.form_id
	local emp_no = data.emp_no

	if utils.chk_is_null(form_id,emp_no) or
	   not utils.str_in_table(src,src_table) then
		return res:json({
			rv = 542,
			msg = "data必须包含form_id ,emp_no."
		})
	end

	local user =  res.locals
    ngx.log(ngx.ERR,cjson.encode(user))
    if not user then
    	return res:json({
			rv = 543,
			msg = "not user data!"
		})
    end

	local code,ret,msg = approve.submit_confirm(user,src,data)

	return res:json({
		rv = code,
		msg = msg,
		data = ret
	})
end)

return approval_router
