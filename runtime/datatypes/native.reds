Red/System [
	Title:   "Native! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %native.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

native: context [
	verbose: 0
	
	preprocess-options: func [							;-- cache optional typesets for native calls
		args	  [red-block!]
		native	  [red-native!]
		path	  [red-path!]
		pos		  [red-value!]
		list	  [node!]
		fname	  [red-word!]
		value	  [red-value!]
		tail	  [red-value!]
		/local	
			base	  [red-value!]
			head	  [red-value!]
			end		  [red-value!]
			word	  [red-word!]
			ref		  [red-refinement!]
			blk		  [red-value!]
			vec		  [red-vector!]
			bool	  [red-logic!]
			s		  [series!]
			ref-array [int-ptr!]
			saved	  [node!]
			index	  [integer!]
			offset	  [integer!]
			ref?	  [logic!]
	][
		s: GET_BUFFER(args)
		vec: vector/clone as red-vector! s/tail - 1
		saved: vec/node
		s/tail: s/tail - 2								;-- clear the vector record
		
		s: as series! native/spec/value
		base:	s/offset
		head:	base
		end:	s/tail
		offset: 0

		while [all [base < end TYPE_OF(base) <> TYPE_REFINEMENT]][
			switch TYPE_OF(base) [
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_LIT_WORD [offset: offset + 1]
				default [0]
			]
			base: base + 1
		]
		if base = end [fire [TO_ERROR(script bad-refines) fname as red-word! pos]]

		s: GET_BUFFER(vec)
		ref-array: as int-ptr! s/offset

		while [value < tail][
			if TYPE_OF(value) <> TYPE_WORD [
				fire [TO_ERROR(script bad-refines) fname as red-word! value]
			]
			word:  as red-word! value
			head:  base
			ref?:  no
			index: 1

			while [head < end][
				switch TYPE_OF(head) [
					TYPE_WORD
					TYPE_GET_WORD
					TYPE_LIT_WORD [
						if ref? [
							block/rs-append args head
							blk: head + 1
							either all [
								blk < end
								TYPE_OF(blk) = TYPE_BLOCK
							][
								typeset/make-in args as red-block! blk
							][
								typeset/make-default args
							]
							offset: offset + 1
						]
					]
					TYPE_REFINEMENT [
						ref: as red-refinement! head
						either EQUAL_WORDS?(ref word) [
							ref-array/index: offset
							ref?: yes
						][
							ref?: no
						]
						index: index + 1
					]
					TYPE_SET_WORD [head: end]
					default [0]							;-- ignore other values
				]
				head: head + 1 
			]
			value: value + 1
		]
		
		block/rs-append args as red-value! none-value	;-- restore vector record
		
		vec: as red-vector! ALLOC_TAIL(args)
		vec/header: TYPE_VECTOR							;-- implicit reset of all header flags
		vec/head: 	0
		vec/node: 	saved
		vec/type:	TYPE_INTEGER
	]
	
	push: func [
		/local
			cell  [red-native!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/push"]]
		
		cell: as red-native! stack/push*
		cell/header: TYPE_NATIVE
		;...TBD
	]
	
	;-- Actions -- 
	
	make: func [
		proto	   [red-value!]
		spec	   [red-block!]
		return:    [red-native!]						;-- return native cell pointer
		/local
			native [red-native!]
			s	   [series!]
			index  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/make"]]
		
		assert TYPE_OF(spec) = TYPE_BLOCK
		s: GET_BUFFER(spec)
		spec: as red-block! s/offset

		native: as red-native! stack/push*
		native/header:  TYPE_NATIVE						;-- implicit reset of all header flags
		native/spec:    spec/node						; @@ copy spec block if not at head
		native/args:	null
		
		index: integer/get s/offset + 1
		native/code: natives/table/index
		native
	]
	
	reflect: func [
		native	[red-native!]
		field	[integer!]
		return:	[red-block!]
		/local
			blk [red-block!]
	][
		case [
			field = words/spec [
				blk: as red-block! stack/arguments
				blk/header: TYPE_BLOCK					;-- implicit reset of all header flags
				blk/node:	native/spec
				blk/head:	0
			]
			field = words/words [
				--NOT_IMPLEMENTED--						;@@ build the words block from spec
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		blk												;@@ TBD: remove it when all cases implemented
	]
	
	form: func [
		value	[red-native!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/form"]]

		string/concatenate-literal buffer "?native?"
		part - 8
	]
	
	mold: func [
		native	[red-native!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/mold"]]

		string/concatenate-literal buffer "make native! ["
		
		part: block/mold
			reflect native words/spec					;-- mold spec
			buffer
			only?
			all?
			flat?
			arg
			part - 14
			indent
		
		string/concatenate-literal buffer "]"
		part - 1
	]

	compare: func [
		arg1	[red-native!]							;-- first operand
		arg2	[red-native!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_NATIVE [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT(arg1/code arg2/code)
			]
			default [
				res: -2
			]
		]
		res
	]

	init: does [
		datatype/register [
			TYPE_NATIVE
			TYPE_VALUE
			"native!"
			;-- General actions --
			:make
			null			;random
			:reflect
			null			;to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
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