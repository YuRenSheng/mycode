local DB = require("app.libs.db")
local db = DB:new()

local version_model = {} 

function version_model:query_curr_version(app_id,os_type)
	local result,err = db:query([[select project_id as app_id,os_type,disk_filename as path,version,publish_date,changelog,size 
								    from project_version_control 
								   where project_id = ? and os_type =? and active = 1 limit 1]],{app_id,os_type})
	if not result or err or type(result) ~= "table" or #result ~=1 then 
		return nil,err
	else 
		return result[1],nil
	end
end



return version_model