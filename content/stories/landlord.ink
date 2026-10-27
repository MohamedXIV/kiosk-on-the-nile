VAR character_id = "abdul_karim"
VAR has_housing_due = false
VAR can_negotiate = false
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
مساء الخير يا ابني. عامل إيه؟ لو عندك وقت نقعد دقيقتين ونشوف حسابنا بهدوء. # speaker:{character_id} # duration:8 # loc:story.landlord.001
* {has_housing_due && can_pay_housing} [اتفضل إيجار السكن، {housing_due_label} جنيه. # loc:story.landlord.002]
 تسلم يا ابني. ده إيصال اللي دفعته، وحسابنا واضح في الدفتر. # speaker:{character_id} # duration:7 # effect:finance\|pay_housing # loc:story.landlord.003
 -> END
* {has_housing_due && can_partial_housing} [أقدر أدفع {partial_label} جنيه دلوقتي، والباقي نتفاهم عليه. # loc:story.landlord.004]
 موافق. أسجل اللي وصلني بس، والباقي لسه علينا نتفق عليه. # speaker:{character_id} # duration:7 # effect:finance\|pay_partial # loc:story.landlord.005
 -> END
* {can_negotiate} [ممكن نتفق على مهلة للإيجار؟ مرتب أولوياتي ومحتاج أوضح الميعاد. # loc:story.landlord.006]
 خلّينا نتفق على موعد نقدر نلتزم بيه، مش مجرد كلام. # speaker:{character_id} # duration:6 # loc:story.landlord.007
 ** {extend_1} [ممكن يوم واحد؟ # loc:story.landlord.008]
  -> extension_one
 ** {extend_3} [محتاج ثلاثة أيام. # loc:story.landlord.009]
  -> extension_three
 ** {extend_7} [أقدر أرتبها خلال أسبوع. # loc:story.landlord.010]
  -> extension_week
 ** [هفكر الأول؛ مش عايز أوعد بحاجة مش واثق منها. # loc:story.landlord.011]
  خُد وقتك. من غير اتفاق جديد، المستحق الأصلي باقٍ زي ما هو. # speaker:{character_id} # duration:7 # loc:story.landlord.012
  -> END
* {!has_housing_due} [حساب إيجار السكن عامل إيه؟ # loc:story.landlord.013]
 اللي اتدفع محفوظ بإيصالاته، والميعاد الجاي ظاهر في دفترك. مش هاخد منك فلوس من غير حساب. # speaker:{character_id} # duration:8 # loc:story.landlord.014
 -> END
* {!has_loan} [ممكن أطلب سلفة وأرد أصلها في موعد نتفق عليه؟ # loc:story.landlord.015]
 {can_loan:
  أقدر أساعد في حدود اللي متاح عندي. نتفق على المبلغ والمدة الأول. # speaker:{character_id} # duration:7 # loc:story.landlord.016
  ** {loan_0} [محتاج {loan_0_label} جنيه. # loc:story.landlord.017]
   -> loan_zero
  ** {loan_1} [محتاج {loan_1_label} جنيه. # loc:story.landlord.018]
   -> loan_one
  ** {loan_2} [محتاج {loan_2_label} جنيه. # loc:story.landlord.019]
   -> loan_two
  ** [معلش، هرتب أموري الأول. # loc:story.landlord.020]
   ولا يهمك. مفيش سلفة اتفقت عليها لسه. # speaker:{character_id} # duration:6 # loc:story.landlord.021
   -> END
 - else:
  اعذرني يا ابني. السلفة مسؤولية، ومش مناسب أوعدك بفلوس دلوقتي. ده مش بيغيّر حقك إننا نتكلم. # speaker:{character_id} # duration:8 # loc:story.landlord.022
  -> END
 }
* {has_loan && can_repay_loan} [اتفضل باقي أصل السلفة: {loan_remaining_label} جنيه. # loc:story.landlord.023]
 وصلني المبلغ. ربنا يوسعها عليك؛ الإيصال محفوظ، ومن غير أي زيادة على الأصل. # speaker:{character_id} # duration:8 # effect:finance\|repay_loan # loc:story.landlord.024
 -> END
* {can_repair} [أنا آسف إني ما التزمتش بالموعد اللي وعدتك بيه. # loc:story.landlord.025]
 مقدّر إنك جيت واتكلمت. الاعتذار له قيمته، والسداد أو اتفاق جديد نرتبه بوضوح. # speaker:{character_id} # duration:8 # effect:finance\|repair # loc:story.landlord.026
 -> END
* {!about_today && can_focus} [{known_abdul_family:طمني على والدتك، عاملة إيه؟ # loc:story.landlord.027|وأنت أخبارك إيه؟ الدنيا ماشية معاك؟ # loc:story.landlord.028}]
 {known_abdul_family:
  {day % 3:
  - 0: الحمد لله أهدى النهارده. قعدنا سوا شوية، وأختي عدّت علينا. متشكر إنك فاكر. # speaker:{character_id} # duration:7 # effect:finance\|personal # loc:story.landlord.029
  - 1: لسه محتاجة راحة، بس بقت بتتصل تسألني اتأخرت ليه. لما أسمع صوتها كده أطمن. # speaker:{character_id} # duration:7 # effect:finance\|personal # loc:story.landlord.030
  - else: كنت عندها قبل ما أجيلك. طلبت مني أجيب لها جرايد زمان، فقعدنا نفتكر حكايات قديمة. # speaker:{character_id} # duration:7 # effect:finance\|personal # loc:story.landlord.031
  }
 - else:
  الحمد لله. أمي كانت تعبانة شوية، وبحاول أعدّي عليها كل يوم. الواحد ساعات يحتاج حد يسأل عليه وبس. # speaker:{character_id} # duration:8 # effect:finance\|personal # effect:learn\|KNOWN_ABDUL_FAMILY\|عم عبد الكريم بيعدّي على والدته كل يوم ويهتم إن حد يسأل عليه. # loc:story.landlord.032
 }
 ** [ربنا يطمنك عليها. لو محتاج حاجة قولي. # loc:story.landlord.033]
  ربنا يخليك. السؤال لوحده بيهوّن. # speaker:{character_id} # duration:6 # loc:story.landlord.034
  -> END
 ** [ألف سلامة عليها. # loc:story.landlord.035]
  الله يسلمك يا ابني. # speaker:{character_id} # duration:5 # loc:story.landlord.036
  -> END
* [نكمّل كلامنا بعدين يا عمّي. # loc:story.landlord.037]
 على راحتك. أنا هفضل شوية وبعدين أمشي. # speaker:{character_id} # duration:6 # loc:story.landlord.038
 -> END
=== extension_one ===
أقدر أستناك لحد {extension_1_date}. لو وافقت يبقى ده وعدنا الجديد، والمبلغ الأصلي زي ما هو. # speaker:{character_id} # duration:8 # effect:finance\|offer_day_1 # loc:story.landlord.039
-> accept_extension
=== extension_three ===
نتفق على {extension_3_date}؟ المبلغ باقٍ، لكن ده يبقى موعد الوعد بيننا. # speaker:{character_id} # duration:8 # effect:finance\|offer_day_3 # loc:story.landlord.040
-> accept_extension
=== extension_week ===
أقدر أستناك لحد {extension_7_date}. خلّينا واضحين عشان كل واحد يرتب حاله. # speaker:{character_id} # duration:8 # effect:finance\|offer_day_7 # loc:story.landlord.041
-> accept_extension
=== accept_extension ===
* [موافق، ده الموعد اللي أقدر أوعدك بيه. # loc:story.landlord.042]
 اتفقنا على {agreed_date}. سجلنا الاتفاق، من غير ما نمسح أصل المستحق. # speaker:{character_id} # duration:7 # effect:finance\|accept_offer # loc:story.landlord.043
 -> END
* [لا، مش هقدر أوعدك. نسيبها من غير اتفاق جديد. # loc:story.landlord.044]
 تمام. عرض المهلة وحده مش وعد عليك. # speaker:{character_id} # duration:6 # effect:finance\|decline_offer # loc:story.landlord.045
 -> END
=== loan_zero ===
أقدر أسلفك {loan_0_label} جنيه. ترد نفس الأصل بعد {loan_duration_label} من الاستلام، من غير زيادة. # speaker:{character_id} # duration:8 # effect:finance\|offer_loan_0 # loc:story.landlord.046
-> accept_loan
=== loan_one ===
أقدر أسلفك {loan_1_label} جنيه. ترد نفس الأصل بعد {loan_duration_label} من الاستلام، من غير زيادة. # speaker:{character_id} # duration:8 # effect:finance\|offer_loan_1 # loc:story.landlord.047
-> accept_loan
=== loan_two ===
أقدر أسلفك {loan_2_label} جنيه. ترد نفس الأصل بعد {loan_duration_label} من الاستلام، من غير زيادة. # speaker:{character_id} # duration:8 # effect:finance\|offer_loan_2 # loc:story.landlord.048
-> accept_loan
=== accept_loan ===
* [موافق على المبلغ والمدة، وهرد نفس الأصل. # loc:story.landlord.049]
 اتفضل. المبلغ وصل لك فعلًا، وميعاد رده وإيصاله محفوظين في الدفتر. # speaker:{character_id} # duration:7 # effect:finance\|accept_offer # loc:story.landlord.050
 -> END
* [متشكر، لكن مش هاخد السلفة دلوقتي. # loc:story.landlord.051]
 ولا يهمك. مفيش فلوس اتنقلت ولا دين اتسجل عليك. # speaker:{character_id} # duration:6 # effect:finance\|decline_offer # loc:story.landlord.052
 -> END
