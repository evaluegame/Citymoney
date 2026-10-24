local Board = require("../src/shared/Board")
local Config = require("../src/shared/Config")
local function check(condition, message) assert(condition, message) end
local positions = {}
for index = 1, #Config.tiles do
    local position = Board.position(index)
    local key = position[1] .. ":" .. position[3]
    check(not positions[key], "Two tiles occupy the same position")
    positions[key] = true
    local nextPosition = Board.position(index % #Config.tiles + 1)
    local dx, dz = position[1] - nextPosition[1], position[3] - nextPosition[3]
    check(dx * dx + dz * dz == 144, "Board path must close with uniformly spaced neighbors")
end
local scene, repeatScene = Board.generate(Config), Board.generate(Config)
check(#scene == #repeatScene and #scene >= 100, "Scene generation is incomplete or nonrepeatable")
local tiles = {}
for index, entry in ipairs(scene) do
    check(entry.name == repeatScene[index].name and entry.color == repeatScene[index].color, "Scene changed between builds")
    for axis = 1, 3 do
        local size, coordinate = entry.size[axis], entry.position[axis]
        check(size > 0 and size < math.huge, "Invalid part size")
        check(coordinate == coordinate and math.abs(coordinate) < 1000, "Invalid scene coordinate")
        check(coordinate == repeatScene[index].position[axis], "Nondeterministic scene position")
    end
    if entry.tileIndex then
        check(entry.tileIndex >= 1 and entry.tileIndex <= 24, "Invalid inspection target")
    end
    if string.match(entry.name, "^Tile%d+$") then
        check(not tiles[entry.tileIndex], "Duplicate scene tile")
        tiles[entry.tileIndex] = true
        check(entry.text and string.find(entry.text, Config.tiles[entry.tileIndex].name, 1, true), "Tile label mismatches game rules")
    end
end
for index = 1, 24 do check(tiles[index], "Scene is missing a game tile") end
print("PASS board scene: closed 24-tile path, deterministic geometry, labels, sizes, and inspection targets.")
