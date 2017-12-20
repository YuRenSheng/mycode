local type = type
local pairs = pairs
local type = type
local mceil = math.ceil
local mfloor = math.floor
local mrandom = math.random
local mmodf = math.modf
local ssub = string.sub
local sgsub = string.gsub
local tinsert = table.insert
local date = require("app.libs.date")
local resty_sha256 = require "resty.sha256"
local str = require "resty.string"
local ngx_quote_sql_str = ngx.quote_sql_str
local cjson = require("cjson")

local _M = {}

function _M.encode(s)
    local sha256 = resty_sha256:new()
    sha256:update(s)
    local digest = sha256:final()
    return str.to_hex(digest)
end


function _M.clear_slash(s)
    s, _ = sgsub(s, "(/+)", "/")
    return s
end

function _M.is_table_empty(t)
    if t == nil or _G.next(t) == nil then
        return true
    else
        return false
    end
end

function _M.table_is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

function _M.mixin(a, b)
    if a and b then
        for k, v in pairs(b) do
            a[k] = b[k]
        end
    end
    return a
end

function _M.random()
    return mrandom(0, 1000)
end


function _M.total_page(total_count, page_size)
    local total_page = 0
    if total_count % page_size == 0 then
        total_page = total_count / page_size
    else
        local tmp, _ = mmodf(total_count/page_size)
        total_page = tmp + 1
    end

    return total_page
end


function _M.days_after_registry(req)
    local diff = 0
    local diff_days = 0 -- default value, days after registry

    if req and req.session then
        local user = req.session.get("user")
        local create_time = user and user.create_time
        if create_time then
            local now = date() -- seconds
            create_time = date(create_time)
            diff = date.diff(now, create_time):spandays()
            diff_days = mfloor(diff)
        end
    end

    return diff_days, diff
end

function _M.now()
    local n = date()
    local result = n:fmt("%Y-%m-%d %H:%M:%S")
    return result
end

function _M.secure_str(str)
    return ngx_quote_sql_str(str)
end


function _M.string_split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        tinsert(result, match)
    end
    return result
end

function _M.str_in_table(str,tb)  -- 10  {123,10,12} {gt = 10,hy = 132}
    for _, v in pairs(tb) do
        if v == str then
            return true
        end
    end
    return false
end

function _M.StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end

    return loadstring("return " .. str)()
end

function _M.RemoveTableElement(key,tb)
    local tmp ={}

    --把每个key做一个下标，保存到临时的table中，转换成{1=a,2=c,3=b}
    --组成一个有顺序的table，才能在while循环准备时使用#table
    for i in pairs(tb) do
        table.insert(tmp, i)
    end

    local newTb = {}
    --使用while循环剔除不需要的元素
    local i = 1
    while i <= #tmp do
        local val = tmp [i]
        if val == key then
            --如果是需要剔除则remove
            table.remove(tmp, i)
         else
            --如果不是剔除，放入新的tab中
            newTb[val] = tb[val]
            i = i + 1
         end
     end

    return newTb
end

function _M.trim(str)

    if type(str) == "string" then
        local s = string.gsub(str,"^%s*(.-)%s*$","%1")
        return s
    end
end

function _M.upd_param(data, match_tb)

    local pos_param = ""

    if (match_tb == nil or type(match_tb) ~= "table") then
        return nil;
    end

    for key, val in pairs(data) do

        local tmp = match_tb[key]

        if tmp ~= nil then
            if (type(val) == "string") then
                pos_param = pos_param .. ", " .. tmp .. "= " .. ngx.quote_sql_str(val)
            else
                pos_param = pos_param .. ", " .. tmp .. "= " .. val
            end
        end
    end

    if #pos_param ~= 0 then
        pos_param = ssub(pos_param,2)
    end

    return pos_param

end

function _M.ToStringEx(value)
    if type(value)=='table' then
       return TableToStr(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
       return tostring(value)
    end
end

function _M.TableToStr(t)
    if t == nil then return "" end
    local retstr= ""

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
          signal = ""
        end

        if key == i then
            retstr = retstr..signal.._M.ToStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['.._M.ToStringEx(key).."]=".._M.ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."=".._M.ToStringEx(value)
                else
                    retstr = retstr..signal..key.."=".._M.ToStringEx(value)
                end
            end
        end

        i = i+1
    end

     retstr = retstr..""
     return retstr
end


function _M.chk_is_null(...)

    local is_null = false
    local len = select('#',...)

    --for k,v in pairs({...}) do
    for k=1, len do
        local v = select(k,...)
        if v == nil      or
           not v         or
           v == ngx.null or
           v == "" then
            is_null  = true
            break;
        end
    end

    return is_null
end

 function _M.encodeBase64(source_str)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local s64 = ''
    local str = source_str

    while #str > 0 do
        local bytes_num = 0
        local buf = 0

        for byte_cnt=1,3 do
            buf = (buf * 256)
            if #str > 0 then
                buf = buf + string.byte(str, 1, 1)
                str = string.sub(str, 2)
                bytes_num = bytes_num + 1
            end
        end

        for group_cnt=1,(bytes_num+1) do
            local b64char = math.fmod(math.floor(buf/262144), 64) + 1
            s64 = s64 .. string.sub(b64chars, b64char, b64char)
            buf = buf * 64
        end

        for fill_cnt=1,(3-bytes_num) do
            s64 = s64 .. '='
        end
    end

    return s64
end

function _M.decodeBase64(str64)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local temp={}
    for i=1,64 do
        temp[string.sub(b64chars,i,i)] = i
    end
    temp['=']=0
    local str=""
    for i=1,#str64,4 do
        if i>#str64 then
            break
        end
        local data = 0
        local str_count=0
        for j=0,3 do
            local str1=string.sub(str64,i+j,i+j)
            if not temp[str1] then
                return
            end
            if temp[str1] < 1 then
                data = data * 64
            else
                data = data * 64 + temp[str1]-1
                str_count = str_count + 1
            end
        end
        for j=16,0,-8 do
            if str_count > 0 then
                str=str..string.char(math.floor(data/math.pow(2,j)))
                data=math.fmod(data,math.pow(2,j))
                str_count = str_count - 1
            end
        end
    end

    local last = tonumber(string.byte(str, string.len(str), string.len(str)))
    if last == 0 then
        str = string.sub(str, 1, string.len(str) - 1)
    end
    return str
end



return _M




-- local resty_sha256 = require "resty.sha256"
    -- local str = require "resty.string"
    -- local sha256 = resty_sha256:new()
    -- ngx.say(sha256:update("hello"))
    -- local digest = sha256:final()
    -- ngx.say("sha256: ", str.to_hex(digest))

    -- local resty_md5 = require "resty.md5"
    -- local md5 = resty_md5:new()
    -- if not md5 then
    --     ngx.say("failed to create md5 object")
    --     return
    -- end

    -- local ok = md5:update("hel")
    -- if not ok then
    --     ngx.say("failed to add data")
    --     return
    -- end

    -- ok = md5:update("lo")
    -- if not ok then
    --     ngx.say("failed to add data")
    --     return
    -- end

    -- local digest = md5:final()

    -- local str = require "resty.string"
    -- ngx.say("md5: ", str.to_hex(digest))
    --     -- yield "md5: 5d41402abc4b2a76b9719d911017c592"
