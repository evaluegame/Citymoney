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
if mode == "showcase" or mode == "home" then
    local Architecture = require("../src/shared/Architecture")
    local showcase = { [2] = { "Avery", Config.playerColors[1], 0 }, [8] = { "Riley", Config.playerColors[2], 1 }, [14] = { "Jamie", Config.playerColors[3], 2 }, [23] = { "Morgan", Config.playerColors[4], 3 } }
    local entries = {}
    if mode == "showcase" then
        for _, entry in ipairs(scene) do
            if not (entry.tileIndex and showcase[entry.tileIndex] and entry.name ~= "Tile"..entry.tileIndex and entry.name ~= "DistrictInlay") then table.insert(entries, entry) end
        end
    end
    for index, owner in pairs(showcase) do
        if mode == "showcase" or index == 2 then
            for _, entry in ipairs(Architecture.property(Config,index,owner[1],owner[2],owner[3],0)) do table.insert(entries,entry) end
        end
    end
    scene = entries
end
print(encode(scene))
