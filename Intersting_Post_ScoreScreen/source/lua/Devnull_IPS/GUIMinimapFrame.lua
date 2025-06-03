local oldSetBackgroundMode = GUIMinimapFrame.SetBackgroundMode

function GUIMinimapFrame:SetBackgroundMode(setMode, forceReset)
	-- mode 0 is btm left (in comm chair)
	-- mode 1 is mid
	-- mode 2 is top left (outside comm chair)
	--print("Called SetBackgroundMode, setmode: " .. tostring(setMode) .. " forcereset: " .. tostring(forceReset) .. " comMode: " .. tostring(self.comMode))
	
	if (setMode == 0 and self.comMode == 1) or (setMode == 2 and self.comMode == 0) then MapCheckStartStopTimer(2, 'Frame setmode ' .. tostring(setMode) .. ' comMode: ' .. tostring(self.comMode)) end 
	
    oldSetBackgroundMode(self, setMode, forceReset)
	
end