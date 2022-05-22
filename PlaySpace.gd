extends Node2D


#当点击发牌时，如果第n-1张牌还未到达targetpos
#在点击第n张牌时，n-1张牌会从第n张牌的startpos开始
#点了第n张牌时，n-1张牌的rect_position会突然变化
#因此startpos也变化
#问题出在rect_position而非startpos，reoganizehand中的rect_position
#发牌过程中当卡牌还没达到inhand状态时，t并不会被清零
#当卡牌未到inhand且仍然在翻转状态时，t清零后会重新翻转
#解决方案：在MoveDrawnCardToHand中加入一个新的计时参数t_draw定义scale

#先拖拽到放置区再发牌时，发牌顺序会改变，发牌后手牌重新组织错误


var CardBase = preload("res://Cards/Card.tscn")
var PlayerHand = preload("res://Cards/PlayerHand.gd")
var CardSlot = preload("res://Cards/CardSlot.tscn")
var CardSelect = []

onready var DeckSize = PlayerHand.SLAVECARDLIST.size()
"""
椭圆参数方程
x=acosθ,y=bsinθ
发牌过程中，当上一次旋转还没到达指定位置时，点击发牌
则上一张牌的位置会瞬间旋转达到下一次发牌应该旋转开头的位置
"""
#椭圆中心位置
onready var CenterCardOval = Vector2(0.5,1.35) * get_viewport().size
onready var hor_rad = get_viewport().size.x * 0.45
onready var ver_rad = get_viewport().size.y * 0.4
var angle = 0
var OvalAngleVector = Vector2()
var spread_rad = 0.15
var number_cards_in_hand = 1
var card_number = 0
var is_card_in_stage = false


enum{
	InHand
	OnStage
	InMouse
	FocusInHand
	MoveDrawnCardToHand
	ReorganiseHand
}

func _ready():
	randomize()
#	var newslot = CardSlot.instance()
#	newslot.rect_position = get_viewport_rect().size * 0.5
#	add_child(newslot)
	

func drawcard():
	if Input.is_action_just_pressed("click_left"):
		number_cards_in_hand = $Cards.get_child_count() + 1
		#不能用number_cards_in_hand/2 - 1/2可能是bug，不对，应该是数据类型的问题，1/2不是float型
		angle = deg2rad(90)-(number_cards_in_hand * 0.5 - 0.5)*spread_rad
		DeckSize = PlayerHand.SLAVECARDLIST.size()
#		angle = deg2rad(90) + 0.4
		var new_card = CardBase.instance()
		CardSelect = randi()%DeckSize
		new_card.card_name = PlayerHand.SLAVECARDLIST[CardSelect]
#		new_card.rect_position = get_global_mouse_position()
#		不再以鼠标的位置为起点，而是椭圆形分布
		#椭圆参数方程
		OvalAngleVector = Vector2(hor_rad * cos(angle),-ver_rad * sin(angle))
		new_card.startpos = $Deck.position
		new_card.targetpos = OvalAngleVector + CenterCardOval
		new_card.cardpos = new_card.targetpos #卡牌的默认位置（固定）
		new_card.startrot = 0
		new_card.targetrot = 90-rad2deg(angle)
#		new_card.rect_rotation = 90-rad2deg(angle)
		new_card.state = MoveDrawnCardToHand
		new_card.card_number = number_cards_in_hand-1
		new_card.number_cards_in_hand = number_cards_in_hand -1
		card_number = 0
		for Card in $Cards.get_children():
#			angle = deg2rad(90)+(number_cards_in_hand * 0.5 - 0.5)*spread_rad
			angle = deg2rad(90)+(number_cards_in_hand * 0.5 - 0.5 - card_number)*spread_rad
			OvalAngleVector = Vector2(hor_rad * cos(angle),-ver_rad * sin(angle))
			Card.startpos = Card.rect_position
			Card.t = 0
			Card.targetpos = OvalAngleVector + CenterCardOval
			Card.cardpos = Card.targetpos
			Card.startrot = Card.rect_rotation
#			angle -= spread_rad
			Card.targetrot = 90-rad2deg(angle)
			Card.card_number = card_number
			card_number += 1
#			Card.state = ReorganiseHand #点了下一张牌之后状态变更，卡牌不再翻转
			if Card.state == InHand:
				Card.t = 0
				Card.state = ReorganiseHand
#				Card.startpos = Card.rect_position
				Card.startscale = Card.rect_position
			elif Card.state == MoveDrawnCardToHand:
				Card.startpos = Card.rect_position
			Card.startscale = Card.rect_scale
			Card.number_cards_in_hand = number_cards_in_hand -1
		$Cards.add_child(new_card)
#		new_card.state = InHand
		PlayerHand.SLAVECARDLIST.erase(PlayerHand.SLAVECARDLIST[CardSelect])
		DeckSize -= 1
#		angle -= spread_rad
		number_cards_in_hand += 1
		return DeckSize
		
func ReParent(CardNumber):
	var Card = $Cards.get_child(CardNumber)
	$Cards.remove_child(Card)
	$CardsOnStage.add_child(Card)
	OrganiseHand()
	
func OrganiseHand():
	card_number = 0
	number_cards_in_hand = $Cards.get_child_count()
	for Card in $Cards.get_children():
			angle = deg2rad(90)+(number_cards_in_hand * 0.5 - 0.5 - card_number)*spread_rad
			OvalAngleVector = Vector2(hor_rad * cos(angle),-ver_rad * sin(angle))
			Card.startpos = Card.rect_position
			Card.t = 0
			Card.targetpos = OvalAngleVector + CenterCardOval
			Card.cardpos = Card.targetpos
			Card.startrot = Card.rect_rotation
			Card.targetrot = 90-rad2deg(angle)
			Card.card_number = card_number
			Card.number_cards_in_hand = number_cards_in_hand -1
			print(number_cards_in_hand)
			card_number += 1
			Card.t = 0
			Card.state = ReorganiseHand
			Card.startscale = Card.rect_position
			Card.startscale = Card.rect_scale
	
func _on_Restart_pressed():
	PlayerHand.SLAVECARDLIST.append_array(["Slave","Citizen","Emperor","Citizen","Citizen"])
	$Deck/DeckDraw.disabled = false
#	for Card in $Cards.get_children():
#		Card.queue_free()


#func _on_CardStage_area_entered(_area):
#	is_card_in_stage = true
#
#
#func _on_CardStage_area_exited(_area):
#	is_card_in_stage = false


func _on_Quit_pressed():
	get_tree().quit()
