local lor 	= require("lor.index")
local utils = require("app.libs.utils")
local nav_router = lor:Router()

nav_router:get("/:navname",function(req, res, next)
  local navname = req.params.navname
  local navnames = {"todo","my","finlish"}

  if not utils.str_in_table(navname,navnames) then
    return res:json({
			rv = 500,
			msg = "navname必須爲todo,my,finlish"
		})
  end

  if navname == "todo" then
    return res:render("app_todo")
  end

  if navname == "my" then
    return res:render("app_my")
  end

  if navname == "finlish" then
    return res:render("app_finish")
  end

end)

return nav_router
