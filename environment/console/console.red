Red [
	Title:	"Red console"
	Author: ["Nenad Rakocevic" "Kaj de Vos"]
	File: 	%console.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system-global [
	#if OS = 'Windows [
		#import [
			"kernel32.dll" stdcall [
				AttachConsole: 	 "AttachConsole" [
					processID		[integer!]
					return:			[integer!]
				]
				SetConsoleTitle: "SetConsoleTitleA" [
					title			[c-string!]
					return:			[integer!]
				]
			]
		]
	]
]

#include %input.red
#include %help.red

system/console: context [

	prompt: "red>> "
	history: make block! 200

	read-argument: routine [
		/local
			args [str-array!]
			str	 [red-string!]
	][
		if system/args-count <> 2 [
			SET_RETURN(none-value)
			exit
		]
		args: system/args-list + 1							;-- skip binary filename
		str: simple-io/read-txt args/item
		SET_RETURN(str)
	]

	init-console: routine [
		str [string!]
		/local
			ret
	][
		#if OS = 'Windows [
			;ret: AttachConsole -1
			;if zero? ret [print-line "ReadConsole failed!" halt]

			ret: SetConsoleTitle as c-string! string/rs-head str
			if zero? ret [print-line "SetConsoleTitle failed!" halt]
		]
	]

	count-delimiters: function [
		buffer	[string!]
		return: [block!]
	][
		list: copy [0 0]
		c: none

		foreach c buffer [
			case [
				escaped?	[escaped?: no]
				in-comment? [if c = #"^/" [in-comment?: no]]
				'else [
					switch c [
						#"^^" [escaped?: yes]
						#";"  [if all [zero? list/2 not in-string?][in-comment?: yes]]
						#"["  [unless in-string? [list/1: list/1 + 1]]
						#"]"  [unless in-string? [list/1: list/1 - 1]]
						#"^"" [if zero? list/2 [in-string?: not in-string?]]
						#"{"  [if zero? list/2 [in-string?: yes] list/2: list/2 + 1]
						#"}"  [if 1 = list/2   [in-string?: no]  list/2: list/2 - 1]
					]
				]
			]
		]
		list
	]

	run: function [][
		buffer: make string! 10000
		cue:    none
		mode:   'mono

		switch-mode: [
			mode: case [
				cnt/1 > 0 ['block]
				cnt/2 > 0 ['string]
				'else 	  [
					do eval
					'mono
				]
			]
			cue: switch mode [
				block  ["[    "]
				string ["{    "]
				mono   [none]
			]
		]

		eval: [
			if error? code: try [load/all buffer][print code]
			
			unless any [error? code tail? code][
				set/any 'result try/all code
				
				case [
					error? :result [
						print result
					]
					not unset? :result [
						if 67 = length? result: mold/part :result 67 [	;-- optimized for width = 72
							clear back tail result
							append result "..."
						]
						print ["==" result]
					]
				]
				unless last-lf? [prin lf]
			]
			clear buffer
		]

		forever [
			line: ask any [cue prompt]
			
			unless tail? line [
				either all [not empty? line escape = last line][
					cue: none
					clear buffer
					mode: 'mono							;-- force exit from multiline mode
					print "(escape)"
				][
					append buffer line
					cnt: count-delimiters buffer
					append buffer lf					;-- needed for multiline modes

					switch mode [
						block  [if cnt/1 <= 0 [do switch-mode]]
						string [if cnt/2 <= 0 [do switch-mode]]
						mono   [do either any [cnt/1 > 0 cnt/2 > 0][switch-mode][eval]]
					]
				]
			]
		]
	]
	
	launch: function [][
		if script: read-argument [
			script: load script
			either any [
				not script/1 == 'Red
				not block? script/2 
			][
				print "*** Error: not a Red program!"
			][
				do skip script 2
			]
			quit
		]

		if system/platform = 'Windows [init-console "Red Console"]

		print [
			"--== Red" system/version "==--" lf
			"Type HELP for starting information." lf
		]
		run
	]
]

q: :quit

system/console/launch