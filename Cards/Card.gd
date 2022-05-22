extends MarginContainer

#两种方法
#鼠标放在卡牌上时周围卡牌移开（已实现
#鼠标放在卡牌上时，卡牌出现在最上层（暂未实现

#第一张和第二张牌会直接瞬移到位而不是慢慢滑过去
#已解决，MoveNeighbourCard函数中的Isfocus前没加neighbour
#同时resetcard函数的isfocus前也没加neighbour导致瞬间移动回去

#聚焦一张卡牌时，再把鼠标放在其他卡牌上时会失灵
#moveneighbor和resetcard会有冲突
#在resetcard中加上if state != FocusInHand
#同时在_on_TextureButton_mouse_entered()中添加FocusInHand

#当从卡牌直接点击到卡牌上时，假设移动到第n张卡牌，n-1张卡牌并不会向左移动
#反而会向右一些
#因为第n-1张牌实际上同时进行了resetcard和moveneighbour的动作
#加上一个isneighbourmove的参数，当moveneighbour时将其设置为true
#当isneighbourmove为false时才执行resetcard
#也就是移动到n时n-1被设置为true不执行reset
#这样就不会执行reset了，所以在ReorganiseHand中再将isneighbourmove设置为false
#n-1在鼠标放在n上时isneighbourmove为true，在移开时变为false

#产生新bug:发牌时瞬移，只有第n-1张牌逐帧移动，其他都瞬移
#因为在ReorganiseHand的else中将t = 0删除，放进了isfocus中
#所以卡牌直接跳进else，在InHand（已验证）加入isfocus = true
#或者PlaySpace的循环中加入t = 0,在此处加入t = 0会导致在途中的卡牌重新翻转
#所以可以在PlaySpace循环的Card.state = InHand中加入Card.t = 0

#预计效果：卡牌拖进放置区松开鼠标卡牌停留、放置区卡牌可拖拽、拖拽完成返回放置区
#卡牌进入放置区再发牌会旋转
#因为onstage中都rect_rotation写的是+=模式而非=，每次t都会被重置
#加上判断当rect_rotation是否大于等于或小于等于0，让rect_rotation始终等于0

#当第n张牌放置在放置区时，拖曳第n+1张牌，已放置的所有卡牌都会到达鼠标位置
#当返回鼠标位置之后第一次点击，并不能让该卡牌进入inmouse状态(已解决，不知道怎么解决的
#目前可以做到将卡牌放在放置区静止不动且无法拖曳而不产生任何bug
#解决放置区卡牌会达到鼠标位置的问题
#解决点击非卡牌位置放置区卡牌会达到鼠标的问题
#在卡牌区域添加参数mouse_entered，只有当鼠标位于卡牌区域时才可以点击卡牌
#点击卡牌时仅仅考虑单张选中卡牌,也可以直接写状态，当mouse_entered状态改变时只能改变单张卡牌

#发牌时如果将鼠标放在某张牌上之后，后续发牌时该卡牌scale会变化，猜测和t有关
#改变了该牌的state，当鼠标放上去时state变为focusinhand，将其变为inhand即可
#inhand中setup = true
#inhand中加入setup也并不能完全解决，因为在发下一张牌时state未必为inhand
#正确解决方法为在playspace的循环中加入Card.startscale = Card.rect_scale
#任何状态下都让startscale等于当前scale

#number_cards_in_hand错误，每张卡片第二次focus才可以显示正确手牌数量，第一次总为0
#在发牌阶段的PlaySpace中的for循环中直接传递，而非在focus中传递


onready var CardDB = preload("res://CardDataBase.gd")
var card_name = "Emperor"
onready var CardInfo = CardDB.DATA[CardDB.get(card_name)]
onready var CardImg = str("res://Asset/") + CardInfo[1] + str(".png")

enum{
	InHand
	OnStage
	InMouse
	FocusInHand
	MoveDrawnCardToHand
	ReorganiseHand
	ForceOnStage
}
var state = InHand
var startpos = Vector2()
var targetpos = Vector2()
var cardpos = Vector2()
var startrot = 0
var targetrot = 0
var t = 0
var t_draw = 0
var DRAWNTIME = 0.5
var ORGANIZETIME = 0.5
var ZOOMTIME = 0.2
var setup = true
var isreorganiseneighbours = true
var isneighbourmove = false
var isplaced = false
var CARDSELECT = true
var mouse_entered = false
var startscale = Vector2()
var origscale = rect_scale
var zoomsize = 2
var number_cards_in_hand = 0
var card_number = 0
var neighbourcard
var spreadfactorsize = 50
var oldstate = INF
var card_on_stage = 0
#var mousepos = get_global_mouse_position()

func _ready():
#	var card_size = rect_size
#	$Border.scale *= card_size/$Border.texture.get_size()
	$Card.texture = load(CardImg)
	

func _input(event):
	match state:
		FocusInHand,OnStage:
			if event.is_action_pressed("click_left") and mouse_entered:
				if CARDSELECT:
#					if $"../".get_child(card_number).state == FocusInHand:
#						$"../".get_child(card_number).state = InMouse
#					if $"../".get_child(card_number).state == OnStage:
#						$"../".get_child(card_number).state = InMouse
					state = InMouse
					setup = true
					CARDSELECT = false

#		OnStage:
#			if event.is_action_pressed("click_left"):
#				state = InMouse
#				setup = true
#				CARDSELECT = false
		InMouse:
			if event.is_action_released("click_left"):#松开鼠标
				if !CARDSELECT:
#					CARDSELECT = true
					if oldstate == FocusInHand or OnStage:#将卡牌放进stage
#						var card_on_stage = $"../".get_child(card_number)
#						var CarOnStage = $"../.."/CarsOnStage
#						if card_on_stage.get_parent():
#							card_on_stage.get_parent().remove_child(card_on_stage)
#						CarOnStage.add_child(card_on_stage)
						setup = true
						oldstate = state
#						if $"../../".is_card_in_stage:
						var mousepos = get_global_mouse_position()
						if mousepos.x>0 and mousepos.x<1280 and\
						mousepos.y>250 and mousepos.y<450:#放置区域
							targetpos = get_viewport_rect().size * 0.5
							targetrot = 0
							setup = true
							$"../".get_child(card_number).isplaced = true
#							$"../../".ReParent()
#							card_on_stage = $"../".get_child(card_number)
#							var new_parent = get_parent().get_parent().get_child(3)
#							get_parent().remove_child(self)
#							new_parent.add_child(self)
#							var CarOnStage = $"../.."/CarsOnStage
#							if card_on_stage.get_parent():
#								card_on_stage.get_parent().remove_child(card_on_stage)
#							CarOnStage.add_child(card_on_stage)
							CARDSELECT = true
							state = OnStage
						else:#回到原位
							if isplaced:
								targetpos = get_viewport_rect().size * 0.5
								state = OnStage
								CARDSELECT = true
							else:
								setup = true
								targetpos = cardpos
								isplaced = false
								state = ReorganiseHand
								CARDSELECT = true

func _process(delta):
	match state:
		InHand:
			pass
		OnStage:
#			print(card_on_stage)
#			CARDSELECT = false
			oldstate = state
			if setup:
				Setup()
			if t <= 1:
				targetpos = get_viewport_rect().size * 0.5
#					state = OnStage
				rect_position = startpos.linear_interpolate(targetpos,t)
				rect_rotation += (targetrot - startrot) * delta/float(ORGANIZETIME)
				if targetrot - startrot <=0:
					if rect_rotation <=0:
						rect_rotation = 0
				else:
					if rect_rotation >=0:
						rect_rotation = 0
#				rect_rotation = startrot * (1-t) + targetrot*t
				rect_scale += (origscale - startscale) * delta/float(ORGANIZETIME)
				t += delta/float(ORGANIZETIME)
			else:
#				CARDSELECT = false
				rect_position = targetpos
				rect_rotation = 0
				rect_scale = origscale
		InMouse:
			if setup:
				Setup()
			if true:
				if t <= 1:
					rect_position = startpos.linear_interpolate(get_global_mouse_position(),t)
					rect_rotation += (0 - startrot) * delta/float(ZOOMTIME)
	#				rect_scale.x = abs(1 - 2 * t) * origscale.x
					rect_scale += (origscale - startscale) * delta/float(ZOOMTIME)
					if rect_scale <= origscale:
						rect_scale = origscale
	#				if rect_scale.x >= origscale.x:
	#					rect_scale.x = origscale.x
					if t>= 0.5:
						$CardBack.visible = false
	#				t_draw += delta/float(DRAWNTIME)#每一帧都插值，使得曲线平滑
					t += delta/float(ZOOMTIME)
				else:
	#				if oldstate != OnStage:
					rect_position = get_global_mouse_position()
					rect_rotation = 0
					rect_scale = origscale
		ReorganiseHand:
			if setup:
				Setup()
			if t <= 1:
				if isneighbourmove:
					isneighbourmove = false
#				if isplaced:
#					targetpos = get_viewport_rect().size * 0.5
#					state = OnStage
				rect_position = startpos.linear_interpolate(targetpos,t)
				rect_rotation += (targetrot - startrot) * delta/float(ORGANIZETIME)
#				rect_rotation = startrot * (1-t) + targetrot*t
				rect_scale += (origscale - startscale) * delta/float(ORGANIZETIME)
				t += delta/float(ORGANIZETIME)#每一帧都插值，使得曲线平滑
				if isreorganiseneighbours == false:
					isreorganiseneighbours = true
					if card_number - 1 >=0:
						ResetCard(card_number - 1)
					if card_number - 2 >=0:
						ResetCard(card_number - 2)
					if card_number + 1 <=number_cards_in_hand:
						ResetCard(card_number + 1)
					if card_number + 2 <=number_cards_in_hand:
						ResetCard(card_number + 2)
					
			else:
				rect_position = targetpos
				rect_rotation = targetrot
				rect_scale = origscale
				state = InHand
		FocusInHand:
			oldstate = state
			if setup:
				Setup()
			if t <= 1:
				rect_position = startpos.linear_interpolate(targetpos,t)
#				rect_rotation += (targetrot - startrot) * delta/float(ORGANIZETIME)
				rect_rotation = startrot * (1-t) + 0*t
				rect_scale += (origscale*zoomsize - startscale) * delta/float(ZOOMTIME)
				t += delta/float(ZOOMTIME)#每一帧都插值，使得曲线平滑
				if isreorganiseneighbours:
					isreorganiseneighbours = false
#					number_cards_in_hand = $"../..".number_cards_in_hand - 2
					if card_number - 1 >=0:
						MoveNeighbourCard(card_number - 1,true,1)
					if card_number - 2 >=0:
						MoveNeighbourCard(card_number - 2,true,0.25)
					if card_number + 1 <=number_cards_in_hand:
						MoveNeighbourCard(card_number + 1,false,1)
					if card_number + 2 <=number_cards_in_hand:
						MoveNeighbourCard(card_number + 2,false,0.25)
			else:
				rect_position = targetpos
				rect_rotation = 0
				rect_scale = origscale*zoomsize
#				setup = true
		MoveDrawnCardToHand:
			if t <= 1:
#				$CardBack.visible = true
				rect_position = startpos.linear_interpolate(targetpos,t)
				"""
				Vector2 linear_interpolate(to: Vector2, weight: float)

				返回这个向量与to之间线性插值的结果，插值量为weight。weight的范围是0.0到1.0，表示插值的数量。
				线性插值，从start到target，提供一个平滑的权重t，平滑的运动过去，我是这么理解的
				当权重weight等于1时，则到达target点，所以t<=1
				线性 直线

				"""
				#一共1/(delta/float(DRAWNTIME))帧，每帧旋转角度
				rect_rotation += (targetrot - startrot) * delta/float(DRAWNTIME)
				rect_scale.x = abs(1 - 2 * t_draw) * origscale.x
				if rect_scale.x >= origscale.x:
					rect_scale.x = origscale.x
				if t_draw >= 0.5:
					$CardBack.visible = false
				t_draw += delta/float(DRAWNTIME)#每一帧都插值，使得曲线平滑
				t += delta/float(DRAWNTIME)
			else:
				rect_position = targetpos
				rect_rotation = targetrot
				rect_scale = origscale
				t_draw = 0
				t = 0
				state = InHand
		ReorganiseHand:
			if state == InHand or MoveDrawnCardToHand or FocusInHand:
				if setup:
					Setup()
				if t <= 1:
#					setup = true
					if isneighbourmove:
						isneighbourmove = false
					rect_position = startpos.linear_interpolate(targetpos,t)
					rect_rotation += (targetrot - startrot) * delta/float(ORGANIZETIME)
	#				rect_rotation = startrot * (1-t) + targetrot*t
#					rect_scale += (origscale - startscale) * delta/float(ORGANIZETIME)
					rect_scale = startscale * (1-t) + origscale*t
					t += delta/float(ORGANIZETIME)#每一帧都插值，使得曲线平滑
					if isreorganiseneighbours == false:
						isreorganiseneighbours = true
						if card_number - 1 >=0:
							ResetCard(card_number - 1)
						if card_number - 2 >=0:
							ResetCard(card_number - 2)
						if card_number + 1 <=number_cards_in_hand:
							ResetCard(card_number + 1)
						if card_number + 2 <=number_cards_in_hand:
							ResetCard(card_number + 2)
						
				else:
					rect_position = targetpos
					rect_rotation = targetrot
					rect_scale = origscale
#					state = InHand


func Setup():
	startpos = rect_position
	startrot = rect_rotation
	startscale = rect_scale
	t = 0
	setup = false

func MoveNeighbourCard(cardnumber,IsLeft,Spreadfactor):
	neighbourcard = $"..".get_child(cardnumber)
	if neighbourcard.state != OnStage:
		if IsLeft == true:
			neighbourcard.targetpos.x = neighbourcard.cardpos.x - Spreadfactor*spreadfactorsize
		else:
			neighbourcard.targetpos.x = neighbourcard.cardpos.x + Spreadfactor*spreadfactorsize
		neighbourcard.state = ReorganiseHand
		neighbourcard.isneighbourmove = true
	neighbourcard.setup = true

func ResetCard(cardnumber):
	neighbourcard = $"../".get_child(cardnumber)
#	if neighbourcard.isneighbourmove:
#		neighbourcard.isneighbourmove = false
#	else:
	if neighbourcard.isneighbourmove == false and neighbourcard.state != OnStage:
#		neighbourcard = $"../".get_child(cardnumber)
		if neighbourcard.state != FocusInHand:
			neighbourcard.targetpos = neighbourcard.cardpos
			neighbourcard.state = ReorganiseHand
			neighbourcard.setup = true

func _on_TextureButton_mouse_entered():
	mouse_entered = true
	match state:
		InHand,ReorganiseHand:
			setup = true
			targetpos = cardpos
#			targetpos.y = cardpos.y - $Node2D/CardArea.rect_size.y/(zoomsize*2)
			targetpos.y = get_viewport_rect().size.y - \
			$Node2D/CardArea.rect_size.y*0.4*zoomsize/(2)#聚焦坐标固定为刚好底面为牌底
#			targetrot = 0
			state = FocusInHand
			mouse_entered = true
			print(number_cards_in_hand)
			print(card_number)


func _on_TextureButton_mouse_exited():
	mouse_entered = false
	if state == FocusInHand:
		setup = true
		targetpos.y = cardpos.y
		state = ReorganiseHand
		mouse_entered = false
#		targetrot = rect_rotation
