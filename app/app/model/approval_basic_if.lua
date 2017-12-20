local DB = require("app.libs.db")
local db = DB:new()

local approval_basic = {}

--select basic info
function approval_basic:check_empno(num)
	local result,err = db:query([[select ap.emp_no,ap.emp_name,ap.dept_code,
									                     ap.dept_name,ap.phone,ap.email,
									     					 			 ap.position,ap.note
																  from approval_person ap
								   					 	   where ap.active = 1
									 				 	 			 and ap.emp_no = ?]],{num})
	if not result or type(result) ~= "table" or #result == 0 then
		return nil,err
	else
		return result,err
	end
end

--is the email exists
function approval_basic:isexist_email(email)
	local result,err = db:query([[select email
																	from approval_person
		                      where exists (select 1 from approval_person ap
		                             where ap.active = 1
																 	 and ap.email = ?)]],{email})
	if not result or type(result) ~= "table" or #result == 0 then
		return nil,err
	else
		return result,err
	end
end

--insert basic info
function approval_basic:write_basicinfo(emp_no,emp_name,dept_code,
									    dept_name,phone,email,position,note)
	local result,err = db:insert([[insert into approval_person
											  										 (emp_no,emp_name,dept_code,
											   								 		 dept_name,phone,email,
											   								 		 position,note)
								   											 values(?,?,?,?,?,?,?,?)]]
								,{emp_no,emp_name,dept_code,dept_name,
								  phone,email,position,note})
end

--update email
function approval_basic:update_email(email,emp_no)
	local result,err = db:update([[update users set mail_notification = ?
								    							where id = (select user_id
																	 from user_emp where active = 1
																		and emp_no = ?)]],{email,emp_no})
	if not result or err or #result == 0 then
		return false
	else
		return true
	end
end

--update basic info
function approval_basic:update_active(num)
	local result,err = db:update([[update approval_person ap
								   	  							set ap.active = 0
																	where ap.emp_no = ?]],{num})
	if not result or err or #result == 0 then
		return false
	else
		return true
	end
end

--insert user
function approval_basic:new(name,username, password, email)
    return db:insert([[insert into users (first_name,login,hashed_password
    									 									 ,mail_notification)
    				   								values(?,?,?,?)]]
    				,{name, username, password, email})

end

return approval_basic
