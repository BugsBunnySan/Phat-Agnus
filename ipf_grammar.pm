####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package ipf_grammar;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'FILENAME' => 1
		},
		GOTOS => {
			'ipf' => 2,
			'image' => 3
		}
	},
	{#State 1
		DEFAULT => -3
	},
	{#State 2
		ACTIONS => {
			'' => 4
		}
	},
	{#State 3
		ACTIONS => {
			'FUNCCALL' => 6
		},
		DEFAULT => -2,
		GOTOS => {
			'functions' => 5
		}
	},
	{#State 4
		DEFAULT => 0
	},
	{#State 5
		DEFAULT => -1
	},
	{#State 6
		ACTIONS => {
			'FUNCTION_IPF' => 7,
			'FUNCTION' => 8,
			'FUNCTION_I' => 10
		},
		GOTOS => {
			'func' => 9
		}
	},
	{#State 7
		ACTIONS => {
			'OPENCIPF' => 11
		}
	},
	{#State 8
		ACTIONS => {
			'OPENC' => 12
		}
	},
	{#State 9
		ACTIONS => {
			'FUNCCALL' => 6
		},
		DEFAULT => -5,
		GOTOS => {
			'functions' => 13
		}
	},
	{#State 10
		ACTIONS => {
			'OPENCI' => 14
		}
	},
	{#State 11
		ACTIONS => {
			'FILENAME' => 1
		},
		GOTOS => {
			'ipf' => 15,
			'image' => 3
		}
	},
	{#State 12
		ACTIONS => {
			'CLOSEC' => 17,
			'COMMA' => 18,
			'ARG' => 19
		},
		GOTOS => {
			'arglist' => 16
		}
	},
	{#State 13
		DEFAULT => -4
	},
	{#State 14
		ACTIONS => {
			'FILENAME' => 1
		},
		GOTOS => {
			'image' => 20
		}
	},
	{#State 15
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		GOTOS => {
			'arglist' => 21
		}
	},
	{#State 16
		ACTIONS => {
			'CLOSEC' => 22
		}
	},
	{#State 17
		DEFAULT => -12
	},
	{#State 18
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		GOTOS => {
			'arglist' => 23
		}
	},
	{#State 19
		ACTIONS => {
			'COMMA' => 24
		},
		DEFAULT => -8
	},
	{#State 20
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		GOTOS => {
			'arglist' => 25
		}
	},
	{#State 21
		ACTIONS => {
			'CLOSEC' => 26
		}
	},
	{#State 22
		DEFAULT => -11
	},
	{#State 23
		DEFAULT => -6
	},
	{#State 24
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		GOTOS => {
			'arglist' => 27
		}
	},
	{#State 25
		ACTIONS => {
			'CLOSEC' => 28
		}
	},
	{#State 26
		DEFAULT => -9
	},
	{#State 27
		DEFAULT => -7
	},
	{#State 28
		DEFAULT => -10
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'ipf', 2, undef
	],
	[#Rule 2
		 'ipf', 1, undef
	],
	[#Rule 3
		 'image', 1,
sub
#line 5 "ipf.yp"
{ main::read_image($_[1]); return $_[1];  }
	],
	[#Rule 4
		 'functions', 3, undef
	],
	[#Rule 5
		 'functions', 2, undef
	],
	[#Rule 6
		 'arglist', 2,
sub
#line 11 "ipf.yp"
{ return main::get_args(); }
	],
	[#Rule 7
		 'arglist', 3,
sub
#line 12 "ipf.yp"
{ main::push_arg($_[1]); return main::get_args(); }
	],
	[#Rule 8
		 'arglist', 1,
sub
#line 13 "ipf.yp"
{ main::push_arg($_[1]); $_[1] }
	],
	[#Rule 9
		 'func', 5,
sub
#line 16 "ipf.yp"
{ main::do_tag($_[1], $_[4]); }
	],
	[#Rule 10
		 'func', 5,
sub
#line 17 "ipf.yp"
{ main::do_tag($_[1], $_[4]); }
	],
	[#Rule 11
		 'func', 4,
sub
#line 18 "ipf.yp"
{ main::do_tag($_[1], $_[3]); }
	],
	[#Rule 12
		 'func', 3,
sub
#line 19 "ipf.yp"
{ main::do_empty_tag($_[1]); }
	]
],
                                  @_);
    bless($self,$class);
}

#line 22 "ipf.yp"


1;
