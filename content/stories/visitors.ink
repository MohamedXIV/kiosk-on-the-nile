INCLUDE context.inkinc
{mode == 3:
 واحد {order_label} من إيدك يا معلم. # speaker:{character_id} # duration:4
 -> END
}
{mode == 2:
 {quality_score == 3:
  الله ينور يا معلم! تسلم إيدك والله. # speaker:{character_id} # duration:5
 - else:
  تسلم يا غالي، تعيش. # speaker:{character_id} # duration:5
 }
- else:
 {character_id:
 - "hassan":
  النيل بالليل ليه هيبة تانية.. ربنا يديم الستر والهدوء. # speaker:hassan # duration:5
 - "nadia":
  ريحة الكبدة الإسكندراني ما شاء الله مفحفحة! # speaker:nadia # duration:5
 - "passer":
  هوا النيل يرد الروح بعد يوم طويل. # speaker:passer # duration:5
 - else:
  مستني {order_label} على مهلك يا ريس. # speaker:{character_id} # duration:4.5
 }
}
-> END
