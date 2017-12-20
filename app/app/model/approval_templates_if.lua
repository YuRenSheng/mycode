local DB = require("app.libs.db")
local db = DB:new()

local approval_templates = {}

--搜索模板概况
function approval_templates:find_templates(promoter,typeid)
	local result,err = db:query([[select apt.id,apt.templates_name,apt.typeid,
																			 apt.create_at from approval_templates apt
								   							 where apt.promoter = ? and apt.typeid = ? and
																 			 apt.active = 1]],{promoter,typeid})
	if not result or type(result) ~= "table" or #result == 0 then
		return nil,err
	else
		return result,err
	end
end

--根据选择的id抛出模板的详细信息
function approval_templates:find_templates_detail(templates_id)
	local result,err = db:query([[select atd.approval_activity_id,atd.order_item,
										 									 atd.approve_empno,atd.approve_empname,
										 								 	 atd.approve_email,atd.approve_dept
																		  from approval_templates_detail atd
								   								   where atd.parent_id = ?
																		 	 and atd.active = 1]],{templates_id})
	if not result or type(result) ~= "table" or #result == 0 then
		return nil,err
	else
		return result,err
	end
end

--檢索模板名稱是否存在
function approval_templates:find_templates_exists(templates_name,promoter,typeid)
	local result,err = db:query([[select 1 from approval_templates apt
								   							 where apt.templates_name = ?
																 	 and apt.promoter = ?
																	 and apt.typeid = ?
																	 and apt.active = 1]]
																 	,{templates_name,promoter,typeid})
	if not result or type(result) ~= "table" or #result == 0 then
		return false
	else
		return true
	end
end

--写入模板主表
function approval_templates:write_templates(templates_name,promoter,typeid)
	local result,err = db:insert([[insert into approval_templates
											   										  (templates_name,promoter,typeid)
																							values(?,?,?)]]
																							,{templates_name,promoter,typeid})
	if not result or err then
		return nil,err
	else
		return result,err
	end
end

--写入模板详情
function approval_templates:write_templates_detail(parent_id,order_item,
												   		approve_empno,approve_empname,approve_dept,
															approve_email,approval_activity_id)
	local result,err = db:insert([[insert into approval_templates_detail
											   											(parent_id,order_item,
																							approve_empno,approve_empname,
																							approve_dept,approve_email,
																							approval_activity_id)
																							values(?,?,?,?,?,?,?)]]
																	,{parent_id,order_item,approve_empno,
																	approve_empname,approve_dept,approve_email,
																	approval_activity_id})
	if not result or err then
		return nil,err
	else
		return result,err
	end
end

--修改模板主表
function approval_templates:alter_templates(templates_name,typeid,templates_id)
	local result,err = db:update([[update approval_templates apt
																		set apt.templates_name = ? , apt.typeid = ?
																	where id = ?]]
																	,{templates_name,typeid,templates_id})
	return result,err
end

--删除模板主表
function approval_templates:delete_templates(templates_id)
	local result,err = db:update([[update approval_templates apt
																		set apt.active = 0 where id = ?]]
																		,{templates_id})
	return result,err
end

--删除模板详情
function approval_templates:delete_templates_detail(templates_id)
	local result,err = db:update([[update approval_templates_detail atd
											   					  set atd.active = 0
																	where parent_id = ?]],{templates_id})
	return result,err
end

return approval_templates
