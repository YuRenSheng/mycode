local DB = require("app.libs.db")
local db = DB:new()

local attendant_model = {} 

function attendant_model:call_make_activity_swipin(plan_time,sponsor,dept_code,pos_id,activity_type,p_status)
	local sql = [[ set @o_res = '0';
				   call make_activity_swipin(?,?,?,?,?,?,@o_res);
				   select @o_res as o_res;]]
	local result, err = db:multi_query(sql,{plan_time,sponsor,dept_code,pos_id,activity_type,p_status})

	if not result or err or type(result) ~= "table" or #result == 0 then-- ~= 3 then 
		return nil, err
	end
--	local result1 = result[2]
--	local result2 = result[4]
--	local res = {}
--	res.main = result2[1].res
--	res.detail = result1

--	return res ,err
	return result ,err
end

function attendant_model:query_emp_detail_swipin(activity_id)
    local sql_m = [[select swp.id, swp.emp_no, emp.name ,swp.card_no, emp.position
									  from emp_dept_extra emp ,swipin_history swp
									 where emp.no = swp.emp_no
									   and emp.active = 1 
									   and swp.status = 0 
									   and swp.parent_id =?]]
    local res,er = db:query(sql_m,{activity_id})
    if not res or er or type(res) ~= "table" or #res == 0 then
		local result, err = db:query([[ select swp.id, swp.emp_no, emp.name ,swp.card_no, emp.position
										  from bas_employee emp ,swipin_history swp
										 where emp.no = swp.emp_no
										   and emp.active = 1 
										   and swp.status = 0 
										   and swp.parent_id =? ]],{activity_id})

		if not result or err or type(result) ~= "table" or #result == 0 then 
			return nil, err 
		else 
			return result, err
		end
	else
		return res,er
	end
end

function attendant_model:query_activity_id_available(id)
	local result, err = db:query("select * from activity_history where id =? limit 1",{id})
	if not result or err or type(result) ~= "table" or #result ~= 1 then 
		return nil, err 
	else 
		return result[1], err
	end
end

function attendant_model:query_swipin_exsist_by_emp(parent_id,emp_no,card_no)
	local result, err = db:query("select * from swipin_history where parent_id =? and emp_no =? and card_no =? ",
					{parent_id,emp_no,card_no})
	if not result or err or type(result) ~= "table" or #result ~= 1 then 
		return nil, err 
	else 
		return result, err
	end
end

function attendant_model:upd_activity_history(id,param)
	local result, err = db:update("update activity_history set " .. param .. " where id =? ",{id})
	if not result or err or result.affected_rows == 0 then 
		return nil ,err
	end
	return result,err 
end

function attendant_model:upd_swipin_history(parent_id,card_no,emp_no,param)
	local result, err = db:update("update swipin_history set " .. param .. " where parent_id =? and ifnull(card_no,'') =? and emp_no =? ",
					{parent_id,card_no,emp_no})
	if not result or err or result.affected_rows == 0 then 
		return nil ,err
	end
	return result, err
end

function attendant_model:upd_swipin_history_member(parent_id,emp_no,param)
	local result, err = db:update("update swipin_history set " .. param .. " where parent_id =? and emp_no =? ",
					{parent_id,emp_no})
	if not result or err or result.affected_rows == 0 then 
		return nil ,err
	end
	return result, err
end

function attendant_model:add_swipin_history(parent_id,emp_no,card_no,status,swipin_time,swipin_times)
	local result, err = db:insert(" insert into swipin_history (parent_id,emp_no,card_no,status,swipin_time,swipin_times) values (?,?,?,?,?,?)",
						{parent_id,emp_no,card_no,status,swipin_time,swipin_times})
	return result, err
end

function attendant_model:query_new_emp_by_dept(code)
	local result, err = db:query([[select p.*, q.card_no from
									(select emp.no,emp.name,emp.dept_code ,emp.position,emp.director  
									  from bas_dept dept ,bas_employee emp
									 where dept.code = emp.dept_code
									   and dept.orderbycode = (
											select substring_index(ex.orderbycode,'-',1) orderbycode 
									          from dept_extra ex where ex.code =? and ex.active = 1 
										union 
											select orderbycode from bas_dept ex where ex.code =? and ex.active = 1 
									         )
										and emp.active = 1 ) p
									left join
										(select * from emp_card_info where active = 1 ) q 
									on p.no = q.emp_no  where card_no is null ]],{code,code})

	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err 
	else 
		return result, err
	end
end

function attendant_model:call_add_new_member_activity_swipin(p_swipin_param,sponsor,dept_code,pos_id,activity_type)
	local sql = [[ set @o_res = '0';
				   call add_new_member_activity_swipin(?,?,?,?,?,@o_res);
				   select @o_res as res;]]
	local result, err = db:multi_query(sql,{activity_type,sponsor,dept_code,pos_id,p_swipin_param})

	if not result or err  then 
		return nil, err
	end
	local result = result[3]
	local res = result[1].res
	return res ,err
end

function attendant_model:query_swipin_exsist_by_emp_member(parent_id,emp_no)
	local result, err = db:query("select * from swipin_history where parent_id =? and emp_no =? ",
					{parent_id,emp_no})
	if not result or err or type(result) ~= "table" or #result ~= 1 then 
		return nil, err 
	else 
		return result, err
	end
end

function attendant_model:get_main_activity_history(activity_type,sponsor,dept_code,pos_id)
	local result, err = db:query([[ select id,create_at,
			sponsor,dept_code,pos_id,status 
							from activity_history 
						   where activity_type =? and sponsor =? and dept_code =? and pos_id =? order by create_at desc ]],
						   {activity_type,sponsor,dept_code,pos_id})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err 
	else 
		return result, err
	end
end

function attendant_model:get_activity_by_id(id)
    local res,er = db:query([[select act.id,bu.building,bu.floor,pos.id as pos_id,pos.position,act.dept_code,act.sponsor,emp.name,act.status,act.plan_begin_time,
									       act.plan_end_time,act.begin_time,act.end_time,act.memo,act.attachment_id
									  from activity_history act, emp_dept_extra emp,position_info pos,bu_area_info bu
									 where emp.no = act.sponsor and emp.active = 1
									   and act.pos_id = pos.id and pos.active = 1 
									   and pos.area_id = bu.id and bu.active = 1 and act.id =? ]],{id})
	if not res or er or type(res) ~= "table" or #res ~= 1 then     

		local result, err = db:query([[ select act.id,bu.building,bu.floor,pos.id as pos_id,pos.position,act.dept_code,act.sponsor,emp.name,act.status,act.plan_begin_time,
										       act.plan_end_time,act.begin_time,act.end_time,act.memo,act.attachment_id
										  from activity_history act, bas_employee emp,position_info pos,bu_area_info bu
										 where emp.no = act.sponsor and emp.active = 1
										   and act.pos_id = pos.id and pos.active = 1 
										   and pos.area_id = bu.id and bu.active = 1 and act.id =? ]],{id})
		if not result or err or type(result) ~= "table" or #result ~=1 then 
			return nil, err 
		else 
			return result, err
		end
	else
		return res,er
	end
end

function attendant_model:get_swipin_by_id(id)
    local res,er = db:query([[ select act.id,his.dept_code,act.emp_no,act.card_no,emp.name,emp.position,act.status,act.swipin_time,
									       act.swipin_times
									  from swipin_history act, emp_dept_extra emp ,activity_history his
									 where emp.no = act.emp_no and emp.active = 1 
									   and his.id = act.parent_id
									   and act.parent_id =? ]],{id})
    if not res or er or type(res) ~= "table" or #res == 0 then

		local result, err = db:query([[ select act.id,his.dept_code,act.emp_no,act.card_no,emp.name,emp.position,act.status,act.swipin_time,
										       act.swipin_times
										  from swipin_history act, bas_employee emp ,activity_history his
										 where emp.no = act.emp_no and emp.active = 1 
										   and his.id = act.parent_id
										   and act.parent_id =? ]],{id})
		if not result or err or type(result) ~= "table" or #result ==0 then 
			return nil, err 
		else 
			return result, err
		end
	else 
		return res,er
	end
end

function attendant_model:query_flow_step_by_activity(activity)
	local result,err = db:query([[select at.code,at.name,afs.order_item_no,afs.step_name
							from activity_flow_steps afs,activity_type at 
						   where afs.activity_type_id = at.id 
						     and at.code = ? ]],{activity})
	if not result or err or type(result) ~= "table" or #result ==0 then 
		return nil, err 
	else 
		return result, err
	end
end

function attendant_model:query_shift_by_dept(dept_code,at_date)
	local sql = [[  set @datem = date(?);
					set @minu = TIME_FORMAT(date_sub(?, interval 1 hour),'%H:%i:%s');
					set @maxm = TIME_FORMAT(date_add(?, interval 1 hour),'%H:%i:%s');
					select distinct @datem as st_date, time(?) as st_time, shift.* -- pes.shift_no     -- 部門班次
					   from (select p.no, es.shift_no 
							   from (select  ext.no
									   from smartfactory.emp_dept_extra  ext
									  where ext.dept_extra_code = ?
										and ext.active =1  
									union all
									 select emp.no
									   from smartfactory.bas_employee emp
									  where emp.dept_code = ?
									) p,
									smartfactory.bas_emp_shift es
							  where p.no=es.emp_no 
								and es.emp_work_date  = @datem 
								and es.active = 1)pes,smartfactory.bas_shift shift
						where pes.shift_no = shift.no 
					      and shift.active = 1
					   and ((case
							when shift.worktime_1st_begin > worktime_1st_end
							  then (shift.worktime_1st_begin <=  @maxm
								or  shift.worktime_1st_end >= @maxm)
							else (shift.worktime_1st_begin <= @maxm
							  and shift.worktime_1st_end >= @maxm) 
						  end )
						or ( case 
							when shift.worktime_2nd_begin >= shift.worktime_2nd_end
							  then (shift.worktime_2nd_begin <= @maxm
								or  shift.worktime_2nd_end >= @maxm)
							else (shift.worktime_2nd_begin <= @maxm
							  and shift.worktime_2nd_end >= @maxm) 
						  end )
						or ( case 
							when shift.overtime_begin >= shift.overtime_end
							  then (shift.overtime_begin <= @maxm
								or  shift.overtime_end >= @maxm)
							else (shift.overtime_begin <= @maxm
							  and shift.overtime_end >= @maxm) 
						  end )
						or (case
							when shift.worktime_1st_begin > worktime_1st_end
							  then (shift.worktime_1st_begin <=  @minu
								or  shift.worktime_1st_end >= @minu)
							else (shift.worktime_1st_begin <= @minu
							  and shift.worktime_1st_end >= @minu) 
						  end )
						or ( case 
							when shift.worktime_2nd_begin >= shift.worktime_2nd_end
							  then (shift.worktime_2nd_begin <= @minu
								or  shift.worktime_2nd_end >= @minu)
							else (shift.worktime_2nd_begin <= @minu
							  and shift.worktime_2nd_end >= @minu) 
						  end )
						or ( case 
							when shift.overtime_begin >= shift.overtime_end
							  then (shift.overtime_begin <= @minu
								or  shift.overtime_end >= @minu)
							else (shift.overtime_begin <= @minu
							  and shift.overtime_end >= @minu) 
						  end )) ; ]]
	local result,err = db:multi_query(sql,{at_date,at_date,at_date,at_date,dept_code,dept_code})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil,err
	end
	return result[4],err
end

function attendant_model:link_attach_to_activity(attach_id,activity_id)
	local result,err = db:update("update activity_history set attachment_id =? where id = ? ",{attach_id,activity_id})
	if not result or err or result.affected_rows == 0 then 
		return nil ,err
	end
	return result, err
end

return attendant_model
