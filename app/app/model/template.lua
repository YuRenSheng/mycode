local DB = require("app.libs.db")
local db = DB:new()

local template_model = {}

function template_model:add_template(name,data,author,src)
	local res, err = db:insert([[insert into data_display_template (name,content,author,api_src_id) 
								(select ?,?,?,id from api_src_info where active = 1 and code =? )
								]],{name,data,author,src})
	if not res or err or type(res) ~= "table"  then  
		return nil,err
	else
		return res.insert_id,err
	end 
end

function template_model:del_template(id)
	local res, err = db:update("update data_display_template set active = 0 where id = ? ",{id})
	return res,err
end

function template_model:upd_template(author,param,id)
	local res, err = db:update("update data_display_template set author =? ," .. param .. " where active = 1 and id =?",{author,id})
	return res, err 					
end

function template_model:query_name_exsist(name)
	local res, err = db:query("select id,name,content,author from data_display_template where active = 1 and name = ?",{name})
	if not res or err or type(res) ~= "table" or #res~=1 then
		return nil,err
	else
		return res,err
	end 
end

function template_model:query_id_exsist(id)
	local res, err = db:query("select id,name,content,author from data_display_template where active = 1 and id = ? order by update_at asc",{id})
	if not res or err or type(res) ~= "table" or #res~=1 then
		return nil,err
	else
		return res,err
	end 
end

function template_model:query_template_all()
	local res, err = db:query("select id,name,content,author from data_display_template where active = 1 order by update_at asc")
	if not res or err or type(res) ~= "table" or #res==0 then
		return nil,err
	else
		return res,err
	end 
end

function template_model:query_src_all()
	local res, err = db:query("select id, code,name from api_src_info order by update_at asc")
	if not res or err or type(res) ~= "table" or #res==0 then
		return nil,err
	else
		return res,err
	end 
end

return template_model