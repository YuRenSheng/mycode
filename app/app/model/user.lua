local DB = require("app.libs.db")
local db = DB:new()

local user_model = {}


function user_model:new(username, password, email)   -- 初始化users
    return db:insert("insert into users (first_name, login, hashed_password, mail_notification) values(?,?,?,?)",
                                 {username, username, password, email})

end

function user_model:new_user_emp_relation(username, emp_no)  --初始化user_emp
    return db:insert("insert into user_emp (user_id, emp_no) (select id, ? from users where status = 0 and login = ? )",
                                 {emp_no, username} )
end

function user_model:update_user_active(usernames)  -- 激活用户名
  -- local res, err =  db:query("select id from users where login in(" .. usernames .. ")")
   local res, err = db:update('update users us,user_emp ue set us.status = 1, ue.active = 1 where us.id = ue.user_id and (us.login in("' .. usernames .. '" )or ue.emp_no in("'.. usernames ..'"))')
   return res, err
end

function user_model:query(username, password)   --检查用户名和密码
   local res, err =  db:query([[select us.*, ue.emp_no
                                  from users us, user_emp ue
                                 where us.id = ue.user_id
                                   and us.status = 1
                                   and ue.active = 1
                                   and us.login=?
                                   and us.hashed_password=? ]], {username, password})

   if not res or err or type(res) ~= "table" or #res ~=1 then
        local res, err = db:query([[select us.*, ue.emp_no
                                      from users us, user_emp ue
                                     where us.id = ue.user_id
                                       and us.status = 1
                                       and ue.active = 1
                                       and ue.emp_no =?
                                       and us.hashed_password =? ]],{username, password})

        if not res or err or type(res) ~= "table" or #res ~=1 then
            return nil, err
        else
            return res, err
        end
    end
   return res, err
end

function user_model:query_by_id(id)
    local result, err =  db:query("select * from users where id=?", {tonumber(id)})
    if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result[1], err
    end
end

function user_model:query_active_by_username(username)  --检查用户名是否激活
    local res, err =  db:query("select * from users where status =1 and login=? limit 1", {username})
    if not res or err or type(res) ~= "table" or #res ~=1 then
        local res, err = db:query("select * from users us, user_emp ue where us.id = ue.user_id and us.status = 1 and ue.active = 1 and ue.emp_no =? ",{username})
        if not res or err or type(res) ~= "table" or #res ~=1 then
            return nil, err
        else
            return res[1], err
        end
    else
        return res[1], err
    end
end

function user_model:query_by_username(username)  --检查用户名是否存在,用户名/工号
   	local res, err =  db:query("select login,mail_notification from users where login=? limit 1", {username})
   	if not res or err or #res ~=1 then
        local res, err = db:query("select us.login,us.mail_notification from users us, user_emp ue where us.id = ue.user_id and ue.emp_no =upper(?) ",{username})
        if not res or err or #res ~=1 then
		        return nil, err
        else
            return res[1], err
        end
	else
	    return res[1], err
    end
end

function user_model:query_dept_by_emp(emp_no)

  local sql_ex = "select * from emp_dept_extra where active = 1 and no =? limit 1"
  local sql_emp = "select * from bas_employee where active = 1 and no =? limit 1"

  local result, err = db:query(sql_ex,{emp_no})
  if not result or err or type(result) ~= "table" or #result ~=1 then

    local result, err = db:query(sql_emp,{emp_no})
    if not result or err or type(result) ~= "table" or #result ~=1 then
      return nil ,err
    else
      return result, err
    end
  end
  return result,err
end

function user_model:query_mail_by_emp_no(emp_no)
  local res,err = db:query([[select a.mail_notification
                    from users a, user_emp b where a.id = b.user_id and a.status = 1 and b.active = 1
                      and b.emp_no = ? limit 1 ]],{emp_no})
  if not res or err or type(res) ~= "table" or #res ~=1 then
    return nil ,err
  else
    return res[1], err
  end
end


-- 原始案例的，没用上

function user_model:update_pwd(username, pwd) --修改密码
    local res, err = db:query("update users set hashed_password=? where login =?", {pwd, username})
    local result ,erro = db:query([[update users us, user_emp ue set us.hashed_password =?
                                     where us.id = ue.user_id and ue.emp_no =upper(?)]], {pwd, username})
    if res or result then
        return true
    else
        return false
    end
end

function user_model:add_app_login_log(sdata,data)
  local result, err = db:insert(" insert into app_login_log(" .. sdata .. ") values (" .. data .. ")")
  return result,err
end



function user_model:update(userid, email, email_public, city, company, github, website, sign)
    local res, err = db:query("update users set email=?, email_public=?, city=?, company=?, github=?, website=?, sign=? where id=?",
        { email, email_public, city, company, github, website, sign, userid})

    if not res or err then
        return false
    else
        return true
    end
end

function user_model:get_total_count()
    local res, err = db:query("select count(id) as c from user")

    if err or not res or #res~=1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end

--新增修改郵箱 --by fatty
function user_model:update_email(email,userid)
    local result,err = db:update([[update users set mail_notification = ?
                                    where id = ?]],{email,userid})

    local result1,err = db:update([[update approval_person ap
                                       set ap.email = ?
                                     where exists(select 1
                                     from  user_emp ue
                                     where ap.emp_no = ue.emp_no
                                       and ue.user_id = ? and ap.active = 1
                                       and ue.active = 1)]],{email,userid})
    if not result or err then
      return false
    else
      return true
    end
end

--新增查询用户信息 --by fatty
function user_model:query_userinfo_by_emp_no(emp_no)
    local result,err = db:query([[select ue.emp_no,ev.name,us.login,
                                         us.sex,us.mail_notification,
                                         us.phone,us.extension,
                                         dv.name as department,
                                         ev.position,ev.director
                                    from users us,user_emp ue,
                                         dept_view dv,employee_view ev
                                   where ue.emp_no = ?
                                     and ue.user_id = us.id
                                     and ue.emp_no = ev.no
                                     and dv.code = ev.dept_code
                                     and ue.active = 1]],{emp_no})
    if not result or err or type(result) ~= "table" or #result ~= 1 then
      return nil,err
    else
      return result,err
    end
end

--新增用户修改信息 --by fatty
function user_model:update_userinfo(sex,extension,phone,userid)
    local result,err = db:update([[update users set sex = ?,extension = ?,
                                          phone = ? where id = ?]]
                                          ,{sex,extension,phone,userid})
    if not result or err then
      return false
    else
      return true
    end
end

return user_model
