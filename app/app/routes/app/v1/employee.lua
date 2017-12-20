local ipairs = ipairs
local sfind = string.find
local slower = string.lower
local supper = string.upper
local ssub = string.sub
local slen = string.len

local cjson = require("cjson")

local lor = require("lor.index")
local utils = require("app.libs.utils")
local config  = require("app.config.config")
local emp_model = require("app.model.emp")
local attendance_model = require("app.model.attendance")
local dept_model = require("app.model.dept")
local attach_model = require("app.model.attachments")

local emp_photo_dir = require("app.config.config").emp_photo_config.dir
local emp_photo_path = require("app.config.config").emp_photo_config.path
local emp_photo_default = require("app.config.config").emp_photo_config.default

local filepath_temp = require("app.config.config").upload_config.dir
local local_emp_photo_dir = require("app.config.config").local_emp_photo_config.dir
local local_emp_photo_path = require("app.config.config").local_emp_photo_config.path

local employee_router = lor:Router()


employee_router:get("/:emp_no/settings",function(req, res, next)

end)

employee_router:post("/:emp_no/avatar/upload",function(req,res,next)
	local file = req.file or {}
	local emp_no = req.params.emp_no 

	emp_no = supper(emp_no)
	if utils.chk_is_null(emp_no) then 
		return res:json({
			rv = 509,
			msg = "工号不能为空"
		})
	end

    if file.success and file.filename then 

	   co = coroutine.create(function (file,emp_no)

      	  local f_file = io.open(file.path, "r")
          local filesize = f_file:seek("end")
          local filename = file.filename

	      local extname = slower(file.extname)

	      io.close(f_file)

	      local result, err = os.execute("mv -f " .. filepath_temp .."/" .. filename .. " " .. local_emp_photo_dir .. "/" ..emp_no .. "." .. extname)

	      return res:json({
	      	rv = 200,
	      	msg = "success",
	      	data = {path = local_emp_photo_path,
	      			filename = emp_no.."."..extname}
	      })
        end)
  
      coroutine.resume(co,file,emp_no)

    else
	  return res:json({
	  		rv = 511,
        	success = false, 
	        msg = file.msg
	    })
    end
end)


employee_router:get("/:emp_no/avatar",function(req, res, next)

	local emp_no = req.params.emp_no
	local emp_no_p4 =  '/'..ssub(emp_no,1,4)..'/'..emp_no

	local emp_photo_0 = local_emp_photo_dir..'/'..emp_no..'.jpg'
	local emp_photo_1 = emp_photo_dir..emp_no_p4..'.JPG'
    local emp_photo_2 = emp_photo_dir..emp_no_p4..'.jpg'  

    local emp_photo = nil;


    local file, err = io.open(emp_photo_0)
    if file and not err then
        emp_photo = local_emp_photo_path..'/'..emp_no..'.jpg'
        io.close(file)
        res:redirect(emp_photo)
        return
    end

    local file, err = io.open(emp_photo_1)
    if file and not err then
        emp_photo = emp_photo_path..emp_no_p4..'.JPG'
        io.close(file)
        res:redirect(emp_photo)
        return
    end

    local file1, err = io.open(emp_photo_2)
    if file1 and not err then
        emp_photo = emp_photo_path..emp_no_p4..'.jpg'
        io.close(file1)
        res:redirect(emp_photo)
        return
    end

    res:status(404):send('404! sorry, not found avatar.' )

end)

employee_router:get("/find",function(req, res, next)

	ngx.log(ngx.ERR,"  -------------------------------  ")
	local card = req.query.card_no or req.body.card_no
	local emp = req.query.emp_no

	if (not card or card == "") and  (not emp or emp == "") then 
		return res:json({
			rv = 500,
			msg = "卡号card_no或者工号emp_no不能为空."
		})
	end

	if card and card ~= "" then 
		local result, err = emp_model:query_empinfo_by_emp_card(card)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = {emp_info = result or {}} or {}
			})
		end

		return res:json({
			rv = 501,
			msg = "没有卡号对应员工记录"
		})
	end

	if emp and emp ~= "" then 
		local result, err = emp_model:query_full_empinfo_by_emp(emp)
		if result and not err then 
			return res:json({
				rv = 200,
				msg = "success",
				data = {emp_info = result or {}} or {}
			})
		end

		return res:json({
			rv = 505,
			msg = "没有工号对应员工记录"
		})
	end
end)


employee_router:post("",function(req,res,next)
	local src = req.body.src
	local data = req.body.data

	if utils.chk_is_null(src, data)  then
		return res:json({
				rv = 502,
				msg = "src和data参数不能为空。"  
		})
	end

	local dept_code = data.dept_code
	local card_no = data.card_no
	local emp_no = data.emp_no

	if utils.chk_is_null(dept_code, card_no, emp_no) then
		return res:json({
				rv = 503,
				msg = "dept_code、card_no、emp_no不能为空。"  
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
				rv = 508,
				msg = "关联部门与员工关系失败."
			})
		end 
	end

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
				rv = 506,
				msg = "绑定工号与卡号关联失败,重试."
			})
		end

		return res:json({
			rv = 200,
			msg = "success"
		})
	end

	return res:json({
		rv = 507,
		msg = "已有绑定，请先解绑"
	})
end)

return employee_router