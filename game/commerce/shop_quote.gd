class_name ShopQuote
extends RefCounted
var id: String
var shop_id: String
var offer_revision: int
var lines: Array[Dictionary]=[]
var total_minor: int=0
func snapshot() -> Dictionary:
 return {"id":id,"shop_id":shop_id,"offer_revision":offer_revision,"lines":lines.duplicate(true),"total_minor":total_minor}
