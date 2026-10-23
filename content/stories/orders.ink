INCLUDE context.inkinc
{order_label == "": -> END}
{mode == 5: -> announcement}
{mode == 7: -> waiting}
-> recall
=== announcement ===
{character_id:
- "amgad": لما تفضى يا ابني، اعملي {order_label} على مهلك. # speaker:amgad # duration:7
- "nadia": لو سمحت يا معلم، عايزة {order_label} قبل ما أروّح. # speaker:nadia # duration:7
- "farid": اعملنا {order_label} يا ريس، وأنا أريح ضهري شوية. # speaker:farid # duration:7
- "salma": ممكن {order_label} لو سمحت؟ القعدة هنا تفتح النفس. # speaker:salma # duration:7
- "youssef": {order_label} يا معلم.. يمكن المخ يفوق شوية. # speaker:youssef # duration:7
- "hassan": أستأذنك في {order_label}، وإحنا مش مستعجلين. # speaker:hassan # duration:7
- "mahmoud": واحد {order_label} يا صاحبي، وخلّي سمير يهدي أعصابه. # speaker:mahmoud # duration:7
- "samir": أنا هاخد {order_label}.. سيبك من كلام محمود! # speaker:samir # duration:7
- else: مساء الخير، ممكن {order_label} على مهلك؟ # speaker:{character_id} # duration:7
}
-> END
=== recall ===
{character_id:
- "amgad":
 {line_variant:
 - 0: ولا يهمك يا ابني، أنا طالب {order_label}. خد وقتك. # speaker:amgad # duration:7
 - 1: ربنا يعينك.. {order_label} يا حبيبي، مش مستعجل. # speaker:amgad # duration:7
 - else: {order_label} يا ابني. وأنا ساعات أنسى داخل الأوضة ليه أصلًا! # speaker:amgad # duration:7
 }
- "nadia":
 {line_variant:
 - 0: إنت لحقت تنسى؟ أنا عايزة {order_label} يا معلم! # speaker:nadia # duration:7
 - 1: {order_label} لو سمحت.. أهو أنا كمان نسيت كنت جاية أجيب إيه من السوق. # speaker:nadia # duration:8
 - else: ولا يهمك، {order_label}. ربنا يقوّيك. # speaker:nadia # duration:6
 }
- "farid":
 {line_variant:
 - 0: {order_label} يا ريس.. ما تودّيناش الورشة جعانين بقى! # speaker:farid # duration:7
 - 1: ولا يهمك، أنا طالب {order_label}. الواحد دماغه بتزحم ساعات. # speaker:farid # duration:7
 - else: {order_label} يا صاحبي. لسه فاكر أنا، اطمن! # speaker:farid # duration:6
 }
- "salma":
 {line_variant:
 - 0: أنا طلبت {order_label}، متشكرة إنك سألت. # speaker:salma # duration:6
 - 1: {order_label} لو سمحت.. مش هعمل لك امتحان فيه! # speaker:salma # duration:7
 - else: ربنا يعينك، {order_label}، وبراحتك خالص. # speaker:salma # duration:6
 }
- "youssef":
 {line_variant:
 - 0: {order_label} يا معلم. حلو، مش أنا لوحدي اللي بنسى! # speaker:youssef # duration:7
 - 1: أنا طالب {order_label}.. لو الامتحان جه بالسؤال ده أعدّي. # speaker:youssef # duration:7
 - else: ولا يهمك، {order_label} بس، خد وقتك. # speaker:youssef # duration:6
 }
- "hassan":
 {line_variant:
 - 0: {order_label} يا ابني.. السؤال أحسن من التخمين. # speaker:hassan # duration:7
 - 1: على مهلك، أنا طالب {order_label}. # speaker:hassan # duration:6
 - else: الذاكرة دي حكاية.. {order_label}، ربنا يدّيك الصحة. # speaker:hassan # duration:7
 }
- "mahmoud":
 {line_variant:
 - 0: {order_label} يا صاحبي. سمير هو اللي لخبطك بكلامه! # speaker:mahmoud # duration:7
 - 1: أنا طالب {order_label}، وفاكره من غير إعادة بطيئة أهو. # speaker:mahmoud # duration:7
 - else: {order_label} على مهلك، إحنا لسه بنتناقش. # speaker:mahmoud # duration:6
 }
- "samir":
 {line_variant:
 - 0: {order_label} يا معلم. ما تسمعش محمود لو قالك غير كده. # speaker:samir # duration:7
 - 1: ولا يهمك، أنا طالب {order_label}، ربنا يعينك علينا. # speaker:samir # duration:7
 - else: {order_label} يا صاحبي.. لسه فاكر طعمه من آخر مرة. # speaker:samir # duration:7
 }
- else:
 {line_variant:
 - 0: ولا يهمك، أنا طالب {order_label}. # speaker:{character_id} # duration:6
 - 1: ربنا يعينك، {order_label} لو سمحت. # speaker:{character_id} # duration:6
 - else: {order_label} يا معلم.. خد وقتك. # speaker:{character_id} # duration:6
 }
}
-> END
=== waiting ===
{line_variant:
- 0: {order_label} لما تفضى.. أنا لسه قاعد شوية. # speaker:{character_id} # duration:6
- 1: خُد نفسك يا معلم، وأنا مستني {order_label} على رواقة. # speaker:{character_id} # duration:6
- else: لو {order_label} مش متاح دلوقتي قولّي، مفيش مشكلة. # speaker:{character_id} # duration:6
}
-> END
