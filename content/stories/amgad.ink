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
 مساء الفل يا ابني.. كوباية شاي على مهلك، لسه قدامنا قعدة. # speaker:amgad # duration:6 # loc:story.amgad.line_001
- else:
 {line_variant:
 - 0: مساء الجمال! قلت أعدّي أشرب الشاي ع النيل قبل ما أروّح. # speaker:amgad # duration:6 # loc:story.amgad.line_002
 - 1: إزيك يا ابني؟ يوم المكتب خلص أخيرًا.. اعملنا شاي. # speaker:amgad # duration:6 # loc:story.amgad.line_003
 - else: مساء الخير على أهل الكشك. كوباية شاي وأنا أقعد أريح رجلي شوية. # speaker:amgad # duration:6 # loc:story.amgad.line_004
 }
}
-> END
=== served ===
{day >= 2 && not known_cheap_fan:
 تسلم إيدك. لما تفضى عايز أقولك على مروحة لأوضة السطح. # speaker:amgad # duration:6 # loc:story.amgad.line_005
- else:
 {line_variant:
 - 0: تسلم، آخد طلبي وأقعد على رواقة. # speaker:amgad # duration:5 # loc:story.amgad.received_0
 - 1: متشكر على تعبك يا ابني. # speaker:amgad # duration:5 # loc:story.amgad.received_1
 - else: الله يبارك لك، تسلم. # speaker:amgad # duration:5 # loc:story.amgad.received_2
 }
}
-> END
=== first_talk ===
أنا أمجد، شغال في المكتب اللي على أول الشارع. باعدّي هنا أفصل قبل البيت. # speaker:amgad # duration:6 # loc:story.amgad.line_010
* [تنور في أي وقت يا عم أمجد # loc:story.amgad.line_011]
 ربنا يكرمك. القعدة هنا تخلّي الواحد ينسى الزحمة شوية. # speaker:amgad # duration:5.5 # effect:mood\|4 # loc:story.amgad.line_012
* [ربنا يعينك ع الشغل # loc:story.amgad.line_013]
 ويعينك يا ابني.. كلنا بنحاول نروّح آخر اليوم رايقين. # speaker:amgad # duration:5.5 # effect:mood\|3 # loc:story.amgad.line_014
* [(ابتسم واسمعه بهدوء) # loc:story.amgad.line_015]
 أهو صوت الميه أريح من صوت التليفونات طول النهار. # speaker:amgad # duration:5.5 # effect:mood\|3 # loc:story.amgad.line_016
- -> END
=== referral ===
عم سعيد الكهربائي اللي ورا المحطة عنده مروحة ستاند مستعملة نضيفة بـ {fan_price_label} جنيه. قوله من طرفي؛ تقدر تطلبها من تليفون الكشك. # speaker:amgad # duration:9 # effect:learn\|KNOWN_CHEAP_FAN\|عم أمجد دلّني على مروحة ستاند مستعملة عند عم سعيد؛ أقدر أطلبها من تليفون الكشك. # loc:story.amgad.line_017
* [تسلم، أوضة السطح فعلًا حر بالليل # loc:story.amgad.line_018]
 ربنا يجعلها نومة مريحة. # speaker:amgad # duration:4.5 # effect:mood\|4 # loc:story.amgad.line_019
* [لما أجمع تمنها إن شاء الله # loc:story.amgad.line_020]
 براحتك يا ابني، مش مستعجلين. # speaker:amgad # duration:4.5 # loc:story.amgad.line_021
- -> END
=== fan_bought ===
عرفت إن المروحة وصلت! أخبار نومة السطح إيه دلوقتي؟ # speaker:amgad # duration:5.5 # loc:story.amgad.line_022
* [فرقت فعلًا، تسلم على المعرفة # loc:story.amgad.line_023]
 تتهنى بيها يا ابني. أهم حاجة الواحد يرتاح في بيته. # speaker:amgad # duration:5 # effect:mood\|3 # loc:story.amgad.line_024
* [لسه بجربها # loc:story.amgad.line_025]
 جرّبها براحتك، وعم سعيد قريب لو احتجت حاجة. # speaker:amgad # duration:5 # loc:story.amgad.line_026
- -> END
=== memory ===
{previous_quality >= 2:
 الشاي اللي شربته عندك المرة اللي فاتت كان مظبوط.. افتكرته وأنا لسه في المكتب. # speaker:amgad # duration:6 # loc:story.amgad.line_027
- else:
 فاكر الكوباية بتاعة المرة اللي فاتت؟ ما تشغلش بالك، كل يوم وليه ظروفه. # speaker:amgad # duration:6 # loc:story.amgad.line_028
}
-> END
=== smalltalk ===
{familiar:
 منور يا صاحبي، بقيت أعرف قعدتك من بعيد. # speaker:amgad # duration:4 # loc:story.amgad.line_029
}
{line_variant:
- 0:
 {hour < 18:
  الشارع زحمة دلوقتي.. هستنى شوية لحد ما يهدى. # speaker:amgad # duration:5 # loc:story.amgad.line_030
 - else:
  أحلى وقت لما الشمس تغيب والنسمة تبدأ تدخل. # speaker:amgad # duration:5 # loc:story.amgad.line_031
 }
- 1: كان يوم ورق وحسابات. خلّينا نبص للميه دقيقتين من غير حسابات. # speaker:amgad # duration:6 # loc:story.amgad.line_032
- else: الراديو عند الحلاق شغّال من الصبح.. لسه الأغنية في ودني لحد دلوقتي. # speaker:amgad # duration:6 # loc:story.amgad.line_033
}
-> END
