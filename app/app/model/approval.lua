local DB = require("app.libs.db")
local emp = require("app.model.emp")
local cjson = require("cjson")
local utils = require("app.libs.utils")
local db = DB:new()

local approval_model = {}

--查询单据类型
function approval_model:query_request_form_type()
	local result,err = db:query("select id,code,name from approval_type where id <> -1")
	if  not result or err or type(result) ~= "table" then
		return nil,err
	else
		return result,err
	end
end

--根据工号查询审核人
function approval_model:query_approval_person_by_empno(emp_no)
	local result,err = db:query("select emp_no,emp_name,dept_name,email,position from approval_person where emp_no = ? limit 1",{emp_no})
	if not result or err or type(result) ~= "table" or #result ~= 1 then
		return nil,err
	else
		return result[1],err
	end
end


--查詢审核主管类型
function approval_model:query_approval_activity()
	local result,err = db:query("select id,approval_person_type from approval_activity where id > 0 and active =1")
	if  not result or err or type(result) ~= "table" then
		return nil,err
	else
		return result,err
	end
end

--获取插入申请表code
--[[
function approval_model:approval_code()
	local date=os.date("%Y%m%d");
	date1 = date..'%'
	local result,err = db:query("SELECT code FROM request_form  where code like ? ",{date1})
	if not result or err or type(result) ~= "table" then
		return nil
	elseif #result == 0 then
			return date.."-00001"
	else
		local code = {}
		for k,v in ipairs(result) do
			table.insert(code,v["code"])
		end
		table.sort(code)
		local num = string.sub(code[#code],10,#code[#code])+1
		local newcode = "00000"..num
		return date.."-"..string.sub(newcode,-5,#newcode)
	end

end
--]]

--获取插入申请表code
function approval_model:code()

	local result,err = db:multi_query([[set @o_res = '0';
								call smartfactory.new_requestform_code(@o_res);
								select @o_res as newcode;]])
	if not result or err or type(result) ~= "table" or #result < 1 then
		return nil
	else
		return result[#result][1]['newcode']
	end
end

--插入申请表
function approval_model:insert_request_form(code,typeid,promoter,dept_code,dept_name,applicant_no,applicant_name,applicant_phone,applicant_email,subject,reason)
	--ngx.log(ngx.ERR,code..typeid..promoter..dept_code..dept_name..applicant_no..applicant_name..applicant_phone..applicant_email..subject..reason..status)
	if utils.chk_is_null(typeid) then
		typeid = -1
	end
	local	result,err = db:insert("insert into request_form (code,typeid,promoter,dept_code,dept_name,applicant_no,applicant_name,applicant_phone,applicant_email,subject,reason) values (?,?,?,?,?,?,?,?,?,?,?)",
								{code,typeid,promoter,dept_code,dept_name,applicant_no,applicant_name,applicant_phone,applicant_email,subject,reason})
	return result,err
end
--根据id更新申請表
function approval_model:update_request_form(id,typeid,dept_code,dept_name,applicant_no,applicant_name,applicant_phone,applicant_email,subject,reason)
	--ngx.log(ngx.ERR,id.." "..typeid..dept_code..dept_name..applicant_no..applicant_name..applicant_phone..applicant_email..subject..reason)
	if utils.chk_is_null(typeid) then
		typeid = -1
	end
    return db:update(" update request_form set typeid="..typeid..
        ",dept_code = '"..dept_code.."', dept_name ='"..dept_name.."' ,applicant_no ='"..applicant_no..
        "', applicant_name ='"..applicant_name.."', applicant_phone ='"..applicant_phone.."', applicant_email ='"..applicant_email..
        "', subject ='"..subject.."', reason ="..ngx.quote_sql_str(reason)..", active = 1 where id="..id)
end
--根据id删除申请表(active置为0)
function approval_model:delete_request_form(id)
	return db:update("update request_form set active = 0 where id = ?",{id})
end


--根据id更新申請表submitat
function approval_model:update_request_form_submitat(id)
    return  db:update("update request_form set submit_at=? where id=?",
                      {os.date("%Y%m%d %H:%M:%S"),id})
end

--插入流程表
function approval_model:insert_approval_flow_detail(request_form_id,approve_empno,approve_empname,order_item,approval_activity_id)
	--ngx.log(ngx.ERR,request_form_id..approve_empno..approve_empname..order_item,approval_activity_id)
	return db:insert([[insert into approval_flow_detail(request_form_id,approve_empno,approve_empname,order_item,approval_activity_id)
								values(?,?,?,?,?)]],{request_form_id,approve_empno,approve_empname,order_item,approval_activity_id})
end
--根据request_form_id删除流程表
function approval_model:delete_approval_flow_detail_by_requestformid(request_form_id)
	return db:delete("delete from approval_flow_detail where request_form_id=?",{request_form_id})
end

--插入附件表
function approval_model:insert_attachments(container_id,filename,disk_filename,filesize,content_type,digest)
	return db:insert([[insert into attachments(container_id,filename,disk_filename,filesize,content_type,digest)
					 values(?,?,?,?,?,?)]],{container_id,filename,disk_filename,filesize,content_type,digest})
end
--根据filename删除附件表
function approval_model:delete_attachments(filename)
	return db:delete("delete from attachments where digest=?",{filename})
end
--插入历史表
function approval_model:insert_approval_history(request_form_id,order_item,approval_activity_id,approve_empno,approve_empname,position)
    ngx.log(ngx.ERR,request_form_id..order_item..approval_activity_id..approve_empno..approve_empname..position)
	return db:insert("insert into approval_history(request_form_id,order_item,approval_activity_id,approve_empno,approve_empname,position) values(?,?,?,?,?,?)",
        {request_form_id,order_item,approval_activity_id,approve_empno,approve_empname,position})
end
--根据id查询申请表
function approval_model:query_request_form_by_id(id)
	local result,err = db:query("select * from request_form where id=?",{id})
	if not result or err or type(result) ~= "table" or #result ~= 1 then
		return nil,err
	else
		return result[1],err
	end
end
--根据id更新申请表目前审核人
function approval_model:update_request_form_processnow_by_id(id,process_now)
	return db:update("update request_form set process_now = ? where id = ?",{process_now,id})
end

--根据id更新申请表下一审核人
function approval_model:update_request_form_processnext_by_id(id,process_next)
	return db:update("update request_form set process_next = ? where id = ?",{process_next,id})
end

--根据disk_filename查询附件表
function approval_model:query_attachments_by_diskfilename(disk_filename)
	local result,err = db:query("select id from attachments where disk_filename = ?",{disk_filename})
	if  not result or err or type(result) ~= "table"  then
		return nil,err
	else
		return result,err
	end
end

return approval_model
