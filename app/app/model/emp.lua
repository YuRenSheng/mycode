local DB = require("app.libs.db")
local db = DB:new()

local emp_model = {}

function emp_model:query_by_id(emp_no)  --工号是否存在
    local res,er = db:query("select no,name,dept_extra_code as dept_code,position,director from emp_dept_extra where active = 1 and no=? limit 1",{emp_no})
    if not res or er or type(res)~="table" or #res~=1 then
      local result, err =  db:query("select no,name,dept_code,position,director from bas_employee where active = 1 and no=? limit 1", {emp_no})
      if not result or err or type(result) ~= "table" or #result ~=1 then
          return nil, err
      else
          return result[1], err
      end
    else
      return res[1],er
    end
end    

-- return user, err
function emp_model:query_user_by_emp_no(emp_no) -- 工号是否已经绑定帐号
   	local res, err =  db:query("select * from user_emp where emp_no=? limit 1", {emp_no})
   	if not res or err or type(res) ~= "table" or #res ~=1 then
		  return nil, err or "error"
	  else
	    return res[1], err
    end
end

function emp_model:query_empinfo_by_emp_no(emp_no)  --return emp_name position dept  
  local res, err = db:query([[ select concat_ws(' ', emp.name, emp.position, ext.name) as res 
                                 from dept_extra ext, 
                                      emp_dept_extra emp 
                                where ext.code = emp.dept_extra_code 
                                  and ext.active = 1 
                                  and emp.active =1 
                                  and emp.no =?  limit 1 ]],
                            {emp_no})
  if not res or err or #res ~=1 then
    local res, err = db:query([[ select concat_ws(' ',emp.name,
                                                  (case emp.position 
                                                        when '無' 
                                                        then '' 
                                                        else emp.position 
                                                    end),
                                                  substring_index(dept.name,'-',-2)) as res 
                                   from bas_employee emp,bas_dept dept 
                                  where emp.dept_code = dept.code 
                                    and dept.active = 1 
                                    and emp.active =1 
                                    and emp.no =? limit 1]],
                                 {emp_no})
    if not res or err or #res ~=1 then
      return nil, err
    else 
      return res[1], err  --res[1] 结果显示 {"res":"賴夢玲  智能系統規劃部-系統開發課"}
    end                   --res    结果显示 [{"res":"賴夢玲  智能系統規劃部-系統開發課"}]
  else 
    return res[1], err
  end
end

function emp_model:query_emp_by_card(card_no)
  local result, err = db:query("select * from emp_card_info where card_no =? and active = 1 ",{card_no})
  if not result or err or type(result) ~= "table" or #result ~=1 then 
    return nil, err 
  else 
    return result, err
  end
end

function emp_model:query_card_by_emp(emp_no)
  local result, err = db:query("select * from emp_card_info where emp_no =? and active = 1 ",{emp_no})
  if not result or err or type(result) ~= "table" or #result ~= 1 then 
    return nil, err 
  else 
    return result, err
  end
end

function emp_model:add_card_emp_relate(emp_no,card_no)
  local result, err = db:insert("insert into emp_card_info(emp_no,card_no) values (?, ?) ",{emp_no,card_no})
  return result, err
end

function emp_model:add_emp_dept_extra(dept_code,emp_no)
  local result, err = db:insert([[insert into emp_dept_extra (no,name,dept_extra_code,site_code,position,director,active,revision) 
                         (select * from 
                         ((select no,name,?,site_code,position,director,2,ifnull(max(revision),0)+1 as rev
                            from emp_dept_extra 
                             where no = ? and active = 1 group by no,name,site_code,position,director)
                             union 
                             (select no,name,?,site_code,position,director,2,ifnull(max(revision)+1,0)+1 as rev
                             from  bas_employee 
                             where no = ? and active = 1 group by no,name,site_code,position,director)limit 1 ) a )]],
                            {dept_code,emp_no,dept_code,emp_no})

  if result and not err then 
    local result, err = db:update([[ update emp_dept_extra set active = active-1 where active > 0 and no =? ]],{emp_no})
    return result, err
  end
  return nil, err
end

function emp_model:query_position_by_emp_card(card_no)
  local sql_base = [[select emp.position 
                       from bas_employee emp,emp_card_info card
                      where emp.no = card.emp_no and emp.active = 1 
                        and card.active = 1 and card.card_no = ?]]

  local sql_m = [[select emp.position
                    from emp_dept_extra emp,emp_card_info card
                   where emp.no = card.emp_no and emp.active = 1
                     and card.active = 1 and card.card_no = ?]]

  local result, err = db:query(sql_m,{card_no})
  if not result or err or type(result) ~= "table" or #result ~=1 then 
    local res ,er = db:query(sql_base,{card_no})
    if not res or er or type(res) ~="table" or #res ~=1 then
      return nil, er
    else
      return res, er
    end
  else
    return result, err
  end
end

function emp_model:query_empinfo_by_emp_card(card_no)
  local sql_base = [[ 
     select a.*,c.card_no,b.pos_id,b.building,b.floor,b.pos_name from 
(select card_no,emp_no from emp_card_info where active = 1 and card_no = ? ) c
left join
(select emp.no, emp.name, emp.position, dept.code dept_code, dept.name dept_name
       from bas_employee emp, bas_dept dept
      where emp.dept_code = dept.code and emp.active = 1
        and dept.active = 1 )a on c.emp_no =a.no
  left join 
(select dept_pos.dept_code,pos.id as pos_id, bu.building, bu.floor, pos.position as pos_name 
  from dept_pos_info dept_pos, position_info pos, bu_area_info bu 
  where  dept_pos.active = 1
  and dept_pos.position_id = pos.id and pos.active = 1
     and pos.area_id = bu.id and bu.active = 1 ) b
on a.dept_code = b.dept_code limit 1;]]
  
local sql_m = [[
    select a.*,c.card_no,b.pos_id,b.building,b.floor,b.pos_name from 
(select card_no,emp_no from emp_card_info where active = 1 and card_no = ? ) c
left join
(select emp.no, emp.name, emp.position, dept.code dept_code, dept.name dept_name
       from emp_dept_extra emp, dept_extra dept
      where emp.dept_extra_code = dept.code and emp.active = 1
        and dept.active = 1 )a on a.no = c.emp_no
  left join 
(select dept_pos.dept_code,pos.id as pos_id, bu.building, bu.floor, pos.position as pos_name 
  from dept_pos_info dept_pos, position_info pos, bu_area_info bu 
  where  dept_pos.active = 1
  and dept_pos.position_id = pos.id and pos.active = 1
     and pos.area_id = bu.id and bu.active = 1) b
on a.dept_code = b.dept_code  limit 1 ; ]]

  local result, err = db:query(sql_m,{card_no})
  if not result or err or type(result) ~= "table" or #result ~=1 or result[1].no ==ngx.null then 
    local res ,er = db:query(sql_base,{card_no})
    if not res or er or type(res) ~="table" or #res ~=1 then
      return nil, er
    else
      return res[1], er
    end
  else
    return result[1], err
  end
end

function emp_model:query_full_empinfo_by_emp(emp_no)
  local sql_base = [[ select a.*,c.card_no,b.pos_id,b.building,b.floor,b.pos_name from 
            (select emp.no, emp.name, emp.position, dept.code dept_code, dept.name dept_name
                   from  bas_employee emp, bas_dept dept
                  where emp.dept_code = dept.code and emp.active = 1
                    and dept.active = 1 
                    and emp.no = ?  limit 1 )a 
              left join 
            (select dept_pos.dept_code,pos.id as pos_id, bu.building, bu.floor, pos.position as pos_name 
              from dept_pos_info dept_pos, position_info pos, bu_area_info bu 
              where  dept_pos.active = 1
              and dept_pos.position_id = pos.id and pos.active = 1
                 and pos.area_id = bu.id and bu.active = 1 ) b
              on a.dept_code = b.dept_code
              left join 
            (select card_no,emp_no from emp_card_info where active = 1 ) c
            on a.no = c.emp_no limit 1 ;
          ]]
  
local sql_m = [[  select a.*,c.card_no,b.pos_id,b.building,b.floor,b.pos_name from 
        (select emp.no, emp.name, emp.position, dept.code dept_code, dept.name dept_name
               from emp_card_info card, emp_dept_extra emp, dept_extra dept
              where emp.dept_extra_code = dept.code and emp.active = 1
                and dept.active = 1 
                and emp.no = ?  limit 1 )a 
          left join 
        (select dept_pos.dept_code,pos.id as pos_id, bu.building, bu.floor, pos.position as pos_name 
          from dept_pos_info dept_pos, position_info pos, bu_area_info bu 
          where  dept_pos.active = 1
          and dept_pos.position_id = pos.id and pos.active = 1
             and pos.area_id = bu.id and bu.active = 1) b
        on a.dept_code = b.dept_code
        left join 
        (select card_no,emp_no from emp_card_info where active = 1 limit 1) c
        on a.no = c.emp_no  limit 1 ;
        ]]

  local result, err = db:query(sql_m,{emp_no})
  if not result or err or type(result) ~= "table" or #result ~=1 or result[1].no ==ngx.null then 
    local res ,er = db:query(sql_base,{emp_no})
    if not res or er or type(res) ~="table" or #res ~=1 then
      return nil, er
    else
      return res[1], er
    end
  else
    return result[1], err
  end
end

function emp_model:query_userinfo_by_emp_no(emp_no)
  local sql_m = [[select b.extension as phone ,b.id,b.login,c.no,c.name,c.dept_extra_code as dept_code,c.position,b.mail_notification as mail
             from user_emp a, users b, emp_dept_extra c
             where a.user_id = b.id and a.emp_no = c.no and c.active = 1 and a.active = 1 
               and b.status = 1 and a.emp_no = ? limit 1 ]]

  local sql_base = [[select b.extension as phone ,b.id,b.login,c.no,c.name,c.dept_code,c.position,b.mail_notification as mail 
              from user_emp a, users b, bas_employee c
             where a.user_id = b.id and a.emp_no = c.no and c.active = 1
               and a.active = 1 and b.status = 1 and a.emp_no = ? limit 1 ]]

  local res, err = db:query(sql_m,{emp_no})
  if not res or err or type(res) ~= "table" or #res ~=1 then 

      local result, err = db:query(sql_base,{emp_no})
      if not result or err or type(result) ~= "table" or #result ~= 1 then 
        return nil,err
      else 
        return result[1],err
      end
  end
    return res[1],err
end

function emp_model:add_approval_person_to_emp_extra(no,name,dept_code,position)
  local res,err = db:insert([[insert into emp_dept_extra (no,name,dept_extra_code,site_code,position,revision,in_approval)
                          values ( ?,?,?,"LH",?,1,1) ]],{no,name,dept_code,position})
  return res,err
end

function emp_model:query_count_emp_by_dept_code(dept_code)
  local result,err = db:query([[select no,name,position,dept_code
              from bas_employee where active = 1 and dept_code = ? 
              union 
              select no,name,position,dept_extra_code as dept_code
              from emp_dept_extra where active = 1 and dept_extra_code =?  ]],{dept_code,dept_code})
  if not result or err or type(result) ~= "table" or #result  == 0 then 
     return nil,err
  else
    return result,err
  end 
end

return emp_model
