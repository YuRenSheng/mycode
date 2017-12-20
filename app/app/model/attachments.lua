local DB = require("app.libs.db")
local db = DB:new()

local attach_model = {} 

function attach_model:add_layout(filename, filepath, extname, filesize, digest)
	local result, err = db:insert("insert into attachments (filename, disk_filename, content_type, filesize, digest) values (?, ?, ?, ?, ?)",
				{filename, filepath, extname, filesize, digest})
	return result, err
end

function attach_model:upd_bu_area_info(filename,building, floor)
	local result, err = db:update([[update bu_area_info 
									   set layout_id = (select id 
									   					  from attachments 
									   					 where filename =? 
									   					   and active = 1 )
 									 where building =?  
 									   and floor =?  
 									   and active = 1 ]],{filename,building, floor})
	if not result or err or result.affected_rows == 0 then 
		return nil ,err
	end
		return result, err
end

function attach_model:query_attachment_by_form_id(form_id)
	local res,err = db:query([[select a.id as attach_id, a.filename,a.digest, a.disk_filename as link, a.filesize,
							b.id as form_id, b.code from attachments a, request_form b 
							 where a.container_id = b.code and a.active = 1 and b.active = 1 
							   and b.id = ? ]],{form_id})
	if not res or err or type(res)~="table" or #res ==0 then
		return nil,err
	else
		return res,err
	end
end

function attach_model:query_attachment_by_activity_id(activity_id)
	local res,err = db:query([[select a.id as attach_id, a.filename,a.digest, a.disk_filename as link, a.filesize,
						b.id as activity_id from attachments a, activity_history b 
						where a.id = b.attachment_id and a.active =1 and b.id = ? limit 1]],{activity_id})
	if not res or err or type(res)~="table" or #res ~=1 then
		return nil,err
	else
		return res[1],err
	end
end

return attach_model