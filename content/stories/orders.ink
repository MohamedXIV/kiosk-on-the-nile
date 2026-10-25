INCLUDE context.inkinc
{order_label == "": -> END}
{mode == 5: -> announcement}
{mode == 7: -> waiting}
-> recall
=== announcement ===
{character_id:
- "amgad": لما تفضى يا ابني، اعملي {order_label} على مهلك. # speaker:amgad # duration:7 # loc:story.orders.001
- "nadia": لو سمحت يا معلم، عايزة {order_label} قبل ما أروّح. # speaker:nadia # duration:7 # loc:story.orders.002
- "farid": اعملنا {order_label} يا ريس، وأنا أريح ضهري شوية. # speaker:farid # duration:7 # loc:story.orders.003
- "salma": ممكن {order_label} لو سمحت؟ القعدة هنا تفتح النفس. # speaker:salma # duration:7 # loc:story.orders.004
- "youssef": {order_label} يا معلم.. يمكن المخ يفوق شوية. # speaker:youssef # duration:7 # loc:story.orders.005
- "hassan": أستأذنك في {order_label}، وإحنا مش مستعجلين. # speaker:hassan # duration:7 # loc:story.orders.006
- "mahmoud": واحد {order_label} يا صاحبي، وخلّي سمير يهدي أعصابه. # speaker:mahmoud # duration:7 # loc:story.orders.007
- "samir": أنا هاخد {order_label}.. سيبك من كلام محمود! # speaker:samir # duration:7 # loc:story.orders.008
- else: مساء الخير، ممكن {order_label} على مهلك؟ # speaker:{character_id} # duration:7 # loc:story.orders.009
}
-> END
=== recall ===
{character_id:
- "amgad":
 {line_variant:
 - 0: ولا يهمك يا ابني، أنا طالب {order_label}. خد وقتك. # speaker:amgad # duration:7 # loc:story.orders.010
 - 1: ربنا يعينك.. {order_label} يا حبيبي، مش مستعجل. # speaker:amgad # duration:7 # loc:story.orders.011
 - else: {order_label} يا ابني. وأنا ساعات أنسى داخل الأوضة ليه أصلًا! # speaker:amgad # duration:7 # loc:story.orders.012
 }
- "nadia":
 {line_variant:
 - 0: إنت لحقت تنسى؟ أنا عايزة {order_label} يا معلم! # speaker:nadia # duration:7 # loc:story.orders.013
 - 1: {order_label} لو سمحت.. أهو أنا كمان نسيت كنت جاية أجيب إيه من السوق. # speaker:nadia # duration:8 # loc:story.orders.014
 - else: ولا يهمك، {order_label}. ربنا يقوّيك. # speaker:nadia # duration:6 # loc:story.orders.015
 }
- "farid":
 {line_variant:
 - 0: {order_label} يا ريس.. ما تودّيناش الورشة جعانين بقى! # speaker:farid # duration:7 # loc:story.orders.016
 - 1: ولا يهمك، أنا طالب {order_label}. الواحد دماغه بتزحم ساعات. # speaker:farid # duration:7 # loc:story.orders.017
 - else: {order_label} يا صاحبي. لسه فاكر أنا، اطمن! # speaker:farid # duration:6 # loc:story.orders.018
 }
- "salma":
 {line_variant:
 - 0: أنا طلبت {order_label}، متشكرة إنك سألت. # speaker:salma # duration:6 # loc:story.orders.019
 - 1: {order_label} لو سمحت.. مش هعمل لك امتحان فيه! # speaker:salma # duration:7 # loc:story.orders.020
 - else: ربنا يعينك، {order_label}، وبراحتك خالص. # speaker:salma # duration:6 # loc:story.orders.021
 }
- "youssef":
 {line_variant:
 - 0: {order_label} يا معلم. حلو، مش أنا لوحدي اللي بنسى! # speaker:youssef # duration:7 # loc:story.orders.022
 - 1: أنا طالب {order_label}.. لو الامتحان جه بالسؤال ده أعدّي. # speaker:youssef # duration:7 # loc:story.orders.023
 - else: ولا يهمك، {order_label} بس، خد وقتك. # speaker:youssef # duration:6 # loc:story.orders.024
 }
- "hassan":
 {line_variant:
 - 0: {order_label} يا ابني.. السؤال أحسن من التخمين. # speaker:hassan # duration:7 # loc:story.orders.025
 - 1: على مهلك، أنا طالب {order_label}. # speaker:hassan # duration:6 # loc:story.orders.026
 - else: الذاكرة دي حكاية.. {order_label}، ربنا يدّيك الصحة. # speaker:hassan # duration:7 # loc:story.orders.027
 }
- "mahmoud":
 {line_variant:
 - 0: {order_label} يا صاحبي. سمير هو اللي لخبطك بكلامه! # speaker:mahmoud # duration:7 # loc:story.orders.028
 - 1: أنا طالب {order_label}، وفاكره من غير إعادة بطيئة أهو. # speaker:mahmoud # duration:7 # loc:story.orders.029
 - else: {order_label} على مهلك، إحنا لسه بنتناقش. # speaker:mahmoud # duration:6 # loc:story.orders.030
 }
- "samir":
 {line_variant:
 - 0: {order_label} يا معلم. ما تسمعش محمود لو قالك غير كده. # speaker:samir # duration:7 # loc:story.orders.031
 - 1: ولا يهمك، أنا طالب {order_label}، ربنا يعينك علينا. # speaker:samir # duration:7 # loc:story.orders.032
 - else: {order_label} يا صاحبي.. لسه فاكر طعمه من آخر مرة. # speaker:samir # duration:7 # loc:story.orders.033
 }
- else:
 {line_variant:
 - 0: ولا يهمك، أنا طالب {order_label}. # speaker:{character_id} # duration:6 # loc:story.orders.034
 - 1: ربنا يعينك، {order_label} لو سمحت. # speaker:{character_id} # duration:6 # loc:story.orders.035
 - else: {order_label} يا معلم.. خد وقتك. # speaker:{character_id} # duration:6 # loc:story.orders.036
 }
}
-> END
=== waiting ===
{line_variant:
- 0: {order_label} لما تفضى.. أنا لسه قاعد شوية. # speaker:{character_id} # duration:6 # loc:story.orders.037
- 1: خُد نفسك يا معلم، وأنا مستني {order_label} على رواقة. # speaker:{character_id} # duration:6 # loc:story.orders.038
- else: لو {order_label} مش متاح دلوقتي قولّي، مفيش مشكلة. # speaker:{character_id} # duration:6 # loc:story.orders.039
}
-> END
