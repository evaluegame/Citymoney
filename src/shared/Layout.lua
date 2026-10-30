-- Layout uses the actual safe GUI area, so Studio's top bar never clips it.
local runtimeScript=getfenv().script
local Presentation=runtimeScript and require(runtimeScript.Parent.Presentation) or require("./Presentation")
local Layout={homeChooserWidth=520,homeChooserHeight=620}
Layout.calculate=Presentation.layout
Layout.board=Presentation.board
return Layout
