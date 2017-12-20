local pairs = pairs
local ipairs = ipairs
local sfind = string.find
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local cjson = require("cjson")
local utils = require("app.libs.utils")
local filepath = require("app.config.config").upload_config.path
local lor = require("lor.index")
local layout_model = require("app.model.layout")
local dept_model = require("app.model.dept")
local attach_model = require("app.model.attachments")
local layout_router = lor:Router()

layout_router:get("",function(req, res, next)
	local src = req.query.src
	local tb = {'building','floor','map','dept'} 
	if not src or src == "" or not utils.str_in_table(src,tb) then 
		return res:json({
			rv = 500,
			msg = "src不得为空，且数据必须在building、floor、map内."
		})
	end

	if src == "building" then
		local result, err = layout_model:query_building()
		local isExist = false
	    if result and not err then
	        isExist = true
	    end

	    if isExist == false then
	        return res:json({
	            rv = 501,
	            msg = "未维护任何楼栋信息."
	        })
	    else

	    	local i 
	    	local arr = {}
	    	local n = #result
	    	for i=1, n do
	    		arr[i] = result[i].building	
	    	end
	    	return res:json({
	    		rv = 200,
	    		msg = "success",
	    		src = "building",
	    		type = "list",
	    		data = arr
	    	})
	    end
	end

	if src == "floor" then
		local build = req.query.building
		if not build or build == "" then
			return res:json({
				rv = 502,
				msg = "楼栋信息不能为空."
			})
		end

		local result, err = layout_model:query_floor_by_build(build)
		local isExist = false
	    if result and not err then
	        isExist = true
	    end

	    if isExist == false then
	        return res:json({
	            rv = 503,
	            msg = "未维护任何楼层信息."
	        })
	    else

	    	local i 
	    	local arr = {}
	    	local n = #result
	    	for i=1, n do
	    		arr[i] = result[i].floor	
	    	end

	    	local filter = {}
	    	filter.building = build
	    	return res:json({
	    		rv = 200,
	    		msg = "success",
	    		src = "floor",
	    		type = "list",
	    		data = arr,
	    		filter = filter
	    	})
	    end
	end

	if src == "map" then
		local build = req.query.building
		local floor = req.query.floor
		if not build or build == "" or not floor or floor == "" then 
			return res:json({
				rv = 504,
				msg = "楼栋与楼层信息不能为空."
			})
		end 

		local mapres, err = layout_model:query_map_by_pos(build, floor)
		local isExist = false
	    if mapres and not err then
	        isExist = true
	    end

	    if isExist == false then
	        return res:json({
	            rv = 505,
	            msg = "未上传任何layout图像信息."
	        })
	    end

    	local detail_res, err = layout_model:query_detail_by_pos(build, floor)
    	if not detail_res or err then
    	--	return res:json({
    	--		rv = 506,
    	--		msg = "未在layout上标注任何地点信息."
    	--	})
    		detail_res = {}
    	end

		local filter = {}
		filter.building = build
		filter.floor = floor
    	return res:json({
    		rv = 200,
    		msg = "success",
    		src = "map",
    		type = "detail",
    		filter = filter,
    		data = {
    			head = mapres[1],
    			items = detail_res
    		}
    	})    
	end

	if src == "dept" then
		local emp_no = utils.trim(req.query.no)
		emp_no = supper(emp_no)

		if not  emp_no or emp_no == "" then 
			return res:json({
				rv = 507,
				msg = "工号不能为空."
			})
		end

		local result, err = dept_model:query_org_by_emp_no(emp_no)
		if result and not err then
			return res:json({
				rv = 200, 
				msg = "success",
				data = result
			})
		else
			return res:json({
				rv = 508,
				msg = "查询失败."
			})
		end
	end
end)

layout_router:post("/file",function(req, res, next)  
	local file = req.file or {}

    if file.success and file.filename then 

      local co = coroutine.create(function (file)

      	  local f_file = io.open(file.path, "r")
          local filesize = f_file:seek("end")
          local filename = file.filename
          local digest = ssub(filename,1,36)

	      local extname = file.extname

	      io.close(f_file)

	   --   os.execute("mv " .. filepath_temp .."/" .. filename .. " " .. filepath_dir)
	      local result, err = attach_model:add_layout(filename, filepath, extname, filesize, digest)
	  	  if result and not err then
	  	  	  local data = {}
	  	  	  data.origin_filename = file.origin_filename
	  	  	  data.filename = filename
	  	  	  data.filepath = filepath
	  	  	  data.filesize = filesize

		      return res:json({
		      		rv = 200,
		        	msg = "success", 
			     	data = data
			  })
		  end
		  return res:json({
		      		rv = 509,
		        	msg = "插入数据失败."
		  })

      end)
  
      coroutine.resume(co,file)

    else
	  return res:json({
	  		rv = 555,
        	success = false, 
	        msg = file.msg
	    })
    end
end)  

layout_router:post("/place",function(req, res, next)
	local act = req.body.act
	local data = req.body.data

	if not act or act == "" or act ~= "place" or not data or data == "" then
		return res:json({
			rv = 533,
			msg = "act和data参数不能为空,且act值只能是place"
		})
	end

	local building = data.building
	local floor = data.floor
	local layout_name = data.layout_name

	if not building or building == "" or not floor or floor == "" or not layout_name or layout_name == "" then
		return res:json({
			rv = 534,
			msg = "楼栋、楼层和layout文件名字不能为空."
		})
	end

	local result, err = attach_model:upd_bu_area_info(layout_name,building, floor)
	if result and not err then 
		return res:json({
			rv = 200,
			msg = "success",
			data = data
		})
	end

	return res:json({
		rv = 535,
		msg = "更新失败，检查文件是否存在."
	})
end)

layout_router:post("/position",function(req,res,next)
	local act = req.body.act
	local data = req.body.data
	local tb = {'add','del','upd','coup','batch_coup'}

	if not act or act == "" or not utils.str_in_table(act,tb)
	    or not data or data == "" then

		return res:json({
				rv = 510,
				msg = "act和data参数不能为空,且act值只能在add、del、upd、coup、batch_coup内."  
			})
	end

	if act == "add" then
		local name = utils.trim(data.name)
		local x = data.x
		local y = data.y
		local r = data.r
		local layout_id = data.layout_id
		
		if not name or name == ""
		    or not x or x == ""
		    or not y or y == ""
		    or not layout_id or layout_id == "" then

		    return res:json({
		    	rv = 511,
		    	msg = "详细位置name、x、y、layout_id不能为空." 
		    	})
		end

		if not r or r == "" then 
			r = 5
		else
			r = r
		end

		local result, err = layout_model:add_position(name, x, y, r, layout_id)
		local isExist = false

		if result and not err then
			isExist = true
		end

		if isExist == false then
			return res:json({
				rv = 512,
				msg = "位置信息存取出错." 
				})
		end

		local result, err = layout_model:query_pos_id(name, x, y, r, layout_id)
		local isExist = false

		if result and not err then
			isExist = true
		end

		if isExist == false then
			return res:json({
				rv = 513,
				msg = "位置未存储成功." 
			})
		else
			return res:json({
					rv = 200,
					msg = "success",
					ids = result.id
				})
		end
	end

	if act == "del" then
		local pos_id = data.id
		if not pos_id or pos_id == "" then 
			return res:json({
				rv = 514,
				msg = "位置pos_id不能为空."
				})
		end

		local result,err = layout_model:query_pos_id_exsist(pos_id)
		local isExist = false

		if result and not err then
			isExist = true
		end

		if isExist == false then
			return res:json({
				rv = 515,
				msg = "该点位置不存在，请核实."
				})
		end

		local result, err = layout_model:del_position(pos_id)
		local isExist = false

		if result and not err then
			isExist = true
		end

		if isExist == false then
			return res:json({
				rv = 516,
				msg = "删除失败，重试."
				})
		else 
			return res:json({
				rv = 200,
				msg = "success",
				ids = pos_id
				})
		end	
	end

	if act == "upd" then
		local pos_id = data.id
		if not pos_id or pos_id == "" then 
			return res:json({
				rv = 517,
				msg = "修改的位置id不得为空."
				})
		end

		local result,err = layout_model:query_pos_id_exsist(pos_id)
		local isExist = false

		if result and not err then
			isExist = true
		end

		if isExist == false then
			return res:json({
				rv = 518,
				msg = "该点位置不存在，请核实."
				})
		end

	    local cnt = 0

	    for k, v in pairs(data) do 
	    	if k ~= "id" then
	    	cnt = cnt + 1 
	    	end 
	    end 

		if  cnt == 0 then
			return res:json({
				rv = 519,
				msg = "更新内容不得为空."
				})
		end
		local match_tb = {['name']='position',['x']='pos_x',['y']='pos_y',['r']='pos_r',['lock']='is_lock'}

		local pos_param = ""
		
		for key, val in pairs(data) do
		     	
			local tmp = match_tb[key]
			
			if tmp ~= nil then
	
				if (type(val) == "string") then 
					pos_param = pos_param .. ", " .. tmp .. "= " ..ngx.quote_sql_str(val)
				else
					pos_param = pos_param .. ", " .. tmp .. "= " .. val
				end

			end
		end

		if (#pos_param == 0) then
			return res:json({
				rv = 520,
				msg = "更新内容未使用指定的键值."
				})
		end
		pos_param = ssub(pos_param,2)

		local result, err = layout_model:upd_position(pos_id,pos_param)
		local isExist = false

		if result and not err then
			isExist = true
		end

		if isExist == false then
			return res:json({
				rv = 521,
				msg = "更新失败." 
				})
		else
			return res:json({
				rv = 200,
				msg = "success",
				ids = pos_id
				})
		end
	end
	
	-- 批量解除关联关系
	if act == "batch_coup" then 
		local dept_code = data.dept_id
		local layout_id = data.layout_id

		if not dept_code or dept_code == "" or not layout_id then
			return res:json({
				rv = 531,
				msg = "批量解除联结关系必须要有layout_id、部门编码."
				})
		end

		local result, err = layout_model:batch_discoup_pos(dept_code,layout_id)
		if result and not err then
				return res:json({
					rv = 200,
					msg = "success",
					filter = {dept_code = dept_code,
							  layout_id = layout_id}
					}) 
		end
		return res:json({
			rv = 532,
			msg = "解除关联失败."
			})
	end

	if act == "coup" then 
		local pos_id = data.id
		local dept_code = data.dept_id
		local coup = data.coup
		if not pos_id or pos_id == "" or not dept_code or dept_code == "" or not coup or coup == "" then
			return res:json({
				rv = 522,
				msg = "建立联结关系必须要有位置id、部门编码、是否联结信息."
				})
		end

		local filter = {}
		filter["dept_id"] = dept_code
		filter["pos_id"] = pos_id

		if coup == 0 then --解除关联
			local result, err = layout_model:pos_discoup_dept(pos_id,dept_code)
			if result and not err then
				return res:json({
					rv = 200,
					msg = "success",
					filter = filter
					}) 
			end
			return res:json({
				rv = 523,
				msg = "解除关联失败."
				})
	    end

	    if coup == 1 then
	    	local result, err = layout_model:pos_coup_dept(pos_id,dept_code)
	    	if result and not err then
				return res:json({
					rv = 200,
					msg = "success",
					filter = filter
					}) 
			end
			return res:json({
				rv = 524,
				msg = "关联失败."
				})
	    end
	end
end)

layout_router:get("/position",function(req,res,next)
	local src = req.query.src 
	local tb = {'dept','pos','coup'} 
	if not src or src == "" or not utils.str_in_table(src,tb) then 
		return res:json({
			rv = 525,
			msg = "src不得为空，且数据必须在dept、pos、coup内."
		})
	end

	if src == "dept" then 
		local pos_id = req.query.pos_id
		if not pos_id or pos_id == "" then 
			return res:json({
				rv = 526,
				msg = "位置id信息不得为空"
				})
		end
		local result, err = layout_model:query_pos_id_exsist(pos_id)
		if result and not err then
			local result, err = layout_model:query_dept_by_pos(pos_id)
			local filter = {}
			filter["pos_id"] = pos_id
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					data = result,
					filter = filter
					})
			else 
				return res:json({
					rv = 527,
					msg = "该位置无关联部门信息."
					})
			end
		else
			return res:json({
				rv = 528,
				msg =  "该点位置不存在，请核实." 
				})
		end
	end

	if src == "pos" then 
		local dept_code = req.query.dept_id
		local layout_id = req.query.layout_id
		if not dept_code or dept_code == "" or not layout_id or layout_id == "" then 
			return res:json({
				rv = 529,
				msg = "查找位置信息必须要有部门编码和layout编号."
				})
		end

		local result, err = layout_model:query_pos_by_dept(dept_code,layout_id)
		if result and not err then 
			local filter = {}
			filter["dept_id"] = dept_code
			filter["layout_id"] = layout_id
			return res:json({
				rv = 200,
				msg = "success",
				data = result,
				filter = filter
				})
		else
			return res:json({
				rv = 530,
				msg = "该部门在此layout图上无关联位置信息."
				})
		end
	end
end)


return layout_router