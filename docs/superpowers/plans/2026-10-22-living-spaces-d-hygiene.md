# Living Spaces D — Hygiene, Experiences and Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for Native execution or superpowers:subagent-driven-development if selected. Track `- [ ]` steps. Requires completed bundles A–C.

**Goal:** نظافة لها أثر قابل للتفسير على الطبخ والبيت وتجارب الزباين، مع حفظ متكامل وناتج Web قابل للعب.

**Architecture:** HygieneService يملك حالة النظافة وأعمال التنظيف، وCustomerExperience يملك أدلة وملخص الزيارة والسمعة المشتقة منها. Ink يعرض الأدلة ولا يحسب السمعة؛ خدمات العناصر والمساحات والطبخ تبقى مصادرها الحالية.

**Tech Stack:** Godot/GDScript/JSON/Ink وأدوات البناء الحالية؛ [العقود والقيود الجامعة](2026-10-22-living-spaces-roadmap.md).

**Spec:** [المواصفات](../specs/2026-10-22-living-spaces-shopping-and-cooking-design.md)، الأقسام 10–16، مع حفظ قواعد النوم السابقة.

## Global Constraints

القيود الجامعة ملزمة. نظافة 0..100 وحدود وصفية 60/30؛ التنظيف يستغرق وقتًا عالميًا. اتساخ المكان لا يخصم جودة طعام لم يلمسه. لا سمعة من زيارة مخترعة ولا عقوبة علاقة لمجرد التجاهل. الحفظ النهائي schema 4/revision 4؛ لا اختبارات آلية دون طلب.

## Review Focus

- D1: تنظيف بعد الطبخ أو تخزين جهاز لا يمحو دليل اتساخه وقت ملامسة الطعام.
- D1/D3: السفر أو الابتعاد يوقف التنظيف مع حفظ التقدم الحقيقي، دون تحرير جهاز يستعمله عمل آخر.
- D2: مغادرة زبون بلا طعام لا تنتج جودة طعام وهمية أو انتظارًا محسوبًا من أول دخوله.
- D2/D3: إعادة التحميل أو إعادة عرض تعليق لا تسجل ملخص زيارة أو أثر سمعة مرتين.
- D3/D4: ملف يدعي revision مكتملًا مع مرجع ناقص يُرفض مع حماية الملف السابق، ولا يعاد تشغيل Ink تحت parent مؤقت.

### D1 — حالة النظافة والتنظيف وأدلة الطبخ

**Files:** Create `game/hygiene/hygiene_service.gd`, `game/hygiene/cleaning_action.gd`, `game/content/hygiene_content_validation.gd`, `content/hygiene.json`. Modify `game/items/item_store.gd`, `game/spaces/space_service.gd`, `game/cooking/recipe_workflow.gd`, `game/cooking/recipe_step_handlers.gd`, `game/world/interaction_router.gd`, `game/life/life_actions.gd`, `game/life/daily_routine.gd`, `game/ui/sleep_panel.gd`, `game/ui/hud.gd`, `game/presentation/equipment_view.gd`, `game/spaces/space_scene_adapter.gd`, `game/app/game_session.gd`, `game/content/content_validation.gd`, `content/ui.json`, `content/time.json`, `content/manifest.json`.

**Interfaces:** `HygieneService.configure(definitions: Dictionary, items: ItemStore, spaces: SpaceService, clock: GameClock, player_pose: Callable, equipment_busy: Callable) -> ActionResult`; `state(target_id: StringName) -> Dictionary`, `record_use(source_id: StringName, target_id: StringName, use_id: StringName) -> ActionResult`, `begin_clean(target_id: StringName) -> ActionResult`, `interrupt_clean() -> void`, `is_cleaning(target_id: StringName) -> bool`, `tick(frame: Dictionary) -> void`, `elapse(world_minutes: float) -> void`, `food_contact_evidence(target_ids: PackedStringArray) -> Dictionary`, `sleep_rest_multiplier(bed_id: StringName) -> float`, `snapshot()/restore(data: Dictionary) -> ActionResult`. `CleaningAction extends RefCounted` يحمل `target_id, location_id, required_minutes, completed_minutes, active`؛ لا timer مستقل.

- [ ] عرّف حالة القطع القابلة للاتساخ بمعرف النسخة، والأرضيات بمعرف المنطقة. اجعل النظافة مملوكة لـHygieneService وحده؛ لا تحفظ نسخة cleanliness ثانية في attributes. انقل/خزن القطعة دون تغيير حالتها، وغبار التخزين صفر. مدد المسح للسطح/الجهاز/الأرض 3/8/5 دقائق، مع وصول فعلي وتعطيل تنظيف جهاز مشغول.
- [ ] اربط الاستعمال الفعلي بمعرف حدث ثابت يمنع تكراره: تجهيز/تجميع 3/2، قلاية/فرن/سيخ 6/3/4 لكل دفعة، أرضية 0.005 لكل دقيقة وزيارة مكتملة 1، وأثاث البيت 0.001 لكل دقيقة والسرير 2 لكل نومة. لا تستدع record_use من رسم الواجهة أو مجرد فتح قائمة.
- [ ] تقدم التنظيف على دقائق frame الحقيقية؛ الابتعاد أو تبديل النشاط أو السفر يوقفه ويحتفظ بتقدم الهدف حتى استئنافه. أربط busy_provider بانشغال المعدات أو التنظيف، مع فحص أحدث حالة عند التأكيد. إن اتسخ الهدف أثناء توقف التنظيف يزيد مقدار العمل المتبقي بنسبة الاتساخ الجديد إلى معدل التنظيف، ولا يفقد التقدم المنجز؛ بعد وصوله إلى 100 يعاد ضبط التقدم.
- [ ] التقط food_contact_evidence عند الخطوة التي تلامس السطح/الجهاز قبل تطبيق اتساخ الاستعمال الناتج عنها؛ يجمد الدليل مع العمل. طبّق عقوبة النظافة بحد درجة واحدة، واجمعها مع المزاج ضمن أرضية الجودة الحالية 1 لغير المحروق و0 للمحروق. الأرض والكرسي خارج هذا الحساب. عرّف مسار جمع الأدلة نفسه للوصفة القديمة النشطة دون تبديل مؤقتاتها.
- [ ] أظهر وصفًا ولونًا تدريجيًا وحالة تقدم عند الهدف، دون شريط أرقام دائم. اربط نظافة السرير أقل من 30 بمعامل راحة 0.9 في المعاينة والتنفيذ، دون تغيير مدة النوم أو سياسة تأخر الاستيقاظ. افحص يدويًا تنظيفًا متقطعًا، تخزين قطعة متسخة، رفض جهاز شغال، وطبخة قبل تنظيفه وبعده مع بقاء دليل الطبخة الأولى. commit `feat: model hygiene and timed cleaning with cooking evidence`.

### D2 — أدلة تجربة الزبون والسمعة وتعليقات Ink

**Files:** Create `game/social/customer_experience.gd`, `game/content/customer_experience_validation.gd`, `content/customer_experience.json`, `content/stories/venue_comments.ink`, `content/stories/venue_comments.ink.json`. Modify `game/content/content_validation.gd`, `game/actors/visit_state.gd`, `game/actors/visitor_service.gd`, `game/actors/visitor_controller.gd`, `game/actors/visitor_history.gd`, `game/service/order_state.gd`, `game/service/service_system.gd`, `game/narrative/narrative_director.gd`, `game/narrative/condition_evaluator.gd`, `game/narrative/conversation_history.gd`, `game/app/game_session.gd`, `game/ui/notebook.gd`, `content/visitors.json`, `content/social.json`, `content/encounters.json`, `content/stories/context.inkinc`, `content/ui.json`, `content/time.json`, `content/manifest.json`.

**Interfaces:** `CustomerExperience.configure(data: Dictionary, hygiene: HygieneService, spaces: SpaceService, clock: GameClock) -> ActionResult`, `observe(visit_id: StringName, actor_pose: ActorPose) -> ActionResult`, `record_order(visit_id: StringName, order_id: StringName, created_at: float, patience: float) -> ActionResult`, `record_service(visit_id: StringName, receipt: Dictionary) -> ActionResult`, `close_visit(visit_id: StringName, reason: StringName, ended_at: float) -> ActionResult`, `context(visit_id: StringName) -> Dictionary`, `reputation(location_id: StringName) -> Dictionary`, `snapshot()/restore(data: Dictionary) -> ActionResult`. إيصال الخدمة يقرأ حقيقة OrderState بعد الدفع: `order_id, item_id, food_id, quality, served_at`؛ لا تقبله الخدمة من UI أو Ink.

- [ ] سجّل مشاهدات محدودة من موضع الزائر ونطاقه ومسار الرؤية المحددين في البيانات: أرضية/جلوس/أسطح خدمة ظاهرة في موقعه فقط. لا رصد لمنزل خاص أو محتوى ثلاجة مغلقة. احتفظ بآخر مشاهدة مؤرخة لكل هدف داخل الزيارة، واحسب متوسط الفئة المرئية فقط. غياب اللاعب لا يوقف رصد الزائر الموجود فعلًا.
- [ ] احفظ created_at عند نشأة الطلب وserved_at عند إتمام تسليم حقيقي؛ إلغاء الطلب ينهي انتظاره وقت الإلغاء، لا في نهاية القعدة. درجة الانتظار `clamp(100 * (1 - waited / patience), 0, 100)`، مع رفض patience غير موجبة في المحتوى. سجل الطعام المستلم فقط ودرجاته 0/40/75/100؛ زائر بلا طلب لا يملك بند انتظار، وبلا تقديم لا يملك بند طعام.
- [ ] التقط الحالة النهائية من حدث مغادرة قبل حذف VisitState، واصدر ملخصًا واحدًا لكل visit_id. احسب البيئة بأوزان أرض/جلوس/سطح 0.3/0.2/0.5، والسمعة من آخر 20 ملخصًا بأوزان بيئة/طعام/انتظار 0.35/0.45/0.20 مع إعادة توزيع البنود الغائبة. السمعة مشتقة من الملخصات دون رصيد مستقل؛ حالة بلا ملخص تبقى غير مقيمة. اربط اكتمال الملخص باتساخ الأرضية مرة واحدة.
- [ ] اربط ميل العودة/الطلب بالسمعة وحساسية الشخصية في البيانات، مع إبقاء cooldown والتنوع وحد تعافٍ لا يصل للصفر. أضف موضوعات Ink ذات source_visit_id وذاكرة تمنع التكرار، بما فيها تحسن رآه نفس الشخص في زيارة لاحقة. أرشف نسخ النصوص الحالية قبل تغيير context كما في C4. لا يمنح التعليق تحديث سمعة ثانٍ أو عقوبة ثقة للتجاهل.
- [ ] راجع يدويًا زائرًا لم يطلب، وآخر انتظر وغادر، وآخر استلم طعامًا وجلس طويلًا؛ افحص دفتر المكان مقابل هذه الوقائع. احفظ بعد المغادرة وقبل/بعد تعليق ثم استكمل الرد؛ يجب ألا يزيد عدد الملخصات أو يتكرر مصدر الحوار. commit `feat: derive venue reputation and Ink comments from real visits`.

### D3 — الحفظ النهائي وقفزات النوم وترابط الحالات

**Files:** Modify `game/persistence/living_spaces_migration.gd`, `game/persistence/living_spaces_save_validation.gd`, `game/persistence/save_codec.gd`, `game/persistence/save_coordinator.gd`, `game/app/game_session.gd`, `game/app/main.gd`, `game/life/life_actions.gd`, `game/life/daily_routine.gd`, `game/commerce/shop_service.gd`, `game/hygiene/hygiene_service.gd`, `game/cooking/recipe_learning.gd`, `game/app/qa_probe.gd`, `game/ui/diagnostics.gd`.

**Interfaces:** revision 4 يضيف `hygiene/customer_experience`، ويحفظ learning ضمن revision 3. لكل مكون `snapshot() -> Dictionary` و`restore(data: Dictionary) -> ActionResult`. `ShopService.elapse(world_minutes: float) -> void` يعالج مواعيد restock المتجاوزة مرة واحدة؛ HygieneService.elapse يطبق الغبار فقط والتنظيف غير النشط لا يتقدم. Clock نفسه يُزاد من مسار النوم الحالي مرة واحدة.

- [ ] رقّ schemas 1–3 والمسودات 4/revisions 1–3 بأقصر سلسلة محددة، مع نظافة أولية كاملة وعدم اختراع تجارب أو سمعة ماضية. بقاء علامة أثاث البداية يمنع منحه ثانية. غياب مكون لازم في revision يدعيه فساد، مع إبقاء original/previous المحميين وعدم الكتابة عليهما من التحميل.
- [ ] تحقق من كل مرجع ملكية/موضع/حجز/جهاز/عمل/دفعة/إيصال/رحلة/تنظيف/مصدر تعلم، ومن تطابق موقع اللاعب ومراحل الرحلة. ميّز السجل التاريخي المكتمل من المرجع الحي: إيصال لوجبة مستهلكة لا يحتاج عنصرًا ما زال حيًا؛ يحتفظ بسجل التسليم الثابت. لا تتطلب بقاء VisitState بعد إصدار ملخصها.
- [ ] استعد المكونات تحت parent الجلسة النهائي بالترتيب: الساعة والعناصر، المساحات والأجهزة، الطبخ والخدمة والزوار والرحلة والتجارة، النظافة والتجارب والتعلم، ثم السرد والمؤقتات. تحقق من المرشح كاملًا قبل تنصيبه؛ لا تعِد reparent لجلسة Ink نشطة ولا تسقط بصمة قصة مجهولة.
- [ ] مرّر قفزة النوم المعتمدة إلى الغبار وتجديد المتاجر، واحتفظ بسياسة النوم الحالية تجاه الزوار والأعمال والإيجار دون اختراع تقدم offline. أوقف التنظيف عند بدء النوم، واحسب معامل السرير من حالته قبل تسجيل اتساخ النومة. الأيام المتجاوزة لا تراكم مخزون متجر فوق السقف أو تعيد سعر شراء.
- [ ] افحص يدويًا حفظًا قديمًا به Ink معلق وعمل نشط، وحفظًا حديثًا به حقيبة ودفعة مقطعة وتنظيف متوقف وملخص زيارة. أعد التحميل واختر ردًا وأكمل حصة فعلًا. راجع في نسخة ملف تجريبية رفض مرجع حي يتيم مع بقاء الحفظ السابق قابلًا للمتابعة. commit `feat: finalize living-space saves and sleep integration`.

### D4 — مراجعة الدورة الكاملة والتصدير القابل للمشاركة

**Files:** Create `docs/notes/2026-10-22-living-spaces-d.md`. Modify `docs/PORT_PARITY.md`, `README.md`, `export_presets.cfg`, `tools/export-web.sh` فقط إن احتاجت استثناءات ملفات المحرر/تضمين المحتوى، وملفات ui/atmosphere التي تكشف المراجعة احتياجها.

**Interfaces:** لا أنظمة لعب جديدة هنا؛ يعتمد المرشح على واجهات A–D3. أمر البناء `bash tools/build.sh --out /tmp/kiosk-living-d`، ثم `bash tools/build.sh --out /tmp/kiosk-living-release --release`؛ النجاح يعني import/export بلا script errors، ولا يثبت وحده صحة اللعب.

- [ ] العب دورة فعلية من حفظ قديم وأخرى من جلسة جديدة: سماع فكرة الوصفة، شراء المعدات والخامات أثناء استمرار طبخة/زبون، العودة والتفريغ والترتيب، تجهيز الشاورما وخدمتها، التنظيف وتعليق مستند إلى تجربة، ثم البيت وترتيبه والنوم بالمدة المختارة. لا تجعل البداية تستلزم شراء كل الأجهزة دفعة واحدة.
- [ ] نفذ حالات Review Focus الجامعة الخمس فعليًا وسجل commit والنتائج وحدود الملاحظة في notes؛ راجع 960×540 و1280×720، RTL، تبديل وسيلة الإدخال، والإشارات المرئية دون صوت. تأخر E القديم يبقى معلومة غير محسومة إلى أن يُقاس. لا تشغل سيناريوهات اللعب الآلية بدل هذه المراجعة.
- [ ] ابنِ debug/release وافتح إصدار release عبر HTTP، وافحص قائمة تصديره للتأكد من غياب EditorPlugin وأدوات أوامر المطور. ملفات JSON/Ink الخارجية موجودة وتُحمَّل من المسار المعتمد، والمحتوى المرفوض لا يستبدل الحزمة السليمة جزئيًا. تحقق أن طلب تغيير بنائي يرفضه runtime وليس فقط زر UI.
- [ ] حدث PORT_PARITY بالمنفذ فعلًا وما بقي وحدود الأدلة، وREADME بطريقة التشغيل عبر HTTP وتفاصيل الحفظ. جهز ZIP وتحقق من احتوائه على HTML/JS/WASM/PCK/content. إن نُشر preview وفق تفويض GitHub السابق، اربطه بـcommit المصدر والملف نفسه؛ لا merge إلى main أو وصفه إصدارًا نهائيًا تلقائيًا.
- [ ] أصلح أي عائق قبول مكتشف داخل مالكه وسجل نتيجته قبل التسليم؛ لا تعتبر خطوة يدوية لم تنفذ ناجحة. commit `docs: record living-space acceptance and web delivery`، وقدم رابط/مسار build الحقيقي مع ملخص ما جُرّب وما بقي.

## بوابة الحزمة D

اكتمال البناء وحده غير كافٍ. القبول يحتاج دورة اللعب والحفظ والاستكمال الفعلية المذكورة، مع أدلة محددة وتصدير قابل للفتح؛ تظل أي مراجعة لم تتوفر وسيلتها معلقة ومذكورة صراحة.
