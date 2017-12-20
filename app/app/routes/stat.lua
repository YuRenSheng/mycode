local pairs = pairs
local ipairs = ipairs
local sfind = string.find
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len
local cjson = require("cjson")
local utils = require("app.libs.utils")
local lor = require("lor.index")
local stat_model = require("app.model.stat")
local dept_model = require("app.model.dept")
local src_model = require("app.model.src")
local stat_router = lor:Router()
    
-- 检查传入参数（参数一致）概况
local dashboard_param = function(req,res,next)
	local src = req.query.src
	local dimension = req.query.dim
	local begin_time = req.query.begin_time
	local end_time = req.query.end_time

	local tb_src = {'wastage','new','total_staff','att_rate',
                    'direct_indirect_manpower'}
	local tb_dimension = {'month','week','day'}

	if src then
		if src ~= "detail_total" then 
			if not src or src == "" or not utils.str_in_table(src,tb_src)
			  or not dimension or dimension == "" 
              or not utils.str_in_table(dimension,tb_dimension)
			  or not begin_time or begin_time =="" or not end_time 
              or end_time == "" then 
				return res:json({
					rv = 503,
					msg = [[src、dim、begin_time、end_time不能爲空，且src必須在
                            detail_total、wastage、new、total_staff、att_rate、
                            direct_indirect_manpower內，dim必須在month、week、day
                            內.]]
				})
			else
				next()
			end
		else
			next()
		end
	else
		return res:json({
			rv = 509,
			msg = [[src不能爲空,且src必須在detail_total、wastage、new、total_staff
                    、att_rate、direct_indirect_manpower內.]]
		})
	end	
	next()
end

-- 人力总数
local total_staff = function(req, res, next)
	local src = req.query.src
	local dimension = req.query.dim
	local begin_time = req.query.begin_time
	local end_time = req.query.end_time

	if src == "total_staff" then 

		local result, err = stat_model:query_total_staff(begin_time, end_time)

		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
				data = result
			})
		else
			return res:json({
				rv = 501,
				msg = "查詢失敗."
			})
		end
	else
		next()
	end
end

-- 出勤率（未完成）
local attendance_rate = function(req,res,next)
	local src = req.query.src
	local dimension = req.query.dim
	local begin_time = req.query.begin_time
	local end_time = req.query.end_time

	if src == "att_rate" then 

		local result,err = stat_model:query_attendance_rate(begin_time,end_time)

		return res:json({
			rv = 200,
			msg = "success",
			param = {dimension = dimension,
					 begin_time = begin_time,
					 end_time = end_time,
					 src = src},
			data = result
		})
	else
		next()
	end
end

-- 流失人力
local wastage = function(req,res,next)
	local src = req.query.src
	local dimension = req.query.dim
	local begin_time = req.query.begin_time
	local end_time = req.query.end_time

	if src == "wastage" then 

		if dimension == "month" then 
			local result, err = stat_model:query_month_wastage_emp(begin_time,end_time)
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
					data = result
				})
			else
				return res:json({
					rv = 505,
					msg = "by月查詢失敗."
				})
			end
		end

		if dimension == "week" then 
			local result, err = stat_model:query_week_wastage_emp(begin_time,end_time)
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
					data = result
				})
			else
				return res:json({
					rv = 507,
					msg = "by周查詢失敗."
				})
			end
		end

		if dimension == "day" then 
			local result, err = stat_model:query_day_wastage_emp(begin_time,end_time)
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
					data = result
				})
			else
				return res:json({
					rv = 509,
					msg = "by天查詢失敗."
				})
			end
		end
	else

		next()
	end
end

-- 新近人力
local new = function(req,res,next)
	local src = req.query.src
	local dimension = req.query.dim
	local begin_time = req.query.begin_time
	local end_time = req.query.end_time

	if src == "new" then 

		if dimension == "month" then 
			local result, err = stat_model:query_month_new_emp(begin_time,end_time)
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
					data = result
				})
			else
				return res:json({
					rv = 504,
					msg = "by月查詢失敗."
				})
			end
		end

		if dimension == "week" then 
			local result, err = stat_model:query_week_new_emp(begin_time,end_time)
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
					data = result
				})
			else
				return res:json({
					rv = 506,
					msg = "by周查詢失敗."
				})
			end
		end

		if dimension == "day" then 
			local result, err = stat_model:query_day_new_emp(begin_time,end_time)
			if result and not err then 
				return res:json({
					rv = 200,
					msg = "success",
					param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
					data = result
				})
			else
				return res:json({
					rv = 508,
					msg = "by天查詢失敗."
				})
			end
		end
	else

		next()
	end
end

-- 直间接人力比
local direct_indirect_manpower = function(req,res,next)
	local src = req.query.src
	local dimension = req.query.dim
	local begin_time = req.query.begin_time
	local end_time = req.query.end_time

	if src == "direct_indirect_manpower" then
		local result, err = stat_model:query_direct_indirect_rate(begin_time,end_time)

		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				param = {dimension = dimension,
							begin_time = begin_time,
							end_time = end_time,
							src = src},
				data = result
			})
		else
			return res:json({
				rv = 511,
				msg = "查詢失敗." 
			})
		end
	else

		next()
	end
end

-- 人力变更总数
local manpower_change_total = function(req,res,next)
	local src = req.query.src

	if src == "detail_total" then 
		local result, err = stat_model:query_manpower_change_list_total()

		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = result[1]
			})
		else 
			return res:json({
				rv = 520,
				msg = "查詢失敗."
			})
		end
	end
end

stat_router:get("", dashboard_param,total_staff,attendance_rate,wastage,new,
                    direct_indirect_manpower,manpower_change_total)

-- 人力變動明細
stat_router:get("/manpower_change_list",function(req,res,next)
	local src = req.query.src
	local tb = {'detail','name','no'}

	if not src or src == "" or not utils.str_in_table(src,tb) then 
		return res:json({
			rv = 512,
			msg = "src不能爲空，且src必須在detail、name、no內."
		})
	end

	if src == "detail" then
		local begin_row = tonumber(req.query.begin_row)
		local row = tonumber(req.query.row)

		if not begin_row or begin_row <=0 or not row or row <= 0 then 
			return res:json({
				rv = 513,
				msg = "begin_row和row不能爲空，且都必須大於0."
			})
		end

		local page_index = begin_row -1;

		local result,err = stat_model:query_manpower_change_list(page_index,row)

		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				param = {src = src,
						begin_row = begin_row,
						row = row},
				data = result
			})
		else
			return res:json({
				rv = 514,
				msg = "查詢失敗."
			})
		end
	end

	if src == "name" then 
		local name = req.query.name

		if not name or name == "" then 
			return res:json({
				rv = 515,
				msg = "name不能爲空，且爲繁體."
			})
		end

		local result, err = stat_model:query_manpower_change_list_by_name(name)

		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				param = {name = name,
						src = src},
				data = result
			})
		else
			return res:json({
				rv = 516,
				msg = "無此信息."
			})
		end
	end

	if src == "no" then 
		local no = req.query.no 

		if not no or no =="" then 
			return res:json({
				rv = 517,
				msg = "no不能爲空."
			})
		end

		no = supper(no)
		local result, err = stat_model:query_manpower_change_list_by_no(no)

		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				param = {no = no,
						src = src},
				data = result
			})
		else
			return res:json({
				rv = 518,
				msg = "無此信息."
			})
		end
	end
end)

-- 整体界面组织 组织分布 公共参数
local statbydept_param = function(req,res,next)
	local src = req.query.src 
	local tb = {"hr_dist"}
	if not src or not utils.str_in_table(src,tb) then
		return res:json({
			rv = 519,
			msg = "sr不得爲空，且src在".. cjson.encode(tb) .."内."
		})
	end
	next()
end

-- 部门架构
local get_dept = function(req,res,next)
	local src = req.query.src 
	if src == "hr_dist" then 
		local dept_code = req.query.dept_code
		if not dept_code or dept_code == "" then 
			return res:json({
				rv = 522,
				msg = "部门代码不能为空."
			})
		end

		local result ,err = dept_model:query_dept_exists_by_dept(dept_code)
		local isExist = false
		if result and not err then 
			isExist = true
		end

		if isExist == false then
			return res:json({
				rv = 521,
				msg = "無此部門."
			})
		end 

		local result, err = stat_model:query_manpower_distribution(dept_code)

		if result and not err then 
			local con_res, err1 = src_model:query_src_contrast_by_src(src)
			local fil_res, err2 = src_model:query_index_content_by_src(src)
	
			return res:json({
				rv = 200,
				msg = "success",
				data = result,
				fields = con_res or {},
				filters = fil_res or {},
				param = {src = src ,
						dept_code = dept_code}
			})
		else
			return res:json({
				rv = 520,
				mag = "查詢失敗."
			})
		end
	end
end

stat_router:get("/dept",statbydept_param,get_dept)

stat_router:post("/dept",function(req,res,next)
	local act = req.body.act
	local act_tb = {"add","del","upd"}

	local user = res.locals --req.session.get("user")
	local author = user.emp_no
--	author = 'F1668963'

	if  utils.chk_is_null(act) or not utils.str_in_table(act,act_tb) then 
		return res:json({
			rv = 520,
			msg = "act不能为空."
		})
	end

	if act == "add" then 
		local item = req.body.item
		local src = req.body.src

		local item = cjson.encode(item) or item 
		if utils.chk_is_null(item,src) then 
			return res:json({
				rv = 521,
				msg = "item 和 src 不能为空."
			})
		end

		local result,err = src_model:query_exists_by_src(src)
		if not result or err then 
			return res:json({
				rv = 522,
				msg = "src无效."
			})
		end

		local result ,err = src_model:add_indicat(item,author,src)

		if not result or err then 
			return res:json({
				rv = 523,
				msg = "新增失败."
			})
		end

		return res:json({
			rv = 200,
			msg = "success",
			data = {--name = name,
					item = item,
					id = result,
					author = author}
		})
	end

	local id = req.body.id
	if  utils.chk_is_null(id) then 
		return res:json({
			rv = 525,
			msg = "id不能为空."
		})
	end

	if act == "del" then 

		local result ,err = src_model:del_indicat(id,author)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = {id = id,
						author = author}
			})
		end

		return res:json({
			rv = 526,
			msg ="删除模板失败."
		})
	end

	if act == "upd" then 
		local item = req.body.item
		if  utils.chk_is_null(item) then 
			return res:json({
				rv = 528,
				msg = "item不能为空."
			})
		end
		
		local item = cjson.encode(item) or item 

		local result,err = src_model:upd_indicat(id,item,author)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				id = id
			})
		end

		return res:json({
			rv = 527,
			msg ="更新模板失败."
		})
	end
end)
return stat_router