local DB = require("app.libs.db")
local db = DB:new()

local stat_model = {} 

function stat_model:query_total_staff(begin_time, end_time)
	local result, err = db:query(" select day,total_staff from report_dashboard where day >=? and day <=? ",
					{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end 	

function stat_model:query_month_new_emp(begin_time, end_time)
	local result, err = db:query([[select concat(year(day),'M',month(day)) x ,sum(new_cnt) y
									 from report_dashboard 
								    where day >= date_format(? ,'%Y-%m-%d') 
								      and day <= date_format(? ,'%Y-%m-%d') group by x;
									]],
						{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_week_new_emp(begin_time, end_time)
	local result, err = db:query([[select concat(year(day),'W',week(day)) x ,sum(new_cnt) y
									 from report_dashboard 
								    where day >= date_format(?,'%Y-%m-%d') 
								      and day <= date_format(?,'%Y-%m-%d') group by x;
									]],
						{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_day_new_emp(begin_time, end_time)
	local result, err = db:query([[select day x ,sum(new_cnt) y
									 from report_dashboard 
								    where day >= date_format(?,'%Y-%m-%d') 
								      and day <= date_format(?,'%Y-%m-%d') group by x;
									]],
						{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_month_wastage_emp(begin_time, end_time)
	local result, err = db:query([[select concat(year(day),'M',month(day)) x ,sum(wastage_cnt) y
									 from report_dashboard 
								    where day >= date_format(? ,'%Y-%m-%d') 
								      and day <= date_format(? ,'%Y-%m-%d') group by x;
									]],
						{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_week_wastage_emp(begin_time, end_time)
	local result, err = db:query([[select concat(year(day),'W',week(day)) x ,sum(wastage_cnt) y
									 from report_dashboard 
								    where day >= date_format(?,'%Y-%m-%d') 
								      and day <= date_format(?,'%Y-%m-%d') group by x;
									]],
						{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_day_wastage_emp(begin_time, end_time)
	local result, err = db:query([[select day x ,sum(wastage_cnt) y
									 from report_dashboard 
								    where day >= date_format(?,'%Y-%m-%d') 
								      and day <= date_format(?,'%Y-%m-%d') group by x;
									]],
						{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_direct_indirect_rate(begin_time, end_time)
	local result, err = db:query([[select day,direct_cnt,indirect_cnt,format(direct_cnt/indirect_cnt,1) rate 
									 from report_dashboard where day >=? and day <=? ]],
							{begin_time, end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_manpower_change_list_total()
	local result ,err = db:query("select count(1) total from report_dashboard_detail ")
	if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_manpower_change_list(page_index,rownum)
	local sql1 = [[ select ctd.is_new,
						   ct.day,ctd.accurate_time,
					       ctd.emp_name,ctd.emp_no,
						   (case position when '無' then '直接' else '間接' end) is_direct,
						   substring_index(ctd.dept_code,'-',-3) dept_code ,
					       ctd.position
					  from report_dashboard ct,report_dashboard_detail ctd
					 where ct.id = ctd.parent_id
					   order by ct.day desc  
					   limit ?, ?]]
	local result, err = db:query(sql1,{page_index,rownum})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_manpower_change_list_by_name(name)
	local result, err = db:query([[ select ctd.is_new,
										   ct.day,ctd.accurate_time,
									       ctd.emp_name,ctd.emp_no,
										   (case position when '無' then '直接' else '間接' end) is_direct,
										   substring_index(ctd.dept_code,'-',-3) dept_code ,
									       ctd.position
									  from report_dashboard ct,report_dashboard_detail ctd
									 where ct.id = ctd.parent_id
									   and ctd.emp_name =? 
									   order by ct.day desc  ]],{name})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_manpower_change_list_by_no(no)
	local result, err = db:query([[ select ctd.is_new,
										   ct.day,ctd.accurate_time,
									       ctd.emp_name,ctd.emp_no,
										   (case position when '無' then '直接' else '間接' end) is_direct,
										   substring_index(ctd.dept_code,'-',-3) dept_code ,
									       ctd.position
									  from report_dashboard ct,report_dashboard_detail ctd
									 where ct.id = ctd.parent_id
									   and ctd.emp_no =? 
									   order by ct.day desc  ]],{no})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_attendance_rate(begin_time,end_time)
	local result, err = db:query("select day,format(actual_cnt/due_cnt,3) rate from report_dashboard where day >=? and day <=? ",
				{begin_time,end_time})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function stat_model:query_manpower_distribution(dept_code)
	sql1 = [[ select format(ifnull(base1.cnt/base2.cnt,1),4) rate,base1.parent_code,base1.code,
						base1.name,base1.cnt total_cnt,ifnull(base3.s_cnt,0) dept_cnt from 
		(select sum(a.cnt) cnt ,b.parent_code,b.code ,b.orderbycode,b.name
		  from 
			(select count(1) cnt, code,orderbycode,dept.name
			   from bas_dept dept, bas_employee emp 
			  where dept.active = 1
				and dept.code = emp.dept_code
				and emp.active = 1
				and emp.no not in (select no from emp_dept_extra where active = 1)
				and dept.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? ),'%')
				group by code,orderbycode,name
			union 
			 select count(1) cnt , code,orderbycode,ex.name
			   from dept_extra ex , emp_dept_extra emp
			  where ex.active = 1
				and ex.code = emp.dept_extra_code
				and emp.active = 1
				and ex.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? 
									  union
								   select orderbycode from dept_extra where active = 1 and code =? ),'%')
				group by code,orderbycode,name
		    ) a,
			(select distinct code, orderbycode,parent_code,name
			   from bas_dept dept
			  where dept.active = 1
				and dept.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? ),'%')
			union 
			 select distinct code,orderbycode,parent_code,name
			   from dept_extra ex 
			  where ex.active = 1
				and ex.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? 
									  union
								   select orderbycode from dept_extra where active = 1 and code =? ),'%')
			)b 
		    where a.orderbycode like concat(b.orderbycode,'%')
		    group by parent_code,code ,orderbycode,name) base1    
		    
    left join
    
		(select sum(a.cnt) cnt ,b.parent_code,b.code ,b.orderbycode
		  from 
			(select count(1) cnt, code,orderbycode
			   from bas_dept dept, bas_employee emp 
			  where dept.active = 1
				and dept.code = emp.dept_code
				and emp.active = 1
				and emp.no not in (select no from emp_dept_extra where active = 1)
				and dept.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? ),'%')
				group by code,orderbycode
			union 
			 select count(1) cnt , code,orderbycode
			   from dept_extra ex , emp_dept_extra emp
			  where ex.active = 1
				and ex.code = emp.dept_extra_code
				and emp.active = 1
				and ex.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? 
									  union
								   select orderbycode from dept_extra where active = 1 and code =? ),'%')
				group by code,orderbycode
		    ) a,
			(select distinct code, orderbycode,parent_code
			   from bas_dept dept
			  where dept.active = 1
				and dept.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? ),'%')
			union 
			 select distinct code,orderbycode,parent_code
			   from dept_extra ex 
			  where ex.active = 1
				and ex.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =?
									  union
								   select orderbycode from dept_extra where active = 1 and code =? ),'%')
			)b 
		    where a.orderbycode like concat(b.orderbycode,'%')
		    group by parent_code,code ,orderbycode) base2  
		   on base1.parent_code = base2.code 
     
    left join

		(select count(1) s_cnt, code,orderbycode,dept.name
			   from bas_dept dept, bas_employee emp 
			  where dept.active = 1
				and dept.code = emp.dept_code
				and emp.active = 1
				and emp.no not in (select no from emp_dept_extra where active = 1)
				and dept.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =? ),'%')
				group by code,orderbycode,name
			union 
			 select count(1) cnt , code,orderbycode,ex.name
			   from dept_extra ex , emp_dept_extra emp
			  where ex.active = 1
				and ex.code = emp.dept_extra_code
				and emp.active = 1
				and ex.orderbycode like concat((select orderbycode from bas_dept where active = 1 and code =?
									  union
								   select orderbycode from dept_extra where active = 1 and code =? ),'%')
				group by code,orderbycode,name) base3
	on base1.code = base3.code]]

	local result, err = db:query(sql1,{dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code,dept_code})

	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end 
end

return stat_model