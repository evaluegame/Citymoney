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
print(encode(Board.generate(Config)))
