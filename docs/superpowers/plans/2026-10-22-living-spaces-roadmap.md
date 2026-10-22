# Living Spaces Implementation Plan — خطة التنفيذ الجامعة

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for Native execution or superpowers:subagent-driven-development if the user chooses that method. Steps use checkbox (`- [ ]`) syntax. This plan is awaiting user review and execution-method confirmation; product implementation has not started.

**Goal:** إتاحة تجهيز البيت والكشك، والتسوق أثناء استمرار العالم، والطبخ بمعدات ومكونات فعلية، والنظافة والسمعة المرتبطتين بتجارب الزباين.

**Architecture:** نمد الخدمات الحالية بملكية واحدة للعناصر والمساحات والأعمال. تشترك أدوات Godot Editor وواجهة ترتيب اللاعب في قواعد الوضع، وتستهلك واجهات المتجر وInk نفس خدمات العالم؛ لا تملك واجهة رصيدًا أو ساعة أو نتيجة طبخ مستقلة.

**Tech Stack:** Godot Standard 4.7.2، GDScript، Compatibility، Godot EditorPlugin، AStarGrid2D وGeometry2D وCharacterBody2D، JSON خارجي، inklecate 1.2.1 وinkgd المثبتان في المشروع.

**Spec:** [المواصفات المعتمدة](../specs/2026-10-22-living-spaces-shopping-and-cooking-design.md). الموافقة على الوثيقة وردت في المحادثة بتاريخ 2026-10-22. قاعدة الكود `c752382`؛ commit المواصفات الأصلي `aea3ad8`.

## Global Constraints

- اقرأ المواصفات والخطة الجامعة وخطة الحزمة قبل العمل؛ الأرقام التفصيلية في قسم «قيم البداية التجريبية» بالمواصفات مصدر التهيئة.
- يبقى منظور 3/4 وSpatialMapping الحالي. لا نسخ للكود أو بنية التطبيق من الريبو المرجعي، ولا WorldKernel أو ECS أو event bus جديد.
- نظام grid واحد بحجم خلية 0.25، وأصول معرفة لكل موقع. الهيكل للمطور فقط، والترتيب للأجهزة والأثاث المسموح للاعب.
- الوقت مستمر أثناء التصفح والبناء والتنظيف، والموقع الافتراضي لا يعد حضورًا داخل الكشك. حالة فتحه مستقلة عن السفر.
- كل ملكية/كمية/موضع/حجز/مؤقت لها مصدر واحد. الأسعار قرش صحيح؛ الوصفات الجديدة تستخدم دقائق عالمية، والأعمال القديمة النشطة تحتفظ بمجال توقيتها المجمد.
- كل القيم والتعريفات والنصوص في JSON وInk؛ النص لا يمنح أجهزة أو كميات أو جودة أو سمعة مباشرة.
- الحفظ العام التالي schema 4. تحفظ مراحل التطوير الخاصة `schema_revision` من 1 إلى 4، مع ترحيل محدد بينها؛ الإصدار العام النهائي 4/revision 4. لا يقبل غياب مكون مطلوب في revision يدعي وجوده.
- تبقى ترقيات schemas 1–3 والتحقق من بصمة النص الأصلي وحماية previous.json. لا يدفع التحميل أو الترحيل مالًا ولا يعيد خصم مكونات.
- العربية وRTL والعمل دون خدمات خارجية مطلوبان. استعمل أدوات Godot الأصلية وأبقِ مراجع إضافات Ink داخل المهايئ الحالي.
- التنفيذ في checkout السحابي الحالي؛ لا worktree جديد إلا بطلب المستخدم. لا merge إلى main أو نشر إصدار نهائي بوصفه كاملًا دون نطاق نشر واضح.
- لا تُضاف أو تُشغّل اختبارات آلية دون طلب صريح من المستخدم وفق تعليمات الجلسة. خطوات التحقق هنا بناء وفحص بيانات ولعب يدوي موثق؛ لا تشغل `tools/run-tests.sh` أو سيناريوهات `tools/web/check.mjs` تلقائيًا.
- لا تستنتج نجاح تجربة من بناء ناجح، ولا تعلن عبور بوابة يدوية لم تُنفذ. خطوات الخطة تتضمن الحالات المتوقع فحصها، وليست أدلة نجاح حالية.

## Review Focus

1. ملكية طعام واحد بين اليد والسطح والحقيبة أو ضغط شراء مكرر: لا نسخ ولا دفع ثانٍ؛ A1/A4 وB3/B4.
2. تغيّر موضع NPC أو باب بين المعاينة والتثبيت: لا حبس أشخاص أو بيانات تخالف التصادم؛ A2/A4.
3. عنوان موقع افتراضي أو حفظ وسط العودة: لا يعيد المحرك الخفي حضور اللاعب للكشك، ولا تضيع المشتريات أو تستأنف المهلة من الصفر؛ B2/B4.
4. مكوّن محجوز أو جهاز مشترك أو دفعة مقطعة جزئيًا: لا سحب من البيت أو استهلاك/حصص مضاعفة؛ B1 وC1/C2/C3.
5. حفظ قديم فيه وصفة مجمدة وInk معلق، أو تعليق نظافة يتكرر: استكمال فعلي قابل للاختيار، وعدم إعادة تأثير/تجربة سمعة؛ A5 وC2/C4 وD2/D3.

## أربع خطط قابلة للتنفيذ بالترتيب

| الحزمة | الخطة | الناتج المستقل | الحفظ |
| --- | --- | --- | --- |
| A | [العناصر والمساحات والبناء](2026-10-22-living-spaces-a-build.md) | ترتيب البيت والكشك، أدوات هيكل للمطور، تصادم ومسارات وعناصر بلا ازدواج ملكية | 4/revision 1 |
| B | [التخزين والرحلات والتسوق](2026-10-22-living-spaces-b-shopping.md) | أسطح وثلاجات ومشتريات حقيقية أثناء استمرار العمل والزباين | 4/revision 2 |
| C | [المعدات والوصفات والتعلم](2026-10-22-living-spaces-c-cooking.md) | معدات مشتركة، شاورما وبطاطس بطرق مختلفة، تعلم مبني على محاولة فعلية | 4/revision 3 |
| D | [النظافة والسمعة والإصدار](2026-10-22-living-spaces-d-hygiene.md) | تنظيف وتجارب وسمعة وحوار، وترحيل ومراجعة وتصدير الدورة الكاملة | 4/revision 4 |

الحزم مرتبطة بعقود العناصر والموقع والحفظ وليست أربع ألعاب أو تجارب منفصلة. لا تبدأ حزمة قبل اكتمال واجهات السابقة وبناء ناتجها. يجوز مراجعة كل حزمة على حدة، وتبقى حالة قبول الدورة الكاملة مفتوحة حتى D4.

## خريطة الملفات والملكية المشتركة

- `game/items/`: `item_store.gd` مصدر النسخ والحاويات، و`item_change_set.gd` تغيير متحقق منه، و`inventory_service.gd` قواعد مخزون المكان والحجوزات. لا يملك CookingService نسخة ثانية من stock/held.
- `game/spaces/`: `space_service.gd` المواضع والهيكل، `grid_placement_rules.gd` تحقق مشترك قابل للعمل في المحرر، `placement_request.gd` طلب واضح، و`build_controller.gd` معاينة/أفعال اللاعب.
- `addons/living_spaces_editor/`: أداة تأليف محلية تستخدم GridPlacementRules وتصدّر نفس بيانات المكان. لا يستورد runtime ملفات EditorPlugin.
- `game/travel/`: `travel_service.gd` المراحل والمواعيد و`journey_state.gd` قيم الرحلة؛ لا حركة عالم بديلة.
- `game/commerce/`: `shop_service.gd` العروض والإيصالات و`shop_quote.gd` عرض سعر، مع واجهة `game/ui/shop_panel.gd`.
- `game/cooking/`: `equipment_service.gd` يبدأ في B1 لدعم الثلاجة والأجهزة المنزلية، ويتوسع في C1 لحجز الموارد؛ ثم تضاف `recipe_workflow.gd` و`recipe_step_handlers.gd` و`recipe_learning.gd` و`legacy_cooking_adapter.gd`؛ CookingService واجهة أعمال الطبخ القائمة والمطورة.
- `game/hygiene/`: `hygiene_service.gd` و`cleaning_action.gd`، و`game/social/customer_experience.gd` لملخصات الزيارة والسمعة.
- `game/content/`: مدققات متخصصة للعناصر والمساحات والتجارة والوصفات المتطورة؛ ContentValidation يركبها دون تحويله لملف ضخم.
- `game/persistence/`: `living_spaces_migration.gd` و`living_spaces_save_validation.gd` إلى جوار مسارات الحفظ الحالية. لا snapshot لمعاينة UI غير مثبتة.
- `content/`: أقسام `items`, `spaces`, `initial_layout`, `containers`, `shops`, `travel`, `equipment`, `recipe_workflows`, `foods`, `learning`, `hygiene`, `customer_experience` في manifest؛ النصوص في ui/stories/encounters.
- `game/app/physical_world_controller.gd`: فصل إنشاء الغرف والمحركات وربط الحالة عن Main عند إدخال الترتيب/المواقع الافتراضية؛ GameSession يظل تركيب خدمات، وMain يظل دورة التطبيق.

## عقود التبادل التي تثبتها الحزم

`ItemStore.get_item(id: StringName) -> Dictionary` يعيد نسخة قراءة بها `id, definition_id, kind, quantity, container_id, attributes`؛ `get_container(id: StringName) -> Dictionary` يعيد `id, location_id, kind, capacity, allowed_tags, host_id`. معرف القطعة منفصل عن تعريفها، والغرفة الافتراضية لا تنشئ مخزون مطبخ.

`ItemChangeSet extends RefCounted` يحمل revision المصدر وتغييرات النسخ والحاويات والحجوزات المرشحة، دون Nodes أو Callables. `ItemStore.commit(change: ItemChangeSet) -> ActionResult` يرفض revision قديمًا ويثبت كل التغيير قبل الإشعار. الصنف لا يرسل عملًا إلى أنظمة أخرى ولا يمثل command bus.

`PlacementRequest extends RefCounted`: `instance_id: StringName, location_id: StringName, cell: Vector2i, rotation: int, host_id: StringName, slot_id: StringName`. الزوايا 0..3؛ الموضع المشتق لا يخزن ثانية داخل ItemStore.

`SpaceService.placement(id: StringName) -> Dictionary` يعيد `instance_id, location_id, cell, rotation, host_id, slot_id`. `changed(location_id: StringName, revision: int)` يبطل هندسة ومسارات ذلك المكان. `busy_provider: Callable` يقرأ انشغال القطعة من مالكه الحالي ثم يشمل حجز المعدة والتنظيف لاحقًا.

`TravelService.snapshot()/restore(data: Dictionary) -> ActionResult` يحفظان رحلة واحدة للاعب: `id, route_id, phase, origin_pose, return_location, started_at, due_at, purchase_container_id`. النهاية world_minutes مطلقة.

`ShopQuote extends RefCounted`: `id, shop_id, offer_revision, lines, total_minor`. سطر السلعة `offer_id, definition_id, quantity, unit_price_minor`. الإيصال ثابت ومحمي بـrequest_id لمنع إعادة التأكيد.

تُوثّق بقية الواجهات الدقيقة في مالكها بالحزم. القارئ اللاحق يستهلك هذه الأسماء دون إنشاء واجهة موازية بنفس المسؤولية.

## سلسلة الزمن والتثبيت

- تغييرات الوضع/النقل/الشراء المتحققة تثبت في حد واضح قبل حركة الفيزياء التالية؛ لا إشعارات نصف معاملة.
- يضاف travel/restock بعد clock، وneeds بعدها، ثم cooking، ثم motion، ثم hygiene عند وجودها، ثم visitors، ثم customer_experience، ثم narrative، ثم scheduler. تعتمد time.json فقط على المراحل المركبة فعليًا في الحزمة.
- يستمر `VisitorController.step(delta)` لكل الزوار رغم إخفاء الغرفة أو تعطيل محرك اللاعب أثناء التسوق. تتغير حالة باب/إشغال ومراجعة المسار من نفس بيانات SpaceService.
- تظل قواعد النوم المعتمدة ومدة التأخير ومرة الإيجار محفوظة. مسار قفزة النوم يمرر مدة القفزة أيضًا إلى المكونات الجديدة المتأثرة بها؛ لا يُضاف تقدم وقت إغلاق التطبيق. لا تعمم واجهة المتجر آلية إيقاف الجلسة المستخدمة حاليًا في fade النوم.

## التحقق والتسليم

لكل حزمة: ابدأ بالفحص الحالي ونسخة حفظ قبلها، نفّذ المهام بترتيبها، اجمع أدلة اللعب اليدوي، وسجل commit مستقلًا لكل مهمة. البناء الموحد: `bash tools/build.sh --out /tmp/kiosk-living-<phase>`؛ التصدير النهائي `bash tools/build.sh --out /tmp/kiosk-living-release --release`. هذا لا يشغل اختبارات اللعب.

تحفظ ملاحظات كل حزمة في `docs/notes/2026-10-22-living-spaces-<phase>.md` مع commit ومقاسات الشاشة والسيناريو والنتيجة وأي فشل. ملاحظة تأخر E السابقة لا توصف كمحلولة دون قياس. لا تدخل الإنجليزية في هذه الدفعة.

## تغطية المواصفات

| أقسام المواصفات | المهام |
| --- | --- |
| 1–3 النطاق والملكية | كل الحزم؛ A1 وA2 يثبتان الأساس |
| 4 الزمن والحضور | B2 وB4، تكامل D3 |
| 5–6 البناء والست وحدات والأسطح | A2–A5، B1 |
| 7–8 التخزين والتسوق | A1، B1–B4 |
| 9 الوظائف والوصفات والتعلم | C1–C4 |
| 10–11 النظافة وتجربة الزبون | D1–D3 |
| 12 الواجهة | A4، B3/B4، C3/C4، D1/D4 |
| 13 البيانات والموازنة | A1–A3، B3، C1/C3، D1/D2 |
| 14 الحفظ | A5، B4، C2/C4، D3 |
| 15–16 القبول وترتيب التنفيذ | بوابات الحزم وD4 |

## تسليم التنفيذ

- [ ] يراجع المستخدم هذه الخطة والحزم المرتبطة ويؤكد طريقة التنفيذ.
- [ ] بعد الاعتماد: يبدأ التنفيذ من A1 باستخدام مهارة التنفيذ المناسبة، دون إعادة طلب اعتماد المتطلبات السابقة.

الترشيح: Native في نفس الجلسة، لأن الاعتماد بين الملكية والمواضع والحفظ قوي، وتقل كلفة نقل السياق ومخاطر اختلاف العقود. لا تفويض لمهام أو مراجعين قبل السماح به وفق تعليمات الجلسة وطريقة التنفيذ المختارة.
