class_name CommerceContentValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 if not bundle.get("shops") is Dictionary or not bundle.shops.get("shops") is Dictionary or not ContentValidation.bounded(bundle.shops.get("restock_minutes"),0,1439):return ContentValidation.fail("shops")
 for shop_id in bundle.shops.shops:
  var shop: Variant=bundle.shops.shops[shop_id]
  if not shop is Dictionary or not shop.get("label") is String or not shop.get("stock") is Dictionary or not shop.get("offers") is Dictionary:return ContentValidation.fail("shops."+shop_id)
  for id in shop.stock:
   if not bundle.items.has(id) or not ContentValidation.integer(shop.stock[id]) or shop.stock[id]<1:return ContentValidation.fail("shops.stock")
  for offer_id in shop.offers:
   var offer: Variant=shop.offers[offer_id]
   if not offer is Dictionary or not offer.get("label") is String or not offer.get("description") is String or not ContentValidation.integer(offer.get("price_minor")) or offer.price_minor<1 or not offer.get("contents") is Array or offer.contents.is_empty():return ContentValidation.fail("shops.offer")
   for part in offer.contents:
    if not part is Dictionary or not shop.stock.has(str(part.get("definition_id",""))) or not ContentValidation.integer(part.get("quantity")) or part.quantity<1:return ContentValidation.fail("shops.contents")
   if offer.has("required_fact") and not offer.required_fact in bundle.social.facts:return ContentValidation.fail("shops.fact")
   if offer.has("unique_owned_definition") and not bundle.items.has(offer.unique_owned_definition):return ContentValidation.fail("shops.unique")
 return ActionResult.success()
