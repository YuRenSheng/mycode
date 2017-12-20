local pairs = pairs
local ipairs = ipairs
local sfind = string.find
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local cjson = require("cjson")
local utils = require("app.libs.utils")
local pwd_secret = require("app.config.config").pwd_secret
local lor = require("lor.index")
local attendant_model = require("app.model.attendance")
local emp_model = require("app.model.emp")
local dept_model = require("app.model.dept")

local attendant_router = lor:Router()

--[[
1、 点到 执行存储过程并返回结果

curl -X POST --data '{"src":"attendance",
    "data":{"plan_time":"2017-07-01 08:00:00","sponsor":"F4941769",
            "dept_code":"RYA307D","position_id":1,"activity_type":7}}' 
    -H 'Content-type: application/json' 
    http://127.0.0.1:8888/app/v1/attendance --noproxy 127.0.0.1 

{"msg":"success，RYA307D部門，F4941769發起的活動，人員已準備就緒。",
 "data":{"main":{"sponsor":"F4941769","id":36,"activity_type":1,
 "dept_code":"RYA307D","pos_id":1},"detail":[{"emp_no":"F2845464",
 "name":"代志遠","position":"無","card_no":null},{"emp_no":"F2845620",
 "name":"鄭慧慧","position":"無","card_no":null},{"emp_no":"F1678823",
 "name":"董闖","position":"無","card_no":null},{"emp_no":"F1668967",
 "name":"葛艷琴","position":"無","card_no":"FG124589"},{"emp_no":"F1668963",
 "name":"賴夢玲","position":"無","card_no":"FG1245"},{"emp_no":"F2828635",
 "name":"萬科","position":"專理","card_no":null}]},"rv":200}

2、 /swipin 点到 更新明细表
	无记录则插入数据

curl -X POST --data '{"src":"swipin",
    "data":{"parent_id":34,"emp_no":"F1668967","card_no":"5455",
            "status":1,"swipin_time":"2017-07-03 09:00:00","swipin_times":5}}' 
    -H 'Content-type: application/json' 
    http://127.0.0.1:8888/app/v1/attendance/swipin --noproxy 127.0.0.1

{"rv":200,"msg":"success","data":{"parent_id":34,"swipin_times":5,
 "emp_no":"F1668967","swipin_time":"2017-07-03 09:00:00","status":1,
 "card_no":"5455"},"act":"insert"}

	有记更新数据

curl -X POST --data '{"src":"swipin",
    "data":{"parent_id":34,"emp_no":"F1668967","card_no":"5455","status":1,
            "swipin_time":"2017-07-03 09:00:00","swipin_times":5}}' 
    -H 'Content-type: application/json' 
    http://127.0.0.1:8888/app/v1/attendance/swipin --noproxy 127.0.0.1

{"rv":200,"msg":"success","data":{"parent_id":34,"swipin_times":5,
"emp_no":"F1668967","swipin_time":"2017-07-03 09:00:00","status":1,
"card_no":"5455"},"act":"update"}

3、/swipin 点到 更新主表

curl -X POST --data '{"src":"activity",
    "data":{"id":35,"plan_begin_time":"2017-07-03 08:00:00",
       "plan_end_time":"2017-07-03 09:00:00","begin_time":"2017-07-04 08:20:00",
            "end_time":"2017-07-03 08:45:00","status":1,"memo":"amanda的肉包子"}}' 
    -H 'Content-type: application/json' 
    http://127.0.0.1:8888/app/v1/attendance/swipin --noproxy 127.0.0.1

{"msg":"success","data":{"memo":"amanda的肉包子","end_time":"2017-07-03 08:45:00"
,"id":35,"plan_begin_time":"2017-07-03 08:00:00",
"begin_time":"2017-07-04 08:20:00","status":1,
"plan_end_time":"2017-07-03 09:00:00"},"rv":200}

4、/member 添加人员 获取人员信息

curl -X GET http://127.0.0.1:8888/app/v1/attendance/member?code=RYA307D 
    --noproxy 127.0.0.1

{"msg":"success","data":[{"no":"F2845464","dept_code":"RYA307D",
"director":"F2828635-萬科-專理","name":"代志遠","position":"無","card_no":null},
{"no":"F2845620","dept_code":"RYA307D","director":"F2828635-萬科-專理",
"name":"鄭慧慧","position":"無","card_no":null},{"no":"F1678823",
"dept_code":"RYA307D","director":"F2828635-萬科-專理","name":"董闖",
"position":"無","card_no":null},{"no":"F2828635","dept_code":"RYA307D",
"director":"10858-張塘煌-資深經理","name":"萬科","position":"專理","card_no":null}]
,"rv":200}


5、/member 添加人员 记录活动数据

curl -X POST --data '{"src":"add_member",
    "data":{"emp_no":["F1678823","F1668967","F1668963"],"dept_code":"RYA307D",
    		"sponsor":"F1668963","position_id":1,"activity_type":2}}' 
    -H 'Content-type: application/json' 
    http://127.0.0.1:8888/app/v1/attendance/member --noproxy 127.0.0.1

{"msg":"success，RYA307D部門，F1668963發起的活動，人員已準備就緒。",
"data":{"main":{"sponsor":"F1668963","id":65,"activity_type":2,
"dept_code":"RYA307D","pos_id":1},"detail":[{"emp_no":"F1678823",
"name":"董闖","position":"無","card_no":null},{"emp_no":"F1668967",
"name":"葛艷琴","position":"無","card_no":null},{"emp_no":"F1668963",
"name":"賴夢玲","position":"無","card_no":null}]},"rv":200}

6、/card 添加人员 刷卡记录卡号，绑定工号,swipin更新明细表
	无记录则插入数据

curl -X POST --data '{"src":"swipin",
	data":{"parent_id":65,"emp_no":"F1668968","card_no":"dgwedgyweidge",
		   "status":1,"swipin_time":"2017-07-03 09:00:00","swipin_times":5}}' 
	-H 'Content-type: application/json' 
	http://127.0.0.1:8888/app/v1/attendance/card --noproxy 127.0.0.1

{"rv":200,"msg":"success","data":{"parent_id":65,"swipin_times":5,
"emp_no":"F1668968","swipin_time":"2017-07-03 09:00:00","status":1,
"card_no":"dgwedgyweidge"},"act":"insert"}

	有记更新数据

curl -X POST --data '{"src":"swipin",
    "data":{"parent_id":65,,"emp_no":"F1678823","card_no":"dgwed7895e",
    	"status":1,"swipin_time":"2017-07-03 09:00:00","swipin_times":5}}' 
    -H 'Content-type: application/json' 
    http://127.0.0.1:8888/app/v1/attendance/card --noproxy 127.0.0.1

{"rv":200,"msg":"success","data":{"parent_id":65,"swipin_times":5,
"emp_no":"F1678823","swipin_time":"2017-07-03 09:00:00","status":1,
"card_no":"dgwed7895e"},"act":"update"}

7、/card 添加人员 更新主表

curl -X POST --data '{"src":"activity",
	"data":{"id":65,"plan_begin_time":"2017-07-03 08:00:00",
	   "plan_end_time":"2017-07-03 09:00:00","begin_time":"2017-07-04 08:20:00",
	   "end_time":"2017-07-03 08:45:00","status":1}}' 
	-H 'Content-type: application/json'
	http://127.0.0.1:8888/app/v1/attendance/swipin --noproxy 127.0.0.1

{"msg":"success","data":{"end_time":"2017-07-03 08:45:00","id":65,
"plan_begin_time":"2017-07-03 08:00:00","begin_time":"2017-07-04 08:20:00",
"status":1,"plan_end_time":"2017-07-03 09:00:00"},"rv":200}

]] --

-- 点到数据生成
attendant_router:post("",function(req, res, next)
	local src = req.body.src
	local data = req.body.data
	if not src or src == "" or src ~="attendance"
	    or not data or data == "" then

		return res:json({
				rv = 500,
				msg = "src和data参数不能为空,且src值只能为attendance."  
			})
	end

	local plan_time = data.plan_time
	local sponsor = supper(data.sponsor)
	local dept_code = data.dept_code
	local pos_id = data.position_id
	local activity_type = data.activity_type

	if not plan_time or plan_time == "" or not sponsor or sponsor == "" 
		or not dept_code or dept_code == "" or not pos_id or pos_id == ""
		or not activity_type or activity_type == "" then 

		return res:json({
			rv = 501,
			msg = "计划时间、发起人、部门代码、位置ID和活动类型都不得为空."
		})
	end

	local result, err = attendant_model:call_make_activity_swipin(plan_time,
								sponsor,dept_code,pos_id,activity_type)

	if result and not err then
		result = cjson.decode(result)

		if result.rv and result.rv == 0 then
			local activity_id = result.data.activity_id

			local detail_res,err = attendant_model:query_emp_detail_swipin(activity_id)

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

				return res:json({
					rv = 200,
					msg = "success，" .. result.msg ,
					data = data
				})
			end

			return res:json({
				rv = 502,
				msg = "未查找到员工明细信息." 
			})

		end

		return res:json({
			rv = 503,
			msg = result.msg
		})

	else
		return res:json({
			rv = 504,
			msg = "存储过程执行失败" 
		})
	end
end)

-- 点到完成
attendant_router:post("/swipin",function(req, res, next)
	local src = req.body.src
	local data = req.body.data
	local tb = {"swipin","activity"}

	if not src or src == "" or not utils.str_in_table(src,tb)
	    or not data or data == "" then

	    return res:json({
				rv = 505,
				msg = "src和data参数不能为空,且src值只能在swipin、activity内."  
		})
	end

	-- 明细表更新字段
	if src == "swipin" then  
		local parent_id = data.parent_id
		local emp_no = supper(data.emp_no)
		local card_no = data.card_no
		local status = data.status
		local swipin_time = data.swipin_time
		local swipin_times = data.swipin_times

		if not parent_id or parent_id =="" or not card_no or card_no == ""
			or not status or status == "" or not swipin_time or swipin_time ==""
			or not swipin_times or swipin_times == "" or not emp_no 
			or emp_no =="" then 
			return res:json({
				rv = 506,
				msg = "更新内容必须包括parent_id、工号、卡号、刷卡状态、时间、次数."
			})
		end

		local result,err = attendant_model:query_activity_id_available(parent_id)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			return res:json({
				rv = 507,
				msg = "无此id，请检查."
			})
		end

		local result, err = attendant_model:query_swipin_exsist_by_emp(parent_id
										,emp_no,card_no)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			local result, err = attendant_model:add_swipin_history(parent_id,
								emp_no,card_no,status,swipin_time,swipin_times)
			if result and not err then 
				return res:json({
					rv = 200,
					act = "insert",
					msg = "success",
					data = data
				})
			end 

			return res:json({
				rv = 508,
				msg = "插入数据失败" .. err
			})
		end

		local match_tb = {['status']='status',['swipin_time']='swipin_time',
						  ['swipin_times']='swipin_times'}
		local param = utils.upd_param(data,match_tb)

		local result, err = attendant_model:upd_swipin_history(parent_id,
						card_no,emp_no,param)
		if result and not err then 
			return res:json({
				rv = 200,
				act = "update",
				msg = "success",
				data = data
			})
		end

		return res:json({
			rv = 509,
			msg = "更新失败" 
		})

	end

	-- 主表更新字段
	if src == "activity" then 
		local id = data.id
		local plan_begin_time = data.plan_begin_time
		local plan_end_time = data.plan_end_time
		local begin_time = data.begin_time 
		local end_time = data.end_time
		local status = data.status  
		local memo = data.memo

		if not id or id == "" or not plan_begin_time or plan_begin_time == ""
			or not plan_end_time or plan_end_time == "" or not status 
			or status == ""or not begin_time or begin_time == "" 
			or not end_time or end_time == "" then

			return res:json({
				rv = 510,
				msg = "更新内容必须包括id，计划开始、结束时间，活动开始、结束时间，状态"
			})
		end

		local result, err = attendant_model:query_activity_id_available(id)
		local isExist = false
		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			return res:json({
				rv = 511,
				msg = "无此id，请检查."
			})
		end

		local match_tb = {['plan_begin_time']='plan_begin_time',
						  ['plan_end_time']='plan_end_time',
						  ['begin_time']='begin_time',['end_time']='end_time',
						  ['status']='status',['memo']='memo'}
		local param = utils.upd_param(data,match_tb)

		local result, err = attendant_model:upd_activity_history(id,param)
		if result and not err then
			return res:json({
				rv = 200,
				msg = "success",
				data = data 
			})
		end

		return res:json({
			rv = 512,
			msg = "更新失败"
		})

	end
end)

-- 读取未记录卡号的员工，添加组员开始
attendant_router:get("/member",function(req, res, next)
	local dept_code = req.query.code
	if not dept_code or dept_code == "" then 
		return res:json({
			rv = 513,
			msg = "部门代码不得为空."
		})
	end

	local result, err = attendant_model:query_new_emp_by_dept(dept_code)

	if result and not err then 
		return res:json({
			rv = 200,
			msg = "success",
			data = result
		})
	end

	return res:json({
		rv = 514,
		msg = "无记录."
	})
end)

-- 生成添加人员活动 ，批量添加按钮    
attendant_router:post("/member",function(req, res, next)
	local src = req.body.src
	local data = req.body.data

	if not src or src == "" or src ~= "add_member"
	    or not data or data == "" then

	    return res:json({
				rv = 515,
				msg = "src和data参数不能为空,且src值只能在add_member内."  
		})
	end

	local sponsor = supper(data.sponsor)
	local dept_code = data.dept_code
	local pos_id = data.position_id
	local activity_type = data.activity_type
	local emp_batch = data.emp_no 

	local emp_param = utils.TableToStr(emp_batch)

	if not emp_param or emp_param == "" or not sponsor or sponsor == "" 
		or not dept_code or dept_code == "" or not pos_id or pos_id == ""
		or not activity_type or activity_type == "" then 

		return res:json({
			rv = 516,
			msg = "所选员工工号、发起人、部门代码、位置ID和活动类型都不得为空."
		})
	end

	local result,err = attendant_model:call_add_new_member_activity_swipin(emp_param,
									sponsor,dept_code,pos_id,activity_type)
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

				return res:json({
					rv = 200,
					msg = "success，" .. result.msg ,
					data = data
				})
			end

			return res:json({
				rv = 517,
				msg = "未查找到员工明细信息,员工工号无效."
			})

		end

		return res:json({
			rv = 518,
			msg = result.msg
		})

	else
		return res:json({
			rv = 519,
			msg = "存储过程执行失败" 
		})
	end
end)

-- 刷卡记录卡号，绑定工号
attendant_router:post("/card",function(req, res, next)
	local src = req.body.src
	local data = req.body.data

	local tb = {"swipin","activity"}

	if not src or src == "" or not utils.str_in_table(src,tb)
	    or not data or data == "" then

	    return res:json({
				rv = 520,
				msg = "src和data参数不能为空,且src值只能在swipin、activity内."  
		})
	end

	if src == "swipin" then
		local parent_id = data.parent_id
		local emp_no = supper(data.emp_no)
		local card_no = data.card_no
		local status = data.status
		local swipin_time = data.swipin_time
		local swipin_times = data.swipin_times

		if not parent_id or parent_id =="" or not card_no or card_no == "" 
			or not status or status == "" or not swipin_time or swipin_time ==""
			or not swipin_times or swipin_times == "" or not emp_no 
			or emp_no =="" then 
			return res:json({
				rv = 521,
				msg = "更新内容必须包括parent_id、工号、卡号、刷卡状态、时间、次数."
			})
		end

		local result, err = attendant_model:query_activity_id_available(parent_id)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			return res:json({
				rv = 522,
				msg = "无此id，请检查."
			})
		end

		local dept_code = result.dept_code

		local result, err = dept_model:query_dept_exists_by_dept(dept_code)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			return res:json({
				rv = 525,
				msg = "部门代码不存在."
			})
		end 

		local result, err = dept_model:query_dept_type_by_code(dept_code)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then  
			local result, err =  emp_model:add_emp_dept_extra(dept_code,emp_no)
			local isExist = false

			if result and not err then 
				isExist = true
			end

			if isExist == false then 
				return res:json({
					rv = 532,
					msg = "关联部门与员工关系失败."
				})
			end 
		end

	-- 工号或卡号原本无关联关系才可绑定
		local card_result, err = emp_model:query_emp_by_card(card_no)
		local emp_result, err = emp_model:query_card_by_emp(emp_no)

		local isExist = false
		if (card_result and not err) or (emp_result and not err) then
			isExist = true
		end

		if isExist == false then 
			local result, err = emp_model:add_card_emp_relate(emp_no,card_no)
			local isExist = false

			if result and not err then 
				isExist = true
			end

			if isExist == false then
				return res:json({
					rv = 527,
					msg = "绑定工号与卡号关联失败,重试."
				})
			end
		end

	-- 只做记录
		local result,err = attendant_model:query_swipin_exsist_by_emp_member(parent_id,emp_no)
		local isExist = false

		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			local result, err = attendant_model:add_swipin_history(parent_id,
							emp_no,card_no,status,swipin_time,swipin_times)
			if result and not err then 
				return res:json({
					rv = 200,
					act = "insert",
					msg = "success",
					data = data
				})
			end 

			return res:json({
				rv = 523,
				msg = "插入数据失败" 
			})
		end

		local match_tb = {['status']='status',['swipin_time']='swipin_time',
						['swipin_times']='swipin_times',['card_no']='card_no'}
		local param = utils.upd_param(data,match_tb)

		local result, err = attendant_model:upd_swipin_history_member(parent_id,
										emp_no,param)
		if result and not err then 
			return res:json({
				rv = 200,
				act = "update",
				msg = "success",
				data = data
			})
		end

		return res:json({
			rv = 524,
			msg = "更新失败" 
		})
	end

	if src == "activity" then 
		local id = data.id
		local plan_begin_time = data.plan_begin_time
		local plan_end_time = data.plan_end_time
		local begin_time = data.begin_time 
		local end_time = data.end_time
		local status = data.status  
		local memo = data.memo

		if not id or id == "" or not status or status == ""
			or not begin_time or begin_time == "" or not end_time or end_time == "" then

			return res:json({
				rv = 528,
				msg = "更新内容必须包括id，活动开始、结束时间，状态"
			})
		end

		local result, err = attendant_model:query_activity_id_available(id)
		local isExist = false
		if result and not err then 
			isExist = true
		end

		if isExist == false then 
			return res:json({
				rv = 529,
				msg = "无此id，请检查."
			})
		end

		local match_tb = {['plan_begin_time']='plan_begin_time',
						  ['plan_end_time']='plan_end_time',
						  ['begin_time']='begin_time',['end_time']='end_time',
						  ['status']='status',['memo']='memo'}
		local param = utils.upd_param(data,match_tb)

		local result, err = attendant_model:upd_activity_history(id,param)
		if result and not err then
			return res:json({
				rv = 200,
				msg = "success",
				data = data 
			})
		end

		return res:json({
			rv = 530,
			msg = "更新失败" 
		})
	end
end)

return attendant_router
