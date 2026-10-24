VAR character_id = "abdul_karim"
VAR has_housing_due = false
VAR housing_due_label = "0.00"
VAR partial_label = "10.00"
VAR can_pay_housing = false
VAR can_partial_housing = false
VAR extend_1 = false
VAR extend_3 = false
VAR extend_7 = false
VAR extension_1_date = ""
VAR extension_3_date = ""
VAR extension_7_date = ""
VAR loan_duration_label = "7 أيام"
VAR can_loan = false
VAR loan_0 = false
VAR loan_1 = false
VAR loan_2 = false
VAR loan_0_label = "10.00"
VAR loan_1_label = "20.00"
VAR loan_2_label = "30.00"
VAR has_loan = false
VAR loan_remaining_label = "0.00"
VAR can_repay_loan = false
VAR day = 1
VAR known_abdul_family = false
VAR about_today = false
VAR can_focus = true
VAR can_repair = false
VAR agreed_date = ""
مساء الخير يا ابني. عامل إيه؟ لو عندك وقت نقعد دقيقتين ونشوف حسابنا بهدوء. # speaker:{character_id} # duration:8
* {has_housing_due && can_pay_housing} [اتفضل إيجار السكن، {housing_due_label} جنيه.]
 تسلم يا ابني. ده إيصال اللي دفعته، وحسابنا واضح في الدفتر. # speaker:{character_id} # duration:7 # effect:finance\|pay_housing
 -> END
* {has_housing_due && can_partial_housing} [أقدر أدفع {partial_label} جنيه دلوقتي، والباقي نتفاهم عليه.]
 موافق. أسجل اللي وصلني بس، والباقي لسه علينا نتفق عليه. # speaker:{character_id} # duration:7 # effect:finance\|pay_partial
 -> END
* {has_housing_due} [ممكن تستنى عليّ شوية؟ مرتب أولوياتي ومحتاج مهلة.]
 خلّينا نتفق على موعد نقدر نلتزم بيه، مش مجرد كلام. # speaker:{character_id} # duration:6
 ** {extend_1} [ممكن يوم واحد؟]
  -> extension_one
 ** {extend_3} [محتاج ثلاثة أيام.]
  -> extension_three
 ** {extend_7} [أقدر أرتبها خلال أسبوع.]
  -> extension_week
 ** [هفكر الأول؛ مش عايز أوعد بحاجة مش واثق منها.]
  خُد وقتك. من غير اتفاق جديد، المستحق الأصلي باقٍ زي ما هو. # speaker:{character_id} # duration:7
  -> END
* {!has_housing_due} [حساب إيجار السكن عامل إيه؟]
 اللي اتدفع محفوظ بإيصالاته، والميعاد الجاي ظاهر في دفترك. مش هاخد منك فلوس من غير حساب. # speaker:{character_id} # duration:8
 -> END
* {!has_loan} [ممكن أطلب سلفة وأرد أصلها في موعد نتفق عليه؟]
 {can_loan:
  أقدر أساعد في حدود اللي متاح عندي. نتفق على المبلغ والمدة الأول. # speaker:{character_id} # duration:7
  ** {loan_0} [محتاج {loan_0_label} جنيه.]
   -> loan_zero
  ** {loan_1} [محتاج {loan_1_label} جنيه.]
   -> loan_one
  ** {loan_2} [محتاج {loan_2_label} جنيه.]
   -> loan_two
  ** [معلش، هرتب أموري الأول.]
   ولا يهمك. مفيش سلفة اتفقت عليها لسه. # speaker:{character_id} # duration:6
   -> END
 - else:
  اعذرني يا ابني. السلفة مسؤولية، ومش مناسب أوعدك بفلوس دلوقتي. ده مش بيغيّر حقك إننا نتكلم. # speaker:{character_id} # duration:8
  -> END
 }
* {has_loan && can_repay_loan} [اتفضل باقي أصل السلفة: {loan_remaining_label} جنيه.]
 وصلني المبلغ. ربنا يوسعها عليك؛ الإيصال محفوظ، ومن غير أي زيادة على الأصل. # speaker:{character_id} # duration:8 # effect:finance\|repay_loan
 -> END
* {can_repair} [أنا آسف إني ما التزمتش بالموعد اللي وعدتك بيه.]
 مقدّر إنك جيت واتكلمت. الاعتذار له قيمته، والسداد أو اتفاق جديد نرتبه بوضوح. # speaker:{character_id} # duration:8 # effect:finance\|repair
 -> END
* {!about_today && can_focus} [{known_abdul_family:طمني على والدتك، عاملة إيه؟|وأنت أخبارك إيه؟ الدنيا ماشية معاك؟}]
 {known_abdul_family:
  {day % 3:
  - 0: الحمد لله أهدى النهارده. قعدنا سوا شوية، وأختي عدّت علينا. متشكر إنك فاكر. # speaker:{character_id} # duration:7 # effect:finance\|personal
  - 1: لسه محتاجة راحة، بس بقت بتتصل تسألني اتأخرت ليه. لما أسمع صوتها كده أطمن. # speaker:{character_id} # duration:7 # effect:finance\|personal
  - else: كنت عندها قبل ما أجيلك. طلبت مني أجيب لها جرايد زمان، فقعدنا نفتكر حكايات قديمة. # speaker:{character_id} # duration:7 # effect:finance\|personal
  }
 - else:
  الحمد لله. أمي كانت تعبانة شوية، وبحاول أعدّي عليها كل يوم. الواحد ساعات يحتاج حد يسأل عليه وبس. # speaker:{character_id} # duration:8 # effect:finance\|personal # effect:learn\|KNOWN_ABDUL_FAMILY\|عم عبد الكريم بيعدّي على والدته كل يوم ويهتم إن حد يسأل عليه.
 }
 ** [ربنا يطمنك عليها. لو محتاج حاجة قولي.]
  ربنا يخليك. السؤال لوحده بيهوّن. # speaker:{character_id} # duration:6
  -> END
 ** [ألف سلامة عليها.]
  الله يسلمك يا ابني. # speaker:{character_id} # duration:5
  -> END
* [نكمّل كلامنا بعدين يا عمّي.]
 على راحتك. أنا هفضل شوية وبعدين أمشي. # speaker:{character_id} # duration:6
 -> END
=== extension_one ===
أقدر أستناك لحد {extension_1_date}. لو وافقت يبقى ده وعدنا الجديد، والمبلغ الأصلي زي ما هو. # speaker:{character_id} # duration:8 # effect:finance\|offer_day_1
-> accept_extension
=== extension_three ===
نتفق على {extension_3_date}؟ المبلغ باقٍ، لكن ده يبقى موعد الوعد بيننا. # speaker:{character_id} # duration:8 # effect:finance\|offer_day_3
-> accept_extension
=== extension_week ===
أقدر أستناك لحد {extension_7_date}. خلّينا واضحين عشان كل واحد يرتب حاله. # speaker:{character_id} # duration:8 # effect:finance\|offer_day_7
-> accept_extension
=== accept_extension ===
* [موافق، ده الموعد اللي أقدر أوعدك بيه.]
 اتفقنا على {agreed_date}. سجلنا الاتفاق، من غير ما نمسح أصل المستحق. # speaker:{character_id} # duration:7 # effect:finance\|accept_offer
 -> END
* [لا، مش هقدر أوعدك. نسيبها من غير اتفاق جديد.]
 تمام. عرض المهلة وحده مش وعد عليك. # speaker:{character_id} # duration:6 # effect:finance\|decline_offer
 -> END
=== loan_zero ===
أقدر أسلفك {loan_0_label} جنيه. ترد نفس الأصل بعد {loan_duration_label} من الاستلام، من غير زيادة. # speaker:{character_id} # duration:8 # effect:finance\|offer_loan_0
-> accept_loan
=== loan_one ===
أقدر أسلفك {loan_1_label} جنيه. ترد نفس الأصل بعد {loan_duration_label} من الاستلام، من غير زيادة. # speaker:{character_id} # duration:8 # effect:finance\|offer_loan_1
-> accept_loan
=== loan_two ===
أقدر أسلفك {loan_2_label} جنيه. ترد نفس الأصل بعد {loan_duration_label} من الاستلام، من غير زيادة. # speaker:{character_id} # duration:8 # effect:finance\|offer_loan_2
-> accept_loan
=== accept_loan ===
* [موافق على المبلغ والمدة، وهرد نفس الأصل.]
 اتفضل. المبلغ وصل لك فعلًا، وميعاد رده وإيصاله محفوظين في الدفتر. # speaker:{character_id} # duration:7 # effect:finance\|accept_offer
 -> END
* [متشكر، لكن مش هاخد السلفة دلوقتي.]
 ولا يهمك. مفيش فلوس اتنقلت ولا دين اتسجل عليك. # speaker:{character_id} # duration:6 # effect:finance\|decline_offer
 -> END
