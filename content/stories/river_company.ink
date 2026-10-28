INCLUDE context.inkinc
{line_variant:
- 0:
 حلوة القعدة بعيد عن زحمة الشارع. # speaker:amgad # duration:5 # effect:world\|peer_relation\|amgad\|hassan\|familiarity\|1 # effect:world\|peer_relation\|hassan\|amgad\|familiarity\|1 # loc:story.river_company.line_001
 أنا سايب الراديو بدوشته وجاي أسمع الميّه. # speaker:hassan # duration:5 # autonomous:river_ambient_end # loc:story.river_company.line_002
- else:
 شايف المركب اللي بعيد دي؟ ماشية على مهلها خالص. # speaker:hassan # duration:5 # effect:world\|peer_relation\|amgad\|hassan\|familiarity\|1 # effect:world\|peer_relation\|hassan\|amgad\|familiarity\|1 # loc:story.river_company.line_003
 ربنا يروّق بالنا زي صاحبها. # speaker:amgad # duration:5 # autonomous:river_ambient_end # loc:story.river_company.line_004
}
* [القعدة الحلوة بتحلى بأهلها. # loc:story.river_company.choice_001]
 تسلم يا معلم.. كفاية إن الواحد يلاقي حد يسمعه. # speaker:hassan # duration:5 # loc:story.river_company.line_005
 أهو كلمتين حلوين بيخففوا اليوم. # speaker:amgad # duration:5 # loc:story.river_company.line_006
 -> END
* [كنتوا بتحكوا عن إيه؟ # loc:story.river_company.choice_002]
 ولا حاجة كبيرة.. بنتكلم عن الهوا وهدوء المكان. # speaker:amgad # duration:5 # loc:story.river_company.line_007
 والفاصل اللي الواحد محتاجه بعد يوم طويل. # speaker:hassan # duration:5 # loc:story.river_company.line_008
 -> END
* [(أكتفي بالسماع من غير ما أتدخل) # loc:story.river_company.choice_003]
 -> river_ambient_end

=== river_ambient_end ===
 طيب نقعد شوية قبل ما الدنيا تسحبنا تاني. # speaker:amgad # duration:5 # loc:story.river_company.line_009
 لسه بدري.. نسيب الدقيقة تعدّي على مهلها. # speaker:hassan # duration:5 # loc:story.river_company.line_010
 -> END
