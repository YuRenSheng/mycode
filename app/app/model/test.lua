local DB = require("app.libs.db")
local db = DB:new()

local test = {}

function test:call_proc()

    local sql= 
[[
    set @o_res = '0';
    call smartfactory.make_activity_swipin('2017-06-14 15:09:01', 'F4941769', 'RYA307D', 1, @o_res);
    select @o_res as res;
]]
    return db:multi_query(sql,{})
end

function test:call_proc1()

    local sql= 
[[
    set @o_res = '0';
    call smartfactory.make_activity_swipin('2017-06-14 15:09:01', 'F4941769', 'RYA307D', 1, @o_res);
    select @o_res as res;
]]
    return db:query(sql,{})
end


return test
