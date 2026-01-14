-- GrassSwayModule: Animates a MeshPart to sway like grass
local GrassSwayModule = {}

function GrassSwayModule.StartSway(grassPart)
    local pos = grassPart.Position
    pos = Vector3.new(pos.x, pos.y-0.2, pos.z)
    local x = 0
    local z = 0
    local T = -99999
    local tall = grassPart.Size.Y / 2
    math.randomseed(os.clock() + pos.X + pos.Z)
    local rand = (math.random(0,20))/10

    task.spawn(function()
        while grassPart and grassPart.Parent do
            x = pos.x + (math.sin(T + (pos.x/5) + rand) * math.sin(T/9))/3
            z = pos.z + (math.sin(T + (pos.z/6) + rand) * math.sin(T/12))/4
            grassPart.CFrame = CFrame.new(x, pos.y, z) * CFrame.Angles((z-pos.z)/tall, 0,(x-pos.x)/-tall)
            task.wait()
            T = T + 0.12
        end
    end)
end

return GrassSwayModule

