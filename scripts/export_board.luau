local Config = require("../src/shared/Config")
local Board = require("../src/shared/Board")
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
local scene = Board.generate(Config)
if mode == "showcase" or mode == "home" or mode=="clubhome" or mode=="clubshowcase" or mode=="table" then
    local Architecture = require("../src/shared/Architecture")
    local showcase = { [2] = { "Avery", Config.playerColors[1], mode=="clubhome" and 2 or 0,"gilded" }, [8] = { "Riley", Config.playerColors[2], 1,"gilded" }, [14] = { "Jamie", Config.playerColors[3], 2,"aurora" }, [23] = { "Morgan", Config.playerColors[4], 3,"rose" } }
    local entries = {}
    if mode == "showcase" or mode=="clubshowcase" or mode=="table" then
        for _, entry in ipairs(scene) do
            if not (entry.tileIndex and showcase[entry.tileIndex] and entry.name ~= "Tile"..entry.tileIndex and entry.name ~= "DistrictInlay") then table.insert(entries, entry) end
        end
    end
    for index, owner in pairs(showcase) do
        if mode == "showcase" or mode=="clubshowcase" or mode=="table" or index == 2 then
            local style=mode=="clubhome" or mode=="clubshowcase"
            for _, entry in ipairs(Architecture.property(Config,index,owner[1],owner[2],owner[3],0,nil,style and owner[4] or "classic")) do table.insert(entries,entry) end
        end
    end
    scene = entries
end
print(encode(scene))
