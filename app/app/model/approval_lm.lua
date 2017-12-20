local DB = require("app.libs.db")
local db = DB:new()

local approval_model = {} 

function approval_model:query_approval_type_by_id(form_id)
	local res,err = db:query([[select a.id ,a.code,a.name from approval_type a, request_form b
								where a.id = b.typeid and a.active = 1 and b.active = 1
								  and b.id = ? limit 1 ]],{form_id})
	if not res or err or type(res)~="table" or #res ~=1 then
		return nil,err
	else
		return res[1],err
	end
end

function approval_model:query_apply_info_by_id(form_id)
	local res,err = db:query([[select id as form_id,promoter,code,dept_code,dept_name,applicant_no,applicant_name,applicant_phone,applicant_email,
								subject,reason,status,process_now,process_next ,submit_at,approval_at,update_at
								from request_form where active = 1 and id = ? limit 1]],{form_id})
	if not res or err or type(res)~="table" or #res ~=1 then
		return nil,err
	else
		return res[1],err
	end
end

function approval_model:query_approve_person_by_id(form_id)
	local res,err = db:query([[select a.order_item,a.approve_empno,a.approve_empname 
							from approval_flow_detail a,request_form b
							where a.request_form_id = b.id and a.active = 1 and b.active = 1
							  and a.order_item = b.process_now and b.id = ? limit 1]],{form_id})
	if not res or err or type(res)~="table" or #res ~=1 then
		return nil,err
	else
		return res[1],err
	end
end

function approval_model:query_apply_log_by_id(form_id)
	local res,err = db:query([[select b.id,a.id as activity_id,a.activity,b.approve_empno, b.approve_empname,b.position,b.status,b.reason,b.create_at, b.order_item
		 					     from approval_activity a, approval_history b 
		 					    where a.id = b.approval_activity_id and a.active = 1 and b.active = 1 
		 					      and b.request_form_id = ? order by order_item]],{form_id})
	if not res or err or type(res)~="table" or #res ==0 then
		return nil,err
	else
		return res,err
	end
end

function approval_model:query_approval_flow_detail_by_id(form_id)
	local res,err = db:query([[select c.id,a.order_item,c.approval_person_type,b.emp_no,b.emp_name,b.position,b.email
								from approval_flow_detail a, approval_person b,approval_activity c
							 where a.approve_empno = b.emp_no and a.approval_activity_id = c.id 
							   and a.active = 1 and b.active = 1 and c.active = 1
							   and a.request_form_id = ? order by a.order_item]],{form_id})
	if not res or err or type(res)~="table" or #res ==0 then
		return nil,err
	else
		return res,err
	end
end

function approval_model:query_approval_pre_log_by_id(form_id)
	local res,err = db:query([[select distinct b.order_item ,a.activity, b.approve_empno, b.approve_empname, b.position
						from approval_activity a, approval_history b
						where a.id = b.approval_activity_id 
						and b.id >= (select id from approval_history where active = 1 
							and request_form_id =?  and order_item = 0 order by id desc limit 1) 
						and b.order_item < (select process_now from request_form where id =? and active = 1 limit 1 )
						and a.active = 1 and b.active = 1  and b.request_form_id =?  order by b.order_item]],
						{form_id,form_id,form_id})
	if not res or err or type(res)~="table" or #res ==0 then
		return nil,err
	else
		return res,err
	end
end

function approval_model:query_process_next_by_process(process_next,form_id)
	local res,err = db:query([[select request_form_id,approve_empno,approve_empname,order_item,approval_activity_id
						from approval_flow_detail 
						where active = 1 and request_form_id = ? and order_item = ? limit 1 ]],
						     {form_id,process_next})
	if not res or err or type(res)~="table" or #res ~=1 then
		return nil,err
	else
		return res[1],err
	end
end

function approval_model:add_approval_init_log(form_id,emp_no,emp_name,position)
	local res,err = db:insert([[insert into approval_history
			 (approve_empno,approve_empname,position,request_form_id,order_item,approval_activity_id,status,reason)
			 (select ? , ? , ? ,id ,0,0,1,'——' from request_form where active = 1 and id = ?)]],
			 			{emp_no,emp_name,position,form_id})
	return res,err
end

function approval_model:add_approval_approve_log(form_id,status,reason,process_pre)
	local res,err = db:insert([[insert into approval_history
			(status,reason,request_form_id,order_item,approval_activity_id,approve_empno,approve_empname,position)
				 (select  ? , ? , a.id,?,c.approval_activity_id,c.approve_empno,c.approve_empname,b.position  
				     from request_form a,approval_person b,approval_flow_detail c
				     where a.id = c.request_form_id and b.emp_no = c.approve_empno
				     and a.active = 1 and b.active = 1 and c.active = 1
				     and a.id = ? and c.order_item = ? limit 1 )]],{status,reason,process_pre,form_id,process_pre})
	return res,err
end

function approval_model:upd_request_approval_status(form_id,process_next,process_now,status)
	local res,err = db:update([[update request_form 
						set process_next =? ,
						    process_now = ? ,
						    status = ? ,
						    approval_at = now() 
						where id = ? and active = 1 and status <> 3]],
						{process_next,process_now,status,form_id})
	return res,err
end

function approval_model:upd_request_init_status(form_id,process_next,process_now,status)
	local res,err = db:update([[update request_form 
						set process_next =? ,
						    process_now = ? ,
						    status = ? ,
						    submit_at = now() 
						where id = ? and active = 1 and status <> 3]],
						{process_next,process_now,status,form_id})
	return res,err
end


return approval_model