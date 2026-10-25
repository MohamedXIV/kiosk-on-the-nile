VAR character_id = "farid"
VAR order_label = ""
VAR kiosk_open = false
VAR request_can_prepare = true
VAR business_allowed = true
VAR line_variant = 0
{kiosk_open:
 {line_variant:
 - 0: لما تكون فاضي، ممكن {order_label} على مهلك؟ # speaker:{character_id} # duration:7 # loc:story.service_availability.001
 - 1: أنا هقعد شوية.. ينفع تعمل لي {order_label}؟ # speaker:{character_id} # duration:7 # loc:story.service_availability.002
 - else: إيه الأخبار يا معلم؟ نفسي في {order_label} لو ينفع. # speaker:{character_id} # duration:7 # loc:story.service_availability.003
 }
- else:
 {line_variant:
 - 0: شغال يا معلم؟ اليافطة بتقول مقفول، بس قلت أسألك.. ينفع {order_label}؟ # speaker:{character_id} # duration:8 # loc:story.service_availability.004
 - 1: قافل ليه يا معلم؟ بتريح شوية؟ لو مش هعطلك، ممكن {order_label}؟ # speaker:{character_id} # duration:8 # loc:story.service_availability.005
 - else: مش عايز أقطع راحتك.. لو متاح تعمل {order_label} أستناك براحة. # speaker:{character_id} # duration:8 # loc:story.service_availability.006
 }
}
* {request_can_prepare && business_allowed} [طبعًا، أعمله لك. # loc:story.service_availability.007]
 تسلم يا صاحبي، وأنا هنا على مهلي. # speaker:{character_id} # duration:6 # effect:service\|accept # loc:story.service_availability.008
 -> END
* [كنت بروّق دماغي شوية، معلش نخليها بعدين. # loc:story.service_availability.009]
 ولا يهمك، خد راحتك. القعدة حلوة حتى من غير طلب. # speaker:{character_id} # duration:6 # effect:service\|decline # loc:story.service_availability.010
 -> END
* {not request_can_prepare && business_allowed} [محتاج أجيب طلبات الأول، المكونات ناقصة. # loc:story.service_availability.011]
 ربنا يعينك، نبقى نشوفها لما تجيب اللي ناقصك. # speaker:{character_id} # duration:6 # effect:service\|decline # loc:story.service_availability.012
 -> END

* {not business_allowed} [الحي موقف النشاط لحد ما أسوّي المستحق، لكن تقدر تقعد معانا.  # loc:story.service_availability.013]
 ولا يهمك. خلّص ورقك على مهلك، والقعدة موجودة. # speaker:{character_id} # duration:7 # effect:service\|decline # loc:story.service_availability.014
 -> END
