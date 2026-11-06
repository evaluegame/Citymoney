local Config = require("../src/shared/Config")
local Board = require("../src/shared/Board")
local Thai = require("../src/shared/Thai")
local encode
encode = function(value: any): string
    if type(value) == "string" then
        return '"' .. string.gsub(value, '[%z\1-\31\\"]', function(character)
            local escapes = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
            return escapes[character] or string.format('\\u%04x', string.byte(character))
        end) .. '"'
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "table" then
        local values = {}
        if #value > 0 then
            for _, entry in ipairs(value) do table.insert(values, encode(entry)) end
            return "[" .. table.concat(values, ",") .. "]"
        end
        local keys = {}
        for key in pairs(value) do table.insert(keys, key) end
        table.sort(keys)
        for _, key in ipairs(keys) do table.insert(values, encode(key) .. ":" .. encode(value[key])) end
        return "{" .. table.concat(values, ",") .. "}"
    end
    error("Unsupported scene data: " .. type(value))
end
local mode = ...
if mode=="camera" or mode=="citycamera" then
    local Camera=require("../src/shared/BoardCamera")
    local P=require("../src/shared/Presentation")
    local A=require("../src/shared/Architecture")
    if mode=="citycamera" then
        print(encode(Camera.fit(1440,1050,{24,24,1392,1002},P.cityYaw,P.cityElevation,1,require("../src/shared/CityScenery").bounds())))
    else
        print(encode(Camera.fit(1440,900,{24,24,1392,852},P.defaultYaw,P.defaultElevation,1,Camera.cityBounds(Config,A))))
    end
    return
end
local scene = Board.generate(Config)
if mode == "showcase" or mode == "home" or mode=="clubhome" or mode=="clubshowcase" or mode=="table" then
    local Architecture = require("../src/shared/Architecture")
    local showcase = { [2] = { "Avery", Config.playerColors[1], mode=="clubhome" and 2 or 0,"gilded" }, [8] = { "Riley", Config.playerColors[2], 1,"gilded" }, [14] = { "Jamie", Config.playerColors[3], 2,"aurora" }, [23] = { "Morgan", Config.playerColors[4], 3,"rose" } }
    local state={properties={}}
    for index=1,#Config.tiles do
        local owner=showcase[index]
        state.properties[index]={ownerId=owner and owner[1] or false,level=owner and owner[3] or 0}
    end
    local entries = {}
    if mode == "showcase" or mode=="clubshowcase" or mode=="table" then
        for _, entry in ipairs(scene) do
            if not (entry.tileIndex and showcase[entry.tileIndex] and not entry.boardSpace) then
                if entry.name=="DeedPlate"..tostring(entry.tileIndex) then entry.text=Board.caption(Config,entry.tileIndex,state) end
                table.insert(entries, entry)
            end
        end
    end
    for index, owner in pairs(showcase) do
        if mode == "showcase" or mode=="clubshowcase" or mode=="table" or index == 2 then
            local style=mode=="clubhome" or mode=="clubshowcase"
            for _, entry in ipairs(Architecture.property(Config,index,owner[1],owner[2],owner[3],0,nil,style and owner[4] or "classic")) do table.insert(entries,entry) end
        end
    end
    if mode=="showcase" or mode=="clubshowcase" or mode=="table" then
        local Actors=require("../src/shared/Actors")
        local seat=0
        for index=1,#Config.tiles do if showcase[index] then
            seat=seat+1
            local p,yaw=Actors.pose(index,seat)
            for _,entry in ipairs(Actors.preview(showcase[index][2],p,yaw)) do table.insert(entries,entry) end
        end end
    end
    scene = entries
end
print(encode(Thai.scene(scene)))
