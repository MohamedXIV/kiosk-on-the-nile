# Living Spaces C — Equipment, Recipes and Ink Learning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for Native execution or superpowers:subagent-driven-development if selected. Track `- [ ]` steps. Requires completed bundles A and B.

**Goal:** أجهزة مشتركة الوظائف ووصفات فعلية، مع تجربة شاورما وتعلم عبر Ink يقرأ المحاولة الحقيقية.

**Architecture:** EquipmentService يحجز موارد جهاز موضوع، وRecipeWorkflow يملك خطة الخطوات والأدلة، وInventoryService يحجز المكونات. الطبخ القديم النشط يكتمل عبر مهايئ معزول، ثم تتحول البداية الجديدة للتعريفات الحديثة.

**Tech Stack:** أدوات Godot/GDScript/JSON/Ink الحالية؛ [العقود الجامعة](2026-10-22-living-spaces-roadmap.md).

**Spec:** [المواصفات](../specs/2026-10-22-living-spaces-shopping-and-cooking-design.md)، الأقسام 7 و9 و12–14 وقيم التشغيل الأولية.

## Global Constraints

القيود الجامعة ملزمة. معرف الطعام مستقل عن الجهاز؛ نفس المكوّن يصلح لطرق مختلفة. لا تعلم يمنح جودة آلية أو جهازًا مجانيًا. الحفظ 4/revision 3، مع تجميد الوصفة النشطة ومجال توقيتها. لا اختبارات آلية دون طلب.

## Review Focus

- C1: فرن له وظيفتان لا يستعمل نفس المورد لعملين يفوقان سعته.
- C2: استعادة عمل قديم لا تخصم مدخلاته ثانية أو تغير ساعته المجمدة.
- C3: تقطيع حصة لا يعيد دفعة السيخ أو عدد حصصها.
- C3: لا يحول فرن بطاطس إلى بديل ضمني لسيخ شاورما.
- C4: معرفة الحوار والمحاولة والحكم على نتيجتها لا تنتج من مجرد فتح قائمة أو تكرار حديث.

### C1 — قدرات الأجهزة وحجوزات التشغيل

**Files:** Modify `game/cooking/equipment_service.gd`, `game/content/content_validation.gd`, `game/cooking/station_definition.gd`, `game/spaces/space_service.gd`, `game/app/game_session.gd`, `content/equipment.json`, `content/items.json`. Create `game/content/cooking_workflow_validation.gd`.

**Interfaces:** Extend `EquipmentService.candidates(location_id: StringName, capability: StringName) -> PackedStringArray`, `reserve(job_id: StringName, instance_id: StringName, requirements: Dictionary) -> ActionResult`, `release(job_id: StringName) -> ActionResult`, `is_busy(instance_id: StringName) -> bool`, `snapshot()/restore(data: Dictionary) -> ActionResult`. المورد `resource_group` وسعة صحيحة، لا نسخة timer داخل الجهاز.

- [ ] عرّف heat_water/griddle/fry/bake/roast_rotisserie/cold_storage/prep_surface، وأسندها لنسخ موضوعة عبر تعريفاتها. المورد المشترك مثل `heat_zone` يمنع التشغيل المتزامن لوظيفتين تتشاركان نفس السعة.
- [ ] تحقق من نفس الموقع والتمكين والوضع وقابلية الوصول والتوافق والسعة عند الحجز. جهاز مخزن أو جهاز من البيت لا يفي بمتطلب الكشك. حرّر الموارد عند نهاية العمل/الإلغاء دون تكرار.
- [ ] وسّع busy_provider في SpaceService ليقرأ الحجوزات؛ لا يسمح بنقل جهاز أو counter حامل أثناء تشغيل. رفض الحجز يترك الجهاز والمكونات دون أثر.
- [ ] افحص من قائمة الوصفات جهازًا غير موضوع، جهازًا موضوعًا، ثم جهازًا مشغولًا. استخدم تعريف وصفة متوافقة إضافية في نسخة بيانات معزولة لمراجعة أن القلاية لا تقيد recipe_id واحدًا. commit `feat: allocate shared equipment capabilities for recipe jobs`.

### C2 — خطوات الوصفات وحقيقة الأعمال والتوافق القديم

**Files:** Create `game/cooking/recipe_workflow.gd`, `game/cooking/recipe_step_handlers.gd`, `game/cooking/legacy_cooking_adapter.gd`, `content/recipe_workflows.json`. Modify `game/cooking/cooking_service.gd`, `game/cooking/cooking_job.gd`, `game/cooking/recipe_definition.gd`, `game/cooking/tea_rules.gd`, `game/cooking/kebda_rules.gd`, `game/items/inventory_service.gd`, `game/app/game_session.gd`, `game/persistence/living_spaces_migration.gd`, `game/persistence/living_spaces_save_validation.gd`, `content/recipes.json`, `content/time.json`, `content/manifest.json`.

**Interfaces:** `RecipeWorkflow.configure(recipes: Dictionary, inventory: InventoryService, equipment: EquipmentService, clock: GameClock, knowledge: KnowledgeBook) -> ActionResult`, `available_recipes(location_id: StringName, instance_id: StringName) -> Array[Dictionary]`, `start(recipe_id: StringName, location_id: StringName, instance_ids: PackedStringArray) -> ActionResult`, `act(job_id: StringName, action_id: StringName) -> ActionResult`, `tick(frame: Dictionary) -> void`, `job(id: StringName) -> Dictionary`, `snapshot()/restore(data: Dictionary) -> ActionResult`. إشارتا `attempt_started(job_id: StringName, recipe_id: StringName, evidence: Dictionary)` و`item_completed(job_id: StringName, item_id: StringName, quality: int)` تصدران بعد تثبيت العمل/النتيجة فقط. `RecipeStepHandlers.apply(step: Dictionary, job: Dictionary, action_id: StringName, evidence: Dictionary) -> ActionResult` يعمل على مرشح قبل commit. `LegacyCookingAdapter.restore_job(record: Dictionary) -> ActionResult`, `act(station_id: StringName) -> ActionResult`, `tick(delta_seconds: float) -> void`.

- [ ] نفذ مفردات الخطوات المحدودة في المواصفات، والتحقق من DAG ومدخلات/مخرجات وقدرات ومهل. كل عمل يحفظ recipe_version وتعريفه الضروري وtime_domain ومدخلاته وأدلة خطواته وموارده؛ لا يعيد حفظه تعريف الوصفة من الكتالوج الحالي.
- [ ] ابدأ بعد تحقق KnowledgeBook من fact البداية المحدد في بيانات الوصفة، ثم الموارد والمكونات المطلوبة للخطوة. جهز مرشحات الحجز/الأجهزة/العمل كلها قبل التثبيت، دون سحب مبكر عند معاينة الواجهة. خطوات جديدة تعتمد world_minutes؛ تترجم cooking.tick من frame المشترك مرة واحدة.
- [ ] احتفظ بقواعد tea/kebda الحالية للعمل النشط القديم فقط داخل LegacyCookingAdapter؛ frozen timers بالثواني لا تصبح دقائق. بعد إفراغ العمل يبدأ تعريف الشاي/الكبدة الحديث بنفس دلالات التسلسل والجودة والسكر، ومن نفس ItemStore. واجهة CookingService القديمة تفوض ولا تملك stock/held أو مؤقتًا مكررًا.
- [ ] أضف إلغاءً صريحًا يحرر غير المستهلك فقط؛ ما تحول فعليًا إلى دفعة لا يعود خامات مجانية. توقف اليد المشغولة إخراج الطعام ولا تستبدل ما فيها؛ يستمر مصدر الحرارة وفق حالته.
- [ ] ارفع revision إلى 3، وترجم حجوزات العمل القديم ومخزونه دون خصم ثانٍ. افحص يدويًا BOILED/READY قديمًا، ونقص مكوّن، وتوقيتًا مبكرًا، ويدًا مشغولة، ثم إعادة تحميل أثناء مرحلة نشطة. commit `feat: execute data-driven recipe steps with legacy job compatibility`.

### C3 — الشاورما وطرق البطاطس والواجهة الفعلية

**Files:** Create `game/ui/recipe_panel.gd`, `game/presentation/equipment_view.gd`. Modify `content/items.json`, `content/equipment.json`, `content/recipe_workflows.json`, `content/atmosphere.json`, `content/ui.json`, `game/cooking/recipe_step_handlers.gd`, `game/cooking/station_controller.gd`, `game/ui/hud.gd`, `game/world/interaction_router.gd`, `game/spaces/space_scene_adapter.gd`, `game/presentation/station_vapour.gd`, `game/presentation/soundscape.gd`, `game/items/inventory_service.gd`, `game/app/qa_probe.gd`.

**Interfaces:** سِجل batch داخل ItemStore له `source_job_id, portions_total, portions_remaining, quality_evidence`؛ `RecipeWorkflow.act(job_id, &"slice")` يستهلك حصة من الدفعة ويُنشئ حشوًا واحدًا بهوية جديدة، ثم `start(&"shawarma_assemble", ...)` يحجز الحشو والعيش والثومية. `RecipePanel.present(instance_id: StringName, recipes: Array[Dictionary]) -> void` يعرض المتطلبات وaction IDs الفعلية.

- [ ] اكتب تعريفات دفعة 3 فراخ + تتبيلة + زيت → ثلاث حصص، وتجميع الحشو+عيش+ثومية. مدد التجهيز/التتبيل/الجاهزية/نافذة التقطيع/الاحتراق 3/15/20/45/60 دقيقة عالمية، والتقطيع 1 والتجميع 2. حفظ وعاء التتبيل داخل ثلاجة ضروري لتقدم خطوة التبريد.
- [ ] اكتب وصفتي البطاطس fry وbake على نفس المكوّن، بنوافذ 8/16/24 و12/24/36. الطبق له هوية طريقة تحضير مستقلة. ترتيب الأفعال هو فعل اللاعب في كل مرحلة؛ انتظار الوقت لا ينقل وعاءً أو سندوتشًا تلقائيًا.
- [ ] احسب الجودة من أدلة الخطوات، مع أدنى خطوة أساسية للشاورما وأثر المزاج المحدود الحالي. خصص seam `hygiene_evidence` في سجل الخطوة؛ لا تطبق عقوبة نظافة قبل وجود D1. لا تنسخ نتائج الدفعة عند رفعها ووضعها على سطح.
- [ ] اربط كل جهاز موضوع برسم وحالة عمل وإشارة جاهزية/احتراق وصوت مناسب، والاختيار القصير للوصفات على الجهاز. اعرض كل متطلب ناقص باسمه ومكانه؛ لا تسرد أزرارًا لكل وصفة في الـHUD العلوي.
- [ ] افحص فعليًا شراء/وضع/تشغيل المعدة، تجهيز دفعة وتبريدها وطبخها وتقطيع حصتين مع حفظ بينهما، ورفض حصة رابعة. قارن نتيجة بطاطس مقلية ومخبوزة وطبخة متأخرة. commit `feat: prepare shawarma batches and alternate potato recipes`.

### C4 — التعلم عبر Ink وطلب الطعام الجديد وخدمته

**Files:** Create `game/cooking/recipe_learning.gd`, `content/learning.json`, `content/foods.json`, `content/stories/shawarma_learning.ink`, `content/stories/shawarma_learning.ink.json`, `docs/notes/2026-10-22-living-spaces-c.md`. Modify `game/narrative/knowledge_book.gd`, `game/narrative/narrative_director.gd`, `game/narrative/narrative_effects.gd`, `game/narrative/condition_evaluator.gd`, `game/app/game_session.gd`, `game/service/service_system.gd`, `game/service/order_state.gd`, `game/actors/visitor_service.gd`, `game/actors/visitor_history.gd`, `game/life/life_actions.gd`, `game/persistence/living_spaces_migration.gd`, `game/persistence/living_spaces_save_validation.gd`, `content/social.json`, `content/encounters.json`, `content/stories/context.inkinc`, `content/visitors.json`, `content/balance.json`, `content/manifest.json`.

**Interfaces:** `RecipeLearning.record_attempt(job_id: StringName, recipe_id: StringName, evidence: Dictionary) -> ActionResult`, `record_result(job_id: StringName, item_id: StringName, quality: int) -> ActionResult`, `context(recipe_id: StringName) -> Dictionary`, `snapshot()/restore(data: Dictionary) -> ActionResult`. تقبل الأدلة من الأعمال/العناصر الموجودة، وتمنع تكرار source ID. `foods` يحدد price_minor/nourishment/tip_table/labels لكل food_id.

- [ ] أرشف نسخ Ink الحالية قبل تعديل context تحت index حسب story_id/hash، مع إبقاء أرشيف النسخة الأقدم الموجود. وسّع اختيار القصة المستعادة ليقبل النسخ المعلومة فقط، دون تحويل cursor إلى نص جديد.
- [ ] اكتب لقاء عم فريد المقترح: فكرة أولية ثم سؤال بعد محاولة فعلية، وفروع ناجحة/ناقصة بحسب الأدلة. معرفة ناقصة تسمح بالمحاولة التي تعلم أساسها، ولا يشترط إتقان كامل. وصّل إشارات RecipeWorkflow إلى record_attempt/record_result في GameSession، ولا تسجل المحاولة من ضغط الواجهة. مصادر التعلم مرة واحدة؛ Ink لا يرفع الجودة أو يمنح سيخًا أو مكونًا.
- [ ] أزل افتراض حصر food_id في tea/kebda من الطلبات والتحقق والحفظ وردود الخدمة وقراءة ذاكرة الزائر. يقرأ LifeActions.consume_held تغذية الطعام من foods ويمررها لـNeedsService بدل ربطها باسم tea/kebda. السعر من foods، مع حفظ القديمة وتحديد 1800 قرش للشاورما و600 لكل بطاطس والبقشيش المعتمد. يختار الزائر من قائمة الطعام المعروضة التي يمكن تجهيزها في المكان، ويحفظ الاختيار قبل الطلب؛ لا يبدل الطلب عند تغير المخزون.
- [ ] افحص سماع النصيحة ثم بدء محاولة فعلية، وإكمالها ثم تعليق مبني على جودتها، والحفظ وسط اختيار والرد بعد Continue. راجع تقديم طبق جديد والدفع مرة واحدة والاستهلاك الشخصي، وعدم معرفة وصفة من حوار بعيد. لا تخفِ الفشل خلف نجاح export.
- [ ] ابنِ وسجل الأدلة، ثم commit `feat: connect learned recipes to real attempts and customer service`.

## بوابة الحزمة C

`bash tools/compile-ink.sh` ثم `bash tools/build.sh --out /tmp/kiosk-living-c`. أكمل في اللعبة طريقًا من المعرفة إلى المعدات والمكونات إلى طبخة وخدمة، واحفظ مرحلة وسطها واستكملها. مراجعة النظافة والسمعة تبدأ في D؛ لا تستدل على صحتها من seam فارغ.
