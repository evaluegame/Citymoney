-- Quiet, optional UI feedback using a bundled Roblox sound; no paid audio IDs.
local Audio={}
Audio.__index=Audio
local cues={tap={1.5,0.09},roll={0.8,0.14},step={1.8,0.045},success={1.2,0.15}}
function Audio.new(gui,clock)
    local self=setmetatable({clock=clock or os.clock,muted=false,nextAt=0,cursor=0,sequence=0,pool={}},Audio)
    self.bank=Instance.new("Folder");self.bank.Name,self.bank.Parent="CitymoneyAudio",gui
    for index=1,4 do
        local sound=Instance.new("Sound")
        sound.Name,sound.SoundId,sound.Volume="CityTone"..index,"rbxasset://sounds/electronicpingshort.wav",0
        sound.Parent=self.bank;table.insert(self.pool,sound)
    end
    return self
end
function Audio:setMuted(muted)
    self.muted=muted==true;self.sequence=self.sequence+1
    if self.muted then for _,sound in ipairs(self.pool) do pcall(function() sound:Stop() end) end end
end
function Audio:play(kind,pitch)
    if self.muted or not self.bank.Parent or self.clock()<self.nextAt then return false end
    local cue=cues[kind]
    if not cue then return false end
    self.nextAt=self.clock()+0.055
    self.cursor=self.cursor%#self.pool+1
    local sound=self.pool[self.cursor]
    return pcall(function()
        sound:Stop();sound.PlaybackSpeed,sound.Volume,sound.TimePosition=pitch or cue[1],cue[2],0
        sound:Play()
    end)
end
function Audio:celebrate()
    self.sequence=self.sequence+1;local sequence=self.sequence
    self:play("success",1)
    for index,pitch in ipairs({1.25,1.5}) do
        task.delay(index*0.12,function()
            if self.sequence==sequence then self:play("success",pitch) end
        end)
    end
end
return Audio
