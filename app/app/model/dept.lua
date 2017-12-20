local DB = require("app.libs.db")
local db = DB:new()

local dept_model = {} 

function dept_model:query_org_by_dept(dept_code)
	local result, err = db:query([[ select code ,parent_code,name ,orderbycode,0 as flag
									  from bas_dept 
									 where active = 1
									   and orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? ),'%')
										union 
									select code,parent_code, name ,orderbycode,1 as flag 
									  from dept_extra 
									 where active = 1
									   and orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? 
									   					          union
                                                               select orderbycode from dept_extra where active = 1 and code =? ),'%') ]],
						{dept_code,dept_code,dept_code})
	if not result or err or type(result) ~= "table" or #result == 0 then
		return nil, err
	end
	return result, err
end

function dept_model:query_org_by_emp_no(emp_no)
	local sql_ext = [[  select  ext.dept_extra_code dept_code
					   from smartfactory.emp_dept_extra  ext,dept_extra ex
					  where ext.no =? 
					    and ext.dept_extra_code = ex.code
					    and ex.active = 1
						and ext.active =1 limit 1 ]]

	local sql_bas = [[   select emp.dept_code
						   from smartfactory.bas_employee emp,bas_dept dept
						  where emp.no =? 
						    and emp.dept_code = dept.code
						    and dept.active = 1
							and emp.active = 1 limit 1 ]]

	local sql_org = [[ select code ,name ,1 as flag
					  	 from bas_dept 
					    where active = 1
					      and orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? ),'%')
						union 
					   select code, name ,0 as flag
					     from dept_extra 
					    where active = 1
					      and orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =?    
					   					             union
                                                  select orderbycode from dept_extra where active = 1 and code =? ),'%') ]]

	local res, err = db:query(sql_ext,{emp_no})
	if not res or err or type(res) ~= "table" or #res ~= 1 then 
		local res, err = db:query(sql_bas,{emp_no})
		if not res or err or type(res) ~= "table" or #res ~= 1 then 
			return nil ,err
		else
			local dept_code = res[1].dept_code 

			local result, err = db:query(sql_org,{dept_code,dept_code,dept_code})
			if not result or err or type(result) ~= "table" or #result == 0 then 
				return nil, err
			else
				return result, err
			end
		end
	end

	local dept_code = res[1].dept_code 

	local result, err = db:query(sql_org,{dept_code,dept_code,dept_code})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err
	else
		return result, err
	end
end

function dept_model:query_dept_exists_by_dept(dept_code)
	local result, err = db:query([[select code ,parent_code,name ,orderbycode
									  from bas_dept 
									 where active = 1
									   and code =? 
										union 
									select code,parent_code, name ,orderbycode
									  from dept_extra 
									 where active = 1
									   and code =? limit 1 ]],
						{dept_code,dept_code})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err
	end
	return result, err
end

function dept_model:query_dept_exists_by_name(dept_name)
	local result, err = db:query([[select code ,parent_code,name ,orderbycode
									  from bas_dept 
									 where active = 1
									   and name =? 
										union 
									select code,parent_code, name ,orderbycode
									  from dept_extra 
									 where active = 1
									   and name =? ]],
						{dept_name,dept_name})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err
	end
	return result, err
end


function dept_model:query_min_dept_by_parent(parent_code)
	local result, err = db:query("select code,parent_code from bas_dept where active = 1 and  parent_code =? ",
						{parent_code})
	
	if not result or err or type(result) ~= "table" or #result ~=1 then
		return nil, err
	end
	return result,err
end

function dept_model:query_min_dept_extra_by_code(code)
	local result, err = db:query("select * from dept_extra where active = 1 and parent_code =? ",{code})
						
	if not result or err or type(result) ~= "table" or #result ~=1 then
		return nil, err
	end
	return result,err
end

function dept_model:add_extra_dept(parent_code,code,name)
	local result, err = db:insert([[insert into dept_extra (id,code,name,parent_code,level,orderbycode) 
									 ( select (select max(id)+1 id from dept_extra)  id,
											?  code ,
									        ?  name ,
									        ?  parent_code ,
											(select (case  when sum(level+1) is null then 1
															else floor(avg(level))+1 end)
													 from dept_extra where parent_code =? )  level ,
											(select concat((select orderbycode obc from bas_dept where active = 1 and code =? 
													        union 
											               select orderbycode obc from dept_extra where active = 1 and code =? ),'-',LPAD(id,5,0))
											)  obc 
									 ) ]],
 							{code,name,parent_code,parent_code,parent_code,parent_code})
	return result, err
end

function dept_model:query_add_result(parent_code,code,name)
	local result, err = db:query([[select code,name,parent_code,orderbycode 
										 from dept_extra 
										where active = 1 and code =? and name =? and parent_code =?]],
							{code,name,parent_code})
	if not result or err or type(result) ~= "table" or #result ~=1 then
		return nil, err
	end
	return result,err
end

function dept_model:del_dept_extra(code)
	local result, err = db:delete("delete from dept_extra where active = 1 and code =? ",{code})
	return result, err
end

function dept_model:query_dept_type_by_code(code)
	local result, err = db:query("select * from bas_dept where active =1 and code =? ",{code})
	if not result or err or type(result) ~= "table" or #result ~=1 then 
		return nil, err
	end
	return result,err
end

function dept_model:query_emp_dept_extra_exists(code)
	local result, err = db:query("select * from emp_dept_extra where active = 1 and dept_extra_code =? ",{code})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err
	end
	return result,err
end

function dept_model:upd_dept_extra(code,name,upd_param)
	local result, err = db:update("update dept_extra set " .. upd_param .. " where active = 1 and code =? and name =? ",{code,name})
	return result, err
end

function dept_model:query_position_by_dept_code(dept_code)
	local result, err = db:query([[ select dpi.dept_code,pos.id,bu.building,bu.floor,pos.position
									 from dept_pos_info dpi,position_info pos,bu_area_info bu
		                            where dpi.dept_code = ? 
		                              and dpi.position_id = pos.id 
		                              and dpi.active = 1 and pos.active = 1 
		                              and pos.area_id = bu.id and bu.active = 1]],{dept_code})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err
	end
		return result,err
end

return dept_model