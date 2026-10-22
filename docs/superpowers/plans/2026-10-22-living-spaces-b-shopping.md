# Living Spaces B — Storage, Travel and Shopping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for Native execution or superpowers:subagent-driven-development if selected. Track `- [ ]` steps. Requires completed bundle A.

**Goal:** مخزون مكان فعلي وتسوق خارج الشاشة، مع ذهاب وعودة واستمرار الزباين والطبخ.

**Architecture:** توسعة حاويات ItemStore، ثم TravelService للموقع والمواعيد، وShopService للشراء. المشاهد والقوائم تعرض هذه الخدمات دون إدارة محاكاة بديلة.

**Tech Stack:** أدوات Godot/GDScript/JSON/Ink الحالية؛ العقود في [الخطة الجامعة](2026-10-22-living-spaces-roadmap.md).

**Spec:** [المواصفات](../specs/2026-10-22-living-spaces-shopping-and-cooking-design.md)، الأقسام 4 و7 و8 و12–14.

## Global Constraints

القيود الجامعة ملزمة. زمن المتجر 10/12/8 دقائق عالمية لكل اتجاه للسوق/الأجهزة/المنزل. UI لا يوقف الساعة، الشراء بالقرش، الحفظ 4/revision 2، ولا اختبارات آلية دون طلب.

## Review Focus

- B1: حجز مكونات أو امتلاء الثلاجة لا يفقد شيئًا أو يسحب من مكان آخر.
- B2: محرك لاعب مخفي لا يكتب location_id فعليًا فوق موقع انتقال افتراضي.
- B2/B4: استمرار الحديث بعيدًا لا يمنح اللاعب معلومة أو mood لم يسمعه.
- B3: ضغط التأكيد مرتين أو عرض تغير سعره لا يخصم مرتين.
- B4: تحميل رحلة بعد وقت يقضيه المستخدم خارج التطبيق لا يعيد مهلة الوصول أو يسقط مشتريات.

### B1 — حاويات المكان والثلاجة والأسطح كاملة

**Files:** Modify `game/items/inventory_service.gd`, `game/items/item_store.gd`, `game/spaces/space_service.gd`, `game/world/interaction_router.gd`, `game/ui/hud.gd`, `game/app/game_session.gd`, `content/items.json`, `content/containers.json`, `content/ui.json`, `content/manifest.json`, `game/presentation/soundscape.gd`, `content/atmosphere.json`. Create `game/cooking/equipment_service.gd`, `content/equipment.json`, `game/ui/inventory_panel.gd`.

**Interfaces:** `InventoryService.available(location_id: StringName, requirements: Array[Dictionary]) -> ActionResult`, `reserve(job_id: StringName, location_id: StringName, requirements: Array[Dictionary]) -> ActionResult`, `consume_reservation(job_id: StringName, amounts: Array[Dictionary]) -> ActionResult`, `release_reservation(job_id: StringName) -> ActionResult`, `unpack_purchase_bag(bag_id: StringName, location_id: StringName) -> ActionResult`. مقدار المكوّن `definition_id, quantity, required_storage`؛ الحجز يحفظ IDs وكميات مصادر فعلية. `EquipmentService.configure(definitions: Dictionary, items: ItemStore, spaces: SpaceService) -> ActionResult`, `is_usable(id: StringName, location_id: StringName, capability: StringName) -> bool`, `set_enabled(id: StringName, enabled: bool) -> ActionResult`. enabled خاصية واحدة للنسخة؛ لا مؤقت طبخ جديد هنا.

- [ ] نفذ سعة/توافق الحاويات ومخزون الموقع والمكونات الباردة والجافة وحاويات الأسطح. وصّل usability بوجود الجهاز موضوعًا ومفعلًا في المكان، دون احتساب أجهزة مخزن الأثاث كأجهزة عاملة.
- [ ] اربط الأثاث المنزلي باستعماله الفعلي: السرير الموضع المعتمد للنوم، والمروحة الموضوعة والمفعلة تؤثر على الراحة، والراديو الموضوع يتيح تشغيلًا/إيقافًا وصوتًا أصليًا بسيطًا عبر Soundscape دون بث خارجي. سجل enabled واحد في النسخة، وإعادة الترتيب تنقل نقطة التفاعل والصوت.
- [ ] نفذ حجزًا ذريًا بعد التحقق من كل المتطلبات، مع استهلاك كمية كل خطوة وتحرير المتبقي. عمليات عدّ المتاح تستبعد المحجوز ولا تقرأ مخزون البيت للكشك. عمل legacy النشط يحتفظ بحقيقة ما خُصم منه.
- [ ] اجعل unpack ينقل بالكميات التي تسمح بها السعات بترتيب IDs ثابت، ويرجع `moved` و`remaining`، مع إبقاء الباقي في الحقيبة. لا يستهلك الطبخ شيئًا من الحقيبة نفسها. تخزين ثلاجة ممتلئة مرفوض؛ النقل بين المواقع يحتاج حاوية يحملها اللاعب.
- [ ] اربط فتح المخزون/إفراغ الحقيبة ورفع الطعام بـE/F ولوحة عربية عند الحاجة؛ العالم مستمر. افحص يدويًا ثلاجة ممتلئة، نقل جزء فقط، مكوّن محجوز، ووجود المكوّن في المكان الخطأ ثم نقله فعليًا. commit `feat: add venue storage and real ingredient reservations`.

### B2 — استمرار العالم وحضور اللاعب ورحلة المتجر

**Files:** Create `game/travel/journey_state.gd`, `game/travel/travel_service.gd`, `game/world/location_registry.gd`, `game/ui/journey_panel.gd`, `content/travel.json`. Modify `game/actors/actor_pose.gd`, `game/app/game_session.gd`, `game/app/main.gd`, `game/app/physical_world_controller.gd`, `game/life/life_actions.gd`, `game/narrative/narrative_director.gd`, `game/narrative/narrative_effects.gd`, `game/narrative/condition_evaluator.gd`, `game/world/location_definition.gd`, `content/locations.json`, `content/time.json`, `content/ui.json`, `content/manifest.json`.

**Interfaces:** `LocationRegistry.kind(id: StringName) -> StringName` يعيد physical/shop/transit؛ `is_physical(id: StringName) -> bool`. `TravelService.configure(routes: Dictionary, clock: GameClock, pose: ActorPose, inventory: InventoryService, locations: LocationRegistry) -> ActionResult`, `depart(route_id: StringName) -> ActionResult`, `begin_return() -> ActionResult` يعيد اللاعب إلى أصل الرحلة، `tick(frame: Dictionary) -> void`, `can_shop(shop_id: StringName) -> bool`, `snapshot()/restore(data: Dictionary) -> ActionResult`.

- [ ] عرّف outbound/browsing/returning/completed ومواعيد world_minutes مطلقة، وحاوية مشتريات الرحلة وموضع العودة. خصص IDs افتراضية مقننة للمتاجر والانتقال، ومعناها لا يحتاج Collider أو KioskNavigation.
- [ ] عند الخروج اخفِ/عطّل محرك اللاعب الفعلي دون تعطيل VisitorController أو الجلسة. لا يستدعي step محرك اللاعب ليعيد commit_pose لموقعه القديم. عند العودة فعّل الجسم في موضع صالح حسب SpaceService.
- [ ] افصل kiosk_open عن موقع اللاعب في LifeActions.travel وعن callable استقبال VisitorService. إغلاق/فتح اللافتة فقط يغير الحالة المعتادة أثناء السفر؛ طبخ وزوار موجودون يستمرون. افصل physical-world presentation عن واجهة متجر دون تحرير جلسة Ink أو إعادة parenting لها.
- [ ] امنع سماع/اختيارات/آثار نفسية أو معرفة لاعب في موقع افتراضي. حديث NPC المستقل يتقدم بسياسة التجاهل؛ لا تطبق mood تلقائيًا من فرع listen حين اللاعب بعيد. استعمل موضع المتحدث الفعلي ونطاق السمع الحالي، لا نقطة كاميرا.
- [ ] عرّف مدد المتاجر المذكورة ومسار البيت↔الكشك 10 دقائق لكل اتجاه كبداية في بياناته، مع بقاء انتقال داخل غرفة عبر باب حركة فعلية. لا sleep/fast-forward داخل رحلة المتجر. افحص يدويًا خروجًا أثناء تسخين، وانتظار زبون ثم مغادرته، وكشكًا مغلقًا أثناء نفس الرحلة، وعدم اكتساب معرفة من حوار بعيد. commit `feat: keep the world running during shopping journeys`.

### B3 — الكتالوجات ومعاملة الشراء وواجهة المتجر

**Files:** Create `game/commerce/shop_quote.gd`, `game/commerce/shop_service.gd`, `game/content/commerce_content_validation.gd`, `game/ui/shop_panel.gd`, `game/ui/product_card.gd`, `content/shops.json`. Modify `game/economy/wallet_service.gd` عند الحاجة لمعاينة دفع، `game/app/game_session.gd`, `game/app/main.gd`, `game/ui/hud.gd`, `game/service/supply_service.gd`, `game/world/interaction_router.gd`, `content/items.json`, `content/locations.json`, `content/ui.json`, `content/manifest.json`.

**Interfaces:** `ShopService.configure(data: Dictionary, wallet: WalletService, items: ItemStore, travel: TravelService, clock: GameClock) -> ActionResult`, `offers(shop_id: StringName) -> Array[Dictionary]`, `quote(shop_id: StringName, lines: Array[Dictionary]) -> ActionResult` → `details.quote: ShopQuote`, `purchase(quote: ShopQuote, request_id: StringName) -> ActionResult` → receipt، `tick(frame: Dictionary) -> void`, `snapshot()/restore(data: Dictionary) -> ActionResult`.

- [ ] أنشئ الكتالوجات الثلاثة بكل أصناف وأسعار قسم القيم المعتمد: تشمل مواد الشاي والكبدة الحالية وحزمة 4+4 بسعر 15 جنيهًا، والأجهزة والأثاث والمكونات الجديدة. التهيئة 20 وحدة للمكوّن وأربع نسخ للقطعة، وتجديد إلى السقف مرة في 09:00 من يوم لاحق، دون تجديد العرض الاجتماعي الفريد.
- [ ] نفذ quote ثم purchase مع تحقق phase والمتجر وrevision العرض والأسعار والكميات والمال. جهز مرشحات العناصر والرصيد والعرض والإيصال كلها قبل التثبيت المتزامن بلا await؛ الإشعار بعد اكتمال كل المالكين. لا مسار نجاح جزئي بعد الدفع. request_id المكرر يعيد نفس الإيصال دون منح/خصم؛ شراء جديد مقصود له ID جديد.
- [ ] اكتب المخزون المدفوع داخل حاوية الرحلة، ثم انقل الأثاث لمخزن أصل الرحلة عند العودة وأبقِ المواد بحقيبتها حتى unpack. فشل سعة أو موضع لا يمحو ملكية السلعة. الخروج من القائمة بعد الدفع يبدأ العودة ولا يعكس الإيصال.
- [ ] صمم قائمة أقسام/بطاقات/معاينة/كمية/تفاصيل footprint والوظائف والسعر وتأكيد وعودة. رأس الوقت/المال يظل مرئيًا، ولا توجد نافذة pause. افصل العرض عن ShopService ليستخدمه محل فعلي لاحقًا.
- [ ] استبدل buy_stock الفوري برحلة السوق، ومرّر عرض مروحة عم أمجد عبر نفس الخدمة والسعر 3500 قرش وحد الملكية الواحدة؛ يحفظ العرض ارتباطه بالمعرفة. افحص يدويًا مكررات التأكيد، رصيدًا ناقصًا، نفادًا، عرضًا تغيرت بياناته، وإلغاء قبل/بعد الدفع. commit `feat: add browsable shops with atomic purchase receipts`.

### B4 — حفظ الرحلات والتصفح ومراجعة الحزمة

**Files:** Modify `game/persistence/living_spaces_migration.gd`, `game/persistence/living_spaces_save_validation.gd`, `game/persistence/save_codec.gd`, `game/app/game_session.gd`, `game/app/qa_probe.gd`, `game/ui/hud.gd`, `game/ui/shop_panel.gd`. Create `docs/notes/2026-10-22-living-spaces-b.md`.

**Interfaces:** revision 2 يضيف travel/shops/equipment إلى امتدادات الحفظ. يظل enabled داخل النسخة، وEquipmentService يحفظ فقط حالته المالكة التي لا تشتق من العناصر؛ لا تحفظ قائمة معاينة أو quote بوصفه شراءً. واجهة restore تتلقى إيصالات وأصناف فعلية، وتعيد فتح browsing من الحالة المعتمدة.

- [ ] رقّ 4/1 وschemas القديمة إلى 4/2 بإضافة الحزمة B فقط. غياب travel/shops في حفظ يدعي revision 2 فساد؛ لا تعالجه كجلسة جديدة. راجع حاوية كل رحلة وإيصالها والمرحلة والموقع الافتراضي وموضع العودة.
- [ ] احفظ outbound وbrowsing بعد شراء وreturning كلًا من داخل اللعبة، ثم أعد التحميل بنفس المتصفح واختر Continue وانتظر الوصول الفعلي. تحقق من موعد due الأصلي وعدم دفع ثانٍ، ومن بقاء جوار غائب يتقدم حين تستأنف اللعبة.
- [ ] افحص يدويًا التصفح الطويل مع طبخ نشط، عدم توقف حركة الزوار، ثم حفظ حقيبة لم تُفرغ وثلاجة ناقصة السعة. راجع العربية واللمس/الماوس عند 960×540 و1280×720 دون تغطية الدليل التشغيلي الأساسي.
- [ ] ابنِ وسجل حدود الأدلة، ثم commit `feat: resume shopping and venue storage across reloads`.

## بوابة الحزمة B

`bash tools/build.sh --out /tmp/kiosk-living-b`، ثم دورة فعلية شراء/عودة/تفريغ/حفظ، مع زيارة وخدمة/مغادرة حقيقية أثناء الغياب. تبقى واجهة الطبخ القديمة قابلة للاستخدام؛ الوصفات المتطورة وحساسية النظافة تدخلان C/D.
