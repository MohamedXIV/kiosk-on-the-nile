INCLUDE context.inkinc
{topic_id:
- "venue_improved": -> improved
- "venue_food_memory": -> food_memory
- else: -> dirty
}
=== dirty ===
{venue_dirty_category:
- "floor": خلي بالك من الأرض يا معلم، محتاجة تتنضف شوية. # speaker:{character_id} # duration:6 # loc:story.venue_comments.line_001
- "seating": القعدة دي محتاجة مسحة قبل ما حد يقعد عليها. # speaker:{character_id} # duration:6 # loc:story.venue_comments.line_002
- else: مكان التحضير اللي قدامي محتاج اهتمام بالنظافة شوية. # speaker:{character_id} # duration:6 # loc:story.venue_comments.line_003
}
-> END
=== improved ===
المكان أنضف من آخر مرة جيت فيها.. باين إنك واخد بالك منه. # speaker:{character_id} # duration:7 # loc:story.venue_comments.line_004
-> END
=== food_memory ===
{venue_previous_quality >= 2:
 لسه فاكر {venue_previous_food} اللي أخدته المرة اللي فاتت، كان حلو. # speaker:{character_id} # duration:7 # loc:story.venue_comments.line_005
- else:
 فاكر {venue_previous_food} اللي أخدته هنا، كان محتاج يتظبط شوية. نجرب أحسن المرة دي؟ # speaker:{character_id} # duration:7 # loc:story.venue_comments.line_006
}
-> END
