-- Quad tiling: 1 window full, 2 side by side, 3 splits the right column
-- top/bottom, 4 fills the bottom-left for an even 2x2 grid. 5+ fall back to
-- a plain grid.

-- 2x2 grid_cell index (row-major) for the nth window: TL, TR, BR, BL
local QUAD = { 1, 2, 4, 3 }

-- ctx.targets is not in spawn order (a new window can come first), so sort by
-- when each window was first seen. Shared across workspaces, never pruned.
local firstSeen = {}
local counter = 0

local function target_id(target)
    local window = target.window
    return window and tostring(window.stable_id) or ("index:" .. target.index)
end

local function spawn_ordered(ctx)
    local targets = {}
    for _, target in ipairs(ctx.targets) do
        local id = target_id(target)
        if not firstSeen[id] then
            counter = counter + 1
            firstSeen[id] = counter
        end
        table.insert(targets, target)
    end
    table.sort(targets, function(a, b)
        return firstSeen[target_id(a)] < firstSeen[target_id(b)]
    end)
    return targets
end

hl.layout.register("quad", {
    recalculate = function(ctx)
        local targets = spawn_ordered(ctx)
        local n = #targets
        if n == 0 then
            return
        end

        if n == 1 then
            targets[1]:place(ctx.area)
        elseif n == 2 then
            for i, target in ipairs(targets) do
                target:place(ctx:column(i, 2))
            end
        elseif n == 3 then
            targets[1]:place(ctx:column(1, 2))
            targets[2]:place(ctx:grid_cell(2, 2, 2))
            targets[3]:place(ctx:grid_cell(4, 2, 2))
        elseif n == 4 then
            for i, target in ipairs(targets) do
                target:place(ctx:grid_cell(QUAD[i], 2, 2))
            end
        else
            local cols = math.ceil(math.sqrt(n))
            for i, target in ipairs(targets) do
                target:place(ctx:grid_cell(i, cols))
            end
        end
    end,
})
