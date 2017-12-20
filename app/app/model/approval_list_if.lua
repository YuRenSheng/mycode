local DB = require("app.libs.db")
local db = DB:new()

local approval_list = {}

function approval_list:dynamic_find_list(query_type,username,...) -- 事件动态查询
	local sql = [[select rf.id as form_id,rf.code as request_code,
										   rf.promoter,rf.dept_code,rf.dept_name,
										 	 rf.status,rf.applicant_no,
										 	 rf.applicant_name,rf.applicant_phone,
										 	 rf.applicant_email,rf.subject,
										 	 rf.reason,rf.typeid,rf.create_at,
										 	 apt.name as type_name,
										 	 apt.code as type_code,
							 (select name from bas_employee
								 where no = rf.promoter and active = 1
								union
								select name from emp_dept_extra
								 where no = rf.promoter and active = 1)
										as promoter_name
								  from request_form rf, approval_type apt ]]
	local params = { ... } -- 将可变长参数赋给params
	if query_type == 1 then -- 查询所有已办
		sql = sql..[[where rf.active = 1 and rf.typeid = apt.id
			and exists (select 1 from approval_history aph
		where rf.id = aph.request_form_id
			and aph.approve_empno = ?)
 order by rf.create_at desc limit ?,?]]
 	local result,err = db:query(sql,{username,params[1] * params[2],params[1]})
	 	if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
	 	else
			return result,err
		end
  end

	if query_type == 2 then -- 根据单号查询已办
		sql = sql..[[where rf.active = 1 and rf.code = ?
			and rf.typeid = apt.id and exists
					(select 1 from approval_history aph
		where rf.id = aph.request_form_id
			and aph.approve_empno = ?)
 order by rf.create_at desc]]
	local result,err = db:query(sql,{params[1],username})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
  end

	if query_type == 3 then -- 根据时间查询已办
		sql = sql..[[where rf.active = 1
			and date(rf.create_at) >= ?
			and date(rf.create_at) <= ?
			and rf.typeid = apt.id and exists
					(select 1 from approval_history aph
		where rf.id = aph.request_form_id
			and aph.approve_empno = ?)
 order by rf.create_at desc limit ?,?]]
	local result,err = db:query(sql,{params[1],params[2],
														username,params[3] * params[4],params[3]})
		if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
		else
			return result,err
		end
  end

	if query_type == 4 then -- 已办模糊查询
		sql = sql..[[where rf.active = 1 and rf.typeid = apt.id
			and (rf.reason like ? or rf.subject like ?)
			and exists (select 1 from approval_history aph
		where rf.id = aph.request_form_id
			and	aph.approve_empno = ?)
 order by rf.create_at desc limit ?,?]]
	local result,err = db:query(sql,{"%"..params[1].."%","%"..params[1].."%",
																	username,params[2] * params[3],params[2]})
		if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
		else
			return result,err
		end
 	end

	if query_type == 5 then -- 已办带时间参数的模糊查询
		sql = sql..[[where rf.active = 1 and rf.typeid = apt.id
			and (rf.reason like ? or rf.subject like ?)
			and date(rf.create_at) >= ?
			and date(rf.create_at) <= ?
			and exists (select 1 from approval_history aph
		where rf.id = aph.request_form_id
			and	aph.approve_empno = ?)
 order by rf.create_at desc limit ?,?]]
	local result,err = db:query(sql,{"%"..params[1].."%","%"..params[1].."%",
									params[2],params[3],username,params[4] * params[5],params[4]})
		if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
		else
			return result,err
		end
 	end

	if query_type == 6 then -- 查询所有我的单
		sql = sql..[[where rf.active = 1 and rf.promoter = ?
			and rf.typeid = apt.id
 order by rf.create_at desc limit ?,?]]
	local result,err = db:query(sql,{username,params[1],params[2]})
		if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 7 then -- 根据单号查询我的单
		sql = sql..[[where rf.active = 1 and rf.code = ?
			and rf.promoter = ?
			and rf.typeid = apt.id]]
	local result,err = db:query(sql,{params[1],username})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 8 then -- 根据时间查询我的单
		sql = sql..[[where rf.active = 1
			and date(rf.create_at) >= ?
			and date(rf.create_at) <= ?
			and rf.promoter = ? and rf.typeid = apt.id
 order by rf.create_at desc limit ?,?]]
	local result,err = db:query(sql,{params[1],params[2],
															username,params[3] * params[4],params[3]})
		if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
		else
			return result,err
		end
 	end

	if query_type == 9 then -- 我的单模糊查询
		sql = sql..[[where rf.active = 1 and rf.promoter = ?
			and rf.typeid = apt.id
			and (rf.reason like ? or rf.subject like ?)
 order by rf.create_at desc limit ?,?]]
	local result,err = db:query(sql,{username,"%"..params[1].."%","%"..params[1].."%",
																	params[2] * params[3],params[2]})
		if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 10 then -- 带时间参数的我的单模糊查询
		sql = sql..[[where rf.active = 1
			and date(rf.create_at) >= ?
			and date(rf.create_at) <= ?
			and rf.promoter = ? and rf.typeid = apt.id
			and (rf.reason like ? or rf.subject like ?)
 order by rf.create_at desc limit ?,?]]
	local result,err = db:query(sql,{params[1],params[2],username,
			"%"..params[3].."%","%"..params[3].."%",params[4] * params[5],params[4]})
 		if not result or err or type(result) ~= "table" or #result == 0 then
 			return nil,err
 		else
 			return result,err
 		end
 	end

	if query_type == 11 then -- 待办任务查询
		sql = sql..[[where rf.active = 1 and rf.typeid = apt.id
			and ((rf.status = 2 and exists
					(select 1 from approval_flow_detail apf
		where apf.approve_empno = ?
			and apf.request_form_id = rf.id
			and apf.order_item = rf.process_now))
			 or (rf.status = 1 and rf.promoter = ?))
 order by rf.create_at desc]]
	local result,err = db:query(sql,{username,username})
		if not result or err or type(result) ~= "table" or #result == 0 then
			return nil,err
		else
			return result,err
		end
 	end

	if not query_type then
		return nil,"there should have a param！"
	end
end

function approval_list:dynamic_find_list_count(query_type,username,...) -- 总数动态查询
	local sql = [[select count(*) as cnt from request_form rf ]]

	params = { ... }
	if query_type == 1 then -- 已办总条目
		sql = sql..[[where rf.active = 1 and exists
							 (select 1 from approval_history aph
							 	 where rf.id = aph.request_form_id
								 	 and aph.approve_empno = ?)]]
	local result,err = db:query(sql,{username})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 2 then -- 时间区域内的已办总条目
		sql = sql..[[where rf.active = 1
									 and date(rf.create_at) >= ?
									 and date(rf.create_at) <= ?
									 and exists (select 1 from approval_history aph
								 where rf.id = aph.request_form_id
								 	 and aph.approve_empno = ?)]]
	local result,err = db:query(sql,{params[1],params[2],username})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 3 then -- 已办模糊查询总条目
		sql = sql..[[where rf.active = 1 and exists
							 (select 1 from approval_history aph
							 	 where rf.id = aph.request_form_id
								 	 and aph.approve_empno = ?)
									 and (rf.reason like ? or rf.subject like ?)]]
	local result,err = db:query(sql,{username,"%"..params[1].."%","%"..params[1].."%"})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 4 then -- 时间区域内的已办模糊查询总条目
		sql = sql..[[where rf.active = 1
									 and date(rf.create_at) >= ?
									 and date(rf.create_at) <= ?
									 and exists (select 1 from approval_history aph
								 where rf.id = aph.request_form_id
								 	 and aph.approve_empno = ?)
									 and (rf.reason like ? or rf.subject like ?)]]
	local result,err = db:query(sql,{params[1],params[2],username,
														"%"..params[3].."%","%"..params[3].."%"})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 5 then -- 我的单总条目
		sql = sql..[[where rf.active = 1 and rf.promoter = ?]]
	local result,err = db:query(sql,{username})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 6 then -- 时间区域内的我的单总条目
		sql = sql..[[where rf.active = 1
									 and date(rf.create_at) >= ?
			 					 	 and date(rf.create_at) <= ?
			 					 	 and rf.promoter = ?]]
	local result,err = db:query(sql,{params[1],params[2],username})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 7 then -- 我的单模糊查询总条目
		sql = sql..[[where rf.active = 1 and rf.promoter = ?
									and (rf.reason like ? or rf.subject like ?)]]
	local result,err = db:query(sql,{username,"%"..params[1].."%","%"..params[1].."%"})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end

	if query_type == 8 then -- 时间区域内的我的单模糊查询总条目
		sql = sql..[[where rf.active = 1
									 and date(rf.create_at) >= ?
			 					 	 and date(rf.create_at) <= ?
			 					 	 and rf.promoter = ?
									 and (rf.reason like ? or rf.subject like ?)]]
	local result,err = db:query(sql,{params[1],params[2],username,
														"%"..params[3].."%","%"..params[3].."%"})
		if not result or err or type(result) ~= "table" or #result ~= 1 then
			return nil,err
		else
			return result,err
		end
	end
end

function approval_list:query_approval_flow(form_id) -- 查询表单的完整流程
	local result,err = db:query([[select * from approval_flow_detail
																				where request_form_id = ?
																					and active = 1]],{form_id})
	if not result or err or type(result) ~= "table" or #result == 0 then
		return nil,err
	else
		return result,err
	end
end

function approval_list:query_approval_history(form_id) -- 查询表单的签核历史
	local result,err = db:query([[select * from approval_history
																				where request_form_id = ?
																					and active = 1]],{form_id})
	if not result or err or type(result) ~= "table" or #result == 0 then
		return nil,err
	else
		return result,err
	end
end

function approval_list:query_approval_form(form_id) -- 查询整张表单的信息
	local result,err = db:query([[select * from request_form where id = ?
																					and active = 1 limit 1]],{form_id})
	if not result or err or type(result) ~= "table" or #result ~= 1 then
		return nil,err
	else
		return result,err
	end
end

return approval_list
