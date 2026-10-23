VAR character_id = "farid"
VAR order_label = ""
VAR kiosk_open = false
VAR request_can_prepare = true
VAR line_variant = 0
{kiosk_open:
 {line_variant:
 - 0: لما تكون فاضي، ممكن {order_label} على مهلك؟ # speaker:{character_id} # duration:7
 - 1: أنا هقعد شوية.. ينفع تعمل لي {order_label}؟ # speaker:{character_id} # duration:7
 - else: إيه الأخبار يا معلم؟ نفسي في {order_label} لو ينفع. # speaker:{character_id} # duration:7
 }
- else:
 {line_variant:
 - 0: شغال يا معلم؟ اليافطة بتقول مقفول، بس قلت أسألك.. ينفع {order_label}؟ # speaker:{character_id} # duration:8
 - 1: قافل ليه يا معلم؟ بتريح شوية؟ لو مش هعطلك، ممكن {order_label}؟ # speaker:{character_id} # duration:8
 - else: مش عايز أقطع راحتك.. لو متاح تعمل {order_label} أستناك براحة. # speaker:{character_id} # duration:8
 }
}
* {request_can_prepare} [طبعًا، أعمله لك.]
 تسلم يا صاحبي، وأنا هنا على مهلي. # speaker:{character_id} # duration:6 # effect:service\|accept
 -> END
* [كنت بروّق دماغي شوية، معلش نخليها بعدين.]
 ولا يهمك، خد راحتك. القعدة حلوة حتى من غير طلب. # speaker:{character_id} # duration:6 # effect:service\|decline
 -> END
* {not request_can_prepare} [محتاج أجيب طلبات الأول، المكونات ناقصة.]
 ربنا يعينك، نبقى نشوفها لما تجيب اللي ناقصك. # speaker:{character_id} # duration:6 # effect:service\|decline
 -> END
