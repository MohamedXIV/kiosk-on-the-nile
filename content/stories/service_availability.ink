VAR character_id = "farid"
VAR order_label = ""
VAR kiosk_open = false
VAR request_can_prepare = true
VAR business_allowed = true
VAR line_variant = 0
VAR needs_hospitality = false
{needs_hospitality:
 كنت هطلب {order_label}.. بس بصراحة اللي معايا مش مكفّي النهاردة، ومكسوف أقولك. # speaker:{character_id} # duration:8 # loc:story.service_availability.015
 -> hospitality_request
}
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

=== hospitality_request ===
* {request_can_prepare && business_allowed} [يا راجل خليها علينا. # loc:story.service_availability.016]
 ربنا يكرمك يا صاحبي. هاقعد هنا وأستناك على مهلك. # speaker:{character_id} # duration:7 # effect:service\|accept_gift # loc:story.service_availability.017
 -> END
* {request_can_prepare && business_allowed} [ربنا الرزاق، أعمله لك وأنا مبسوط. # loc:story.service_availability.018]
 تسلم، وقفتك دي فارقة معايا. # speaker:{character_id} # duration:6 # effect:service\|accept_gift # loc:story.service_availability.019
 -> END
* {request_can_prepare && business_allowed} [ولا يهمك، إحنا أصحاب. # loc:story.service_availability.020]
 تعيش يا صاحبي، متشكر على ذوقك. # speaker:{character_id} # duration:6 # effect:service\|accept_gift # loc:story.service_availability.021
 -> END
* [والله يا صاحبي أنا كمان مزنوق، وعندي إيجار ومصاريف. # loc:story.service_availability.022]
 فاهمك والله، ولا تزعل نفسك. هاقعد معاك شوية وخلاص. # speaker:{character_id} # duration:7 # effect:service\|decline # loc:story.service_availability.023
 -> END
* {not request_can_prepare && business_allowed} [نفسي أعمله لك، بس المكونات ناقصة دلوقتي. # loc:story.service_availability.024]
 ولا يهمك، القعدة معاك تكفي. # speaker:{character_id} # duration:6 # effect:service\|decline # loc:story.service_availability.025
 -> END
* {not business_allowed} [النشاط موقوف لحد ما أسوّي المستحق، بس تقدر تقعد معانا. # loc:story.service_availability.026]
 ربنا يفكها علينا كلنا. أنا هاقعد أهو. # speaker:{character_id} # duration:6 # effect:service\|decline # loc:story.service_availability.027
 -> END
