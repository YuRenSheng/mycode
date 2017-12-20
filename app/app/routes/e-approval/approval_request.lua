local lor = require("lor.index")
local cjson = require("cjson")
local utils = require("app.libs.utils")
local slower = string.lower
local filedir_temp = require("app.config.config").upload_config.dir
local filepath_temp = require("app.config.config").upload_config.path
local filepath = require("app.config.config").upload_files.path
local filedir = require("app.config.config").upload_files.dir
local approval = require("app.model.approval")
local approval_func = require("app.routes.e-approval.approval_func")

local request_form_router = lor:Router()


local function checksrc(src)
	local srcs = {"type","dept","request","approval_person",
							  "approval_activity","del_file","code"}
	for k,v in ipairs(srcs) do
		if v == src then
			return true
		end
	end
	return false
end

request_form_router:get("",function(req,res,next)
	local src = req.query.src

	if utils.chk_is_null(src) then
		return res:json({
				rv = 501,
				msg = "src不能为空"
			})
	end

	if not checksrc(src) then
		return res:json({
				rv = 502,
				msg = "src错误"
			})
	end


	--查询单据类型
	if src == "type" then
		local result,err = approval:query_request_form_type()
		if result and not err then
			return res:json({
					rv = 200,
					type = "M",
					msg ="success",
					data = result
				})
		else
			return res:json({
					rv = 500,
					msg = "查询错误"
				})
		end
	end

	--查询审核人类型
	if src == "approval_activity" then
		local result,err = approval:query_approval_activity()
		if result and not err then
			return res:json({
					rv = 200,
					type = "M",
					msg ="success",
					data = result
				})
		else
			return res:json({
					rv = 500,
					msg = "查询错误"
				})
		end
	end

	--根据工号查询审核人
	if src == "approval_person" then
		local emp_no = req.query.emp_no
		if utils.chk_is_null(emp_no) then
			return res:json({
					rv = 501,
					msg = "emp_no不能为空"
				})
		end

		local result,err = approval:query_approval_person_by_empno(emp_no)
		if result and not err then
			return res:json({
					rv = 200,
					type = "S",
					msg = "success",
					data = result
				})
		else
			return res:json({
					rv = 501,
					msg = "查询错误"
				})
		end

	end

--[[	--刪除申請單
	if src == "del_form" then
		local formid = req.query.formid
		local result1,err1 = approval:delete_request_form(formid)
		if not result1 or err1 then
			return res:json({
						rv = 501,
						msg = "刪除失敗"
				   })
		else
			return res:json({
						rv = 200,
						msg = "success"
					})
		end

	end--]]



end)

--上传文件
request_form_router:post("/upload",function(req,res,next)
	local file = req.file or {}

    if file.success and file.filename and slower(file.extname) == "pdf" then

	 	local co = coroutine.create(function (file)

      	  local f_file = io.open(file.path, "r")
          local filesize = f_file:seek("end")
          local disk_filename = file.filename
          local filename = file.origin_filename
	      local extname = slower(file.extname)

	      io.close(f_file)

	      return res:json({
	      	rv = 200,
	      	msg = "success",
	      	type = "S",
	      	data = {path = filepath_temp,
	      			filename = filename,
	      			disk_filename = disk_filename,
					filesize = filesize,
					content_type = extname}
	      })
        end)

      coroutine.resume(co,file)

    else
	  return res:json({
	  		rv = 500,
        	success = false,
	        msg = file.msg or "只允許上傳pdf類型."
	    })
    end
end)


request_form_router:post("",function(req,res,next)
	local act = req.body.act
	local key = req.body.key
	if utils.chk_is_null(act) then
		--刪除文件的判斷
  		if not key then
  			ngx.log(ngx.ERR,"key nil")
  			return res:json({
					rv = 501,
					msg = "act不能为空"
				})
  		else
  			key = utils.decodeBase64(key)
  			if not cjson.decode(key) then
  				ngx.log(ngx.ERR,"key change false")
  				return res:json({
					rv = 501,
					msg = "act不能为空"
				})
			else
			 	key = cjson.decode(key)
				if utils.chk_is_null(key.act) then
					ngx.log(ngx.ERR,"key act nil")
					return res:json({
						rv = 501,
						msg = "act不能为空"
					})
				end
  			end
  		end

		--[[return res:json({
				rv = 501,
				msg = "act不能为空"
			})
   --]]
	end

	--[[	local user_m = {username = 'tom',
            userid = 29,
            emp_no = 'F2828635',
            emp_name = '万科',
            dept_code = 'RYA307D',
            position = '专理',
            photo = nil,
            create_time =''}
    --]]
	local user = res.locals
	ngx.log(ngx.ERR,cjson.encode(user))
	--req.session.get("user") or user_m

--暂存
	if act == "pre_add"  then
		if not user then
			return res:json({
			rv = 502,
			msg = "該操作需要先登錄",
		})
		end

		local reqform_info = req.body.data
		local rv,msg,forminfo = approval_func.pre_addform(user,reqform_info)

		--暂存失败删除申请表
		if rv ~= 200 then
			if utils.chk_is_null(forminfo) and utils.chk_is_null(forminfo["id"]) then
				approval:delete_request_form(forminfo["id"])
			end
		end

		return res:json({
			rv = rv,
			msg = msg,
			data = forminfo
		})
	end
--提交
	if act == "submit"  then
		if not user then
			return res:json({
				rv = 502,
				msg = "該操作需要先登錄",
			})
		end
		local reqform_info = req.body.data
		local rv,msg,forminfo = approval_func.pre_addform(user,reqform_info)
		if rv == 200 then
			local rv1,msg1 = approval_func.checkForm(reqform_info)
			ngx.log(ngx.ERR,"檢查數據結果:"..rv1.." "..msg1)
			if rv1 == 200 then
				local submit_info = {["form_id"]=forminfo["id"],["emp_no"]=user.emp_no}
				local rv2,msg2,data2 = approval_func.submit_confirm(user,"init",submit_info)
				return res:json({
					rv = rv2,
					msg = msg2,
					data = data2
				})
			else
				--将暂存信息返回给前台,避免重复添加
				return res:json({
					rv = rv1,
					msg = msg1,
					data = forminfo
			})
		    end
		else
			--暂存失败删除申请表
			if utils.chk_is_null(forminfo) and utils.chk_is_null(forminfo["id"]) then
				approval:delete_request_form(forminfo["id"])
			end
			return res:json({
				rv = rv,
				msg = msg
			})
		end
	end

--刪除申請單
	if act == "del_form" then
		local formid = req.body.data.formid
		local filenames = req.body.data.filenames

		--移除緩存區文件
		for i=1,#filenames do
			local filename = filenames[i]
			local result,err = io.open(filedir_temp .."/" .. filename)
			--local result = os.execute("rm -f " .. filedir_temp .."/" .. filename)
			if not err then
				os.execute("rm -f " .. filedir_temp .."/" .. filename)
			end
		end
		--刪除申請單
		local result1,err1 = approval:delete_request_form(formid)
		if not result1 or err1 then
			return res:json({
						rv = 501,
						msg = "刪除失敗"
				   })
		else
			return res:json({
						rv = 200,
						msg = "success"
					})
		end

	end

--取消
	if act == "cancel" then
		local filenames = req.body.data.filenames

		--移除緩存區文件
		for i=1,#filenames do
			local filename = filenames[i]
			local result,err = io.open(filedir_temp .."/" .. filename)
			--local result = os.execute("rm -f " .. filedir_temp .."/" .. filename)
			if not err then
				os.execute("rm -f " .. filedir_temp .."/" .. filename)
			end
		end

		return res:json({
						rv = 200,
						msg = "success"
					})

	end

--刪除文件
	if act == "del_file" then
		local filename = req.body.filename

		local result,err = io.open(filedir_temp .."/" .. filename)
		if not err then
			os.execute("rm -f " .. filedir_temp .."/" .. filename)
		else
			local from = ngx.re.find(filename, ".pdf".."$")
			local result1,err1 = approval:delete_attachments(string.sub(filename,1,from-1))
			if err1 then
				return res:json({
					rv = 502,
					msg = "delete "..filename.." false",
				})
			else
				os.execute("rm -f " .. filedir .."/" .. filename)
			end
		end
		return res:json({
						rv = 200,
						msg = "success"
					})
	end

--刪除文件(key)
	if key.act == "del_file" then

		local filename = key.filename

		local result,err = io.open(filedir_temp .."/" .. filename)
		if not err then
			ngx.log(ngx.ERR,"缓存区找到")
			os.execute("rm -f " .. filedir_temp .."/" .. filename)
		else
			ngx.log(ngx.ERR,"缓存区未找到".."  "..filepath.."/"..filename)
			local result1,err1 = approval:delete_attachments(filepath.."/"..filename)
			if err1 then
				return res:json({
					rv = 502,
					msg = "delete "..filename.." false",
				})
			else
				os.execute("rm -f " .. filedir .."/" .. filename)
			end
		end
		return res:json({
						rv = 200,
						msg = "success"
					})
	end



end)


return request_form_router
