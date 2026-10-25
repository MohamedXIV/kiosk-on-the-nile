VAR character_id = "fathi"
VAR emergency_label = "3.00"
VAR emergency_available = true
VAR emergency_reason = ""
ألو، معاك فتحي. قول لي يا معلم؛ نرتب الطلبات والمواعيد بهدوء. # speaker:{character_id} # duration:7 # loc:story.supplier.greeting
* [عايز أراجع اتفاق التوريد أو حسابي معاك. # loc:story.supplier.manage_choice]
 نشوف السلة ومكان التخزين والميعاد وطريقة الدفع. ما فيش اتفاق إلا لما توافق على تفاصيله. # speaker:{character_id} # duration:7 # effect:supply\|manage # loc:story.supplier.manage_reply
 -> END
* [أنا مزنوق ومحتاج لقمة آكلها على الحساب. # loc:story.supplier.help_choice]
 {emergency_available:
  أقدر أوصلك سندوتش كبدة بـ{emergency_label} جنيه على حسابك، من غير أجرة توصيل للحالة دي. ساندوتش واحد لحد ما تسدد القديم. تحب؟ # speaker:{character_id} # duration:8 # loc:story.supplier.offer
  ** [موافق، وصل السندوتش وسجل ثمنه عليّ. # loc:story.supplier.accept_choice]
  اتسجل طلبك؛ السندوتش وصلك في إيدك، وثمنه ظاهر في الدفتر. كل براحتك. # speaker:{character_id} # duration:7 # effect:supply\|emergency # loc:story.supplier.accept_reply
  -> END
  ** [متشكر، خلينا دلوقتي من غير طلب. # loc:story.supplier.decline_choice]
  ولا يهمك، ما اتسجلش عليك شيء. # speaker:{character_id} # duration:5 # loc:story.supplier.decline_reply
  -> END
 - else:
  {emergency_reason} # speaker:{character_id} # duration:7 # loc:story.supplier.refusal
  -> END
 }
* [هكلمك وقت تاني يا عم فتحي. # loc:story.supplier.bye_choice]
 تنور في أي وقت يا ابني. # speaker:{character_id} # duration:5 # loc:story.supplier.bye_reply
 -> END
