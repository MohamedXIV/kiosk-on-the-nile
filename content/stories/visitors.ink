INCLUDE context.inkinc
{mode == 1: -> arrival}
{mode == 2: -> served}
{mode == 3: -> waiting}
{mode == 4: -> ambient}
{topic_id == "memory": -> memory}
-> smalltalk
=== arrival ===
{character_id:
- "nadia":
 {line_variant:
 - 0: مساء الخير، سندوتش كبدة آخده معايا وأنا مروّحة لو سمحت. # speaker:nadia # duration:5
 - 1: إزيك يا معلم؟ واحد كبدة للسكة، مش هعطلك. # speaker:nadia # duration:5
 - else: لسه طالعة من عند أختي.. قلت آخد العشا من عندك. # speaker:nadia # duration:5
 }
- "farid":
 {line_variant:
 - 0: قفلت الورشة خلاص.. سندوتش كبدة وأنا واقف هنا أريح ضهري. # speaker:farid # duration:6
 - 1: واحد كبدة يا ريس، إيدي واجعاني من الشغل ومش قادر أطبخ. # speaker:farid # duration:6
 - else: مساء الخير. اعملنا سندوتش عشان نعرف نكمّل السكة. # speaker:farid # duration:5
 }
- "salma":
 {visit_count > 1:
  {line_variant:
  - 0: مساء الخير تاني. قلت أشرب الشاي هنا بدل زحمة البيت. # speaker:salma # duration:5
  - 1: مساء النور. النهاردة عايزة كوباية شاي من غير كراسات ولا تصحيح. # speaker:salma # duration:6
  - else: أهلًا يا معلم، لقيت الكرسي فاضي قلت دي علامة.. شاي لو سمحت. # speaker:salma # duration:6
  }
 - else:
  أنا سلمى، بادرّس في المدرسة اللي ورا. كوباية شاي وأقعد شوية لو سمحت. # speaker:salma # duration:6
 }
- "youssef":
 {line_variant:
 - 0: كوباية شاي يا معلم.. هراجع ورقتين قبل ما أروّح. # speaker:youssef # duration:5
 - 1: مساء الخير. شاي وأنا أستنى صاحبي، لو افتكر ييجي! # speaker:youssef # duration:5
 - else: خلصنا المحاضرات بالعافية.. شاي على رواقة بقى. # speaker:youssef # duration:5
 }
- else: -> END
}
-> END
=== served ===
{quality_score >= 2 && line_variant == 1:
 {character_id:
 - "nadia": حلو قوي، ده هيتاكل قبل ما أوصل البيت كده. # speaker:nadia # duration:5
 - "farid": تسلم يا ريس. نأكل بقى قبل ما حد يفتكر الشغل تاني. # speaker:farid # duration:5
 - "salma": ريحتها حلوة.. أهو وقت صغير لنفسي. # speaker:salma # duration:5
 - "youssef": كده نقدر نفتح الكتاب، أو نحاول يعني. # speaker:youssef # duration:5
 - else: على كده الواحد يقعد دقيقتين كمان. تسلم. # speaker:{character_id} # duration:5
 }
 -> END
}
{quality_score >= 2 && line_variant == 2:
 {character_id:
 - "nadia": ربنا يبارك لك، وفّرت عليّا طبخة النهاردة. # speaker:nadia # duration:5
 - "farid": الله يفتح عليك. أحلى من العشا وأنا لوحدي في الورشة. # speaker:farid # duration:5
 - "salma": متشكرة، الشاي مع النسمة دي حكاية تانية. # speaker:salma # duration:5
 - "youssef": تسلم.. كده القعدة مش ناقصها حاجة. # speaker:youssef # duration:5
 - else: الله ينور، متشكر على تعبك. # speaker:{character_id} # duration:5
 }
 -> END
}
{quality_score >= 2:
 {character_id:
 - "nadia": تسلم إيدك. كده العشا اتظبط، أشوفك على خير. # speaker:nadia # duration:5
 - "farid": الله ينور يا ريس.. أهو ده مسك الختام بعد الورشة. # speaker:farid # duration:5
 - "salma": متشكرة، هاشربها قبل ما أبص في كراسات التصحيح. # speaker:salma # duration:5
 - "youssef": دي جت في وقتها، يمكن المخ يشتغل! # speaker:youssef # duration:5
 - "hassan": تسلم إيدك. هاشربها وأنا باصص للناحية التانية. # speaker:hassan # duration:5
 - "mahmoud": كوباية تروق الأعصاب بعد الماتش ده. # speaker:mahmoud # duration:5
 - "samir": تسلم يا معلم.. نتعشى وننسى الكورة شوية. # speaker:samir # duration:5
 - else: متشكر، تسلم إيدك. # speaker:{character_id} # duration:4
 }
- else:
 {line_variant:
 - 0: تسلم.. يمكن محتاجة تتظبط شوية المرة الجاية. # speaker:{character_id} # duration:5
 - 1: متشكر يا معلم. كل يوم وليه ظروفه. # speaker:{character_id} # duration:5
 - else: تعيش. خد نفسك إنت كمان لو يومك متعب. # speaker:{character_id} # duration:5
 }
}
-> END
=== waiting ===
{line_variant:
- 0: على مهلك.. بس افتكر طلبي لما تفضى. # speaker:{character_id} # duration:4.5
- 1: لسه فاكرني يا معلم؟ أنا واقف هنا. # speaker:{character_id} # duration:4.5
- else: لو الخامات خلصت قولّي، مفيش مشكلة. # speaker:{character_id} # duration:4.5
}
-> END
=== memory ===
{previous_food == "tea":
 {previous_quality >= 2:
  الشاي بتاع آخر مرة كان مظبوط. عشان كده قلت أعدّي تاني. # speaker:{character_id} # duration:6
 - else:
  الشاي آخر مرة ما كانش على مزاجي قوي.. نجرب تاني النهاردة. # speaker:{character_id} # duration:6
 }
- else:
 {previous_quality >= 2:
  السندوتش بتاع المرة اللي فاتت كان حلو.. افتكرته وأنا معدّي. # speaker:{character_id} # duration:6
 - else:
  آخر سندوتش كان محتاج يتظبط شوية، بس كلنا عندنا أيام متعبة. # speaker:{character_id} # duration:6
 }
}
-> END
=== ambient ===
{character_id:
- "mona":
 {line_variant:
 - 0: شايفين الفلوكة الصغيرة دي؟ لسه كانت عند الكوبري من شوية. # speaker:mona # duration:6
 - 1: الهوا هنا أحسن من بلكونة البيت النهاردة. # speaker:mona # duration:5
 - else: خلاص هاقف دقيقتين كمان وبعدين أروّح. # speaker:mona # duration:5
 }
- "hassan":
 {line_variant:
 - 0: النيل بالليل ليه هيبة تانية. # speaker:hassan # duration:5
 - 1: المراكب شغالة لسه.. ربنا يرزق الناس كلها. # speaker:hassan # duration:5
 - else: النسمة اتغيّرت.. باين الليل هيبقى ألطف. # speaker:hassan # duration:5
 }
- "youssef":
 {line_variant:
 - 0: بقالي عشر دقايق في نفس الصفحة.. واضح إن المذاكرة خلصت النهاردة. # speaker:youssef # duration:6
 - 1: صاحبي ده لو قال خمس دقايق تبقى نص ساعة. # speaker:youssef # duration:5
 - else: يمكن أتمشى شوية بدل ما أفضل باصص في الورق. # speaker:youssef # duration:5
 }
- else:
 {line_variant:
 - 0: هوا النيل يرد الروح بعد يوم طويل. # speaker:{character_id} # duration:5
 - 1: مساء الخير على الناس الرايقة. # speaker:{character_id} # duration:4
 - else: لفة صغيرة ع الكورنيش ونروّح بقى. # speaker:{character_id} # duration:5
 }
}
-> END
=== smalltalk ===
{character_id:
- "nadia":
 {line_variant:
 - 0: أنا نادية، ساكنة في الشارع اللي ورا. ساعات باعدّي وأنا راجعة من عند أختي. # speaker:nadia # duration:6
 - 1: النهاردة كنت مستعجلة من الصبح.. أخيرًا لقيت عشر دقايق لنفسي. # speaker:nadia # duration:6
 - else: ريحة الأكل بتوصل لحد أول الشارع.. ربنا يرزقك. # speaker:nadia # duration:5
 }
- "farid":
 {line_variant:
 - 0: أنا فريد، بتاع الورشة. طول اليوم دوشة مواتير.. هنا الواحد يسمع نفسه. # speaker:farid # duration:6
 - 1: غيرت سير مروحة عربية النهاردة.. ورجعت البيت لقيت مروحتي واقفة! # speaker:farid # duration:6
 - else: يومين وأقفل الورشة بدري، نفسي أشوف الغروب مرة. # speaker:farid # duration:6
 }
- "salma":
 {line_variant:
 - 0: آخر حصة النهاردة كانت رسمة عن النيل. كل طفل شايفه بطريقة. # speaker:salma # duration:6
 - 1: هصحح الكراسات بعدين.. مش لازم آخد المدرسة معايا كل حتة. # speaker:salma # duration:6
 - else: واحد من العيال رسم المركب أكبر من الكوبري.. يمكن عنده حق! # speaker:salma # duration:6
 }
- "mona":
 {line_variant:
 - 0: أنا منى، جارتكم من آخر الشارع. مش جاية أطلب، بس أحب أقف عند السور شوية. # speaker:mona # duration:6
 - 1: نزلت أجيب عيش ولفّيت اللفة الطويلة عشان أعدّي من هنا. # speaker:mona # duration:6
 - else: النهاردة مفيش مشاوير تاني.. أهو وقت صغير لنفسنا. # speaker:mona # duration:5
 }
- "youssef":
 {line_variant:
 - 0: أنا يوسف، في الجامعة. هنا الورق ما بيبانش تقيل زي أوضة المذاكرة. # speaker:youssef # duration:6
 - 1: الامتحان لسه عليه وقت.. أنا بس بحاول أقنع نفسي بكده. # speaker:youssef # duration:6
 - else: لما أخلّص امتحانات هاجي هنا من غير الشنطة دي خالص. # speaker:youssef # duration:6
 }
- "hassan":
 {line_variant:
 - 0: الناس بتناديني أستاذ حسن، مع إني بطلت شغل من سنين. الاسم فضل بس. # speaker:hassan # duration:6
 - 1: كنت باعدّي من هنا وأنا رايح الشغل زمان.. دلوقتي باجي من غير ميعاد. # speaker:hassan # duration:6
 - else: أحب القعدة اللي ما تحتاجش الواحد يتكلم فيها طول الوقت. # speaker:hassan # duration:6
 }
- "mahmoud":
 {line_variant:
 - 0: أنا وسمير بنختلف في كل حاجة إلا القعدة هنا. # speaker:mahmoud # duration:5
 - 1: ماتسمعش كلام سمير في الكورة.. بس صاحبي من أيام المدرسة. # speaker:mahmoud # duration:6
 - else: خلّينا في الشاي أحسن، الكورة تعبت أعصابنا كفاية. # speaker:mahmoud # duration:5
 }
- "samir":
 {line_variant:
 - 0: محمود لو فريقه خسر يلوم أي حاجة إلا الفريق. # speaker:samir # duration:5
 - 1: أنا جاي للقعدة والأكل.. خناقة الكورة بتيجي لوحدها. # speaker:samir # duration:5
 - else: النهاردة هاروّح بدري، عندي مشوار الصبح. # speaker:samir # duration:5
 }
- else:
 {hour < 18:
  الشارع لسه زحمة.. هوا النيل أحسن من الوقفة عند الإشارة. # speaker:{character_id} # duration:6
 - else:
  لفة ع الكورنيش قبل البيت.. الواحد محتاج يهدى شوية. # speaker:{character_id} # duration:5
 }
}
-> END
