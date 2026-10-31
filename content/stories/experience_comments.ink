INCLUDE context.inkinc
VAR comment_item = ""
VAR comment_food = ""
VAR comment_suggestion = ""
VAR comment_score = 0
عندي كلمة صغيرة عن المكان والأكل.. تحب تسمع؟ # speaker:{character_id} # duration:5 # policy_action:offer # effect:semantic\|offer # loc:story.experience_comments.invite
* [قول يا صاحبي، سامعك # policy_choice:listen # loc:story.experience_comments.listen]
 -> selected
* [معلش، مش وقت كلام دلوقتي # policy_choice:refuse # loc:story.experience_comments.refuse]
 -> END
* [نخليها وقت تاني على رواق # policy_choice:postpone # loc:story.experience_comments.postpone]
 -> END
=== selected ===
{topic_id:
- "notice": -> notice
- "taste": -> taste
- "suggestion": -> suggestion
- "improved": -> improved
- else: -> dirty
}
=== notice ===
إضافة {comment_item} هنا فكرة حلوة. # speaker:{character_id} # duration:7 # policy_action:record # effect:semantic\|record # loc:story.experience_comments.notice
-> END
=== suggestion ===
لو في يوم تقدر تزود {comment_suggestion} يبقى حلو.. براحتك، مفيش استعجال. # speaker:{character_id} # duration:7 # policy_action:record # effect:semantic\|record # loc:story.experience_comments.suggestion
-> END
=== dirty ===
الحتة اللي شايفها دي محتاجة اهتمام بالنظافة شوية. # speaker:{character_id} # duration:7 # policy_action:record # effect:semantic\|record # loc:story.experience_comments.dirty
-> END
=== improved ===
المكان أنضف من آخر مرة شفته فيها.. باين إنك واخد بالك. # speaker:{character_id} # duration:7 # policy_action:record # effect:semantic\|record # loc:story.experience_comments.improved
-> END
=== taste ===
{comment_score >= 70:
 فاكر {comment_food} اللي جربته عندك.. جاي على مزاجي. # speaker:{character_id} # duration:7 # policy_action:record # effect:semantic\|record # loc:story.experience_comments.taste_good
- else:
 جربت {comment_food} عندك، بس لسه مش جاي على مزاجي قوي. نجرب أظبط المرة الجاية. # speaker:{character_id} # duration:7 # policy_action:record # effect:semantic\|record # loc:story.experience_comments.taste_adjust
}
-> END
