-- Appearance only. The engine never reads this catalogue or pass ownership.
local Cosmetics={}
Cosmetics.styles={
    {id="classic",name="City Original",label="ORIGINAL",premium=false,accent="386BF0",trim="FFFFFF",glass="69D5ED",stone="E7EDF5",door="3555A5",light="FFE4A4",dice="EAF1FF",pip="224377",
        description="The original waterfront home, with your player-colored roof and garden."},
    {id="gilded",name="Golden Estate",label="GOLDEN ESTATE",premium=true,accent="D6B36C",trim="E9D5A8",glass="ACCFD1",stone="EBE6D9",door="344B43",light="FFE2A2",dice="293E37",pip="E9C778",
        description="Brass-framed windows, marble steps, pearl topiary and warm garden lanterns."},
    {id="aurora",name="Aurora Residence",label="AURORA",premium=true,accent="73D6DA",trim="BEDADC",glass="7DCEDB",stone="D2E2E1",door="2B4858",light="A5EDF0",dice="253F50",pip="9AF0E5",
        description="Brushed silver, turquoise light strips and a sculpted crystal garden."},
    {id="rose",name="Rose Conservatory",label="ROSE",premium=true,accent="E2A7B9",trim="E9CEBD",glass="D3C5D9",stone="EFE3DE",door="694E60",light="FFD5D8",dice="513B52",pip="F3C2D5",
        description="Rose-gold details, pale stone, flowering planters and a soft evening glow."},
}
function Cosmetics.find(id: any)
    if type(id)~="string" then return nil end
    for _,style in ipairs(Cosmetics.styles) do if style.id==id then return style end end
    return nil
end
function Cosmetics.get(id: any) return Cosmetics.find(id) or Cosmetics.styles[1] end
function Cosmetics.passId(config)
    local id=config.clubPassId
    return type(id)=="number" and id>0 and id<math.huge and id%1==0 and id or 0
end
function Cosmetics.allowed(id: any,ownsPass,studio)
    local style=Cosmetics.find(id)
    return style~=nil and (not style.premium or ownsPass==true or studio==true)
end
function Cosmetics.normalize(saved: any)
    if type(saved)~="table" then return {styleId="classic",effects=true} end
    return {styleId=Cosmetics.get(saved.styleId).id,effects=saved.effects~=false}
end
return Cosmetics
