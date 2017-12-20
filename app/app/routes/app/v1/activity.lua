local pairs = pairs
local ipairs = ipairs
local sfind = string.find
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local lor 	= require("lor.index")
local cjson = require("cjson")
local filepath_temp = require("app.config.config").upload_config.dir
local filepath_dir = require("app.config.config").attendance_upload_config.dir
local filepath = require("app.config.config").attendance_upload_config.path

local utils 	 = require("app.libs.utils")
local pwd_secret = require("app.config.config").pwd_secret

local attendant_model = require("app.model.attendance")
local emp_model 	  = require("app.model.emp")
local dept_model 	  = require("app.model.dept")
local attach_model = require("app.model.attachments")

-- call-the-roll  		点名
-- link-the-card-no  	绑定卡号与工号和所属部分的关系
-- leave-the-post 		离岗/返岗 return to the post
-- check-the-post		查岗
-- sign-in				签到
-- check-in				报到
-- call-for-help		异常呼叫

local activity_list = {	
					"link-the-card-no",
					"leave-the-post",
					"check-the-post",
					"sign-in",
					"check-in",
					"call-for-help",
					"call-the-roll"}

local function get_activity_type(activity_name)

	local index = 0

	for i=1,#activity_list do
		if (activity_name == activity_list[i]) then
			index = i 
			break
		end
	end	

	return index
end					

local action = { "pre","add","upd","del"}

local activity_router = lor:Router()

function activity_router:call_the_roll(act,data)

	local plan_time = data.plan_time
	local sponsor 	= supper(data.sponsor)
	local dept_code = data.dept_code
	local pos_id 	= data.position_id
	local activity_type = data.activity_type or 7

	if utils.chk_is_null(plan_time, sponsor, dept_code, pos_id, activity_type) then

		return {
			rv = 501,
			msg = '计划时间、发起人、部门代码、位置ID和活动类型都不得为空,act 在"pre","add","upd"内'
		}
	end


	local p_status
	if act == "pre" then p_status = 0 end
	if act == "add" then p_status = 1 end

	local result, err = attendant_model:call_make_activity_swipin(plan_time,sponsor,dept_code,pos_id,activity_type,p_status)

	if result and not err then
		if p_status ==1 then
			result1 = result[3]
			result = result1[1].o_res
			result = cjson.decode(result)
				ngx.log(ngx.ERR,cjson.encode(result))
			if result.rv and result.rv == 0 then
				local activity_id = result.data.activity_id

				local detail_res, err = attendant_model:query_emp_detail_swipin(activity_id)

				if detail_res and not err then
				    local data = {}
				    local activity = {}

				    activity.id = activity_id
				    activity.dept_code = dept_code
				    activity.sponsor = sponsor
				    activity.pos_id = pos_id
				    activity.activity_type = activity_type

				    data.main = activity
				    data.detail = detail_res

					return {
						rv = 200,
						msg = "success，" .. result.msg ,
						data = data,
						type = "N"
					}
				end

				return {
					rv = 502,
					msg = "未查找到员工明细信息." 
				}

			end

			return {
				rv = 503,
				msg = result.msg
			}
		elseif p_status == 0 then
			local result1 = result[2]
			local result2 = result[4]
			local res_info = {}
			res_info.main = cjson.decode(result2[1].o_res)
			res_info.detail = result1
				ngx.log(ngx.ERR,cjson.encode(res_info))
			return {
				rv = 200,
				msg = "success",
				data = res_info,
				type = "N"
			}
		end
	else
		return {
			rv = 504,
			msg = "存储过程执行失败" 
		}
	end
end

-- 生成添加人员活动 ，批量添加按钮    
function activity_router:link_the_card_no(act,data)

	if not act or act == "" then 
		return {
			rv = 505,
			msg = "act 不能为空."
		}
	end

	if act == "pre" then 
		local dept_code = data.dept_code
		if not dept_code or dept_code == "" then 
			return {
				rv = 506,
				msg = "部门代码不得为空."
			}
		end

		local result, err = attendant_model:query_new_emp_by_dept(dept_code)

		if result and not err then 
			return {
				rv = 200,
				msg = "success",
				data = result,
				type = "M"
			}
		end

		return {
			rv = 507,
			msg = "无记录."
		}
	end

	if act == "add" then 
		local sponsor = supper(data.sponsor)
		local dept_code = data.dept_code
		local pos_id = data.position_id
		local activity_type = data.activity_type or 2
		local emp_batch = data.emp_no 

		local emp_param = utils.TableToStr(emp_batch)

		if utils.chk_is_null(emp_param, sponsor, dept_code, pos_id, activity_type) then
			return {
				rv = 508,
				msg = "所选员工工号、发起人、部门代码、位置ID和活动类型都不得为空."
			}
		end

		local result, err = attendant_model:call_add_new_member_activity_swipin(emp_param,sponsor,dept_code,pos_id,activity_type)
		if result and not err then

			result = cjson.decode(result)

			if result.rv and result.rv == 0 then
				local activity_id = result.data.activity_id

				local detail_res, err = attendant_model:query_emp_detail_swipin(activity_id)

				if detail_res and not err then
				    local data = {}
				    local activity = {}
				    activity.id = activity_id
				    activity.dept_code = dept_code
				    activity.sponsor = sponsor
				    activity.pos_id = pos_id
				    activity.activity_type = activity_type

				    data.main = activity
				    data.detail = detail_res

					return {
						rv = 200,
						msg = "success，" .. result.msg ,
						data = data,
						type = "N"
					}
				end

				return {
					rv = 509,
					msg = "未查找到员工明细信息,员工工号无效."
				}
			end

			return {
				rv = 510,
				msg = result.msg
			}

		else
			return {
				rv = 511,
				msg = "存储过程执行失败" 
			}
		end
	end
end

function activity_router:update_activity_history(data)
	-- 主表更新字段

	local id = data.id
	local plan_begin_time = data.plan_begin_time
	local plan_end_time = data.plan_end_time
	local begin_time = data.begin_time 
	local end_time = data.end_time
	local status = data.status  
	local memo = data.memo

	-- end-time allow is null by status == startup
	if utils.chk_is_null(id, plan_begin_time,plan_end_time,status,begin_time) then
		return{
			rv = 523,
			msg = "更新内容必须包括id，计划开始、结束时间，活动开始、结束时间，状态"
		}
	end

	local result, err = attendant_model:query_activity_id_available(id)
	local isExist = false
	if result and not err then 
		isExist = true
	end

	if isExist == false then 
		return{
			rv = 524,
			msg = "无此id，请检查."
		}
	end

	local match_tb = {['plan_begin_time']='plan_begin_time',['plan_end_time']='plan_end_time',['begin_time']='begin_time',['end_time']='end_time',['status']='status',['memo']='memo'}
	local param = utils.upd_param(data,match_tb)

	local result, err = attendant_model:upd_activity_history(id,param)
	if result and not err then
		return{
			rv = 200,
			msg = "success",
			data = data 
		}
	end

	return {
		rv = 525,
		msg = "更新失败"
	}
end

activity_router:post("",function(req, res, next)
	local src = req.body.src
	local act = req.body.act
	local data = req.body.data

	if utils.chk_is_null(src, act, data) then
		return res:json({
				rv = 512,
				msg = "src和data参数不能为空。"  
			})
	end

	if not utils.str_in_table(src,activity_list) then
		return res:json({
				rv = 513,
				msg = "src 的值不在 activity_list 清单中。" 
			})		
	end

	if act == "upd" then
		return res:json(activity_router:update_activity_history(data))
	end

	-- call-the-roll
	if src == activity_list[7] then
		return res:json(activity_router:call_the_roll(act,data))
	end 

	-- link-the-card-no
	if src == activity_list[1] then
		return res:json(activity_router:link_the_card_no(act,data))
	end 

	return res:json({
				rv = 514,
				msg = "没有找到处理这个activity的方法。"
			})
end)

activity_router:get("/flow_steps",function(req,res,next)
	local activity = req.query.src

	if utils.chk_is_null(activity) or 
		not utils.str_in_table(activity,activity_list) then
		return res:json({
			rv = 523,
			msg = "src 不能为空."
		})
	end

	local result,err = attendant_model:query_flow_step_by_activity(activity)

	if result and not err then 
		return res:json({
			rv = 200,
			msg = "success",
			data = result or {}
		})
	end

	return res:json({
		rv = 524,
		msg = "查询出错"
	})
end)

activity_router:get("/history",function(req, res, next)
	
	local src = req.query.src
	local sponsor = req.query.sponsor
	local dept_code = req.query.dept_code
	local pos_id = req.query.pos_id
	local activity_type = -1 

	if utils.chk_is_null(src, sponsor, dept_code, pos_id) then
		
		return res:json({
				rv = 515,
				msg = "参数不能为空。"  
			})
	end

	activity_type = get_activity_type(src)

	if activity_type == 0 then
		return res:json({
				rv = 516,
				msg = "src 的值不在 activity-list 清单中。"   
			})		
	end

	-- 通过 activity_type & sponsor & dept_code & pos_id 来从数据库查询和过滤数据,
	local result, err = attendant_model:get_main_activity_history(activity_type,sponsor,dept_code,pos_id)

	if result and not err then 
		return res:json({
			rv = 200,
			msg = "success",
			data = result,
			type = "M"
		})
	end

	return res:json({
		rv = 517,
		msg = "无历史记录."
	})
end)

activity_router:get("",function(req, res, next)
	local id = req.query.id

	if  utils.chk_is_null(id) then 
		return res:json({
			rv = 526,
			msg = "id 不能为空"
		})
	end

	local result1 ,err1 = attendant_model:get_activity_by_id(id)
	local result2 ,err2 = attendant_model:get_swipin_by_id(id)

	if result1 and result2 and not err1 and not err2 then 
		return res:json({
			rv = 200,
			msg = "success",
			data = {main = result1[1],
					detail = result2
				   },
			type = "N"
		})
	end

	return res:json({
		rv = 527,
		msg = "没有符合条件的查询"
	})
end)

--[[
swiping
+--------------+-------------+
| Field        | Type        |
+--------------+-------------+
| id           | int(11)     |
| parent_id    | int(11)     |
| emp_no       | varchar(45) |
| card_no      | varchar(45) |
| status       | varchar(45) | 
| swipin_time  | datetime    |
| swipin_times | int(11)     |
| create_at    | timestamp   |
| update_at    | timestamp   |
+--------------+-------------+

]]--

activity_router:post("/swiping", function(req, res, next)
	local act = req.body.act
	local data = req.body.data
	if     utils.chk_is_null(act, data)  or 
	   not utils.str_in_table(act, action) then
	    return res:json({
				rv = 518,
				msg = "act、data参数不能为空."  
		})
	end

	-- 明细表更新字段
	local parent_id = data.parent_id
	local emp_no = supper(data.emp_no)
	local card_no = data.card_no or ''
	local status = data.status
	local swipin_time = data.swipin_time
	local swipin_times = data.swipin_times
	--swipin_time , card_no allow is null
	if utils.chk_is_null(parent_id, status, swipin_times, emp_no) then 
		return res:json({
			rv = 519,
			msg = "更新内容必须包括parent_id、工号、卡号、刷卡状态、时间、次数."
		})
	end

	if act == "add" then 
		local result, err = attendant_model:add_swipin_history(parent_id,emp_no,card_no,status,swipin_time,swipin_times)
		if result and not err then 
			local result, err = attendant_model:query_swipin_exsist_by_emp_member(parent_id,emp_no)
			
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					data =  result,
					type = "M"
				})
			end
		end 

		return res:json({
				rv = 520,
				msg = "插入数据失败" .. err
			})
	end

	if act == "upd" then 

		--[[
		local result, err = attendant_model:query_activity_id_available(parent_id)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			return res:json({
				rv = 519,
				msg = "无此id，请检查."
			})
		end

		local result, err = attendant_model:query_swipin_exsist_by_emp(parent_id,emp_no,card_no)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			
			return res:json({
				rv = 530,
				msg = "没有这条记录，不能更新" 
			})
		end
		--]]
		local match_tb = {['status']='status',['swipin_time']='swipin_time',['swipin_times']='swipin_times'}
		local param = utils.upd_param(data,match_tb)

		local result, err = attendant_model:upd_swipin_history(parent_id,card_no,emp_no,param)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success"
			})
		end

		return res:json({
			rv = 521,
			msg = "更新失败" 
		})
	end
end)


activity_router:post("/:activity_id/live_photo/upload",function(req, res, next)  
	local file = req.file or {}
	local activity_id = req.params.activity_id

	if utils.chk_is_null(activity_id) then 
		return res:json({
			rv = 552,
			msg = "activity_id不能为空"
		})
	end

    if file.success and file.filename then 

	   co = coroutine.create(function (file)

      	  local f_file = io.open(file.path, "r")
          local filesize = f_file:seek("end")
          local filename = file.filename
          local digest = ssub(filename,1,36)

	      local extname = file.extname

	      io.close(f_file)

	      local result,err = os.execute("mv -f " .. filepath_temp .."/" .. filename .. " " .. filepath_dir)

	      local result, err = attach_model:add_layout(filename, filepath, extname, filesize, digest)
	  	  if result and not err then
	  	  	  local attach_link,err = attendant_model:link_attach_to_activity(result,activity_id)
	  	  	  	if attach_link and not err then 
		  	  	  local data = {}
		  	  	  data.origin_filename = file.origin_filename
		  	  	  data.filename = filename
		  	  	  data.filepath = filepath
		  	  	  data.filesize = filesize
		  	  	  data.id = result

			      return res:json({
			      		rv = 200,
			        	msg = "success", 
				     	data = data
				  })
				end
				return res:json({
					rv = 580,
					msg = "绑定大合照失败."
				})
		  end
		  return res:json({
		      		rv = 522,
		        	msg = "插入数据失败."
		  })

      end)
  
      coroutine.resume(co,file)

    else
	  return res:json({
	  		rv = 524,
        	success = false, 
	        msg = file.msg
	    })
    end
end)  

activity_router:get("/:activity_id/live_photo",function(req,res,next)
	local activity_id = req.params.activity_id
	if utils.chk_is_null(activity_id) then 
		res:status(404):send('404! sorry, params error. ' )
	end

	local result,err = attach_model:query_attachment_by_activity_id(activity_id)
	if result and not err then 
		local live_photo = result.link .."/" ..result.filename
		res:redirect(live_photo)
        return
	end

	res:status(404):send('404! sorry, not found live_photo.' )
end)

activity_router:get("/shift",function(req,res,next)
	local dept_code = req.query.dept_code
	local at_date = req.query.date or os.date("%Y-%m-%d %H:%M:%S")

	if utils.chk_is_null(dept_code,at_date) then 
		return res:json({
			rv = 550,
			msg = "dept_code不能为空."
		})
	end

	local shift_info,err = attendant_model:query_shift_by_dept(dept_code,at_date)
	if not shift_info or err then 
		return res:json({
			rv = 551,
			msg = "没有查找到班次信息."
		})
	end

	return res:json({
		rv = 200,
		msg = "success",
		result = shift_info
	})
end)

return activity_router
