Red/System [
	Title:   "Event! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %event.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

event: context [
	verbose: 0
	
	push: func [
		evt [red-event!]
	][	
		stack/push as red-value! evt
	]

	;-- Actions --
	
	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-point!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/make"]]

		as red-point! 0
	]
	
	form: func [
		evt		[red-event!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/form"]]
		
		string/concatenate-literal buffer "event"
		part - 5
	]
	
	mold: func [
		evt		[red-event!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/mold"]]

		form evt buffer arg part
	]
	
	eval-path: func [
		evt		[red-event!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			word [red-word!]
			sym	 [integer!]
	][
		if value <> null [fire [TO_ERROR(script invalid-path-set) path]]
		word: as red-word! element
		sym: symbol/resolve word/symbol
comment {		
		case [
			sym = words/type	[gui/get-event-type	  evt/msg]
			sym = words/face	[gui/get-event-face	  evt/msg]
			sym = words/window	[gui/get-event-window evt/msg]
			sym = words/offset	[gui/get-event-offset evt/msg]
			sym = words/key		[gui/get-event-key	  evt/msg]
			sym = words/flag	[gui/get-event-flag	  evt/msg]
			sym = words/code	[gui/get-event-code	  evt/msg]
		]
}
		as red-value! 0
	]
	
	init: does [
		datatype/register [
			TYPE_EVENT
			TYPE_VALUE
			"event!"
			;-- General actions --
			null			;make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			null			;compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]