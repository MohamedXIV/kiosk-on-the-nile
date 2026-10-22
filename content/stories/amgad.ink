INCLUDE context.inkinc
{mode == 1: -> arrival}
{mode == 2: -> served}
{topic_id:
- "fan_bought": -> fan_bought
- "fan_referral": -> referral
- "introduction": -> first_talk
- "memory": -> memory
- else: -> smalltalk
}
=== arrival ===
{amgad_visits <= 1:
 مساء الفل يا ابني.. كوباية شاي على مهلك، لسه قدامنا قعدة. # speaker:amgad # duration:6
- else:
 {line_variant:
 - 0: مساء الجمال! قلت أعدّي أشرب الشاي ع النيل قبل ما أروّح. # speaker:amgad # duration:6
 - 1: إزيك يا ابني؟ يوم المكتب خلص أخيرًا.. اعملنا شاي. # speaker:amgad # duration:6
 - else: مساء الخير على أهل الكشك. كوباية شاي وأنا أقعد أريح رجلي شوية. # speaker:amgad # duration:6
 }
}
-> END
=== served ===
{day >= 2 && not known_cheap_fan:
 تسلم إيدك. لما تفضى عايز أقولك على مروحة لأوضة السطح. # speaker:amgad # duration:6
- else:
 {quality_score >= 2:
  {line_variant:
  - 0: تسلم إيدك.. دي تتشرب على رواقة. # speaker:amgad # duration:5
  - 1: الله ينور. ريحة الشاي لوحدها تفوق. # speaker:amgad # duration:5
  - else: كده القعدة كملت، متشكر يا ابني. # speaker:amgad # duration:5
  }
 - else:
  معلش، المرة الجاية نضبطها سوا. يومك شكله كان طويل. # speaker:amgad # duration:6
 }
}
-> END
=== first_talk ===
أنا أمجد، شغال في المكتب اللي على أول الشارع. باعدّي هنا أفصل قبل البيت. # speaker:amgad # duration:6
* [تنور في أي وقت يا عم أمجد]
 ربنا يكرمك. القعدة هنا تخلّي الواحد ينسى الزحمة شوية. # speaker:amgad # duration:5.5 # effect:mood\|4
* [ربنا يعينك ع الشغل]
 ويعينك يا ابني.. كلنا بنحاول نروّح آخر اليوم رايقين. # speaker:amgad # duration:5.5 # effect:mood\|3
* [(ابتسم واسمعه بهدوء)]
 أهو صوت الميه أريح من صوت التليفونات طول النهار. # speaker:amgad # duration:5.5 # effect:mood\|3
- -> END
=== referral ===
عم سعيد الكهربائي اللي ورا المحطة عنده مروحة ستاند مستعملة نضيفة بـ {fan_price_label} جنيه. قوله من طرفي؛ تقدر تطلبها من تليفون الكشك. # speaker:amgad # duration:9 # effect:learn\|KNOWN_CHEAP_FAN\|عم أمجد دلّني على مروحة ستاند مستعملة عند عم سعيد؛ أقدر أطلبها من تليفون الكشك.
* [تسلم، أوضة السطح فعلًا حر بالليل]
 ربنا يجعلها نومة مريحة. # speaker:amgad # duration:4.5 # effect:mood\|4
* [لما أجمع تمنها إن شاء الله]
 براحتك يا ابني، مش مستعجلين. # speaker:amgad # duration:4.5
- -> END
=== fan_bought ===
عرفت إن المروحة وصلت! أخبار نومة السطح إيه دلوقتي؟ # speaker:amgad # duration:5.5
* [فرقت فعلًا، تسلم على المعرفة]
 تتهنى بيها يا ابني. أهم حاجة الواحد يرتاح في بيته. # speaker:amgad # duration:5 # effect:mood\|3
* [لسه بجربها]
 جرّبها براحتك، وعم سعيد قريب لو احتجت حاجة. # speaker:amgad # duration:5
- -> END
=== memory ===
{previous_quality >= 2:
 الشاي اللي شربته عندك المرة اللي فاتت كان مظبوط.. افتكرته وأنا لسه في المكتب. # speaker:amgad # duration:6
- else:
 فاكر الكوباية بتاعة المرة اللي فاتت؟ ما تشغلش بالك، كل يوم وليه ظروفه. # speaker:amgad # duration:6
}
-> END
=== smalltalk ===
{familiar:
 منور يا صاحبي، بقيت أعرف قعدتك من بعيد. # speaker:amgad # duration:4
}
{line_variant:
- 0:
 {hour < 18:
  الشارع زحمة دلوقتي.. هستنى شوية لحد ما يهدى. # speaker:amgad # duration:5
 - else:
  أحلى وقت لما الشمس تغيب والنسمة تبدأ تدخل. # speaker:amgad # duration:5
 }
- 1: كان يوم ورق وحسابات. خلّينا نبص للميه دقيقتين من غير حسابات. # speaker:amgad # duration:6
- else: الراديو عند الحلاق شغّال من الصبح.. لسه الأغنية في ودني لحد دلوقتي. # speaker:amgad # duration:6
}
-> END
