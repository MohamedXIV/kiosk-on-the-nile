VAR character_id = "farid"
VAR topic_id = ""
VAR invitation = false
VAR trial_week = false
VAR appointment_label = ""
{invitation: -> invite}
-> selected
=== invite ===
 {character_id:
 - "farid": الهوا هنا يفك الضهر بعد يوم في الورشة.. لو مش مشغول، نقعد ندردش؟ # speaker:farid # duration:6
 - else: الواحد ييجي هنا يسمع صوت الميه بدل صوت دماغه.. عندك حبة وقت؟ # speaker:youssef # duration:6
 }
 * [أنا سامعك، خد راحتك.] -> selected
 * [معلش، محتاج أروق مع نفسي شوية.]
  ولا يهمك يا صاحبي، القعدة تساعنا كلنا. # speaker:{character_id} # duration:5
  -> END
 * [نخليها بعدين؟]
  براحتك خالص، مفيش حاجة مستعجلة. # speaker:{character_id} # duration:5
  -> END
=== selected ===
{topic_id:
- "meet_farid":
 أنا فريد، عندي ورشة قريبة من هنا. باجي أفرد ضهري ع النيل؛ مش كل يوم الواحد لازم يعمل حاجة. # speaker:farid # duration:8 # effect:social\|meet_farid
 القعدة دي نعمة والله.. أهو نتعرف واحدة واحدة. # speaker:farid # duration:6
 -> END
- "meet_youssef":
 يوسف.. في الكلية ولسه بحاول أفهم الدنيا. بحب أتمشى هنا بعد المحاضرات، بعيد عن الدوشة. # speaker:youssef # duration:8 # effect:social\|meet_youssef
 حلو إن فيه مكان ينفع تسكت فيه من غير ما حد يسألك مالك. # speaker:youssef # duration:6
 -> END
- "hear_farid":
 فاكر الورشة اللي حكيت لك عنها؟ محتاج حد يساعدني في ترتيب العِدد وشغل بسيط، وأعلمه واحدة واحدة. # speaker:farid # duration:8
 المعتاد عندي ثلاثة عصاري في الأسبوع، بس نتكلم ونشوف ظروف اللي جاي. تجربة الأول، مش وعد بشغل مضمون. # speaker:farid # duration:8 # effect:social\|hear_farid
 -> END
- "hear_youssef":
 بصراحة بدور على شغل جنب الدراسة. المصاريف بقت تقيلة، بس مش عايز أسيب الكلية. # speaker:youssef # duration:8
 أقدر على يومين بعد المحاضرات، أكثر من كده المذاكرة هتضيع مني. عشان كده بسأل براحة. # speaker:youssef # duration:8 # effect:social\|hear_youssef
 -> END
- "refer_farid":
 يوسف بيدور على شغل؟ حلو إنك فكرت فينا. ممكن نتكلم عن تجربة بسيطة، ونشوف هو مرتاح للشغل ولا لأ. # speaker:farid # duration:8 # effect:social\|refer_farid
 -> consent_farid
- "refer_youssef":
 فريد محتاج حد يتعلم معاه في الورشة؟ دي ممكن تبقى بداية كويسة، بس خليني أسأل عن طبيعة الشغل الأول. # speaker:youssef # duration:8 # effect:social\|refer_youssef
 -> consent_youssef
- "consent_farid": -> consent_farid
- "consent_youssef": -> consent_youssef
- "days_farid":
 يومين بس عشان الكلية؟ ينفع نجرب يومين. التعليم محتاج نفس، وأنا موافق إن الدراسة تيجي الأول. # speaker:farid # duration:8
 * [أوصل له إنك موافق على يومين؟]
  أيوه، قوله. ولو ارتحنا في التجربة نكمل أسبوع تجربة على اليومين دول. # speaker:farid # duration:8 # effect:social\|days_farid
  -> END
 * [خليني أتأكد من مواعيده ونرجع للكلام.]
  براحتكم، المواعيد لازم تناسبه هو كمان. # speaker:farid # duration:6
  -> END
- "days_youssef":
 فريد موافق على يومين؟ كده أقدر أحافظ على المحاضرات وأجرب الشغل من غير ما أظلم نفسي. # speaker:youssef # duration:8
 * [أقوله اتفقنا على يومين، لو ارتحتوا في التجربة؟]
  أيوه، أنا موافق. نكمل أسبوع تجربة يومين لو المهام ناسبتنا؛ خطوة خطوة. # speaker:youssef # duration:8 # effect:social\|days_youssef
  -> END
 * [رتب مواعيدك الأول وخد راحتك.]
  تسلم، هراجع جدول الكلية. # speaker:youssef # duration:5
  -> END
- "appointment_farid":
 اتكلمنا أنا ويوسف فعلًا؛ اتفقنا على تجربة {appointment_label}. ولو واحد فينا لسه هنا، نخلص قعدتنا ونظبط البداية براحتنا. # speaker:farid # duration:9 # effect:social\|appointment_farid
 -> END
- "appointment_youssef":
 اتواصلنا وظبطنا تجربة {appointment_label}. هروح أتعرف على العِدد وأجرب الشغل البسيط، وبعدها نشوف. # speaker:youssef # duration:8 # effect:social\|appointment_youssef
 -> END
- "pending_farid":
 لسه بنظبط الميعاد، أنا وافقت نتواصل بس ما ثبتناش حاجة لسه. هنبقى نحكي لك لما تحصل. # speaker:farid # duration:7
 -> END
- "pending_youssef":
 لسه بنرتبها مع بعض؛ الموافقة على إننا نتكلم مش معناها إن التجربة حصلت. على رواقة. # speaker:youssef # duration:7
 -> END
- "result_farid":
 يوسف جه الورشة وجربنا فعلًا. بدأنا بترتيب العِدد ومراجعة البسيط مع بعض؛ بيسأل وبيسمع، وده يطمن. # speaker:farid # duration:9 # effect:social\|result_farid
 {trial_week: -> continuation_farid}
 بس لسه استمرار الأيام محتاج اتفاق، عشان ما نجيش على دراسته. التجربة نفسها كانت بداية طيبة. # speaker:farid # duration:8
 -> END
- "result_youssef":
 رحت الورشة فعلًا. أولها كنت قلقان ألخبط العِدد، بس فريد خلاني أجرب واحدة واحدة وأسأل براحتي. # speaker:youssef # duration:9 # effect:social\|result_youssef
 {trial_week: -> continuation_youssef}
 المهام نفعت مبدئيًا، بس لسه محتاجين نتفق على الأيام عشان الكلية. مش معنى إني جربت إني سيبت الدراسة. # speaker:youssef # duration:8
 -> END
- "continuation_farid": -> continuation_farid
- "continuation_youssef": -> continuation_youssef
- else: -> END
}
=== consent_farid ===
* [لو مناسب لك، يتواصل معاك وتظبطوا تجربة؟]
 أيوه، أنا موافق يتواصل معايا ونتفق على ميعاد تجربة. نوصل لبعض بعيد عن قعدتنا هنا، ونشوف الظروف. # speaker:farid # duration:9 # effect:social\|consent_farid
 -> END
* [خليني أسأله الأول، من غير ما أوعد بحاجة.]
 تمام، ما نوعدش حد بالنيابة عنه. # speaker:farid # duration:5
 -> END
=== consent_youssef ===
* [تحب تتواصلوا وتجرب الشغل الأول؟]
 أيوه، موافق نتواصل ونرتب تجربة. قوله إني مهتم، بس لسه بنتعرف على الشغل ومش باتفق على دوام دائم. # speaker:youssef # duration:9 # effect:social\|consent_youssef
 -> END
* [فكر براحتك، مفيش إلزام.]
 متشكر، خلينا نرجع لها لما أكون مرتب دماغي. # speaker:youssef # duration:5
 -> END
=== continuation_farid ===
 اتفقنا نكمل أسبوع تجربة يومين؛ نعلّم ونتعلم ونراعي الكلية. لسه مش حكم نهائي ولا شغل مضمون للأبد. # speaker:farid # duration:8 # effect:social\|continuation_farid
-> END
=== continuation_youssef ===
 اليومين نفعوا مع المحاضرات واتفقنا على أسبوع تجربة. مبسوط إني باخد خطوة من غير ما أسيب الدراسة. تسلم إنك سألت عليا. # speaker:youssef # duration:9 # effect:social\|continuation_youssef
-> END
