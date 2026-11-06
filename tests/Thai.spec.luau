local Thai=require('../src/shared/Thai')
local Config=require('../src/shared/Config')
local Cosmetics=require('../src/shared/Cosmetics')
local Board=require('../src/shared/Board')
local passed=0
local function test(name,fn)
 local ok,message=pcall(fn);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
end
local function translated(value)
 local result=Thai.text(value)
 assert(result~=value,value)
 assert(utf8.len(result) and string.find(result,'[\224-\239]'),value)
 return result
end
test('all twenty-four tile names and eight districts have Thai captions',function()
 for _,tile in ipairs(Config.tiles) do translated(tile.name) end
 for _,group in pairs(Config.groups) do translated(group.name);translated(string.upper(group.name)) end
end)
test('all home levels and their descriptions are translated',function()
 for _,name in ipairs(Config.homeNames) do translated(name) end
 for _,description in ipairs(Config.homeDescriptions) do translated(description) end
end)
test('all five cards and seven goals have complete Thai descriptions',function()
 for _,definition in pairs(Config.cardDefinitions) do translated(definition.name);translated(definition.description) end
 for _,goal in ipairs(Config.challenges) do translated(goal.name);translated(goal.description) end
end)
test('news events, festivals and free opportunity choices are translated',function()
 for _,event in ipairs(Config.events) do translated(event.text) end
 for _,event in ipairs(Config.festivals) do translated(event.name);translated(event.description) end
 for _,offer in ipairs(Config.opportunities) do
  translated(offer.name);translated(offer.description)
  for _,choice in ipairs(offer.choices) do translated(choice.label);translated(choice.detail) end
 end
end)
test('free and premium collections use Thai names without changing their IDs',function()
 for _,style in ipairs(Cosmetics.styles) do translated(style.name);translated(style.label);translated(style.description);assert(Cosmetics.find(style.id)==style) end
end)
test('dynamic captions preserve user names including punctuation and Thai',function()
 for _,name in ipairs({'Ready','Sell','%Roblox [123]','สมชาย','Alice · Bob'}) do
  assert(Thai.text(name.."'s turn")=='ตาของ '..name)
  assert(Thai.text("It's "..name.."'s turn.")=='ถึงตาของ '..name)
 end
end)
test('nested property, card and home captions translate without changing numbers',function()
 assert(Thai.text('Avery bought Copper Lane as a level 2 Garden villa for $210!')=='Avery ซื้อตรอกทองแดงเป็นวิลล่าสวนระดับ 2 ราคา $210!')
 assert(Thai.text('Avery chose Demolition permit from TACTIC CARDS!')=='Avery เลือกการ์ดรื้อบ้านจากการ์ดกลยุทธ์!')
 assert(Thai.text('Copper Lane · Ready · L3')=='ตรอกทองแดง · Ready · ระดับ 3')
 assert(Thai.text('Copper Lane · $1560 available · Current L0')=='ตรอกทองแดง · มีเงิน $1560 · ระดับปัจจุบัน 0')
 assert(Thai.text('Rent boost ×1')=='เพิ่มค่าเช่า ×1')
 assert(Thai.text('Set 1.5× rent · $120')=='ตั้งค่า ค่าเช่า 1.5× · $120')
 assert(Thai.text('Rent 1.5× · SHIELDED')=='ค่าเช่า 1.5 เท่า · มีโล่')
end)
test('level templates cannot mistake ordinary words for numbers',function()
 assert(Thai.text('Lantern Festival · $80')=='เทศกาลโคมไฟ · $80')
 assert(Thai.text('L3')=='ระดับ 3' and Thai.text('Liam')=='Liam')
 assert(Thai.text('Loading collection…')=='กำลังโหลด…')
end)
test('Thai and English mixed names remain valid UTF-8 during repeated updates',function()
 for _,source in ipairs({'Copper Lane\nRENT $108','Avery\nTownhouse','55s left · Events [P]',"สมชาย's home · Garden villa"}) do
  local result=Thai.text(source);assert(utf8.len(result));assert(Thai.text(result)==result,result)
 end
 assert(Thai.text('55s left · Events [P]')=='เหลือ 55 วินาที · กิจกรรม [P]')
end)
test('Thai initials and label widths count characters instead of UTF-8 bytes',function()
 assert(Thai.initial('สมชาย')=='ส' and Thai.initial('Avery')=='A')
 assert(Thai.width('ค่าเช่า')==5 and Thai.width('ไทย')==3 and Thai.width('$150')==4)
 for index=1,24 do assert(utf8.len(Thai.shortNames[index]) and Thai.width(Thai.shortNames[index])<=8) end
end)
test('Robux and ordinary money keep their exact amounts and currencies',function()
 assert(Thai.text('Unlock Club · R$ 1,499')=='ปลดล็อกคลับ · R$ 1,499')
 assert(Thai.text('Cost $80 · Balance after $1420')=='ราคา $80 · เงินคงเหลือ $1420')
 assert(Thai.text('RENT $108')=='ค่าเช่า $108')
end)
test('canonical board captions translate while interaction IDs stay unchanged',function()
 assert(Thai.text(Board.caption(Config,4))=='การ์ดกลยุทธ์\nการ์ดฟรี')
 local entries=Thai.scene({{name='CardSpaceSign',text='RENT CARDS',interaction='cards',tileIndex=22}})
 assert(entries[1].text=='การ์ดค่าเช่า' and entries[1].interaction=='cards' and entries[1].tileIndex==22)
 for _,entry in ipairs(Board.generate(Config)) do if entry.text then assert(utf8.len(entry.text),entry.name) end end
end)
print('\n'..passed..' Thai localization cases passed.')
