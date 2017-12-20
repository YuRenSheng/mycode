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
local config = require("app.config.config")
local version_model = require("app.model.version_control")

local version_router = lor:Router()

version_router:get("update",function (req,res,next)
	local app_id = req.query.app_id
	local os_type = req.query.os_type
	local version = req.query.version

	if utils.chk_is_null(app_id,os_type,version) then 
		return res:json({
			rv = 500,
			msg = "app_id,os_type,version不能为空."
		})
	end

	local result, err = version_model:query_curr_version(app_id,os_type)
	if result and not err then 
		local curr_ver = result.version
		if utils.chk_is_null(curr_ver) then 
			return res:json({
				rv = 501,
				msg = "未维护版本信息，联系IT开发人员维护。"
			})
		end

		if curr_ver == version then 
			return res:json({
				rv = 200,
				upd = false,
				msg = "已是最新稳定版本"
			})
		end

		if curr_ver > version then 
			return res:json({
				rv = 200,
				msg = "当前版本不是最新版本，建议更新.",
				data = result,
				upd = true,
				filter = {os_type = os_type,
						  version = version,
						  app_id = app_id}
			})
		else
			return res:json({
				rv = 200,
				upd = false,
				msg = "已是最新稳定版本."
			})
		end
	end

	return res:json({
		rv = 502,
		msg = "未维护版本信息，联系IT开发人员维护。"
	})

end)
return version_router
