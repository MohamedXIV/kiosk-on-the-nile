# Living Spaces A — Items and Shared Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for Native execution or superpowers:subagent-driven-development if selected. Track steps with `- [ ]`. Read the approved spec and master plan before executing.

**Goal:** امتلاك وترتيب عناصر البيت والكشك من نفس النظام، مع هيكل للمطور ومرور وحفظ فعليين.

**Architecture:** ItemStore يملك العناصر والحاويات؛ SpaceService يملك مواضعها. قواعد GridPlacementRules مشتركة بين المحرر واللعب، ومهايئ المشهد يعكسها في التصادم والتفاعل.

**Tech Stack:** نفس Godot/GDScript/JSON/AStarGrid2D وEditorPlugin المحددين بالخطة الجامعة.

**Spec:** [المواصفات](../specs/2026-10-22-living-spaces-shopping-and-cooking-design.md)، الأقسام 3 و5 و6 و13 و14؛ [القيود والعقود الجامعة](2026-10-22-living-spaces-roadmap.md).

## Global Constraints

كل قيود الخطة الجامعة ملزمة؛ الخلية 0.25، ست counters، أدوات الهيكل للمطور فقط، لا نسخ ملكية/مواضع، ولا اختبارات آلية دون طلب. هذه الحزمة revision 1 من schema 4.

## Review Focus

- A1/A4: نفس الطعام لا يكون في اليد وفوق سطح معًا.
- A2/A4: إعادة التحقق بعد دخول NPC مكان المعاينة وحماية المخارج.
- A3: runtime لا يمنح صلاحية إنشاء حائط من زر مخفي أو flag حفظ.
- A5: ترحيل مخزون قديم وعمل نشط ومروحة دون تكرار منح أو خصم.
- A5: معاينة غير مثبتة وحفظ معلق لا يستبدلان موضعًا مؤكدًا.

### A1 — سجل العناصر والحاويات وربط الملكية الحالية

**Files:** Create `game/items/item_store.gd`, `game/items/item_change_set.gd`, `game/items/inventory_service.gd`, `game/content/item_content_validation.gd`, `content/items.json`, `content/containers.json`. Modify `game/cooking/cooking_service.gd`, `game/life/home_service.gd`, `game/service/supply_service.gd`, `game/service/service_system.gd`, `game/app/game_session.gd`, `game/app/session_config.gd`, `game/content/content_validation.gd`, `content/manifest.json`.

**Interfaces:** `ItemStore.configure(definitions: Dictionary, containers: Dictionary) -> ActionResult`; `get_item/get_container` وItemChangeSet من الجامعة. `prepare_moves(moves: Array[Dictionary]) -> ActionResult`, `prepare_grants(grants: Array[Dictionary]) -> ActionResult`, `commit(change: ItemChangeSet) -> ActionResult`; النتيجة المرشحة في `details.change`. سطر النقل `item_id, quantity, from_container, to_container`؛ المنح `definition_id, quantity, container_id, attributes`. `snapshot() -> Dictionary`, `restore(data: Dictionary) -> ActionResult`. `InventoryService.stock_count(location_id: StringName, ingredient_id: StringName) -> int`, `held_id() -> StringName`, `prepared_item(id: StringName) -> PreparedItem` كنسخة قراءة، و`consume_held(expected_id: StringName) -> ActionResult` للاستهلاك المصرح.

- [ ] عرّف سجلًا واحدًا للنسخ والحاويات ومعدادات IDs؛ العنصر المفرد كمية 1، والمواد وحدات صحيحة. لا ترجع Dictionaries حية. ارفض كمية سالبة أو مصدرًا مختلفًا أو حاوية غير متوافقة أو نقلًا يتجاوز السعة قبل أي تغيير.
- [ ] نفذ candidate/commit متزامنًا مع revision؛ إصدار إشارات التغيير يأتي بعد تثبيت الملكية كاملة. تكرار نقل item من حاوية لم يعد فيها يفشل دون إنشاء نسخة.
- [ ] اربط held/stock الحاليين بالسجل: مفاتيح التوافق `tea → tea_portion`, `kebda → kebda_portion`. أبقِ `CookingService.held_item()/stock_count()/inventory_snapshot()` كقراءات توافق دون `_stock` و`_held` مستقلين. دلالات Ready والنتائج والبقشيش الحالية تبقى.
- [ ] حوّل المروحة إلى نسخة ذات `attributes.enabled`؛ HomeService يقرأ الملكية ووجودها الموضوعة. `fan_on` للنوم يشترط وجود مروحة موضوعة ومفعلة في البيت؛ منع إعادة شرائها يشمل النسخة المخزنة. شراء جديد يمنح نسخة في مخزن الأثاث بدل إنشائها كرسم مجاني.
- [ ] افحص عبر اللعب العادي تحضير/حمل/تقديم/استهلاك، طلبًا مرفوضًا لإيد مشغولة، ومحاولة شراء غير كافية المال. راقب read-only QaProbe عند الحاجة؛ لا تضف جسور أوامر للعبة. سجل الفروق، ثم commit `feat: centralize item ownership and legacy inventory access`.

### A2 — قواعد الوضع والهيكل ومشهد يتبعها

**Files:** Create `game/spaces/placement_request.gd`, `game/spaces/grid_placement_rules.gd`, `game/spaces/space_service.gd`, `game/spaces/space_scene_adapter.gd`, `game/content/space_content_validation.gd`, `game/app/physical_world_controller.gd`, `content/spaces.json`, `content/initial_layout.json`. Modify `game/world/location_view.gd`, `game/world/kiosk_navigation.gd`, `game/world/interaction_router.gd`, `game/actors/visitor_controller.gd`, `game/app/main.gd`, `game/app/game_session.gd`, `content/locations.json`, `content/manifest.json`.

**Interfaces:** `GridPlacementRules.validate(layout: Dictionary, request: PlacementRequest, catalog: Dictionary, actors: Array[Dictionary], structural_authoring: bool = false) -> ActionResult`؛ pure `@tool` للمعرفة الهندسية دون Session. `SpaceService.configure(definitions: Dictionary, layout: Dictionary, items: ItemStore, actors: Callable, busy_provider: Callable) -> ActionResult`; `can_place(request: PlacementRequest) -> ActionResult`, `place(request: PlacementRequest) -> ActionResult`, `store(instance_id: StringName) -> ActionResult`, `set_door_open(door_id: StringName, opened: bool) -> ActionResult`, `placement/snapshot/restore`. واجهات اللاعب لا تحتوي معامل structural_authoring. `PhysicalWorldController.configure(session: GameSession, parent: Node2D) -> ActionResult`, `step(delta: float) -> void`, `set_active_location(id: StringName) -> void`.

- [ ] عرّف أصول الشبكة والفوتبرنت/الاتجاه/السطح وخلايا الوقوف والحوائط على الحواف والأبواب ووصلات الغرف. عرّف غرفتين بباب متصل في بيانات تأليف قابلة للمعاينة، وتحقق من المراجع والحدود مع AStarGrid2D/Geometry2D.
- [ ] افصل فحص المسار الممكن عبر باب يمكن فتحه عن تصادم الباب المغلق الحالي. ارفض تداخل عنصر/شخص أو سد آخر مسار للخروج/التشغيل، ورفض نقل قطعة مشغولة. يتحقق `place` مجددًا من أحدث ActorPose قبل التثبيت.
- [ ] نفذ التثبيت عند حد فيزيائي واضح: لا يعلن SpaceService موضعًا جديدًا قبل جهوزية التصادم/المواقف. الرسم والتصادم والمرور من نفس layout. عند `changed` يبطل VisitorController المسار والهدف المشتق من موضع قطعة الخدمة، ثم يعيد الحساب من موضع الزائر الحالي.
- [ ] استبدل الأجهزة/الأثاث القابلة للترتيب في props/solids الثابتة بنسخ موضوعة؛ احتفظ بالخلفيات والديكور غير التفاعلي. أنشئ صف الست counters حسب الأصل والأبعاد في المواصفات، والثلاجة الأولية في الكشك فقط. كل محطة تقرأ موضع معدتها المثبتة.
- [ ] استخرج تركيب الغرف والمحركات من Main إلى PhysicalWorldController، مع بقاء الجلسة مالكة للحالة. شاهد يدويًا المسار حول أثاث متحرك، وبابًا مغلقًا ثم مفتوحًا، ورفض وضع يسد الخروج أو يتداخل مع شخص. ابنِ الحزمة وفق بوابة A، ثم commit `feat: add shared spatial placement and live navigation updates`.

### A3 — أداة هيكل للمطور في Godot

**Files:** Create `addons/living_spaces_editor/plugin.cfg`, `addons/living_spaces_editor/plugin.gd`, `addons/living_spaces_editor/layout_document.gd`, `addons/living_spaces_editor/layout_dock.gd`. Modify `project.godot`, `export_presets.cfg`, `game/content/space_content_validation.gd`.

**Interfaces:** `LayoutDocument.load_bundle(root: String) -> ActionResult`, `apply_structure(edit: Dictionary) -> ActionResult`, `export_bundle(destination: String) -> ActionResult`. الفعل البنائي محصور في تعريف حائط/باب/غرفة/منطقة بناء؛ يستخدم GridPlacementRules مع structural_authoring=true داخل أداة المحرر فقط.

- [ ] نفذ EditorPlugin بلوحة اختيار الموقع، شبكة ومعاينة وحائط/باب وتحديد خلايا غرفة ومعرفاتها، وUndoRedo عبر EditorUndoRedoManager. لا تنشئ GameSession أو صوتًا أو Ink من الأداة.
- [ ] اجعل export يتحقق من الحزمة كاملة ويكتب مؤقتًا قبل استبدال ملفات JSON؛ رفض غرفة متداخلة أو باب بلا اتصال يبقي البيانات الجيدة على القرص. Core `@tool` المشترك لا يستورد EditorPlugin.
- [ ] استبعد مجلد الإضافة من Web/release عبر export_presets؛ لا مكان لعلم صلاحية المطور في save أو UI اللاعب. افحص يدويًا تأليف غرفتين وباب، إعادة الفتح من القرص، ورفض تعديل غير صالح ثم تصدير صالح.
- [ ] ابنِ Web وتأكد أن المشهد يستخدم JSON الناتج دون الاعتماد على الإضافة داخل pack. commit `feat: author structural layouts with a Godot editor tool`.

### A4 — واجهة ترتيب اللاعب والأسطح الأساسية

**Files:** Create `game/spaces/build_controller.gd`, `game/ui/build_panel.gd`, `game/presentation/placement_preview.gd`. Modify `game/ui/hud.gd`, `game/app/main.gd`, `game/world/interaction_router.gd`, `game/spaces/space_service.gd`, `game/items/inventory_service.gd`, `content/ui.json`.

**Interfaces:** `BuildController.begin(location_id: StringName) -> ActionResult`, `select(instance_id: StringName) -> ActionResult`, `preview(cell: Vector2i, rotation: int, host_id: StringName = &"", slot_id: StringName = &"") -> ActionResult`, `confirm() -> ActionResult`, `cancel() -> void`. `InventoryService.put_down(surface_slot_id: StringName) -> ActionResult`, `pick_up(surface_slot_id: StringName) -> ActionResult`؛ Surface slots حاويات في ItemStore مرتبطة بالموضع.

- [ ] أضف دخول ترتيب من القائمة واختيار قطعة موضوعة أو مخزنة، وتدوير ومعاينة وسبب رفض وتأكيد/إلغاء. الشبكة لا توقف الزمن أو تمحو الموضع الأصلي قبل confirm.
- [ ] امنع اختيار/تغيير الهيكل في الخدمة نفسها، حتى لو وصل معرف حائط كعنصر مختار. نقل counter ينقل الأجهزة المثبتة الخاملة كوحدة بعد التحقق؛ الطعام فوقه يجب رفعه قبل نقله، وتخزينه يحتاج إفراغه.
- [ ] اربط E/F بوضع العنصر في فتحة خالية ورفعه بنفس ID والجودة. ارفض اليد المشغولة والفتحة المشغولة دون فقد. المعاينة قراءة فقط ولا تحفظ.
- [ ] افحص يدويًا تدوير ونقل نفس نوع الكرسي في البيت والكشك، نقل جهاز خامل، رفض جهاز شغال، دخول NPC المعاينة قبل confirm، ووضع ورفع طبق. افحص RTL عند 960×540 و1280×720 ثم commit `feat: arrange owned furniture and use counter surfaces`.

### A5 — ترحيل وحفظ حزمة البناء

**Files:** Create `game/persistence/living_spaces_migration.gd`, `game/persistence/living_spaces_save_validation.gd`, `docs/notes/2026-10-22-living-spaces-a.md`. Modify `game/persistence/save_codec.gd`, `game/persistence/save_migrations.gd`, `game/persistence/save_coordinator.gd`, `game/app/game_session.gd`, `game/app/qa_probe.gd`, `game/ui/diagnostics.gd`.

**Interfaces:** `LivingSpacesMigration.upgrade(envelope: Dictionary, config: SessionConfig, target_revision: int) -> ActionResult` → `details.data`; `LivingSpacesSaveValidation.validate(session: GameSession, envelope: Dictionary) -> ActionResult`. revision 1 يطلب items/spaces، مع بقاء بقية مكونات schema 3 ما عدا stock/held المشتقين الآن من العناصر.

- [ ] أبقِ مسار ترحيل 1/2 إلى 3 ثم طبق التحويل 3→4/1 في مرشح فقط. ضمّن schema 3 صراحة في fallback تحقق النص الأصلي بعد رفع CURRENT إلى 4؛ لا يستبدل `[1,2,CURRENT]` دعم الإصدار 3 عرضًا.
- [ ] حوّل Stock/held/المروحة والمحطتين إلى نسخ وحاويات ومواضع، وانقل next_item لمنع اصطدام IDs مع إيصالات قديمة. امنح الست counters والثلاجة الأولية مرة واحدة بـmigration marker، ولا تمنح معدات التوسع المدفوعة. حافظ على تعريف العمل النشط المجمد وخصوماته السابقة.
- [ ] تحقق من ارتباط كل placement بنسخة واحدة، ومنع ملكية مزدوجة/حاوية يتيمة. عالج تعارض شخص مع التخطيط بالقاعدة الحتمية في المواصفات، دون تغيير ذلك الشخص أثناء نقل عادي داخل اللعب.
- [ ] افتح حفظًا سابقًا به طعام باليد ومحطة نشطة وحوار معلق؛ أكمل العمل واختر الرد فعليًا ثم احفظ وأعد التحميل. استعد العناصر ثم المساحات قبل ربط الطبخ والخدمة والزوار، وأنشئ Ink تحت مالك الجلسة النهائي؛ لا تعِد reparent لجلسة Ink المستعادة. افحص حفظ طبق فوق سطح وإلغاء معاينة قبل حفظ آخر.
- [ ] شغّل بوابة A وراجع السجل اليدوي؛ commit `feat: persist shared layouts and migrate existing sessions`.

## بوابة الحزمة A

`bash tools/build.sh --out /tmp/kiosk-living-a` يجب أن ينجح، مع فتح اللعبة الفعلية واستخدام الترتيب والسطح والحفظ. سجل الأدلة والفشل صراحة في notes. لا يشترط وجود متاجر أو وصفة شاورما قبل الانتقال إلى B، لكن الشاي والكبدة والحوار والنوم يجب أن تظل قابلة للاستخدام.
