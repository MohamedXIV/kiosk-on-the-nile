VAR character_id = "fathi"
VAR emergency_label = "3.00"
VAR emergency_available = true
VAR emergency_reason = ""
ألو، معاك فتحي. قول لي يا معلم؛ نرتب الطلبات والمواعيد بهدوء. # speaker:{character_id} # duration:7
* [عايز أراجع اتفاق التوريد أو حسابي معاك.]
 نشوف السلة ومكان التخزين والميعاد وطريقة الدفع. ما فيش اتفاق إلا لما توافق على تفاصيله. # speaker:{character_id} # duration:7 # effect:supply\|manage
 -> END
* [أنا مزنوق ومحتاج لقمة آكلها على الحساب.]
 {emergency_available:
  أقدر أوصلك سندوتش كبدة بـ{emergency_label} جنيه على حسابك، من غير أجرة توصيل للحالة دي. ساندوتش واحد لحد ما تسدد القديم. تحب؟ # speaker:{character_id} # duration:8
  ** [موافق، وصل السندوتش وسجل ثمنه عليّ.]
  اتسجل طلبك؛ السندوتش وصلك في إيدك، وثمنه ظاهر في الدفتر. كل براحتك. # speaker:{character_id} # duration:7 # effect:supply\|emergency
  -> END
  ** [متشكر، خلينا دلوقتي من غير طلب.]
  ولا يهمك، ما اتسجلش عليك شيء. # speaker:{character_id} # duration:5
  -> END
 - else:
  {emergency_reason} # speaker:{character_id} # duration:7
  -> END
 }
* [هكلمك وقت تاني يا عم فتحي.]
 تنور في أي وقت يا ابني. # speaker:{character_id} # duration:5
 -> END
