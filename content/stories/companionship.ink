VAR character_id = "farid"
VAR topic_id = ""
VAR invitation = false
VAR trial_week = false
VAR appointment_label = ""
{invitation: -> invite}
-> selected
=== invite ===
 {character_id:
 - "farid": الهوا هنا يفك الضهر بعد يوم في الورشة.. لو مش مشغول، نقعد ندردش؟ # speaker:farid # duration:6 # loc:story.companionship.001
 - else: الواحد ييجي هنا يسمع صوت الميه بدل صوت دماغه.. عندك حبة وقت؟ # speaker:youssef # duration:6 # loc:story.companionship.002
 }
 * [أنا سامعك، خد راحتك. # loc:story.companionship.003] -> selected
 * [معلش، محتاج أروق مع نفسي شوية. # loc:story.companionship.004]
  ولا يهمك يا صاحبي، القعدة تساعنا كلنا. # speaker:{character_id} # duration:5 # loc:story.companionship.005
  -> END
 * [نخليها بعدين؟ # loc:story.companionship.006]
  براحتك خالص، مفيش حاجة مستعجلة. # speaker:{character_id} # duration:5 # loc:story.companionship.007
  -> END
=== selected ===
{topic_id:
- "meet_farid":
 أنا فريد، عندي ورشة قريبة من هنا. باجي أفرد ضهري ع النيل؛ مش كل يوم الواحد لازم يعمل حاجة. # speaker:farid # duration:8 # effect:social\|meet_farid # loc:story.companionship.008
 القعدة دي نعمة والله.. أهو نتعرف واحدة واحدة. # speaker:farid # duration:6 # loc:story.companionship.009
 -> END
- "meet_youssef":
 يوسف.. في الكلية ولسه بحاول أفهم الدنيا. بحب أتمشى هنا بعد المحاضرات، بعيد عن الدوشة. # speaker:youssef # duration:8 # effect:social\|meet_youssef # loc:story.companionship.010
 حلو إن فيه مكان ينفع تسكت فيه من غير ما حد يسألك مالك. # speaker:youssef # duration:6 # loc:story.companionship.011
 -> END
- "hear_farid":
 فاكر الورشة اللي حكيت لك عنها؟ محتاج حد يساعدني في ترتيب العِدد وشغل بسيط، وأعلمه واحدة واحدة. # speaker:farid # duration:8 # loc:story.companionship.012
 المعتاد عندي ثلاثة عصاري في الأسبوع، بس نتكلم ونشوف ظروف اللي جاي. تجربة الأول، مش وعد بشغل مضمون. # speaker:farid # duration:8 # effect:social\|hear_farid # loc:story.companionship.013
 -> END
- "hear_youssef":
 بصراحة بدور على شغل جنب الدراسة. المصاريف بقت تقيلة، بس مش عايز أسيب الكلية. # speaker:youssef # duration:8 # loc:story.companionship.014
 أقدر على يومين بعد المحاضرات، أكثر من كده المذاكرة هتضيع مني. عشان كده بسأل براحة. # speaker:youssef # duration:8 # effect:social\|hear_youssef # loc:story.companionship.015
 -> END
- "refer_farid":
 يوسف بيدور على شغل؟ حلو إنك فكرت فينا. ممكن نتكلم عن تجربة بسيطة، ونشوف هو مرتاح للشغل ولا لأ. # speaker:farid # duration:8 # effect:social\|refer_farid # loc:story.companionship.016
 -> consent_farid
- "refer_youssef":
 فريد محتاج حد يتعلم معاه في الورشة؟ دي ممكن تبقى بداية كويسة، بس خليني أسأل عن طبيعة الشغل الأول. # speaker:youssef # duration:8 # effect:social\|refer_youssef # loc:story.companionship.017
 -> consent_youssef
- "consent_farid": -> consent_farid
- "consent_youssef": -> consent_youssef
- "days_farid":
 يومين بس عشان الكلية؟ ينفع نجرب يومين. التعليم محتاج نفس، وأنا موافق إن الدراسة تيجي الأول. # speaker:farid # duration:8 # loc:story.companionship.018
 * [أوصل له إنك موافق على يومين؟ # loc:story.companionship.019]
  أيوه، قوله. ولو ارتحنا في التجربة نكمل أسبوع تجربة على اليومين دول. # speaker:farid # duration:8 # effect:social\|days_farid # loc:story.companionship.020
  -> END
 * [خليني أتأكد من مواعيده ونرجع للكلام. # loc:story.companionship.021]
  براحتكم، المواعيد لازم تناسبه هو كمان. # speaker:farid # duration:6 # loc:story.companionship.022
  -> END
- "days_youssef":
 فريد موافق على يومين؟ كده أقدر أحافظ على المحاضرات وأجرب الشغل من غير ما أظلم نفسي. # speaker:youssef # duration:8 # loc:story.companionship.023
 * [أقوله اتفقنا على يومين، لو ارتحتوا في التجربة؟ # loc:story.companionship.024]
  أيوه، أنا موافق. نكمل أسبوع تجربة يومين لو المهام ناسبتنا؛ خطوة خطوة. # speaker:youssef # duration:8 # effect:social\|days_youssef # loc:story.companionship.025
  -> END
 * [رتب مواعيدك الأول وخد راحتك. # loc:story.companionship.026]
  تسلم، هراجع جدول الكلية. # speaker:youssef # duration:5 # loc:story.companionship.027
  -> END
- "appointment_farid":
 اتكلمنا أنا ويوسف فعلًا؛ اتفقنا على تجربة {appointment_label}. ولو واحد فينا لسه هنا، نخلص قعدتنا ونظبط البداية براحتنا. # speaker:farid # duration:9 # effect:social\|appointment_farid # loc:story.companionship.028
 -> END
- "appointment_youssef":
 اتواصلنا وظبطنا تجربة {appointment_label}. هروح أتعرف على العِدد وأجرب الشغل البسيط، وبعدها نشوف. # speaker:youssef # duration:8 # effect:social\|appointment_youssef # loc:story.companionship.029
 -> END
- "pending_farid":
 لسه بنظبط الميعاد، أنا وافقت نتواصل بس ما ثبتناش حاجة لسه. هنبقى نحكي لك لما تحصل. # speaker:farid # duration:7 # loc:story.companionship.030
 -> END
- "pending_youssef":
 لسه بنرتبها مع بعض؛ الموافقة على إننا نتكلم مش معناها إن التجربة حصلت. على رواقة. # speaker:youssef # duration:7 # loc:story.companionship.031
 -> END
- "result_farid":
 يوسف جه الورشة وجربنا فعلًا. بدأنا بترتيب العِدد ومراجعة البسيط مع بعض؛ بيسأل وبيسمع، وده يطمن. # speaker:farid # duration:9 # effect:social\|result_farid # loc:story.companionship.032
 {trial_week: -> continuation_farid}
 بس لسه استمرار الأيام محتاج اتفاق، عشان ما نجيش على دراسته. التجربة نفسها كانت بداية طيبة. # speaker:farid # duration:8 # loc:story.companionship.033
 -> END
- "result_youssef":
 رحت الورشة فعلًا. أولها كنت قلقان ألخبط العِدد، بس فريد خلاني أجرب واحدة واحدة وأسأل براحتي. # speaker:youssef # duration:9 # effect:social\|result_youssef # loc:story.companionship.034
 {trial_week: -> continuation_youssef}
 المهام نفعت مبدئيًا، بس لسه محتاجين نتفق على الأيام عشان الكلية. مش معنى إني جربت إني سيبت الدراسة. # speaker:youssef # duration:8 # loc:story.companionship.035
 -> END
- "continuation_farid": -> continuation_farid
- "continuation_youssef": -> continuation_youssef
- "exam_open":
 عندي امتحان قريب، وبقسم المذاكرة حتت صغيرة بدل ما أفضل قلقان من الكل. القعدة هنا بتريح دماغي وبعدين أرجع للكتب. # speaker:youssef # duration:9 # effect:social\|exam_open # loc:story.companionship.exam_open
 -> END
- "exam_follow":
 فاكر لما قلت لك هقسم المذاكرة؟ خلصت الجزء اللي كنت مأجله، وراجعت مع زميل. لسه الامتحان قدامي، بس بقيت أهدى؛ مش لازم أخلص الدنيا في ليلة. # speaker:youssef # duration:9 # effect:social\|exam_follow # loc:story.companionship.exam_follow
 -> END
- "exam_ask":
 مش شايف يوسف في القعدة النهارده. لو قابلته، تسأله عامل إيه؟ طمني عليه بس، مش عايز أزن عليه. # speaker:farid # duration:9 # loc:story.companionship.exam_ask
 * [لو قابلته هسأله وأوصل لك كلامه. # loc:story.companionship.exam_ask.yes]
  تسلم، لما تلاقوا وقت بس؛ مفيش حاجة مستعجلة. # speaker:farid # duration:5 # effect:social\|exam_ask # loc:story.companionship.exam_ask.confirm
  -> END
 * [مش هقدر أوعدك، خلينا على راحتنا. # loc:story.companionship.exam_ask.later]
  ولا يهمك، نتقابل على خير. # speaker:farid # duration:5 # loc:story.companionship.exam_ask.okay
  -> END
- "exam_answer":
 فريد سأل عليا؟ تسلموا. قوله أنا كويس وبراجع للامتحان، وقسمت المذاكرة وبقيت أهدى. لما أفضى هعدي أسلم عليه؛ من غير ما أوعد بميعاد دلوقتي. # speaker:youssef # duration:9 # effect:social\|exam_answer # loc:story.companionship.exam_answer
 -> END
- "exam_return":
 إنت قابلت يوسف وقال لك كده؟ الحمد لله، طمنتني. خليه ياخد وقته في المذاكرة؛ هنتقابل لما الظروف تسمح. # speaker:farid # duration:9 # effect:social\|exam_return # loc:story.companionship.exam_return
 -> END
- "radio_open":
 عندي راديو قديم من أيام أبويا، بحاول أظبط صوته على مهلي. مش شغل ورشة ولا طلب لحد؛ حاجة بحب أقعد لها لما أروق. # speaker:farid # duration:9 # effect:social\|radio_open # loc:story.companionship.radio_open
 -> END
- "radio_follow":
 الراديو اللي حكيت لك عنه؟ نضفت الوصلات واشتغل صوته تاني. لسه فيه وش خفيف، بس سمعت عليه أغنية قديمة وقعدت مبسوط. مش كل حاجة لازم ترجع جديدة. # speaker:farid # duration:9 # effect:social\|radio_follow # loc:story.companionship.radio_follow
 -> END
- "radio_ask":
 هو فريد ما جاش النهارده؟ لو شفته، اسأله أخباره إيه. بقالي شوية ما قعدتش معاه، ونفسي أطمن عليه. # speaker:youssef # duration:9 # loc:story.companionship.radio_ask
 * [لو قابلته هسأله وأوصل لك كلامه. # loc:story.companionship.radio_ask.yes]
  تسلم، لما تلاقوا وقت بس؛ مفيش حاجة مستعجلة. # speaker:youssef # duration:5 # effect:social\|radio_ask # loc:story.companionship.radio_ask.confirm
  -> END
 * [مش هقدر أوعدك، خلينا على راحتنا. # loc:story.companionship.radio_ask.later]
  ولا يهمك، نتقابل على خير. # speaker:youssef # duration:5 # loc:story.companionship.radio_ask.okay
  -> END
- "radio_answer":
 يوسف بيسأل؟ قوله أنا بخير، والراديو القديم رجع يغني. لو قابلني نقعد نحكي؛ من غير مواعيد شغل ولا التزامات. # speaker:farid # duration:9 # effect:social\|radio_answer # loc:story.companionship.radio_answer
 -> END
- "radio_return":
 حلو إنك قابلت فريد وطمنتني. والراديو ده أكيد وراه حكايات؛ لما أشوفه أبقى أسمع منه. تسلم إنك وصلت الكلام. # speaker:youssef # duration:9 # effect:social\|radio_return # loc:story.companionship.radio_return
 -> END
- else: -> END
}
=== consent_farid ===
* [لو مناسب لك، يتواصل معاك وتظبطوا تجربة؟ # loc:story.companionship.036]
 أيوه، أنا موافق يتواصل معايا ونتفق على ميعاد تجربة. نوصل لبعض بعيد عن قعدتنا هنا، ونشوف الظروف. # speaker:farid # duration:9 # effect:social\|consent_farid # loc:story.companionship.037
 -> END
* [خليني أسأله الأول، من غير ما أوعد بحاجة. # loc:story.companionship.038]
 تمام، ما نوعدش حد بالنيابة عنه. # speaker:farid # duration:5 # loc:story.companionship.039
 -> END
=== consent_youssef ===
* [تحب تتواصلوا وتجرب الشغل الأول؟ # loc:story.companionship.040]
 أيوه، موافق نتواصل ونرتب تجربة. قوله إني مهتم، بس لسه بنتعرف على الشغل ومش باتفق على دوام دائم. # speaker:youssef # duration:9 # effect:social\|consent_youssef # loc:story.companionship.041
 -> END
* [فكر براحتك، مفيش إلزام. # loc:story.companionship.042]
 متشكر، خلينا نرجع لها لما أكون مرتب دماغي. # speaker:youssef # duration:5 # loc:story.companionship.043
 -> END
=== continuation_farid ===
 اتفقنا نكمل أسبوع تجربة يومين؛ نعلّم ونتعلم ونراعي الكلية. لسه مش حكم نهائي ولا شغل مضمون للأبد. # speaker:farid # duration:8 # effect:social\|continuation_farid # loc:story.companionship.044
-> END
=== continuation_youssef ===
 اليومين نفعوا مع المحاضرات واتفقنا على أسبوع تجربة. مبسوط إني باخد خطوة من غير ما أسيب الدراسة. تسلم إنك سألت عليا. # speaker:youssef # duration:9 # effect:social\|continuation_youssef # loc:story.companionship.045
-> END
