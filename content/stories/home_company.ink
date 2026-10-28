VAR character_id = "youssef"
VAR home_mode = "visit"
{home_mode:
- "invite":
 إنت بتعزمني أقعد معاك بكرة بعد الضهر؟ حلوة القعدة معاك، بس نخليها من غير التزامات. # speaker:{character_id} # duration:7 # loc:story.home_company.invite
 * [أهلا بيك بكرة، لو أنا في البيت والظروف سمحت. # loc:story.home_company.yes]
 حلوة القعدة معاك. أعدي بعد الضهر لحد بالليل لو لقينا بعض فاضيين، ومفيش أي استعجال. # speaker:{character_id} # duration:7 # effect:home\|invite # loc:story.home_company.accept
  -> END
 * [نخليها لوقت تاني، على راحتنا. # loc:story.home_company.later]
 براحتك خالص، مش محتاجة وعد. # speaker:{character_id} # duration:7 # loc:story.home_company.okay
  -> END
- "cancel":
 نأجل قعدة البيت لبعدين؟ مش عايز أوعدك وأنا مش متأكد. # speaker:{character_id} # duration:7 # loc:story.home_company.cancel
 * [أيوه، نخليها يوم تاني. # loc:story.home_company.cancel_yes]
 ولا يهمك، أهو نتقابل هنا على رواقة. # speaker:{character_id} # duration:7 # effect:home\|cancel # loc:story.home_company.cancelled
  -> END
 * [خلاص، نخلي القعدة زي ما اتفقنا. # loc:story.home_company.keep]
 تمام، لو الظروف سمحت نلاقي بعض. # speaker:{character_id} # duration:7 # loc:story.home_company.keep_reply
  -> END
- "goodbye":
 نكتفي بالقعدة الحلوة دي النهارده ونكمل مرة تانية؟ # speaker:{character_id} # duration:7 # loc:story.home_company.goodbye
 * [تنور في أي وقت، نكمل بعدين. # loc:story.home_company.bye_yes]
 ربنا يخليك. أنا أمشي على مهلي، ونشوف بعض على خير. # speaker:{character_id} # duration:7 # effect:home\|goodbye # loc:story.home_company.bye
  -> END
 * [لا، لسه بدري؛ خد راحتك. # loc:story.home_company.stay]
 متشكر، أهو وقت رايق. # speaker:{character_id} # duration:7 # loc:story.home_company.stay_reply
  -> END
- else:
 {character_id:
 - "farid":تسلم على القعدة. الواحد مش كل مرة لازم يكون جاي لحساب ولا شغل؛ ساعات كلمة حلوة وكوباية ميه يكفوا. # speaker:{character_id} # duration:7 # effect:home\|heard # loc:story.home_company.visit_farid
 - else:حلو إني أقعد مع حد من غير طلب ولا حاجة مطلوب أخلصها. نسمع الهوا وندردش، ولو محتاج تسكت أنا معاك. # speaker:{character_id} # duration:7 # effect:home\|heard # loc:story.home_company.visit_youssef
 }
 -> END
}
