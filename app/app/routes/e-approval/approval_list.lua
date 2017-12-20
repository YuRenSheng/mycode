local pairs = pairs
local ssub = string.sub
local supper = string.upper
local mail = require("app.libs.mail")
local cjson = require("cjson")
local lor = require("lor.index")
local utils = require("app.libs.utils")

local approval_list = require("app.model.approval_list_if")

local approval_list_router = lor:Router()

approval_list_router:get("",function(req,res,nest)

	local DEFAULT_LENGTH = 15 --默认单页显示条目长度
	local PAPER_COUNT = 1 --默认显示页数为1页
	local PAGE_LENGTH --自定义的单页条目长度

	local function checknum(num) --计算数据的总页数
		local n1,n2 = math.modf(num / PAGE_LENGTH)
			if n2 > 0 then
				PAPER_COUNT = n1 + 1
			end

			if n2 == 0 then
				PAPER_COUNT = n1
			end
			return PAPER_COUNT
	end

	local function checkdata(table_data) --判断输出的table是否为空来确定抛出的内容
		if table_data ~= nil then
			return table_data
		else
			return ngx.null
		end
	end

	local user = res.locals
	local username = utils.trim(supper(user.emp_no)) --工号

	local src = req.query.src --资源（接口）
	local code = req.query.code --单号
	local start_time = req.query.start_time
	local end_time = req.query.end_time --筛选条件的结束时间
	local condition = req.query.condition -- 查询条件
	local index = req.query.index --前端发送的页码
	PAGE_LENGTH = req.query.lengh --页码定义的长度
	local form_id = tonumber(req.query.form_id) -- 需要查看流程的表单的id

	if utils.chk_is_null(username) then
		return res:json({
				rv = 501,
				msg = "請檢查用戶是否登錄！"
			})
	end
	--如果没有给定义的单页条目长度就取默认的长度
	if utils.chk_is_null(PAGE_LENGTH) then
		PAGE_LENGTH = DEFAULT_LENGTH
	else
		PAGE_LENGTH = tonumber(PAGE_LENGTH)
	end

	if utils.chk_is_null(index) then  --如果没有给页码就默认选择第1页
		index = 1
	end

	local src_tb = {"todo","finish","my","query","urging"}

	if not utils.str_in_table(src,src_tb) then
		return res:json({
				rv = 501,
				msg = "請檢查訪問的鏈接地址！"
			})
	end

	if src == "finish" then  --已办任务接口
		if utils.chk_is_null(code) and
		not (utils.chk_is_null(start_time) == utils.chk_is_null(end_time)) then
			return res:json({
					rv = 502,
					msg = "請提供完整的日期參數進行查詢！"
				})
		end

		if utils.chk_is_null(code) and utils.chk_is_null(start_time) and
			 utils.chk_is_null(end_time) and utils.chk_is_null(condition) then
			-- local finish_count,err = approval_list:dynamic_find_list_count(1,username)
			-- local paper_data,err = approval_list:dynamic_find_list(1,username,
			-- 											PAGE_LENGTH,index - 1)
			-- return res:json({
			-- 		rv = 200,
			-- 		msg = "查詢所有已辦任務成功！",
			-- 		data = checkdata(paper_data),
			-- 		paper_count = checknum(finish_count[1].cnt)
			-- 	})
			local end_time = os.date("%Y-%m-%d")
			local start_time = os.date("%Y-%m-%d",os.time() - (86400 * 30))
			local finish_count,err = approval_list:dynamic_find_list_count(2,username,
															start_time,end_time)
			local paper_data,err = approval_list:dynamic_find_list(3,username,
														start_time,end_time,PAGE_LENGTH,index - 1)
			return res:json({
					rv = 200,
					msg = "默认查詢已辦任務成功！",
					data = checkdata(paper_data),
					paper_count = checknum(finish_count[1].cnt)
				})
		end

		if utils.chk_is_null(code) and not utils.chk_is_null(start_time) and
			 not utils.chk_is_null(end_time) and utils.chk_is_null(condition) then
			local finish_count,err = approval_list:dynamic_find_list_count(2,username,
															start_time,end_time)
			local paper_data,err = approval_list:dynamic_find_list(3,username,
														start_time,end_time,PAGE_LENGTH,index - 1)
			return res:json({
					rv = 200,
					msg = "根據日期查詢已辦任務成功！",
					data = checkdata(paper_data),
					paper_count = checknum(finish_count[1].cnt)
				})
		end

		if utils.chk_is_null(code) and utils.chk_is_null(start_time) and
			 utils.chk_is_null(end_time) and not utils.chk_is_null(condition) then
				local finish_count,err = approval_list:dynamic_find_list_count(3,username,condition)
	 			local paper_data,err = approval_list:dynamic_find_list(4,username,
	 														condition,PAGE_LENGTH,index - 1)
	 			return res:json({
	 					rv = 200,
	 					msg = "根據条件查詢已辦任務成功！",
	 					data = checkdata(paper_data),
	 					paper_count = checknum(finish_count[1].cnt)
	 				})
		end

		if utils.chk_is_null(code) and not utils.chk_is_null(start_time) and
			 not utils.chk_is_null(end_time) and not utils.chk_is_null(condition) then
				 local finish_count,err = approval_list:dynamic_find_list_count(4,username,
				 										start_time,end_time,condition)
	 			local paper_data,err = approval_list:dynamic_find_list(5,username,
	 										condition,start_time,end_time,PAGE_LENGTH,index - 1)
	 			return res:json({
	 					rv = 200,
	 					msg = "根據日期和条件查詢已辦任務成功！",
	 					data = checkdata(paper_data),
	 					paper_count = checknum(finish_count[1].cnt)
	 				})
		end

		if not utils.chk_is_null(code) then
			local paper_data,err = approval_list:dynamic_find_list(2,username,code)
			return res:json({
					rv = 200,
					msg = "根據單號查詢已辦任務成功！",
					data = checkdata(paper_data)
				})
		end
	end

	if src == "todo" then  --待办任务接口
		local result,err = approval_list:dynamic_find_list(11,username)
		return res:json({
				rv = 200,
				msg = "查詢所有待辦任務成功！",
				data = checkdata(result)
			})
	end

	if src == "my" then  --我提的单接口
		if utils.chk_is_null(code) and utils.chk_is_null(start_time) and
			 utils.chk_is_null(end_time) and utils.chk_is_null(condition) then
			return res:json({
					rv = 502,
					msg = "請提供篩選條件進行查詢！"
				})
		end

		if utils.chk_is_null(code) and
		not (utils.chk_is_null(start_time) == utils.chk_is_null(end_time)) then
			return res:json({
					rv = 502,
					msg = "請提供完整的日期參數進行查詢！"
				})
		end

		if utils.chk_is_null(code) and not utils.chk_is_null(start_time) and
		not utils.chk_is_null(end_time) and utils.chk_is_null(condition) then
			local myrequest_count,err = approval_list:dynamic_find_list_count(6,username,start_time,end_time)
			local paper_data,err = approval_list:dynamic_find_list(8,username,
										start_time,end_time,PAGE_LENGTH,index - 1)
			return res:json({
					rv = 200,
					msg = "根據日期查詢我提的單成功",
					data = checkdata(paper_data),
					paper_count = checknum(myrequest_count[1].cnt)
				})
		end

		if utils.chk_is_null(code) and utils.chk_is_null(start_time) and
		utils.chk_is_null(end_time) and not utils.chk_is_null(condition) then
			local myrequest_count,err = approval_list:dynamic_find_list_count(7,username,condition)
			local paper_data,err = approval_list:dynamic_find_list(9,username,
														condition,PAGE_LENGTH,index - 1)
			return res:json({
					rv = 200,
					msg = "模糊查詢我提的單成功",
					data = checkdata(paper_data),
					paper_count = checknum(myrequest_count[1].cnt)
				})
		end

		if utils.chk_is_null(code) and not utils.chk_is_null(start_time) and
		not utils.chk_is_null(end_time) and not utils.chk_is_null(condition) then
			local myrequest_count,err = approval_list:dynamic_find_list_count(8,username,
															start_time,end_time,condition)
			local paper_data,err = approval_list:dynamic_find_list(10,username,
										start_time,end_time,condition,PAGE_LENGTH,index - 1)
			return res:json({
					rv = 200,
					msg = "根據日期条件查詢我提的單成功",
					data = checkdata(paper_data),
					paper_count = checknum(myrequest_count[1].cnt)
				})
		end

		if not utils.chk_is_null(code) then
			local paper_data,err = approval_list:dynamic_find_list(7,username,code)
			return res:json({
					rv = 200,
					msg = "根據單號查詢我提的單成功",
					data = checkdata(paper_data)
				})
		end
	end

	if src == "query" then --查询签核进度
		if utils.chk_is_null(form_id) then
			return res:json({
				rv = 502,
				msg = "查詢的表單的id不能為空!"
			})
		end

		local approval_flow,err = approval_list:query_approval_flow(form_id)
		local approval_history,err1 = approval_list:query_approval_history(form_id)
		if not approval_flow or err then
			return res:json({
				rv = 503,
				msg = "該表單不存在簽核流程!"
			})
		end
		if not approval_history or err1 then
			return res:json({
				rv = 503,
				msg = "該表單不存在簽核歷史!"
			})
		end

		return res:json({
			rv = 200,
			approval_flow = approval_flow,
			approval_history = approval_history,
			msg = "查詢簽核流程成功!"
		})
	end

	if src == "urging" then
		local allow_urging = false
		if utils.chk_is_null(form_id) then
			return res:json({
				rv = 502,
				msg = "需要跟催的表單的id不能為空!"
			})
		end

		local form,err = approval_list:query_approval_form(form_id)
		if not form or err then
			return res:json({
				rv = 503,
				msg = "沒有該表單的信息!"
			})
		end

		local process_now = form[1].process_now
		if process_now <= 0 then
			return res:json({
				rv = 503,
				msg = "該表單的狀態不是審核中!"
			})
		end

		local approval_history,err = approval_list:query_approval_history(form_id)
		if not approval_history or err then
			return res:json({
				rv = 503,
				msg = "該表單沒有簽核歷史!"
			})
		end

		local approval_flow,err = approval_list:query_approval_flow(form_id)
		if not approval_flow or err then
			return res:json({
				rv = 503,
				msg = "該表單沒有簽核流程!"
			})
		end

		local process_now_no = ""
		local process_now_name = ""
		for i = 1,#approval_flow do
			if process_now == approval_flow[i].order_item then
				process_now_no = approval_flow[i].approve_empno
				process_now_name = approval_flow[i].approve_empname
			end
		end
		ngx.log(ngx.ERR,"---------------process_now_no:"..process_now_no)
		ngx.log(ngx.ERR,"---------------process_now_name:"..process_now_name)

		local update_time = approval_history[#approval_history].update_at
		ngx.log(ngx.ERR,"---------------update_time:"..update_time)
		local last_time = os.time({year = ssub(update_time,1,4),
															 month = ssub(update_time,6,7),
															 day = ssub(update_time,9,10),
														 	 hour = ssub(update_time,12,13),
														 	 min = ssub(update_time,15,16),
														 	 sec = ssub(update_time,18,19)})
		ngx.log(ngx.ERR,"---------------last_time:"..last_time)
		local current_time = os.time()
		if current_time - last_time > 7200 then
			allow_urging = true
		else
			allow_urging = false
		end

		if allow_urging then
			ngx.log(ngx.ERR,"---------------form[1].subject:"..form[1].subject)
			-- 生成token，链接地址
			-- local code,mail_token,err = mail.make_approval_token(process_now_no,form_id)
			-- if code ~= 200 then
			-- 	return code,nil,msg
			-- end
			--
			-- local mail_subject = "【電子簽核系統】邀請您審核 "..form[1].subject .."，請查看詳情，謝謝！"
			-- local view ="/mail_template/invitationSignMail.html"
			-- local content_pre = "<p>哎呀，内容加载错误了(〒︿〒)</p> \n "
			-- local func = template.compile(view)
			-- local content = func{
			-- 					approval_name = process_now_name,
			-- 					submit_at = form[1].submit_at,
			-- 					subject = form[1].subject,
			-- 					promoter = promoter_name,
			-- 					approval_time = os.date("%Y-%m-%d %H:%M:%S"),
			-- 					link_auth = self_url .. "/auth/login",
			-- 					link = self_url .. "/approval/"..form_id.."?mail_token="..mail_token
			-- 				} or content_pre
		else
			return res:json({
				rv = 504,
				msg = "距離上次發送送簽郵件未滿兩小時，無法再次推送!"
			})
		end
	end
end)

return approval_list_router
