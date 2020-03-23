extends Label

export var prefix := ""
export var postfix := ""

func update_text(txt):
    text = prefix + str(txt) + postfix
