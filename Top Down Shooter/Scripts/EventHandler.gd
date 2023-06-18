extends Node
var interpreter = {
	"widget_dying" = func(data):
		emit_signal("widget_dying",data.dying_widget,data.killing_widget),
	"widget_damaged" = func(data):
		emit_signal("widget_damaged",data.damaged_widget,data.source_widget,data.amount)
}
signal widget_dying(dying_widget,killing_widget)
signal widget_damaged(damaged_widget,source_widget,amount)

func TriggerEvent(event_name : String, data):
	interpreter[event_name].call(data)
