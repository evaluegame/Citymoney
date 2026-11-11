# Citymoney 1.5 — publish and connect Robux

**Ready to upload for a private playtest.** The automated checks pass; native Studio rendering, live multiplayer, saved preferences and real Robux checkout still need testing in your Roblox account. The package includes both place formats, all source, English/Thai guides, the pass icon and test results.

**Updating an existing game:** keep your current cosmetic pass Asset ID and enter it in the new Config before publishing to the same experience. See **[docs/PUBLISHING.md](docs/PUBLISHING.md)** for the full update and live-test steps.

1. Right-click **Citymoney-Publish-Ready.zip → Extract All…**. In Roblox Studio choose **File → Open from File → Citymoney/build/Citymoney.rbxl** from the extracted folder. The direct **[Citymoney.rbxl download](https://raw.githubusercontent.com/evaluegame/Citymoney/main/Citymoney.rbxl)** also opens without extracting a ZIP.
2. Press **Play → PLAY NOW → 2 / 4 PLAYERS → PRACTICE WITH BOTS**. Try buying a starting house level, upgrading, rent settings, card collection/use, dice movement and automatic next turns. Stop Play before editing or publishing.
3. Choose **File → Publish / Publish to Roblox** and create the experience under your Roblox account or group. Keep access private for your first playtest and give your testers playtest access. For an existing game, publish to its intended start place.
4. In **[Creator Dashboard](https://create.roblox.com/dashboard/creations)** select this same experience → **Monetization → Passes → Create pass**. Upload **Citymoney/docs/Club-pass-icon.png**, choose a name, enable sales and set your Robux price. This is one permanent cosmetic pass, not a developer product. Copy its numeric **Asset ID**.
5. In Studio, stop Play and open **Explorer → ReplicatedStorage → Citymoney → Config**. Replace `clubPassId = 0,` with `clubPassId = YOUR_NUMERIC_PASS_ID,` using the actual number without quotes. Publish to the **same experience** again and join a new server. Roblox supplies checkout and price; the server verifies ownership. Until the ID is configured, purchases remain disabled and free play is available.
6. Test in the **Roblox app** with tester accounts: 2-player and 4-player queues, friend invitations, a player leaving, English/Thai settings and phone input. Test checkout cancellation with a non-owner, ownership/equipping with a pass owner, and appearance saving after rejoining. A real purchase costs real Robux and cannot be verified by the Studio cosmetic preview. Use **MENU → Cosmetic Shop → Check ownership** to retry verification.
7. Once the live checks pass, complete Roblox's audience/account eligibility and **Maturity & Compliance** requirements, then set the experience's audience/access to **Public** in Creator Dashboard. Uploading the place alone does not make it public.

The pass unlocks house/dice styles, aura and trails only. Game cash, cards, rent and dice results are unaffected. The full walkthrough and live checks are in **[docs/PUBLISHING.md](docs/PUBLISHING.md)**; the automated evidence is in **[docs/RELEASE-CHECKS.md](docs/RELEASE-CHECKS.md)**. Suggested listing text is in **[docs/ROBLOX-LISTING.txt](docs/ROBLOX-LISTING.txt)**.

# ซิตี้มันนี่ 1.5 — เปิดเกมและเผยแพร่บน Roblox

เกมเลือกภาษาตามการตั้งค่า Roblox ของผู้เล่นแต่ละคน: English แสดงอังกฤษ และภาษาไทยแสดงไทย ผู้เล่นต่างภาษาเล่นห้องเดียวกันได้ ชื่อผู้เล่นและกติกาเหมือนกันทุกภาษา มุมกระดานและกล้องนิ่งยังเหมือนเดิม ไม่ต้องติดตั้งปลั๊กอินเพื่อเปิดไฟล์เกม

รุ่นนี้ใช้ธีมสีน้ำเงินเข้ม เพิ่มความชัดของตัวหนังสือและปุ่ม พร้อมการลองใหม่เมื่อสร้างบ้านหรือส่งข้อมูลพลาด และแก้การยกเลิกคิวเมื่อบริการ Roblox ตอบกลับไม่สำเร็จ การทดสอบอัตโนมัติไม่สามารถรับประกันว่าระบบออนไลน์จะไม่มีปัญหาได้ทั้งหมด

1. ดาวน์โหลด **[Citymoney.rbxl](https://raw.githubusercontent.com/evaluegame/Citymoney/main/Citymoney.rbxl)** บันทึกลง Desktop แล้วเปิด Roblox Studio → **File → Open from File** → **Citymoney.rbxl** หากใช้ **Citymoney-Publish-Ready.zip** ให้คลิกขวา **Extract All…** ก่อน แล้วเลือก **Citymoney/build/Citymoney.rbxl** จากโฟลเดอร์ที่แตกไฟล์แล้ว
2. กด **Play** → **เริ่มเล่น (PLAY NOW)** → เลือก **2 คน / 4 คน (2 / 4 PLAYERS)** → **ฝึกกับบอต (PRACTICE WITH BOTS)** เพื่อทดลองเล่น
3. หยุด Play แล้วเลือก **File → Publish to Roblox** เพื่อบันทึกเกมในบัญชีของคุณ
4. เข้า [Creator Dashboard](https://create.roblox.com/dashboard/creations) เลือกเกมนี้ → **Monetization → Passes → Create pass** ใช้ภาพ **docs/Club-pass-icon.png** และชื่อ/คำอธิบายใน [ROBLOX-LISTING.txt](docs/ROBLOX-LISTING.txt) ตั้งราคา Robux และเปิดขาย
5. คัดลอก **Asset ID** ของพาส ใน Studio เปิด **ReplicatedStorage → Citymoney → Config** เปลี่ยน `clubPassId = 0` เป็นเลข ID แล้วเผยแพร่ไปยังเกมเดิมอีกครั้ง
6. เข้าเซิร์ฟเวอร์ใหม่ผ่านแอป Roblox ทดสอบ **เมนู → ร้านของตกแต่ง** การยกเลิกซื้อ ผู้ที่มีพาส และเกมออนไลน์ **2 / 4 คน** ก่อนเปิดให้ผู้เล่นทั่วไป

พาสซื้อครั้งเดียวปลดล็อกของตกแต่ง 3 สไตล์ ได้แก่ บ้าน ลูกเต๋า ออร่า และเอฟเฟกต์เดิน ไม่มีผลต่อเงิน ค่าเช่า การ์ด หรือโอกาสทอย ระบบแสดงราคา Robux จาก Roblox และตรวจสอบสิทธิ์บนเซิร์ฟเวอร์

เกมฟรีเล่นได้โดยไม่ต้องมีพาส ขณะนี้ `clubPassId = 0` จึงยังไม่เปิดซื้อจริง การสร้างพาสต้องทำผ่าน Creator Dashboard ที่ลงชื่อเข้าใช้บัญชีของคุณ

อ่าน [คู่มือเล่นภาษาไทย](START-HERE-TH.txt) และ [ผลตรวจรุ่นนี้](docs/RELEASE-CHECKS.md) ภาพตัวอย่างสร้างจากซอร์ส ไม่ใช่ภาพจาก Studio การแสดงผลจริง การย้ายเซิร์ฟเวอร์ และการซื้อ Robux ยังต้องทดสอบใน Roblox
