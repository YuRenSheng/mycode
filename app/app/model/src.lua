local DB = require("app.libs.db")
local db = DB:new()

local src_model = {} 

function src_model:query_src_contrast_by_src(src)
	local result,err = db:query([[select sfi.code, sfi.name 
						    from src_filter_indicator sfi , api_src_info asi 
					       where sfi.api_src_id = asi.id 
					         and asi.code = ? 
					         and sfi.active = 1 
					         and asi.active = 1 ]],{src})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end 	
end

function src_model:query_index_content_by_src(src)
	local result ,err = db:query([[select tem.id,tem.content as item
		 						from src_filter_condition tem , api_src_info asi 
		 					   where tem.api_src_id = asi.id 
		 					     and asi.active = 1
		 					     and tem.active = 1 
		 					     and asi.code = ? ]],{src})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end 	
end

function src_model:query_exists_by_src(src)
	local result ,err = db:query("select id from api_src_info where active = 1 and code = ? ",{src})
	if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result, err
    end 	
end

function src_model:add_indicat(item,author,src)
	local sql = [[insert into src_filter_condition (api_src_id,content,author)
		         (select id,?,? from api_src_info where active = 1 and code = ? )]]

	local result ,err = db:insert(sql,{item,author,src})
   
	if not result or err or type(result) ~= "table"  then  
		return nil,err
	else
		return result.insert_id,err
	end 
	
end

function src_model:del_indicat(id,author)
	local result ,err = db:update([[update src_filter_condition
		 					          set active = 0,
		 					          author = ? 
					                 where id = ? and active = 1]],{author,id})
    return result, err 	
end

function src_model:upd_indicat(id,item,author)
	local result ,err = db:update([[update src_filter_condition 
								      set content = ? ,
								      	  author = ?
								     where id = ? and active = 1]],{item,author,id})
    return result, err 	
end

return src_model