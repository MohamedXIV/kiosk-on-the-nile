INCLUDE context.inkinc
{ mode == 1:
 {amgad_visits <= 1:
  مساء الفل يا ابني.. اعملنا كوباية شاي من إيدك نفتح بيها القعدة. # speaker:amgad # duration:6
 - else:
  مساء الجمال! الشاي بتاع المرة اللي فاتت كان {last_served_quality}.. صبّلي واحد زيه وتعالى أقولك على مصلحة. # speaker:amgad # duration:7
 }
 -> END
}
{ mode == 2:
 {day >= 2 && not known_cheap_fan:
  تسلم إيدك! قرّب كلمني [E] عايز أقولك على مروحة لقطة لأوضة السطح. # speaker:amgad # duration:7
 - else:
  أحلى كوباية شاي ع النيل.. تسلم إيدك يا معلم. # speaker:amgad # duration:5.5
 }
 -> END
}
{day == 1: -> first_talk}
-> referral
=== first_talk ===
{familiar:
 منور يا صاحبي، بقينا عارفين مزاج بعض. # speaker:amgad # duration:4
}
 الجو ع النيل النهاردة يرد الروح.. الواحد بيهرب من زحمة المكتب هنا. # speaker:amgad # duration:5.5
 * [نورت الكشك يا عم أمجد]
  ده منور بأصحابه يا ابني والله. # speaker:amgad # duration:5.5 # effect:mood\|4
 * [ربنا يعينك ع الشغل]
  يارب يا حبيبي، لقمة العيش عايزة صبر. # speaker:amgad # duration:5.5 # effect:mood\|3
 * [(ابتسم واسمعه بهدوء)]
  أحلى حاجة هنا الهدوء ده. # speaker:amgad # duration:5.5 # effect:mood\|3
 - -> END
=== referral ===
 {known_cheap_fan:
  لسه فاكر المروحة؟ عم سعيد مستنيك، براحتك يا بطل. # speaker:amgad # duration:5.5
 - else:
  بقولك إيه.. عم سعيد الكهربائي اللي ورا المحطة عنده مروحة ستاند نضيفة بـ {fan_price_label} جنيه لو قولتله من طرفي! # speaker:amgad # duration:7.5 # effect:learn\|KNOWN_CHEAP_FAN\|معرفة من عم أمجد: مروحة ستاند مستعملة عند عم سعيد؛ اطلبها من تليفون الكشك.
 }
 * [تسلم يا عم أمجد، الأوضة فعلاً حر بالليل!]
  توكل على الله، المروحة هتفرق معاك في نومة السطح. # speaker:amgad # duration:5.5 # effect:mood\|6
 * [ربنا يسهل لما أجمع تمنها]
  براحتك يا بطل، أنا قولت أبلغك عشان لقطة. # speaker:amgad # duration:5.5 # effect:mood\|3
 - -> END
