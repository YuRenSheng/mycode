local cjson = require("cjson")
local supper = string.upper
local utils = require("app.libs.utils")
local lor = require("lor.index")
local mail = require("app.libs.mail")
local approval_model = require("app.model.approval_lm")
local user_model = require("app.model.user")
local emp_model = require("app.model.emp")
local attach_model = require("app.model.attachments")
local approval = require("app.model.approval")
local config = require("app.config.config")
local filedir_temp = config.upload_config.dir
local filepath_temp = config.upload_config.path
local filepath = config.upload_files.path
local filedir = config.upload_files.dir
local template = require ("resty.template")
local self_url = config.server_self.url

local redis = require("resty.redis")
local red = redis:new()
red:set_timeout(config.redis.timeout)
local timeout = config.redis.timeout
local host = config.redis.connect_config.host
local port = config.redis.connect_config.port
local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size = config.redis.pool_config.pool_size

local _M = {}

function _M.submit_confirm(user,submit_code,data)

	local view
	local mail_subject
	local mail_to = nil
	local process_pre_no
	local process_pre_name
	local process_next
	local process_next_no --下一签核人工号
	local process_next_name
	local process_now_name
	local process_now -- 当前签核人
	local process_now_no -- 当前签核人工号
	local log_status
	local msg = "success"
	if type(data) ~= "table" then
		msg = "传入参数为table类型，且长度必须大于0."
		return 501,nil,msg
	end

	local form_id = data.form_id
	local emp_no = data.emp_no
	local back_to_order = data.back_to_order
	local back_to_empno = data.back_to_empno
	local back_to_empname = data.back_to_empname
	local reason = data.reason

	local src_table = {"init","pass","refuse"}
	if utils.chk_is_null(form_id,emp_no,submit_code) or
	   not utils.str_in_table(submit_code,src_table) then
		msg = '传入参数必须有form_id,emp_no,src,且src必须在init,pass,refuse内'
		return 502,nil,msg
	end

	if not user.emp_no or emp_no ~= user.emp_no then
		msg = "登录工号与当前工号不一致，请确认."
		return 503,nil,msg
	end

	local emp_name = user.emp_name
	local position = user.position

	local apply_info,err = approval_model:query_apply_info_by_id(form_id)
	if not apply_info or err then
		msg = "没有找到表单信息，请检查."
		return 504, nil, err or msg
	end

	local subject = "《".. apply_info.subject .. "》"  --郵件內容
	local promoter = apply_info.promoter
	local submit_at = apply_info.submit_at
	local pre_approve_time = apply_info.update_at
	local status = apply_info.status
	local process_pre = apply_info.process_now -- apply_info.process_next or 0 专理
	local process_now = apply_info.process_next -- 副理
	local attach_name --= apply_info.code
	local attachments = {}

  -- 找承办人名字
	local promoter_info,err = emp_model:query_userinfo_by_emp_no(promoter)
	if not promoter_info or err then
		msg = "没有承办人信息,请检查."
		return 505,nil,err or msg
	end
	local promoter_name = promoter_info.name

	if status == 3 then
		msg = "表单已经签核完成，请检查."
		return 506, nil, msg
	end

	if submit_code == "init" then
		if process_pre ~= 0 then
			msg = "表單已處於籤核中狀態，不能修改."
			return 544, nil, msg
		end
		process_pre_no = apply_info.promoter
	else  --找当前签核人工号
		local process_next_info,err =
		      approval_model:query_process_next_by_process(process_pre,form_id)
		if not process_next_info or err then
			msg = "没有找到当前签核人员工号信息."
			return 507,nil,err or msg
		end
		process_pre_no = process_next_info.approve_empno -- 专理工号
	end

	ngx.log(ngx.ERR,emp_no,process_pre_no)
	if emp_no ~= process_pre_no then
		msg = "登录工号与当前审核人工号不一致，请检查."
		return 508,nil,msg
	end

	if process_now ~= -1 then  --找下一个签核人工号
		local process_next_info,err =
		      approval_model:query_process_next_by_process(process_now,form_id)
		if not process_next_info or err then
			msg = "没有找到下一签核人员工号信息."
			return 509,nil,err or msg
		end

		process_now_no = process_next_info.approve_empno -- 副理工号
		process_now_name = process_next_info.approve_empname
	else
		process_now_no = promoter--emp_no
		process_now_name = promoter_name--emp_name
	end

	-- 拒绝时，退件去向为下一个签核人
	if submit_code == "refuse" then
		log_status = 0
		ngx.log(ngx.ERR,back_to_order,back_to_empno,back_to_empname,reason)
		if utils.chk_is_null(back_to_order,back_to_empno,back_to_empname,reason) then
			msg = "退件必须指明退件去向和退件理由."
			return 510,nil,msg
		end
		--process_next = back_to_order
		process_now = back_to_order    --  soujiro
		process_now_no = back_to_empno --  soujiro
		process_now_name = back_to_empname

		-- 退到申请人，申请中，否则，签核中
		if process_now == 0 then
			status = 1  -- 申请中
			process_next = 1
			mail_subject = "【電子簽核系統】"..subject .." 被拒絕，請查看詳情，謝謝！"
			view = "/mail_template/rejectToApplicantMail.html"
		else
			status = 2  -- 签核中
			local process_next_info,err =
			      approval_model:query_process_next_by_process(process_now+1,form_id)
			if not process_next_info or err then
				msg = "没有找到下一签核人员."
				return 511,nil,err or msg
			end
			mail_subject = "【電子簽核系統】請您重新評估審核 "..subject .."，請查看詳情，謝謝！"
			view = "/mail_template/rejectToAuditorMail.html"
			process_next = process_next_info.order_item --专理
		end
	else
		log_status = 1  --默认同意

		if process_now == -1 then  --籤核結束
			status = 3
			process_now = -1
			process_next = -2
			process_next_no = emp_no
			mail_subject = "【電子簽核系統】"..subject .." 審批完成，請查看詳情，謝謝！"
			view = "/mail_template/signFinishMail.html"
			attach_name = apply_info.code..".pdf"

			local is_exsist = false
			--用户上传的附件,名字和大小一样的取其中一个
			local user_attachments,err = attach_model:query_attachment_by_form_id(form_id )
			if user_attachments and not err then 
				ngx.log(ngx.ERR,"-----------",#user_attachments)
				for i=1,#user_attachments,1 do
					if i == #user_attachments then 
						table.insert(attachments,{attach_code = user_attachments[i].digest .. ".pdf",
											  attach_name = user_attachments[i].filename,
											  attach_size = user_attachments[i].filesize})
						break
					end
					
					is_exsist = false
					for j=i+1,#user_attachments,1 do
				
						if user_attachments[i].filename == user_attachments[j].filename and 
							user_attachments[i].filesize == user_attachments[j].filesize  then 

							is_exsist = true
							break
						end
					end

					if is_exsist == false then
						table.insert(attachments,{attach_code = user_attachments[i].digest .. ".pdf",
										  attach_name = user_attachments[i].filename,
										  attach_size = user_attachments[i].filesize})
					end
				end
			end
			ngx.log(ngx.ERR,"-----------",#attachments)

		else   -- 下一個籤核
			mail_subject = "【電子簽核系統】邀請您審核 "..subject .."，請查看詳情，謝謝！"
			view ="/mail_template/invitationSignMail.html"
			local process_next_1 = process_now+1
			-- 没有下下 下一路由信息，默认完结，要发邮件给用户  经理
			local process_info,err =
			      approval_model:query_process_next_by_process(process_next_1,form_id)

			-- 没有经理
			if not process_info or process_info == ngx.null or err then
				process_next = -1
				status = 2
				process_next_no = emp_no
			else
				-- 有下一路由信息，签核中
				process_next = process_info.order_item --process_next_1 经理
				status = 2
				process_next_no = process_info.approve_empno  -- 经理工号
			end
		end
	end

	local reason = reason or "无"

	-- 找到下一个签核人邮件信息
	--退件soujiro pass 副理
	local mail_info,err = user_model:query_mail_by_emp_no(process_now_no)
	if not mail_info or err then
		msg = "没有找到下一签核人员"..process_now_no.."的邮箱信息,请检查."
		return 512,nil,err or msg
    end

    mail_to = mail_info.mail_notification

    -- 生成token，链接地址
    local code,mail_token,err = mail.make_approval_token(process_now_no,form_id)
    if code ~= 200 then
    	return code,nil,msg
    end

    local mail_subject = mail_subject or "【電子簽核系統】任务推送"
	local content_pre = "<p>哎呀，内容加载错误了(〒︿〒)</p> \n "
	local func = template.compile(view)
	local content = func{ approval_name = process_now_name,
						  submit_at = submit_at,
						  approve_reject_name = emp_name,
						  reject_reason = reason,
						  subject = subject,
						  promoter = promoter_name,
						  pre_approve_time = pre_approve_time,
						  approval_time = os.date("%Y-%m-%d %H:%M:%S"),
						  link_auth = self_url .. "/auth/login",
						  link = self_url .. "/approval/"..form_id.."?mail_token="..mail_token
						} or content_pre

	-- 更新request_form  approval_history
	if submit_code == "init" then

		local request_upd,err =
		      approval_model:upd_request_init_status(form_id,process_next,
					                                       process_now,status)
		if not request_upd or err then
			msg = "更新流程状态失败."
			return 513,nil,err or msg
		end

		ngx.log(ngx.ERR,form_id,emp_no,emp_name,position)
		local log,err =
		      approval_model:add_approval_init_log(form_id,emp_no,emp_name,position)
		if not log or err then
			msg = "记录初始化log失败."
			return 514,nil,err or msg
		end
	else

		local request_upd,err =
		      approval_model:upd_request_approval_status(form_id,process_next,
					                                           process_now,status)
		if not request_upd or err then
			msg = "更新流程状态失败."
			return 515,nil,err or msg
		end

		local log,err = approval_model:add_approval_approve_log(form_id,log_status,
		                                                        reason,process_pre)
		if not log or err then
			msg = "记录签核log失败."
			return 516,nil,err or msg
		end
	end

	-- 发邮件
	ngx.log(ngx.ERR,mail_to)
	ngx.log(ngx.ERR,content)
	ngx.log(ngx.ERR,view)

	local mail_param = cjson.encode{mail_to = mail_to,
							mail_subject = mail_subject,
							content = content, --内容
							attach_name = attach_name,
							attachments = attachments,
							form_id = form_id,
							form_code = apply_info.code,
							emp_no = user.emp_no}

	local result, err = red:connect(host,port)
	if not result or err then
        msg = "failed to connect: ",err
        return 581,nil,msg
    end

    local result, err = red:rpush("pending_mail_source",mail_param)
    if not result then
        msg = "failed to set key: ", err
        return 582,nil,msg
    end

    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        msg = "failed to set_keepalive: ", err
        return 583,nil,msg
    end

    return 200,mail_param,msg

end
--提交前對表單的檢驗
function _M.checkForm(data)
	local typeid = data.typeid
	local dept_code = data.dept_code
	local dept_name = data.dept_name
	local applicant_no = data.applicant_no
	local applicant_name = data.applicant_name
	local applicant_phone = data.applicant_phone
	local applicant_email = data.applicant_email
	local subject = data.subject
	local reason = data.reason
	local approval_flow = data.approval_flow
	local files = data.files

	if(utils.chk_is_null(typeid)) then
		return 517,"類型不能為空"
	end
	if(utils.chk_is_null(dept_code)) then
		return 518,"費用代碼不能為空"
	end
	if(utils.chk_is_null(dept_name)) then
		return 519,"部門不能為空"
	end
	if(utils.chk_is_null(applicant_no)) then
		return 520,"申請人不能為空"
	end
	if(utils.chk_is_null(applicant_name)) then
		return 521,"申請人姓名不能為空"
	end
	if(utils.chk_is_null(applicant_phone)) then
		return 522,"申請人電話不能為空"
	end
	if(utils.chk_is_null(applicant_email)) then
		return 523,"申請人郵箱不能為空"
	end
	if(utils.chk_is_null(subject)) then
		return 524,"主題不能為空"
	end
	if(utils.chk_is_null(reason)) then
		return 525,"申請理由不能為空"
	end
	if(utils.chk_is_null(approval_flow)) then
		return 526,"審核流程不能為空"
	end

	--审核流程数据检查
	for i=1,#approval_flow do
		local approval_f = approval_flow[i]
		if utils.chk_is_null(approval_f['emp_no']) then
			return 560,"第"..i.."个流程审核人工号为空"
		end
		if utils.chk_is_null(approval_f['approval_activity_id']) then
			return 562,"第"..i.."个流程审核人类型为空"
		end
		local promoter_info,err = emp_model:query_userinfo_by_emp_no(approval_f['emp_no'])
		if not promoter_info or err then
			return 563,"未找到第"..i.."个流程审核人,请检查信息是否正确"
		end
	end

	--[[审核流程顺序检查
      1.签核人必须有直属主管和签核主管
			2.直属主管必须唯一且为第一个
			3.谦和主管必须唯一且为第二个
	--]]
	local approval_per = {}
	if #approval_flow <2 then
		return 527,"簽核人不能少於兩個"
	end
	for i=1,#approval_flow do
		local approval_f = approval_flow[i]
		if  approval_f.approval_activity_id == 1 then
			approval_per[1] = approval_f.order_item
		end
		if approval_f.approval_activity_id == 4 then
			approval_per[2] = approval_f.order_item
		end
		if not (utils.chk_is_null(approval_per[1])) and
		   not(utils.chk_is_null(approval_per[2])) then
			break
		end
	end

	if utils.chk_is_null(approval_per[1]) then
		return 528,"直屬主管不能為空"
	end
	if utils.chk_is_null(approval_per[2]) then
		return 529,"核准主管不能為空"
	end
	if approval_per[1] ~= 1 then
		return 530,"直屬主管必須為簽核的第一個且只能有一個"
	end
	if approval_per[2] ~= #approval_flow then
		return 531,"核准主管必須為簽核的最後一個且只能有一個"
	end

	if(utils.chk_is_null(files)) then
		return 532,"附件不能為空"
	end
	return 200,"success"
end
--暫存
function _M.pre_addform(user,data)

	local id = data.id
	local code = data.code
	local typeid = data.typeid
	local dept_code = supper(data.dept_code)
	local dept_name = data.dept_name
	local applicant_no = supper(data.applicant_no)
	local applicant_name = data.applicant_name
	local applicant_phone = data.applicant_phone
	local applicant_email = data.applicant_email
	local subject = data.subject

	local reason = data.reason
	ngx.log(ngx.ERR,"reason:"..reason)
	local approval_flow = data.approval_flow
	local files = data.files

	local returnforminfo = {['id']=nil,['code']=nil}

	local date
	if utils.chk_is_null(id,code) then
		date = os.date("%Y%m%d")
	else
		date = string.sub(code,1,8)
	end

	if utils.chk_is_null(id)  then
		--未暂存过
		--1.插入主表返回id值
		local newcode = approval:code()
		local result1,err1 = approval:insert_request_form(newcode,typeid,supper(user.emp_no),
		               dept_code,dept_name,applicant_no,applicant_name,
							     applicant_phone,applicant_email,subject,reason)
		if not result1 or err1 then
				return 533,"插入申请表失败",returnforminfo
		end
		local formid = result1

			--2.插入流程表

		for i=1,#approval_flow do
			local result2,err2 = approval:insert_approval_flow_detail(formid,
			          utils.trim(supper(approval_flow[i].emp_no)),approval_flow[i].emp_name,
								approval_flow[i].order_item,approval_flow[i].approval_activity_id)
			if not result2 or err2 then
				return 534,"第"..i.."个流程插入流程表失败",returnforminfo
			end
		end

		local date_form,a,b,c = os.execute("/bin/sh ./mkdir_date.sh "..date .." ".. newcode)
		if not date_form then
			return 590,"新建日期文件夹失败."
		end
			--4.插入附件表
		for i=1,#files do
			--判断文件是否已在附件表内
			local result = approval:query_attachments_by_diskfilename(filepath.."/"..date .."/"..newcode .."/"..
							files[i].disk_filename)
			if result == nil or #result == 0 then

			--移动缓存区的文件
				local osexe,a,b,c = os.execute("mv -f " .. filedir_temp .."/" ..
				                    files[i].disk_filename .. " " .. filedir .. "/" ..date .."/"..newcode .."/"..
														files[i].disk_filename)
				local from = ngx.re.find(files[i].disk_filename, "."..files[i].content_type.."$")
				if osexe then
					local result5,err5 = approval:insert_attachments(newcode,
					                     files[i].filename,filepath.."/"..date .."/"..newcode .."/"..
															 files[i].disk_filename,files[i].filesize,
															 files[i].content_type,string.sub(files[i].disk_filename,1,from-1))
					if not result5 or err5 then
						return 535,"第"..i.."个附件插入附件表失败",returnforminfo
					end
				else
					return 536,"移动缓存区文件"..files[i].disk_filename.."失败"
				end
		  end
		end

		returnforminfo.id = formid
		returnforminfo.code = newcode

		return 200,"success",returnforminfo


	else
			--已暂存
			--1.更新申请表
		local result1,err1 = approval:update_request_form(id,typeid,dept_code,
		                     dept_name,supper(applicant_no),applicant_name,
									       applicant_phone,applicant_email,subject,reason)
		if not result1 or err1  then
			return 537,"更新申请表失败,该申请表不存在或信息错误",returnforminfo
		end
		
		ngx.log(ngx.ERR,"----------",date)
		local date_form,a,b,c = os.execute("/bin/sh ./mkdir_date.sh "..date .." ".. code)
		if not date_form then
			return 590,"新建日期文件夹失败."
		end

			--3.插入附件表
		for i=1,#files do
			--判断文件是否已在附件表内
			local result = approval:query_attachments_by_diskfilename(filepath.."/"..date .."/"..code .."/"..
							files[i].disk_filename)
			if result == nil or #result == 0 then

				--移动缓存区的文件
				local osexe = os.execute("mv -f " .. filedir_temp .."/" ..
				                         files[i].disk_filename .. " " .. filedir.."/" ..date .."/"..code .."/"
																..files[i].disk_filename)
				local from = ngx.re.find(files[i].disk_filename, "."..files[i].content_type.."$")
				if osexe then
					local result5,err5 = approval:insert_attachments(code,files[i].filename,
					                     filepath.."/"..date .."/"..code .."/" ..files[i].disk_filename,
															 files[i].filesize,files[i].content_type,
															 string.sub(files[i].disk_filename,1,from-1)
															 )
					if not result5 or err5 then
						return 538,"第"..i.."个附件插入附件表失败",returnforminfo
					end
				end
			end
		end
			--4.删除流程表
		local result4,err4 = approval:delete_approval_flow_detail_by_requestformid(id)
		if not result4 or err4 then
			return 539,"删除流程表失败",returnforminfo
		end
			--5.插入流程表
		for i=1,#approval_flow do
			local result5,err5 = approval:insert_approval_flow_detail(
			          id,utils.trim(supper(approval_flow[i].emp_no)),
								approval_flow[i].emp_name,approval_flow[i].order_item,
								approval_flow[i].approval_activity_id)
			if not result5 or err5 then
				return 540,"第"..i.."个流程插入流程表失败",returnforminfo
			end

		end

		returnforminfo.id = id
		returnforminfo.code = code

		return 200,"success",returnforminfo
	end

end


return _M
