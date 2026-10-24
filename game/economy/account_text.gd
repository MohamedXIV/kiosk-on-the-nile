class_name AccountText
extends RefCounted
static func date(at: float) -> String:
 var minute := int(fposmod(at,1440))
 return "اليوم %d الساعة %02d:%02d" % [floori(at/1440)+1,minute/60,minute%60]
static func ledger(session: GameSession) -> String:
 var now := session.clock.world_minutes
 var week_start: float=floorf(now/10080.0)*10080.0
 var report := session.accounts.summary(week_start,week_start+20160)
 var lines := PackedStringArray(["نشاط الكشك: شغال" if report.business_allowed else "نشاط الكشك موقوف؛ سدّد مستحق الحي المطبق عليه الإيقاف."])
 for row in report.rows:
  var remaining := int(row.gross)-int(row.paid)
  var status := "مغطّى" if remaining==0 else "متأخر" if now>=float(row.due_at) else "قادم"
  lines.append("%s — %s\n%s · المتبقي %.2f ج.م · %s" % [row.label,row.creditor_name,status,float(remaining)/100.0,date(float(row.due_at))])
  if row.creditor=="district" and remaining>0:lines.append("آخر موعد قبل الإيقاف: "+date(float(row.enforce_at)))
 for promise in session.commitments.state.promises.values():
  lines.append("وعد السكن: %s · %s" % [promise.status,date(float(promise.deadline))])
 for loan in session.commitments.state.loans.values():
  lines.append("سلفة من %s: الأصل %.2f · المتبقي %.2f ج.م · %s" % [session.presence.profile(&"abdul_karim").name,float(loan.principal)/100.0,float(int(loan.principal)-int(loan.paid))/100.0,date(float(loan.due_at))])
 lines.append("الإيصالات:")
 for receipt in session.accounts.state.receipts.values():
  lines.append("%s · %s · %s\nالإجمالي %.2f ج.م" % [receipt.id,receipt.creditor_name,date(float(receipt.at)),float(receipt.net)/100.0])
  for line in receipt.lines:lines.append("%s → %s · أساسي %.2f − خصم %.2f = %.2f ج.م" % [date(float(line.start)),date(float(line.end)),float(line.gross)/100.0,float(line.discount)/100.0,float(line.net)/100.0])
 for receipt in session.commitments.state.receipts.values():lines.append("%s · %s · %s" % [receipt.id,date(float(receipt.at)),receipt.get("journal_text","")])
 return "\n\n".join(lines)
