class_name DestinationArt
extends RefCounted
## Visual identifiers only; TravelService still decides all legal routes.
const ATLAS=preload("res://assets/ui/nile/destinations.svg")
const CELLS := {"market":0,"appliances":1,"homewares":2,"district":3,"supplier":4,"to_rooftop":5,"to_kiosk":6}
static func texture(route: String) -> Texture2D:
 if not CELLS.has(route):return CozyTheme.icon_texture("outings")
 var index: int=CELLS[route]
 var image := AtlasTexture.new()
 image.atlas=ATLAS
 image.region=Rect2(index%4*96,floori(float(index)/4)*72,96,72)
 image.filter_clip=true
 return image
static func view(route: String,extent: Vector2=Vector2(88,66)) -> TextureRect:
 var art := TextureRect.new()
 art.texture=texture(route)
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size=extent
 art.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return art
