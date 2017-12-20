local DB = require("app.libs.db")
local db = DB:new()

local layout_model = {}

function layout_model:query_building()  ---查找楼栋
	local result, err = db:query("select distinct building from bu_area_info where active = 1 ")
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end 

function layout_model:query_floor_by_build(building)  -- 根据查找查找楼层
	local result, err = db:query("select distinct floor from bu_area_info where active = 1 and building =? ", {building})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function layout_model:query_map_by_pos(building, floor)  -- layout_id
	local result, err = db:query([[select att.id as id,  
		                                  concat(att.disk_filename,'/',att.filename) as layout_file_path
		                             from bu_area_info ba,
		                                  attachments att
		                            where ba.layout_id = att.id 
		                              and ba.active = 1 
		                              and att.active = 1 
		                              and ba.building =? 
		                              and ba.floor =? ]], 
								{building, floor})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function layout_model:query_detail_by_pos(building, floor)
	local result, err = db:query([[ select pos.id ,pos.position name, 
		                                   pos.pos_x x, pos.pos_y y, 
		                                   pos.pos_r r, pos.active, pos.is_lock 'lock'
		                              from position_info pos, 
		                                   bu_area_info ba 
		                             where pos.area_id = ba.id 
		                               and ba.active = 1 
		                               and ba.building =? 
		                               and ba.floor =? 
		                               and pos.active = 1 ]], 
 								{building, floor})
	if not result or err or type(result) ~= "table" or #result ==0 then
        return nil, err
    else
        return result, err
    end
end

function layout_model:query_dept_by_pos(pos_id)
	local sql1 = [[ select distinct substring_index(dept.name,'-',-2) as dept_name, dept.code
					  from dept_pos_info dpi , dept_extra dept
					 where dpi.dept_code = dept.code 
					   and dpi.active = 1 
					   and dept.active = 1
					   and dpi.position_id =? 
				union
					 select distinct substring_index(dept.name,'-',-2) as dept_name,dept.code
					  from dept_pos_info dpi , bas_dept dept
					 where dpi.dept_code = dept.code 
					   and dpi.active = 1 
					   and dept.active = 1
					   and dpi.position_id =? ]]

	local result, err = db:query(sql1, {pos_id,pos_id})
	if not result or err or type(result) ~= "table" or #result ~=0 then   
        return result, err
    else 
    	return nil, err
    end
end

function layout_model:query_pos_by_dept(dept_code,layout_id)
	local result, err = db:query([[ select pos.id
									  from position_info pos ,dept_pos_info dpi, bu_area_info ba
									 where pos.id = dpi.position_id
									   and pos.area_id = ba.id
									   and pos.active = 1
									   and dpi.active = 1
									   and ba.active = 1
									   and dpi.dept_code =? 
									   and ba.layout_id =? ]],{dept_code,layout_id})
	if not result or err or type(result) ~= "table" or #result == 0 then 
		return nil, err
	end
	return result, err
end

function layout_model:add_position(name, x, y, r, layout_id)  --新增position，返回pos_id
	local result, err = db:insert([[  insert into position_info (area_id,position,pos_x,pos_y,pos_r)
							(select ba.id,?,?,?,?
   							   from bu_area_info ba where ba.active = 1 and ba.layout_id = ? )]], {name, x, y, r, layout_id})
	if result and not err then 
		return result,err
    else
    	return nil,err
    end
end

function layout_model:query_pos_id(name, x, y, r, layout_id)
	local res, err = db:query([[select pos.id 
									  from position_info pos ,bu_area_info ba
									 where pos.area_id = ba.id
									   and pos.active = 1
									   and pos.position =? 
									   and pos.pos_x =? 
									   and pos.pos_y =? 
									   and pos.pos_r =? 
									   and ba.layout_id =?  ]],{name, x, y, r, layout_id})
    if not res or err or #res ~=1 then
		return nil, err
	else
    	return res[1], err
    end
end

function layout_model:del_position(pos_id)
	local result, err = db:delete(" delete from position_info where active = 1 and id =? ",{pos_id})
	return result, err
end

function layout_model:upd_position(pos_id,pos_param)
	local result, err = db:update(" update position_info set " .. pos_param .. " where active = 1 and id =?",{pos_id})

	return result, err
end

function layout_model:query_pos_id_exsist(pos_id)
	local result, err = db:query(" select * from position_info where id =? ",{pos_id})
	if not result or err or type(result) ~= "table" or #result ~= 1 then 
		return nil ,err
	end
	return result,err
end

function layout_model:pos_coup_dept(pos_id,dept_code)
	local result, err = db:insert(" insert into dept_pos_info (dept_code,position_id) values (? ,? )",{dept_code, pos_id})
	if result and not err then 
		return result,err
    else
    	return nil,err
    end
end

function layout_model:pos_coup_dept_exsist(pos_id,dept_code)
	local result, err = db:query(" select * from dept_pos_info where active = 1 and position_id =? and dept_code =? ",
								{pos_id,dept_code})
	if not result or err or type(result) ~= "table" or #result ~= 1 then 
		return nil ,err
	end
	return result,err
end

function layout_model:pos_discoup_dept(pos_id,dept_code)
	local result, err = db:delete(" delete from dept_pos_info where active = 1 and position_id =? and dept_code =? ",
								  {pos_id,dept_code})
	return result, err
end

function layout_model:batch_discoup_pos(dept_code,layout_id)
	local result, err = db:delete([[delete from dept_pos_info
									 where active = 1 
									   and dept_code =? 
									   and position_id in (select pos.id 
															 from position_info pos , bu_area_info ba
															where pos.area_id = ba.id
														      and pos.active = 1
														      and ba.active = 1
														      and ba.layout_id =? )]],{dept_code,layout_id})
	return result, err
end

return layout_model