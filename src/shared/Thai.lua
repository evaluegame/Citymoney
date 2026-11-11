-- Thai presentation only. Protocol IDs, rules, player names and money stay intact.
local Thai={locale="th-th"}
local exact,templates={},{}
local function escape(value) return (string.gsub(value,"([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")) end
local function add(source,target)
    source=string.gsub(source,"\\n","\n");target=string.gsub(target,"\\n","\n")
    if not string.find(source,"{",1,true) then exact[source]=target;return end
    local pattern,keys,last="^",{},1
    for start,key,finish in string.gmatch(source,"(){([%w]+)}()") do
        pattern=pattern..escape(string.sub(source,last,start-1))..(string.sub(key,1,1)=="n" and "([%d%.,]+)" or "(.-)")
        table.insert(keys,key);last=finish
    end
    table.insert(templates,{pattern=pattern..escape(string.sub(source,last)).."$",keys=keys,target=target,weight=#string.gsub(source,"{[%w]+}","")})
end
local catalogue=[=[
1  ROLL	1  ทอย
2  MOVE	2  เดิน
3  CHOOSE	3  เลือก
4  NEXT	4  ตาถัดไป
Watch the city, or join your next match.	ชมเมือง หรือเข้าร่วมเกมถัดไป
Keep cash for rent. Sell a home if you need funds.	เก็บเงินไว้จ่ายค่าเช่า ขายบ้านได้หากต้องการเงิน
Your first home starts on an empty property.	เดินถึงที่ดินว่างเพื่อสร้างบ้านหลังแรก
Cards and upgrades are optional before you roll.	ใช้การ์ดหรืออัปเกรดบ้านก่อนทอยได้
Complete a district pair to double its base rent.	ซื้อที่ดินให้ครบคู่ในย่าน เพื่อเพิ่มค่าเช่าพื้นฐานเป็นสองเท่า
CITY COMPLETE	เมืองของเราสร้างสำเร็จแล้ว
YOUR MATCH	ผลงานของคุณ
WINNER'S MATCH	ผลงานของผู้ชนะ
HOMES	บ้านที่มี
RENT EARNED	ค่าเช่าที่ได้รับ
GOALS COMPLETE	เป้าหมายที่สำเร็จ
THE FINAL STANDINGS	อันดับเมื่อจบเกม
CITY BUILDER · {1}	นักสร้างเมือง · {1}
RENT LEADER · {1}	เจ้าพ่อค่าเช่า · {1}
STRATEGIST · {1}	นักวางกลยุทธ์ · {1}
{n1} homes · {n2} goals	บ้าน {n1} หลัง · สำเร็จ {n2} เป้าหมาย
A fresh city is waiting. Play again with your friends.	เมืองใหม่กำลังรอคุณ เล่นกับเพื่อนอีกครั้งได้เลย
SOUND: ON	เสียง: เปิด
SOUND: OFF	เสียง: ปิด
Quiet game sounds. Change any time.	เสียงเบา ๆ ในเกม เปิดหรือปิดได้ทุกเมื่อ
WAITING	ยังไม่พร้อม
citymoney	ซิตี้มันนี่
CITYMONEY	ซิตี้มันนี่
BUILD YOUR CITY	สร้างเมืองในแบบคุณ
YOUR BALANCE	เงินของคุณ
YOUR STARTING BALANCE	เงินเริ่มต้น
AT THE TABLE	ผู้เล่น
WELCOME HOME	ยินดีต้อนรับ
THE NEIGHBORHOOD	ย่านของเมือง
Your next address	ที่ดินแห่งใหม่
A place to call your own	บ้านของคุณ
Your homes	บ้านของฉัน
Golden hour	แสงยามเย็น
Upgrade options	อัปเกรด
Rent options	ตั้งค่าเช่า
Sell	ขายบ้าน
Walk through your home	เดินชมบ้าน
Repaint	เปลี่ยนสี
Your collection	บ้านของฉัน
Homes that work for you.	บ้านและรายได้ของคุณ
Your first address is waiting.\nLand on a property and buy it to\nsee your new home appear.	ยังไม่มีบ้าน\nเดินถึงที่ดินแล้วเลือกซื้อ\nบ้านจะปรากฏบนที่ดินของคุณ
TAP TO ROLL	แตะเพื่อทอย
A neighborhood of possibilities.	สร้างเมืองไปด้วยกัน
Start solo against City Bot, or invite your friends.	ฝึกกับบอต หรือชวนเพื่อนมาเล่น
Connecting…	กำลังเชื่อมต่อ…
SKIP	ข้าม
City view	ดูเมือง
Board view	ดูกระดาน
Fit	จัดกลาง
Welcome home	ยินดีต้อนรับ
Back to board	กลับกระดาน
Your city. Your table.	เมืองของคุณ เริ่มได้เลย
01   CLICK THE DICE	01   ทอยลูกเต๋า
Tap either die or the central tray. The dice settle,\nthen your avatar moves around the 24-space board.	แตะลูกเต๋าหรือถาดกลางกระดาน\nรอผลทอย แล้วตัวละครจะเดินทีละช่อง
02   BUY & BUILD	02   ซื้อและสร้างบ้าน
Choose a home level when buying. Use cards,\nupgrades and the city plaza before your next roll.	เลือกขนาดบ้านตอนซื้อที่ดิน\nใช้การ์ด อัปเกรด หรือตั้งค่าเช่าก่อนทอย
03   THE CITY KEEPS MOVING	03   เล่นต่อโดยอัตโนมัติ
Resolved turns advance automatically after four seconds.\nPress P or click plaza stations for events and cards.	เมื่อทำรายการเสร็จ จะเปลี่ยนตาใน 4 วินาที\nกดกิจกรรมเพื่อดูเทศกาลและวิธีรับการ์ด
Let's build a neighborhood	มาสร้างเมืองกัน
How to play	วิธีเล่น
Let this home go?	ต้องการขายบ้านนี้ไหม?
Keep my home	เก็บบ้านไว้
Confirm sale	ยืนยันขาย
A neighborhood well built.	เมืองของเราสร้างสำเร็จแล้ว
Play again	เล่นอีกครั้ง
Keep looking	ดูเมืองต่อ
Choose your home level	เลือกขนาดบ้าน
No confirmation yet. Check the refreshed details before retrying.	กำลังตรวจสอบรายการ กรุณารอข้อมูลล่าสุด
Your next home	บ้านหลังใหม่
Choose a rent multiplier	เลือกอัตราค่าเช่า
Choose your upgrade	เลือกการอัปเกรด
Included already	รวมไว้แล้ว
CURRENT RATE	อัตราปัจจุบัน
YOUR CURRENT HOME	บ้านปัจจุบัน
CHOOSE A HIGHER OPTION	เลือกระดับที่สูงขึ้น
SELECTED	เลือกแล้ว
TAP TO PREVIEW	แตะเพื่อดู
Choose a higher option. Your current one is included.	เลือกระดับที่สูงขึ้น ราคาหักส่วนที่มีแล้ว
Your current investment is already included.	หักมูลค่าบ้านปัจจุบันให้แล้ว
The multiplier stays on this property for future payments.	อัตรานี้ใช้กับค่าเช่าครั้งต่อไปของที่ดินนี้
Land + all selected building levels are included.	ราคารวมที่ดินและบ้านระดับที่เลือก
You pay only for the levels you add.	จ่ายเฉพาะระดับที่อัปเกรดเพิ่ม
Confirming your selection…	กำลังยืนยัน…
Dice are rolling…	กำลังทอยลูกเต๋า…
Choose a higher option	เลือกระดับที่สูงขึ้น
Start a match to receive cards and challenges.	เริ่มเกมเพื่อรับการ์ดและเป้าหมาย
READY	พร้อม
LOBBY OPEN	ห้องรอพร้อมแล้ว
Your next city awaits.	เมืองใหม่กำลังรอคุณ
Build your city.	สร้างเมืองของคุณ
Choose online play or practice with bots.	เล่นออนไลน์ หรือฝึกกับบอต
Return to lobby	กลับห้องรอ
Connecting players...	กำลังเชื่อมต่อผู้เล่น…
PLAY NOW	เริ่มเล่น
YOUR TURN	ตาของคุณ
Turn complete.	จบตาแล้ว
A new address is waiting.	ที่ดินใหม่กำลังรอคุณ
Roll to move. Events are optional.	ทอยเพื่อเดิน หรือดูกิจกรรมก่อน
Choose a home level, or skip this lot.	เลือกขนาดบ้าน หรือข้ามที่ดินนี้
Choose a free card from this space.	เลือกการ์ดฟรีจากช่องนี้
Choose cash or a tactical card.	เลือกรับเงินหรือการ์ด
Next player starts automatically.	ผู้เล่นถัดไปจะเริ่มโดยอัตโนมัติ
Serve detention	พักในเรือนจำ
ROLL DICE	ทอยลูกเต๋า
COLLECT CARD	รับการ์ด
CHOOSE REWARD	เลือกรางวัล
Next player	ผู้เล่นถัดไป
End turn	จบตา
City events	กิจกรรมเมือง
View matchmaking queue	ดูคิวจับคู่
Find an online match	ค้นหาเกมออนไลน์
Rolling the dice…	กำลังทอยลูกเต๋า…
ROLLING...	กำลังทอย…
ROLLING THE DICE	กำลังทอยลูกเต๋า
Wait for both dice to stop.	รอให้ลูกเต๋าทั้งสองหยุด
GET READY...	เตรียมเดิน…
Dice settled. Your resident moves next.	ลูกเต๋าหยุดแล้ว เตรียมเดินทีละช่อง
ON THE MOVE...	กำลังเดิน…
MOVING SPACE BY SPACE	เดินทีละช่อง
Your result appears when you land.	รายละเอียดจะแสดงเมื่อเดินถึง
Fully upgraded	ระดับสูงสุด
Rent maxed	ค่าเช่าสูงสุด
Choose your starting home level before you buy.	เลือกขนาดบ้านก่อนยืนยันซื้อ
Return to matchmaking	กลับไปจับคู่
Time for a fresh start.	พร้อมเริ่มเมืองใหม่
MENU  [M]	เมนู [M]
CLAIM REWARD	รับรางวัล
CARDS & GOALS	การ์ดและเป้าหมาย
YOUR TURN · Upgrade, play a card, or roll the dice!	ตาของคุณ อัปเกรด ใช้การ์ด หรือทอยได้เลย
Click the dice when it is your turn to roll.	แตะลูกเต๋าเมื่อถึงตาของคุณ
DICE SETTLED · MOVING NEXT	ได้ผลทอยแล้ว เตรียมเดิน
ONE SPACE AT A TIME	เดินทีละช่อง
ARRIVING	กำลังถึงช่อง
Your turn starts automatically	ตาของคุณจะเริ่มโดยอัตโนมัติ
This multiplier applies to future rent payments.	ใช้อัตรานี้กับค่าเช่าครั้งต่อไป
Only the added levels are charged.	คิดเงินเฉพาะระดับที่เพิ่ม
2 / 4 players · online queues or practice with bots	2 / 4 คน · ออนไลน์หรือฝึกกับบอต
MENU	เมนู
Everything in one place.	เลือกสิ่งที่ต้องการทำ
DAY / NIGHT	กลางวัน / กลางคืน
PLAY TOGETHER	เล่นกับเพื่อน
Online, friends or practice	ออนไลน์ ชวนเพื่อน หรือฝึกเล่น
Play a card or claim a reward	ใช้การ์ดหรือรับรางวัล
CITY EVENTS	กิจกรรมเมือง
Festival, market and news	เทศกาล ช่องการ์ด และข่าว
YOUR PROPERTIES	ที่ดินของฉัน
Upgrade, set rent or visit	อัปเกรด ตั้งค่าเช่า หรือชมบ้าน
COSMETIC SHOP	ร้านของตกแต่ง
Styles and the Robux Club pass	สไตล์และพาสตกแต่ง Robux
HOW TO PLAY	วิธีเล่น
Learn the three easy steps	เริ่มง่าย ๆ ใน 3 ขั้นตอน
Turns move on automatically. Just roll, choose, and play.	ทอย เลือก และเล่น ระบบจะเปลี่ยนตาให้เอง
EVENTS	กิจกรรม
MY HOMES	บ้านของฉัน
Play together	เล่นด้วยกัน
Choose 2 or 4 players, then start playing.	เลือก 2 หรือ 4 คน แล้วเริ่มเล่น
Leave party	ออกจากกลุ่ม
Leave match	ออกจากเกม
2 PLAYERS	2 คน
4 PLAYERS	4 คน
Practice settings	ตั้งค่าฝึกเล่น
Fill empty seats with bots	เติมบอตในที่ว่าง
DEMOLITION RULE	กติกาการรื้อบ้าน
Remove one level	ลดลง 1 ระดับ
Destroy whole house	รื้อบ้านทั้งหลัง
Online matches always use full-house demolition.	เกมออนไลน์ใช้กติกาการรื้อบ้านทั้งหลัง
YOUR COLOR · pick one if you like	สีของคุณ · แตะเพื่อเลือก
YOUR PARTY	กลุ่มของคุณ
Ready	พร้อม
INVITE FRIENDS	ชวนเพื่อน
PLAY ONLINE	เล่นออนไลน์
PRACTICE WITH BOTS	ฝึกกับบอต
PRACTICE WITH PARTY	ฝึกกับกลุ่ม
SETTINGS	ตั้งค่า
Cards & challenges	การ์ดและเป้าหมาย
Your challenge	เป้าหมายของคุณ
Claim reward	รับรางวัล
New goal $50	เปลี่ยนเป้า $50
ONE TACTICAL CARD PER TURN	ใช้การ์ดได้ตาละ 1 ใบ
Demolish	รื้อบ้าน
Demand rent	เรียกเก็บค่าเช่า
Rent boost	เพิ่มค่าเช่า
Shield	โล่ป้องกัน
Renovate	อัปเกรดฟรี
CHOOSE THE PROPERTY	เลือกที่ดิน
Choose a property	เลือกที่ดิน
Back	กลับ
No confirmation yet. Refreshing the match before you retry.	กำลังตรวจสอบ กรุณารอข้อมูลเกมล่าสุด
READY · tap to unready	พร้อมแล้ว · แตะเพื่อยกเลิก
I'M READY TO PLAY	ฉันพร้อมแล้ว
Waiting for your friends to tap Ready.	รอเพื่อนกดพร้อม
Play online, or try a quick practice game.	เล่นออนไลน์ หรือเริ่มฝึกเล่นได้เลย
Everyone is ready. The host can start!	ทุกคนพร้อมแล้ว เจ้าห้องเริ่มได้เลย
RETURN TO LOBBY	กลับห้องรอ
CONNECTING...	กำลังเชื่อมต่อ…
CANCEL SEARCH	ยกเลิกค้นหา
Your turn changed. Choose your action again.	เปลี่ยนตาแล้ว กรุณาเลือกใหม่
YOUR TACTICAL CARD HAS BEEN USED THIS TURN	ตานี้ใช้การ์ดไปแล้ว
ONE TACTICAL CARD PER TURN · CHOOSE YOUR TARGETS	ใช้ได้ตาละ 1 ใบ · เลือกเป้าหมาย
No opponent owns a house yet.	ยังไม่มีคู่แข่งที่เป็นเจ้าของบ้าน
Buy a property before using this card.	ซื้อบ้านก่อนใช้การ์ดนี้
CHOOSE WHO MUST PAY	เลือกผู้เล่นที่ต้องจ่าย
ATTACK RULE: FULL HOUSE DEMOLITION	กติกา: รื้อบ้านทั้งหลัง
ATTACK RULE: REMOVE ONE LEVEL; L0 HOMES ARE DEMOLISHED	กติกา: ลด 1 ระดับ บ้านระดับ 0 จะถูกรื้อ
Select a property to see the effect.	เลือกที่ดินเพื่อดูผลของการ์ด
A shield will block this attack; both cards are used.	โล่จะป้องกันการโจมตี และใช้การ์ดทั้งสองใบ
Demolish this house. The lot returns to the city.	รื้อบ้านนี้ ที่ดินจะกลับมาเปิดขาย
Rent +50% for the next two payments.	ค่าเช่าเพิ่ม 50% สำหรับการจ่าย 2 ครั้งถัดไป
Block the next demolition attempt.	ป้องกันการรื้อบ้านครั้งถัดไป
Playing card…	กำลังใช้การ์ด…
Wait for your turn	รอถึงตาของคุณ
Card already used this turn	ตานี้ใช้การ์ดแล้ว
Choose valid targets	เลือกเป้าหมายให้ครบ
You have no copies. Earn cards at City Gate, City News, the park or challenges.	ยังไม่มีการ์ดนี้ รับได้จากช่องการ์ด ข่าว สวน หรือเป้าหมาย
Publish the place, then invite friends from a live Roblox server.	เผยแพร่เกมก่อน แล้วชวนเพื่อนจากเซิร์ฟเวอร์ Roblox
Invite friends from the lobby before your party joins a queue.	ชวนเพื่อนในห้องรอก่อนเข้าคิว
Roblox cannot open invites here. Friends can use the experience's Join button.	เปิดคำเชิญไม่ได้ ให้เพื่อนกดเข้าร่วมจากหน้าเกม
The invite prompt could not open. Try the Roblox experience page.	เปิดคำเชิญไม่ได้ กรุณาลองจากหน้าเกม Roblox
CITY OPPORTUNITY	โอกาสของเมือง
Choose your reward.	เลือกรางวัล
CARD	การ์ด
CHOOSE THIS >	เลือกรางวัลนี้ >
No cost. If time runs out, cash is chosen automatically.	รับฟรี เมื่อหมดเวลาระบบจะเลือกเงินให้
CONTINUE WITHOUT CARD	ข้ามการรับการ์ด
FREE CARD SPACE	ช่องรับการ์ดฟรี
Free card. On timeout, an available card is collected automatically.	รับฟรี เมื่อหมดเวลาระบบจะเลือกการ์ดที่ยังรับได้
FREE	ฟรี
COLLECT CARD >	รับการ์ดนี้ >
HAND FULL · CHOOSE ANOTHER OR CONTINUE	เต็มแล้ว · เลือกใบอื่นหรือข้าม
HAND FULL · TAKE CASH INSTEAD	การ์ดเต็ม · เลือกรับเงิน
Confirming your reward...	กำลังรับรางวัล…
Choose one of your homes	เลือกบ้านของคุณ
Rent boost already active	เพิ่มค่าเช่าไว้อยู่แล้ว
Already protected	มีโล่แล้ว
Already fully upgraded	ระดับสูงสุดแล้ว
+50% rent for 2 payments	เพิ่มค่าเช่า 50% จำนวน 2 ครั้ง
Block the next demolition	ป้องกันการรื้อครั้งถัดไป
Choose an event.	เลือกกิจกรรม
X	ปิด
< ALL EVENTS	< กิจกรรมทั้งหมด
Choose a home	เลือกบ้าน
CLOSE	ปิด
FESTIVAL	เทศกาล
Improve one of your homes	เพิ่มความสามารถให้บ้าน
CARD SPACES	ช่องรับการ์ด
Land on a space, collect a card	เดินถึงช่องแล้วรับการ์ดฟรี
CHALLENGES	เป้าหมาย
Complete goals, collect rewards	ทำเป้าหมายแล้วรับรางวัล
CITY NEWS	ข่าวเมือง
Read the city bulletin	อ่านข่าวล่าสุด
OPEN >	เปิด >
Cards are free on marked board spaces.\nFestival home services use game cash.	รับการ์ดฟรีเมื่อเดินถึงช่องการ์ด\nบริการเทศกาลใช้เงินในเกม
Checking your purchase. Please wait for the refreshed match.	กำลังตรวจสอบรายการ กรุณารอข้อมูลล่าสุด
Your turn changed. Review the current offer.	เปลี่ยนตาแล้ว กรุณาดูข้อเสนอใหม่
Festival applied to your home!	ใช้บริการเทศกาลให้บ้านแล้ว!
BACK TO BOARD	กลับกระดาน
Collect cards on the board.	รับการ์ดบนกระดาน
Around the city.	ข่าวรอบเมือง
Join the festival.	ร่วมเทศกาล
FREE CARD SPACES >	ดูช่องรับการ์ดฟรี >
REWARD READY >	รับรางวัลได้แล้ว >
VIEW YOUR GOAL >	ดูเป้าหมาย >
LATEST UPDATES >	ข่าวล่าสุด >
CHOSEN	เลือกแล้ว
Buy a home first to join this festival.\nCollect free cards on the marked board spaces.	ซื้อบ้านก่อนร่วมเทศกาล\nรับการ์ดฟรีได้เมื่อเดินถึงช่องการ์ด
Land, choose, collect.	เดินถึง เลือก แล้วรับเลย
Tactic Cards offers demolition, shields or renovation. Rent Cards offers rent demand or rent boost.	ช่องการ์ดกลยุทธ์: รื้อบ้าน โล่ หรืออัปเกรด\nช่องการ์ดค่าเช่า: เรียกเก็บหรือเพิ่มค่าเช่า
Rent Cards space	ช่องการ์ดค่าเช่า
Tactic Cards space	ช่องการ์ดกลยุทธ์
Collect free cards when your pawn lands on the marked spaces.	รับการ์ดฟรีเมื่อตัวละครเดินถึงช่องการ์ด
VIEW CARDS & GOALS	ดูการ์ดและเป้าหมาย
RECENT CITY NEWS	ข่าวล่าสุด
Events and offers change as the match progresses.	กิจกรรมและข้อเสนอเปลี่ยนไปตามเกม
Look around! Paid offers open on your turn.	เลือกดูก่อนได้ ใช้บริการเมื่อถึงตาของคุณ
Use city offers before rolling on your next turn.	ใช้บริการก่อนทอยในตาถัดไป
City offer used. Your next step is to roll.	ใช้บริการแล้ว ทอยลูกเต๋าต่อได้เลย
CONFIRMING...	กำลังยืนยัน…
BROWSE FOR NEXT TURN	ดูไว้สำหรับตาถัดไป
CHOOSE A HOME	เลือกบ้าน
CARD LIMIT REACHED	การ์ดชนิดนี้เต็มแล้ว
YOUR GOAL	เป้าหมายของคุณ
TAP TO CLAIM	แตะรับรางวัล
REWARD READY	รับรางวัลได้แล้ว
YOUR NEXT GOAL	เป้าหมายถัดไป
CLAIMING...	กำลังรับ…
You earned it!	ทำสำเร็จแล้ว!
Claim on your turn	รับเมื่อถึงตาของคุณ
Card Spaces	ช่องรับการ์ด
Land on a marked space for a free card	เดินถึงช่องการ์ดเพื่อรับฟรี
Click to see how cards work	แตะเพื่อดูวิธีรับการ์ด
Card Space	ช่องรับการ์ด
Land here to choose a free card	เดินถึงช่องนี้เพื่อเลือกการ์ดฟรี
Click to view cards	แตะเพื่อดูการ์ด
Challenge Hall	ศูนย์เป้าหมาย
Your city goals and rewards	เป้าหมายและรางวัลของคุณ
Click to view challenges	แตะเพื่อดูเป้าหมาย
City News	ข่าวเมือง
See what is happening	ดูความเคลื่อนไหวของเมือง
Click to read the bulletin	แตะเพื่ออ่านข่าว
Let's roll!	ทอยเลย!
Your next move starts here	เริ่มเดินจากการทอย
Click the dice on your turn	แตะลูกเต๋าเมื่อถึงตา
GO!	เริ่ม!
YOUR CITY STARTS HERE	เริ่มสร้างเมืองของคุณ
Roll, build homes, and outsmart the table.	ทอย สร้างบ้าน และวางแผนให้ชนะ
SHIELD SAVED THE HOUSE!	โล่ป้องกันบ้านไว้!
DEMOLITION!	รื้อบ้านแล้ว!
HOME UPGRADED!	อัปเกรดบ้านแล้ว!
FREE HOME UPGRADE!	อัปเกรดบ้านฟรี!
RENT BOOST ACTIVATED	เพิ่มค่าเช่าแล้ว
HOME PROTECTED	บ้านมีโล่แล้ว
RENT DEMAND!	เรียกเก็บค่าเช่า!
A resident	ผู้เล่น
CARD COLLECTED!	ได้รับการ์ดแล้ว!
CITY REWARD!	รางวัลจากเมือง!
GOAL COMPLETE!	เป้าหมายสำเร็จ!
WIN	สำเร็จ
NEWS	ข่าว
OUT OF CASH	เงินหมดแล้ว
CITY	เมือง
YOUR NEXT HOME?	บ้านหลังใหม่ของคุณ?
WELCOME HOME!	กลับถึงบ้านแล้ว!
RENT PAID	จ่ายค่าเช่าแล้ว
HOME	บ้าน
PAYDAY AT CITY GATE!	รับเงินผ่านจุดเริ่มต้น!
A CARD FOR YOUR NEXT MOVE	การ์ดสำหรับตาถัดไป
COLLECT A FREE CARD	รับการ์ดฟรี
CITY TAX	ภาษีเมือง
TAX	ภาษี
A DETOUR TO DETENTION	ต้องไปเรือนจำ
JUST VISITING	แวะเยี่ยม
CHOOSE YOUR REWARD!	เลือกรางวัลของคุณ!
PICK	เลือก
COSMETIC SHOP · WATERFRONT CLUB	ร้านตกแต่ง · วอเตอร์ฟรอนต์คลับ
Make it yours.	แต่งเมืองในแบบคุณ
3 signature styles · one-time Robux pass · yours to keep	3 สไตล์ · พาส Robux ซื้อครั้งเดียว
Reduced motion: OFF	ลดภาพเคลื่อนไหว: ปิด
Preview collection	ดูตัวอย่าง
Check ownership	ตรวจสอบพาส
House finishes · Dice skins · Aura + trail. Cosmetics only.	ตกแต่งบ้าน ลูกเต๋า ออร่า และเอฟเฟกต์เดิน
Verification is delayed. Use Verify my purchase or Check ownership.	ตรวจสอบล่าช้า กดตรวจสอบการซื้อหรือพาสอีกครั้ง
Purchase cancelled. You can keep playing or preview another style.	ยกเลิกการซื้อแล้ว เล่นต่อหรือดูสไตล์อื่นได้
Roblox could not open the purchase prompt. Please try again.	เปิดหน้าซื้อของ Roblox ไม่ได้ กรุณาลองใหม่
Reduced motion: OFF · animations and trail on	ลดภาพเคลื่อนไหว: ปิด · แสดงเอฟเฟกต์
Reduced motion: ON · still dice and preview	ลดภาพเคลื่อนไหว: เปิด · ลดเอฟเฟกต์
Loading your collection…	กำลังโหลดสไตล์…
STUDIO PREVIEW · no purchases or permanent unlocks	ตัวอย่างใน Studio · ไม่มีการซื้อจริง
CLUB MEMBER · all three collections unlocked	สมาชิกคลับ · ปลดล็อกครบ 3 สไตล์
Preview any collection before purchasing.	ดูตัวอย่างทุกสไตล์ก่อนตัดสินใจซื้อ
Roblox handles checkout and verifies ownership. Game cash cannot buy Club.	ซื้อผ่าน Roblox เท่านั้น ใช้เงินในเกมซื้อพาสไม่ได้
Choose a collection	เลือกสไตล์
Loading collection…	กำลังโหลด…
Complete Roblox checkout…	ทำรายการในหน้าซื้อ Roblox…
Verifying with Roblox…	กำลังตรวจสอบกับ Roblox…
Equipped ✓	ใช้อยู่ ✓
Equip in Studio preview	ใช้ในตัวอย่าง Studio
Verify my purchase	ตรวจสอบการซื้อ
Club pass coming soon	ยังไม่เปิดขายพาส
Checking Robux price…	กำลังตรวจราคา Robux…
Retry Robux price	ตรวจราคาอีกครั้ง
Pass not on sale	พาสยังไม่เปิดขาย
Unlock Club · FREE	ปลดล็อกคลับ · ฟรี
City Original	สไตล์เมืองดั้งเดิม
ORIGINAL	ดั้งเดิม
Golden Estate	คฤหาสน์ทอง
GOLDEN ESTATE	คฤหาสน์ทอง
Aurora Residence	บ้านแสงออโรรา
AURORA	ออโรรา
Rose Conservatory	เรือนสวนกุหลาบ
ROSE	กุหลาบ
The original waterfront home, with your player-colored roof and garden.	บ้านริมน้ำพร้อมหลังคาและสวนตามสีผู้เล่น
Brass-framed windows, marble steps, pearl topiary and warm garden lanterns.	กรอบหน้าต่างสีทอง บันไดหินอ่อน และโคมไฟสวน
Brushed silver, turquoise light strips and a sculpted crystal garden.	ขอบสีเงิน แสงเทอร์ควอยซ์ และสวนคริสตัล
Rose-gold details, pale stone, flowering planters and a soft evening glow.	ตกแต่งสีโรสโกลด์ หินสีอ่อน และสวนดอกไม้
Cottage	บ้านเล็ก
Townhouse	ทาวน์เฮาส์
Garden villa	วิลล่าสวน
Grand villa	วิลล่าหรู
A furnished cottage, porch, flower boxes and private garden.	บ้านพร้อมเฟอร์นิเจอร์ ระเบียง และสวนส่วนตัว
Two floors, an upstairs bedroom and a staircase.	บ้าน 2 ชั้น พร้อมห้องนอนและบันได
A larger villa with a balcony, roof garden and pergola.	วิลล่าพร้อมระเบียง สวนดาดฟ้า และซุ้มพักผ่อน
Three floors, upstairs bedrooms and the highest rental income.	บ้าน 3 ชั้น พร้อมห้องนอนและค่าเช่าสูงสุด
Old Town	ย่านเมืองเก่า
Sunset District	ย่านตะวันตก
Harbor District	ย่านท่าเรือ
Metro District	ย่านใจกลางเมือง
Garden District	ย่านสวน
Rose District	ย่านกุหลาบ
Sky District	ย่านท้องฟ้า
Crown District	ย่านมงกุฎ
CITY GATE	จุดเริ่มต้น
Copper Lane	ตรอกทองแดง
Brick Courtyard	ลานอิฐ
TACTIC CARDS	การ์ดกลยุทธ์
Sunset Street	ถนนตะวันตก
Mango Market	ตลาดมะม่วง
DETENTION	เรือนจำ
Harbor Walk	ถนนริมน้ำ
Portside	ท่าเรือ
Midtown Loft	ลอฟต์กลางเมือง
Metro Square	จัตุรัสเมือง
CENTRAL PARK	สวนกลางเมือง
Garden Gate	ประตูสวน
Garden Lane	ซอยสวน
Fern Park	สวนเฟิร์น
Neon Row	ถนนนีออน
Pixel Pier	ท่าพิกเซล
Sky Avenue	ถนนท้องฟ้า
Crown Heights	เนินมงกุฎ
Grand Boulevard	ถนนแกรนด์
Fern Avenue	ถนนเฟิร์น
Neon Square	จัตุรัสนีออน
Pixel Plaza	ลานพิกเซล
GO TO DETENTION	ไปเรือนจำ
Skyline Terrace	ระเบียงฟ้า
Cloud Court	ลานเมฆ
RENT CARDS	การ์ดค่าเช่า
Crown Lane	ถนนมงกุฎ
Royal Heights	เนินราชา
Demolition permit	การ์ดรื้อบ้าน
Rent demand	เรียกเก็บค่าเช่า
Property shield	โล่ป้องกันบ้าน
Renovation grant	อัปเกรดบ้านฟรี
Choose a rival's home. Match rules set full demolition or one-level damage.	เลือกบ้านคู่แข่ง รื้อทั้งหลังหรือลดระดับตามกติกา
Choose a rival's home. Remove one level; cottages return to the city.	เลือกบ้านคู่แข่งเพื่อลด 1 ระดับ บ้านเล็กจะถูกรื้อ
Choose a rival's home. Demolish it and return the plot to the city.	เลือกบ้านคู่แข่งเพื่อรื้อทั้งหลัง ที่ดินจะเปิดขายใหม่
Choose your home and a rival. Collect 2× its rent now (up to $350).	เลือกบ้านของคุณและคู่แข่ง เก็บค่าเช่า 2 เท่า สูงสุด $350
Choose your property. Raise rent by 50% for its next two rent payments.	เลือกบ้านของคุณ เพิ่มค่าเช่า 50% สำหรับ 2 ครั้งถัดไป
Choose your property. Block the next demolition attempt on it.	เลือกบ้านของคุณ ป้องกันการรื้อครั้งถัดไป
Choose your property. Add one home level for free, up to level 3.	เลือกบ้านของคุณ เพิ่ม 1 ระดับฟรี สูงสุดระดับ 3
Neighborhood builder	เจ้าของบ้านมือใหม่
Own two homes at the same time.	เป็นเจ้าของบ้าน 2 หลังพร้อมกัน
Home improvement	นักพัฒนาบ้าน
Add two building levels.	เพิ่มระดับบ้านรวม 2 ระดับ
Rental business	ธุรกิจค่าเช่า
Collect $200 in rent payments.	เก็บค่าเช่ารวม $200
City explorer	นักสำรวจเมือง
Pass City Gate twice.	ผ่านจุดเริ่มต้น 2 ครั้ง
In the headlines	คนดังประจำเมือง
Land on City News twice.	เดินถึงช่องข่าวเมือง 2 ครั้ง
Make your move	นักวางกลยุทธ์
Play two tactical cards.	ใช้การ์ดกลยุทธ์ 2 ใบ
District collector	นักสะสมย่าน
Own a complete district pair.	เป็นเจ้าของที่ดินครบคู่ในย่านเดียวกัน
Builder's Deal	ข้อเสนอผู้สร้างเมือง
A city investor likes your plans. Choose your guaranteed reward.	นักลงทุนชอบแผนของคุณ เลือกรางวัลได้เลย
Renovation card	การ์ดอัปเกรดบ้าน
Upgrade one of your homes for free when you play this card.	ใช้การ์ดนี้เพื่ออัปเกรดบ้านของคุณฟรี
Neighborhood Watch	เพื่อนบ้านช่วยดูแล
Your neighborhood is looking out for you. Pick what helps your city.	เพื่อนบ้านพร้อมช่วย เลือกสิ่งที่เมืองคุณต้องการ
Protect a home from its next demolition attempt.	ป้องกันการรื้อบ้านครั้งถัดไป
Rent Campaign	แคมเปญค่าเช่า
A local business offers a partnership. Which reward fits your plan?	ธุรกิจในเมืองอยากร่วมมือ เลือกรางวัลตามแผนของคุณ
Choose a home and an opponent when you play the card.	เลือกบ้านและคู่แข่งเมื่อใช้การ์ด
Festival Sponsor	ผู้สนับสนุนเทศกาล
The city festival wants a sponsor. Choose a reward for helping out.	เทศกาลต้องการผู้สนับสนุน เลือกรางวัลได้เลย
Give a chosen home +50% rent for two paid collections.	เพิ่มค่าเช่าบ้านที่เลือก 50% สำหรับ 2 ครั้ง
City Makeover	ปรับโฉมเมือง
An empty skyline makes room for a new plan. Pick your advantage.	เมืองพร้อมรับแผนใหม่ เลือกรางวัลของคุณ
Choose a rival home to demolish when you play this card.	ใช้การ์ดนี้เพื่อเลือกบ้านคู่แข่งที่จะรื้อ
Lantern Festival	เทศกาลโคมไฟ
Sponsor one of your homes: +50% rent for its next two paid collections.	สนับสนุนบ้านของคุณ เพิ่มค่าเช่า 50% จำนวน 2 ครั้ง
Design Fair	งานออกแบบบ้าน
Choose one of your homes and add a building level for $110, up to L3.	เลือกบ้านเพื่อเพิ่ม 1 ระดับในราคา $110 สูงสุดระดับ 3
Protect one of your homes against its next demolition attempt for $60.	ป้องกันการรื้อบ้านครั้งถัดไปในราคา $60
You landed on a card space. Choose one free card for your hand.	เดินถึงช่องการ์ดแล้ว เลือกรับการ์ดฟรี 1 ใบ
FREE CARD	การ์ดฟรี
JAIL	เรือนจำ
JUST VISIT	แวะเยี่ยม
PARK	สวน
GO TO	ไปที่
FOR SALE	ขายที่ดิน
LET'S ROLL!	ทอยเลย!
LAND HERE · FREE CARD	เดินถึงแล้วรับการ์ดฟรี
DEMO	รื้อบ้าน
SHIELD	โล่
UPGRADE	อัปเกรด
RENT	ค่าเช่า
BOOST	เพิ่มค่าเช่า
SHIELDED	มีโล่
RENT +50%	ค่าเช่า +50%
ARTS	หอศิลป์
HARBOR	ท่าเรือ
BAKERY	ร้านขนม
CITY HALL	ศาลากลาง
LIBRARY	ห้องสมุด
CAFE	คาเฟ่
CITY HOTEL	โรงแรม
CITY POLICE	สถานีตำรวจ
CITY SERVICES	บริการเมือง
CITY BANK	ธนาคารเมือง
A paid rental improvement. This multiplier applies to future rent payments on this property.	ใช้อัตรานี้กับค่าเช่าครั้งต่อไปของที่ดินนี้
Your avatar is still loading.	กำลังโหลดตัวละคร กรุณารอสักครู่
MARKET	ตลาด
POLICE	สถานีตำรวจ
BANK	ธนาคาร
FERRY	เรือข้ามฟาก
TAKE A CARD	รับการ์ด
WELCOME	ยินดีต้อนรับ
Take ${n1}	รับเงิน ${n1}
Add ${n1} to your balance now.	รับเงิน ${n1} ทันที
NET WORTH  ${n1}	ทรัพย์สินรวม ${n1}
Your homes  ·  {1}	บ้านของฉัน · {1}
MY HOMES · {1}	บ้านของฉัน · {1}
TURN {1} / {2}	ตาที่ {1} / {2}
{1}'s turn	ตาของ {1}
{1} has finished.	{1} เล่นจบตาแล้ว
{1}'s home · {t2}	บ้านของ {1} · {t2}
{1}'s home	บ้านของ {1}
SOLD!	ขายแล้ว!
UPGRADED!	อัปเกรดแล้ว!
At home · {t1}	กำลังชมบ้าน · {t1}
FOR SALE · from ${n1}	ขายที่ดิน · เริ่ม ${n1}
{1} including land	{1} รวมที่ดิน
{1} / visit	{1} / ครั้ง
LEVEL {1}	ระดับ {1}
RENT  ${n1}	ค่าเช่า ${n1}
RENT ${n1}	ค่าเช่า ${n1}
FROM ${n1}	เริ่ม ${n1}
Rent {n1}×	ค่าเช่า {n1} เท่า
{t1} · SHIELDED	{t1} · มีโล่
{t1} · BOOST {2}	{t1} · เพิ่มค่าเช่า {2}
{1} · Level {2}	{1} · ระดับ {2}
{t1} · L{n2}	{t1} · ระดับ {n2}
L{n1}	ระดับ {n1}
TOTAL {1}	รวม {1}
{t1} · PAIR	{t1} · ครบคู่
YOU ROLLED {1}	คุณทอยได้ {1}
NEXT TURN IN {1}s	ตาถัดไปใน {1} วินาที
{n1}s left	เหลือ {n1} วินาที
{t1} · Events [P]	{t1} · กิจกรรม [P]
Buy home · ${n1}+	ซื้อบ้าน · ${n1}+
Buy {t1}	ซื้อ{t1}
Set {t1}	ตั้งค่า {t1}
Upgrade to {t1}	อัปเกรดเป็น{t1}
{t1} available	มีเงิน {t1}
{t1} · Land included	{t1} · รวมที่ดิน
{t1} · Current {2}	{t1} · ปัจจุบัน {2}
{t1} · Current L{2}	{t1} · ระดับปัจจุบัน {2}
{t1} · ${n2} available · Land included	{t1} · มีเงิน ${n2} · รวมที่ดิน
{t1} · ${n2} available · Current L{n3}	{t1} · มีเงิน ${n2} · ระดับปัจจุบัน {n3}
{t1} · ${n2} available · Current {n3}×	{t1} · มีเงิน ${n2} · อัตราปัจจุบัน {n3} เท่า
{1} total	รวม {1}
{1} fee	ค่าบริการ {1}
{1} to upgrade	อัปเกรด {1}
{1} rent	ค่าเช่า {1}
Need ${n1} more	ขาดอีก ${n1}
NEED ${n1} MORE	ขาดอีก ${n1}
Total price: ${n1}	ราคารวม ${n1}
Rental fee: ${n1}	ค่าตั้งอัตราเช่า ${n1}
Upgrade cost: ${n1}	ค่าอัปเกรด ${n1}
{t1}   ·   Rent ${n2}	{t1} · ค่าเช่า ${n2}
Balance after: ${n1}	เงินคงเหลือ ${n1}
Need ${n1} more. Choose a lower option, or go back.	ขาดอีก ${n1} เลือกระดับที่ถูกลงหรือกลับ
{t1} returns to the city for ${n2}. Its house will be removed, and you may lose your district bonus.	ขาย{t1}ได้เงิน ${n2} บ้านจะถูกรื้อและอาจเสียโบนัสย่าน
{1} wins the neighborhood.	{1} ชนะเกม!
${n1} net worth. Home, sweet home.	ทรัพย์สินรวม ${n1} ยินดีด้วย!
Your level {1} {t2} at {t3} is ready.	บ้านระดับ {1} {t2} ที่{t3}พร้อมแล้ว
{t1} is now a level {2} {t3}.	{t1}อัปเกรดเป็น{t3} ระดับ {2} แล้ว
{t1} now charges {2}× rent on future visits.	{t1}คิดค่าเช่า {2} เท่าในครั้งต่อไป
Your house at {t1} was demolished. The lot is now for sale.	บ้านที่{t1}ถูกรื้อแล้ว ที่ดินเปิดขายใหม่
Land ${n1} + building ${n2}	ที่ดิน ${n1} + บ้าน ${n2}
Fill empty seats with bots: ON	เติมบอตในที่ว่าง: เปิด
Fill empty seats with bots: OFF	เติมบอตในที่ว่าง: ปิด
READY · {1} · host	พร้อม · {1} · เจ้าห้อง
WAITING · {1} · host	ยังไม่พร้อม · {1} · เจ้าห้อง
READY · {1}	พร้อม · {1}
WAITING · {1}	ยังไม่พร้อม · {1}
PLAY ONLINE · {1} PLAYERS	เล่นออนไลน์ · {1} คน
{1} / {2} · reward ${n3} + card	{1} / {2} · รับ ${n3} และการ์ด
{1} / {2} · reward ${n3} · hand full	{1} / {2} · รับ ${n3} · การ์ดเต็ม
Claim ${n1} + card	รับ ${n1} และการ์ด
Claim ${n1}	รับ ${n1}
{t1} ×{2}	{t1} ×{2}
Play {t1}	ใช้{t1}
Demand ${n1} now using {t2}.	เรียกเก็บ ${n1} จาก{t2}ตอนนี้
Remove one level: L{1} → L{2}	ลดระดับ {1} → {2}
Free upgrade: L{1} → L{2}	อัปเกรดฟรี {1} → {2}
Upgrade to level {1}	อัปเกรดเป็นระดับ {1}
Your choice · {1} seconds left	เลือกได้เลย · เหลือ {1} วินาที
{1} turns left · choose your home below	เหลือ {1} ตา · เลือกบ้านด้านล่าง
Cost ${n1} · Balance after ${n2}	ราคา ${n1} · เงินคงเหลือ ${n2}
Choose a home · festival costs ${n1}	เลือกบ้าน · ค่าบริการ ${n1}
FREE · up to {1} each · scroll for all {2} cards	ฟรี · เก็บได้ชนิดละ {1} ใบ · เลื่อนดูครบ {2} ชนิด
{1} / {2} in your hand · {t3}	มี {1} / {2} ใบ · {t3}
Current festival: {t1}	เทศกาล: {t1}
JOIN FESTIVAL · ${n1}	ร่วมเทศกาล · ${n1}
{1} turns until the next festival	อีก {1} ตาจะเปลี่ยนเทศกาล
Offer ${n1} · click to explore	ราคา ${n1} · แตะเพื่อดู
{t1} · click to inspect	{t1} · แตะเพื่อดู
{1} collected ${n2} using {t3}.	{1} เก็บเงิน ${n2} จาก{t3}
{1} at {t2}	{1} · {t2}
{1} chose {t2}.	{1} เลือก{t2}
+${n1} and a card. Your next goal is ready.	+${n1} และการ์ด เป้าหมายใหม่พร้อมแล้ว
+${n1}. Your next goal is ready.	+${n1} เป้าหมายใหม่พร้อมแล้ว
CLUB MEMBER · {t1}	สมาชิกคลับ · {t1}
CLUB · {t1}	คลับ · {t1}
Equip {t1}	ใช้{t1}
{t1} ✓	{t1} ✓
Unlock Club · R$ {1}	ปลดล็อกคลับ · R$ {1}
{1}× RENT	ค่าเช่า {1} เท่า
FOR SALE · from ${n1} including land	ขายที่ดิน · เริ่ม ${n1} รวมที่ดิน
{t1} · {2} · L{3}	{t1} · {2} · ระดับ {3}
{t1} · ${n2} rent	{t1} · ค่าเช่า ${n2}
{t1}   ·   Rent ${n2} → ${n3}	{t1} · ค่าเช่า ${n2} → ${n3}
Rent ${n1} → ${n2}	ค่าเช่า ${n1} → ${n2}
{t1} is now a level {n2} {t3}!	{t1}อัปเกรดเป็น{t3} ระดับ {n2} แล้ว!
No district pair required. {t1}	ไม่ต้องมีย่านครบคู่ {t1}
OLD TOWN	ย่านเมืองเก่า
SUNSET DISTRICT	ย่านตะวันตก
HARBOR DISTRICT	ย่านท่าเรือ
METRO DISTRICT	ย่านใจกลางเมือง
GARDEN DISTRICT	ย่านสวน
ROSE DISTRICT	ย่านกุหลาบ
SKY DISTRICT	ย่านท้องฟ้า
CROWN DISTRICT	ย่านมงกุฎ
Your startup pays a dividend. Collect $120.	ธุรกิจจ่ายเงินปันผล รับ $120
A city grant arrives. Collect $80.	ได้รับเงินสนับสนุนเมือง $80
Street repairs cost $90.	จ่ายค่าซ่อมถนน $90
You win the design contest! Collect $150.	ชนะประกวดออกแบบ รับ $150!
A paperwork mix-up! Go to detention.	เอกสารผิดพลาด ต้องไปเรือนจำ
Express ride to City Gate! Collect $200.	เดินทางด่วนไปจุดเริ่มต้น รับ $200
Your phone needs repairs. Pay $60.	โทรศัพท์เสีย จ่ายค่าซ่อม $60
The night market is a hit. Collect $100.	ตลาดกลางคืนขายดี รับ $100
A demolition permit arrives. Choose when to use it.	ได้รับการ์ดรื้อบ้าน เก็บไว้ใช้เมื่อพร้อม
Your lawyer prepares a rent demand.	ทนายเตรียมการ์ดเรียกเก็บค่าเช่าให้
A festival makes one of your rentals more popular.	เทศกาลช่วยเพิ่มความนิยม ได้รับการ์ดเพิ่มค่าเช่า
An insurance voucher can protect your next big investment.	ได้รับการ์ดโล่สำหรับป้องกันบ้าน
A renovation grant lets you improve a home for free.	ได้รับการ์ดอัปเกรดบ้านฟรี
Collect two new tactical cards.	ได้รับการ์ดกลยุทธ์ 2 ใบ
Garden maintenance costs $20 per home you own.	จ่ายค่าดูแลสวนหลังละ $20
Your community business pays $35 per home you own.	ธุรกิจชุมชนจ่ายให้บ้านคุณหลังละ $35
A street fair gives every resident $40.	งานถนนคนเดินแจกผู้เล่นทุกคน $40
A service charge costs $30 for each building level you own.	จ่ายค่าบริการระดับบ้านละ $30
You find a forgotten savings account. Collect $180.	พบบัญชีเงินเก่า รับ $180
A networking event earns you a tactical card.	ร่วมงานพบปะ ได้รับการ์ดกลยุทธ์
Welcome to Citymoney! {1} goes first.	ยินดีต้อนรับสู่ซิตี้มันนี่! {1} เริ่มก่อน
It's {1}'s turn.	ถึงตาของ {1}
{1} landed on {t2}. Collect a free card!	{1} เดินถึง{t2} เลือกรับการ์ดฟรีได้เลย!
{1} landed on {t2}.	{1} เดินถึง{t2}
{1} discovered {t2}. Choose cash or a tactical card!	{1} พบ{t2} เลือกรับเงินหรือการ์ด!
{1} continued without collecting a card.	{1} ข้ามการรับการ์ด
{1} chose {t2} from {t3}!	{1} เลือก{t2}จาก{t3}!
{1} bought {t2} as a level {3} {t4} for ${n5}!	{1} ซื้อ{t2}เป็น{t4}ระดับ {3} ราคา ${n5}!
{1} upgraded {t2} to level {3} {t4} for ${n5}.	{1} อัปเกรด{t2}เป็น{t4}ระดับ {3} ราคา ${n5}
{1} sold {t2} for ${n3}.	{1} ขาย{t2}ได้เงิน ${n3}
{1} went bankrupt.	{1} ล้มละลายแล้ว
{1} is detained and will miss their next move.	{1} เข้าเรือนจำและต้องหยุดเดินในตาถัดไป
{1} served their detention and can move next turn.	{1} พักครบแล้ว เดินได้ในตาถัดไป
{1} owes {2} ${n3} rent.	{1} จ่ายค่าเช่าให้ {2} จำนวน ${n3}
{1} owes ${n2} city tax.	{1} จ่ายภาษีเมือง ${n2}
{1} passed on the property.	{1} ข้ามการซื้อที่ดิน
{1} passed City Gate and collected ${n2}.	{1} ผ่านจุดเริ่มต้น รับ ${n2}
{1} found a tactical card in Central Park.	{1} พบการ์ดในสวนกลางเมือง
{1} left the match. Their deeds return to the city.	{1} ออกจากเกม ที่ดินเปิดขายใหม่
{1} raised future rent at {t2} to {3}× for ${n4}.	{1} ตั้งค่าเช่าที่{t2}เป็น {3} เท่า จ่าย ${n4}
{1} refreshed the exterior of {t2}.	{1} เปลี่ยนสีบ้านที่{t2}
{1} wins Citymoney with ${n2} net worth!	{1} ชนะด้วยทรัพย์สินรวม ${n2}!
The city is empty. Start a new match!	ไม่มีผู้เล่นเหลือ เริ่มเกมใหม่ได้เลย!
{1}: {t2}	{1}: {t2}
{1}'s shield blocked demolition at {t2}!	โล่ของ {1} ป้องกันการรื้อที่{t2}!
{1} demolished {2}'s house at {t3}. The empty lot returns to the city.	{1} รื้อบ้านของ {2} ที่{t3} ที่ดินเปิดขายใหม่
{1} removed one building level from {2}'s {t3}.	{1} ลดระดับบ้านของ {2} ที่{t3}ลง 1 ระดับ
{1} demands ${n2} from {3} using {t4}!	{1} เรียกเก็บ ${n2} จาก {3} โดยใช้{t4}!
{1} boosted rent at {t2} by 50% for the next two payments.	{1} เพิ่มค่าเช่าที่{t2} 50% จำนวน 2 ครั้ง
{1} protected {t2} against its next demolition attempt.	{1} เพิ่มโล่ป้องกันการรื้อให้{t2}
{1} used a renovation grant to upgrade {t2} to level {3} for free.	{1} ใช้การ์ดอัปเกรด{t2}เป็นระดับ {3} ฟรี
{1} completed {t2} and collected ${n3} plus a card!	{1} ทำเป้า{t2}สำเร็จ รับ ${n3} และการ์ด!
{1} completed {t2} and collected ${n3}! Their card hand is full.	{1} ทำเป้า{t2}สำเร็จ รับ ${n3}! การ์ดเต็มแล้ว
{1} chose a new challenge for ${n2}.	{1} เปลี่ยนเป้าหมาย จ่าย ${n2}
{1} joined {t2} at {t3} for ${n4}.	{1} ใช้บริการ{t2}กับ{t3} จ่าย ${n4}
Wait for your turn.	กรุณารอถึงตาของคุณ
Start a match first.	เริ่มเกมก่อน
A match is already running.	มีเกมกำลังเล่นอยู่
A match needs 2–6 players.	ต้องมีผู้เล่น 2–6 คน
Duplicate player.	พบผู้เล่นซ้ำ
Each resident needs a different color.	ผู้เล่นแต่ละคนต้องใช้สีต่างกัน
Only active residents can visit a home.	ผู้เล่นที่ยังอยู่ในเกมจึงจะชมบ้านได้
Select a property.	เลือกที่ดิน
You can walk through homes you own.	เข้าชมได้เฉพาะบ้านของคุณ
You are bankrupt. End your turn.	คุณล้มละลายแล้ว กรุณาจบตา
That home selection expired. Open the options again.	รายการบ้านหมดอายุ กรุณาเปิดตัวเลือกใหม่
This is a different property. Open its options again.	ที่ดินไม่ตรงกัน กรุณาเปิดตัวเลือกใหม่
This property is already owned.	ที่ดินนี้มีเจ้าของแล้ว
Choose a home level from 0 to {1}.	เลือกระดับบ้านตั้งแต่ 0 ถึง {1}
You need ${n1} for this home and its land.	ต้องมีเงิน ${n1} เพื่อซื้อบ้านพร้อมที่ดิน
You don't own this property.	คุณไม่ได้เป็นเจ้าของที่ดินนี้
Choose a higher rent multiplier.	เลือกอัตราค่าเช่าที่สูงขึ้น
This rental improvement costs ${n1}.	การตั้งอัตราค่าเช่านี้ใช้เงิน ${n1}
This property is fully upgraded.	บ้านนี้อยู่ระดับสูงสุดแล้ว
Choose a higher home level, up to {1}.	เลือกระดับบ้านที่สูงขึ้น สูงสุด {1}
You need ${n1} for this upgrade.	ต้องใช้เงิน ${n1} เพื่ออัปเกรด
That action is unavailable right now.	ยังทำรายการนี้ไม่ได้ในตอนนี้
You can claim one challenge each turn.	รับรางวัลเป้าหมายได้ตาละ 1 ครั้ง
Finish the challenge before claiming it.	ทำเป้าหมายให้สำเร็จก่อนรับรางวัล
You can change your challenge once each turn.	เปลี่ยนเป้าหมายได้ตาละ 1 ครั้ง
A new challenge costs ${n1}.	เปลี่ยนเป้าหมายใช้เงิน ${n1}
Play cards during your own turn.	ใช้การ์ดเมื่อถึงตาของคุณ
That card selection expired. Choose a target again.	รายการการ์ดหมดอายุ กรุณาเลือกเป้าหมายใหม่
You can play one tactical card per turn.	ใช้การ์ดได้ตาละ 1 ใบ
Choose a valid tactical card.	เลือกการ์ดที่ใช้ได้
You do not have that card.	คุณยังไม่มีการ์ดนี้
Choose a property.	เลือกที่ดิน
Choose an owned property.	เลือกที่ดินที่มีเจ้าของ
Choose an opponent's house for demolition.	เลือกบ้านคู่แข่งที่ต้องการรื้อ
Choose one of your own properties.	เลือกที่ดินของคุณ
Choose the opponent who must pay.	เลือกคู่แข่งที่ต้องจ่ายเงิน
Choose an active opponent to pay rent.	เลือกคู่แข่งที่ยังอยู่ในเกม
This home already has a shield.	บ้านนี้มีโล่แล้ว
This home still has an active rent boost.	บ้านนี้ยังมีผลเพิ่มค่าเช่าอยู่
This home is already fully upgraded.	บ้านนี้อยู่ระดับสูงสุดแล้ว
Choose an opportunity during your own turn.	เลือกรางวัลเมื่อถึงตาของคุณ
There is no opportunity waiting.	ไม่มีรางวัลที่รอเลือก
That opportunity expired. Review the current choices.	รางวัลหมดอายุ กรุณาดูตัวเลือกปัจจุบัน
Choose one of the listed rewards.	เลือกหนึ่งในรางวัลที่แสดง
Your hand is full for this card. Choose another or continue without a card.	การ์ดชนิดนี้เต็มแล้ว เลือกใบอื่นหรือข้าม
Your hand is full for this card. Take the cash instead.	การ์ดชนิดนี้เต็มแล้ว เลือกรับเงินแทน
Visit the plaza during your turn.	ใช้บริการเมืองเมื่อถึงตาของคุณ
That plaza offer expired. Open it again.	ข้อเสนอหมดอายุ กรุณาเปิดใหม่
Cards are collected for free. Land on a Tactic Cards or Rent Cards space.	การ์ดรับฟรีเมื่อเดินถึงช่องการ์ดกลยุทธ์หรือค่าเช่า
Use the city plaza before rolling your dice.	ใช้บริการเมืองก่อนทอยลูกเต๋า
You can make one plaza purchase per turn.	ใช้บริการเทศกาลได้ตาละ 1 ครั้ง
The festival changed. Review the current offer.	เทศกาลเปลี่ยนแล้ว กรุณาดูข้อเสนอใหม่
Choose one of your homes.	เลือกบ้านของคุณ
Festival offers apply to your own homes.	ใช้บริการเทศกาลได้กับบ้านของคุณเท่านั้น
This home already has a rent boost.	บ้านนี้เพิ่มค่าเช่าไว้อยู่แล้ว
This festival offer costs ${n1} in game cash.	บริการนี้ใช้เงินในเกม ${n1}
Choose a festival service for your home.	เลือกบริการเทศกาลให้บ้านของคุณ
Already joined.	เข้าร่วมแล้ว
Only the host can change match settings.	เฉพาะเจ้าห้องเท่านั้นที่ตั้งค่าเกมได้
Choose a valid match setting.	เลือกการตั้งค่าที่ใช้ได้
Choose ready or not ready.	เลือกพร้อมหรือยังไม่พร้อม
Choose a player color.	เลือกสีผู้เล่น
That color is already taken.	มีผู้เล่นเลือกสีนี้แล้ว
Only the host can start the match.	เฉพาะเจ้าห้องเท่านั้นที่เริ่มเกมได้
The host must be ready first.	เจ้าห้องต้องกดพร้อมก่อน
A resident still needs an available color.	ยังมีผู้เล่นที่ต้องเลือกสีใหม่
Waiting for {1} more ready player(s). Invite friends, or enable bots.	รอผู้เล่นพร้อมอีก {1} คน ชวนเพื่อนหรือเปิดบอตได้
City Bot {1}	บอตเมือง {1}
That party leader is no longer in this lobby.	หัวหน้ากลุ่มออกจากห้องแล้ว
Leave your existing party before joining a friend.	ออกจากกลุ่มเดิมก่อนเข้ากลุ่มเพื่อน
That party already has four players.	กลุ่มนี้มีผู้เล่นครบ 4 คนแล้ว
You are not in a party.	คุณยังไม่ได้อยู่ในกลุ่ม
Your token is still moving. Choose after it lands.	ตัวละครยังเดินอยู่ กรุณารอถึงช่องก่อน
Your friend is already queued.	เพื่อนอยู่ในคิวแล้ว
Finish this match or leave it before queuing.	เล่นให้จบหรือออกจากเกมก่อนเข้าคิว
Choose an available party leader.	เลือกหัวหน้ากลุ่มที่พร้อมเข้าร่วม
Cancel matchmaking before changing party settings.	ยกเลิกคิวก่อนเปลี่ยนการตั้งค่ากลุ่ม
Return to the lobby to change the party.	กลับห้องรอก่อนเปลี่ยนกลุ่ม
Change match settings and colors between games.	เปลี่ยนการตั้งค่าและสีได้ระหว่างเกม
Choose a tactical card and its targets.	เลือกการ์ดและเป้าหมาย
Return to the lobby to queue another online match.	กลับห้องรอก่อนค้นหาเกมใหม่
Cancel matchmaking before starting practice.	ยกเลิกคิวก่อนเริ่มฝึกเล่น
Choose a valid home level.	เลือกระดับบ้านที่ใช้ได้
Could not verify your pass. Use Check ownership to retry.	ตรวจสอบพาสไม่ได้ กดตรวจสอบพาสเพื่อลองใหม่
Saved style is unavailable. You can still play and choose a style.	โหลดสไตล์เดิมไม่ได้ คุณยังเล่นและเลือกสไตล์ได้
Your collection is loading. Try again shortly.	กำลังโหลดสไตล์ กรุณารอสักครู่
Choose a valid style and effects setting.	เลือกสไตล์และการตั้งค่าเอฟเฟกต์ที่ใช้ได้
The Waterfront Club pass unlocks this style.	พาสวอเตอร์ฟรอนต์คลับใช้ปลดล็อกสไตล์นี้
Your collection is loading.	กำลังโหลดสไตล์
The Club pass is not available for sale yet.	พาสคลับยังไม่เปิดขาย
You left this server.	คุณออกจากเซิร์ฟเวอร์แล้ว
A newer ownership check is already available.	มีผลตรวจสอบพาสที่ใหม่กว่าแล้ว
Roblox could not verify ownership. Try Check ownership again.	Roblox ตรวจสอบพาสไม่ได้ กรุณาตรวจสอบอีกครั้ง
Your Club collection is unlocked.	ปลดล็อกสไตล์คลับแล้ว
You do not own the Club pass yet.	คุณยังไม่มีพาสคลับ
Studio preview · preferences last for this test session.	ตัวอย่างใน Studio · เก็บการตั้งค่าเฉพาะรอบทดสอบนี้
Saving your latest style…	กำลังบันทึกสไตล์ล่าสุด…
Style saved for your next visit.	บันทึกสไตล์ไว้สำหรับครั้งหน้าแล้ว
Style equipped. Saving is delayed; the server will retry.	ใช้สไตล์แล้ว การบันทึกล่าช้า ระบบจะลองใหม่
Checking your Club purchase with Roblox…	กำลังตรวจสอบการซื้อกับ Roblox…
Roblox has not confirmed this purchase yet. Use Check ownership to retry.	Roblox ยังไม่ยืนยันการซื้อ กดตรวจสอบพาสเพื่อลองใหม่
Choose a style first.	เลือกสไตล์ก่อน
Please wait a moment before changing your style again.	กรุณารอสักครู่ก่อนเปลี่ยนสไตล์อีกครั้ง
Please wait a few seconds before checking again.	กรุณารอสักครู่ก่อนตรวจสอบอีกครั้ง
Teleport failed. Cancel and queue again.	ย้ายเซิร์ฟเวอร์ไม่สำเร็จ กรุณายกเลิกแล้วเข้าคิวใหม่
Roblox could not connect yet. Retrying the reserved match.	Roblox ยังเชื่อมต่อไม่ได้ กำลังลองเข้าเกมอีกครั้ง
Searching for a match…	กำลังค้นหาเกม…
Online match	เกมออนไลน์
Waiting for the matched players to arrive…	กำลังรอผู้เล่นที่จับคู่ไว้…
Studio local matchmaking	ทดสอบจับคู่ใน Studio
Online matchmaking ready	พร้อมจับคู่เกมออนไลน์
Return to the public lobby before joining a new queue.	กลับห้องรอหลักก่อนเข้าคิวใหม่
Your party leader joins the queue for everyone.	หัวหน้ากลุ่มจะเข้าคิวให้ทุกคน
Choose 4 players, or leave the larger party first.	เลือกเกม 4 คน หรือออกจากกลุ่มก่อน
A party member has left this server.	สมาชิกในกลุ่มออกจากเซิร์ฟเวอร์แล้ว
{1} must finish the current match first.	{1} ต้องเล่นเกมปัจจุบันให้จบก่อน
{1} must be ready before your party queues.	{1} ต้องกดพร้อมก่อนเข้าคิว
Someone in your party is already queued.	มีสมาชิกในกลุ่มอยู่ในคิวแล้ว
Searching for a {1}-player match…	กำลังค้นหาเกม {1} คน…
Roblox matchmaking is temporarily unavailable. Please try again.	ระบบจับคู่ Roblox ไม่พร้อม กรุณาลองใหม่
Queue entry was cancelled.	ยกเลิกคิวแล้ว
Could not reach the queue. Try cancel again.	ติดต่อระบบคิวไม่ได้ กรุณายกเลิกอีกครั้ง
Your match is connecting. Please wait for the teleport.	กำลังเชื่อมต่อเกม กรุณารอย้ายเซิร์ฟเวอร์
Match found! Connecting {1} player(s)…	พบเกมแล้ว! กำลังเชื่อมต่อผู้เล่น {1} คน…
Could not connect. Cancel the queue and try again.	เชื่อมต่อไม่ได้ กรุณายกเลิกคิวแล้วลองใหม่
Connecting failed. Retrying your match…	เชื่อมต่อไม่สำเร็จ กำลังลองใหม่…
Queue entry expired. Please queue again.	คิวหมดอายุ กรุณาเข้าคิวใหม่
This is a Studio local test. Stop/restart Play to return to the test lobby.	นี่คือการทดสอบใน Studio หยุดแล้วกด Play ใหม่เพื่อกลับห้องรอ
Could not return to the lobby. Please try again.	กลับห้องรอไม่ได้ กรุณาลองใหม่
Your friend is no longer available in this lobby.	เพื่อนออกจากห้องนี้แล้ว
Match incomplete. Returning to the public lobby…	ผู้เล่นมาไม่ครบ กำลังกลับห้องรอหลัก…
Matchmaking service is retrying. Your place in the queue is kept.	ระบบกำลังลองใหม่ คุณยังอยู่ในคิวเดิม
]=]
for source,target in string.gmatch(catalogue,"([^\t\n]+)\t([^\n]+)") do add(source,target) end
table.sort(templates,function(a,b) return a.weight>b.weight end)
function Thai.text(value:string,depth:number?):string
    if exact[value] then return exact[value] end
    depth=depth or 0
    if depth>6 then return value end
    local prefix,body,suffix=string.match(value,"^(%s*)(.-)(%s*)$")
    if prefix~="" or suffix~="" then return prefix..Thai.text(body,depth+1)..suffix end
    for _,entry in ipairs(templates) do
        local captures={string.match(value,entry.pattern)}
        if #captures>0 then
            local args={}
            for i,key in ipairs(entry.keys) do args[key]=string.sub(key,1,1)=="t" and Thai.text(captures[i],depth+1) or captures[i] end
            return (string.gsub(entry.target,"{([%w]+)}",function(key) return args[key] or "" end))
        end
    end
    if string.find(value,"\n",1,true) then
        return (string.gsub(value,"[^\n]+",function(line) return Thai.text(line,depth+1) end))
    end
    if string.find(value," · ",1,true) then
        local pieces,last={},1
        while true do
            local position=string.find(value," · ",last,true)
            if not position then table.insert(pieces,Thai.text(string.sub(value,last),depth+1));break end
            table.insert(pieces,Thai.text(string.sub(value,last,position-1),depth+1));last=position+4
        end
        return table.concat(pieces," · ")
    end
    return value
end
function Thai.scene(entries)
    for _,entry in ipairs(entries) do if entry.text then entry.text=Thai.text(entry.text) end end
    return entries
end
function Thai.width(value:string):number
    local count=0
    for _,cp in utf8.codes(value) do
        if cp~=0x0e31 and not (cp>=0x0e34 and cp<=0x0e3a) and not (cp>=0x0e47 and cp<=0x0e4e) then count=count+1 end
    end
    return count
end
function Thai.initial(value:string):string
    return string.sub(value,1,(utf8.offset(value,2) or (#value+1))-1)
end
Thai.shortNames={ [1]="เริ่ม",[2]="ทองแดง",[3]="ลานอิฐ",[4]="กลยุทธ์",[5]="ตะวันตก",[6]="มะม่วง",[7]="เรือนจำ",[8]="ริมน้ำ",[9]="ท่าเรือ",[10]="ภาษี",[11]="ลอฟต์",[12]="จัตุรัส",[13]="สวน",[14]="ซอยสวน",[15]="เฟิร์น",[16]="ข่าวเมือง",[17]="นีออน",[18]="พิกเซล",[19]="ไปเรือนจำ",[20]="ท้องฟ้า",[21]="ลานเมฆ",[22]="ค่าเช่า",[23]="มงกุฎ",[24]="แกรนด์" }
return Thai
