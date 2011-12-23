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
			'FUNCTION' => 8
		},
		GOTOS => {
			'func' => 9
		}
	},
	{#State 7
		ACTIONS => {
			'OPENCIPF' => 10
		}
	},
	{#State 8
		ACTIONS => {
			'OPENC' => 11
		}
	},
	{#State 9
		ACTIONS => {
			'FUNCCALL' => 6
		},
		DEFAULT => -5,
		GOTOS => {
			'functions' => 12
		}
	},
	{#State 10
		ACTIONS => {
			'FILENAME' => 1
		},
		GOTOS => {
			'ipf' => 13,
			'image' => 3
		}
	},
	{#State 11
		ACTIONS => {
			'CLOSEC' => 15,
			'ARG' => 16
		},
		GOTOS => {
			'arglist' => 14
		}
	},
	{#State 12
		DEFAULT => -4
	},
	{#State 13
		ACTIONS => {
			'COMMA' => 17
		}
	},
	{#State 14
		ACTIONS => {
			'CLOSEC' => 18
		}
	},
	{#State 15
		DEFAULT => -10
	},
	{#State 16
		ACTIONS => {
			'COMMA' => 19
		},
		DEFAULT => -7
	},
	{#State 17
		ACTIONS => {
			'ARG' => 16
		},
		GOTOS => {
			'arglist' => 20
		}
	},
	{#State 18
		DEFAULT => -9
	},
	{#State 19
		ACTIONS => {
			'ARG' => 16
		},
		GOTOS => {
			'arglist' => 21
		}
	},
	{#State 20
		ACTIONS => {
			'CLOSEC' => 22
		}
	},
	{#State 21
		DEFAULT => -6
	},
	{#State 22
		DEFAULT => -8
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
		 'arglist', 3,
sub
#line 11 "ipf.yp"
{ main::push_arg($_[1]); return main::get_args(); }
	],
	[#Rule 7
		 'arglist', 1,
sub
#line 12 "ipf.yp"
{ main::push_arg($_[1]); }
	],
	[#Rule 8
		 'func', 6,
sub
#line 15 "ipf.yp"
{ print "@_\n"; main::do_tag($_[1], $_[5]); return ""; }
	],
	[#Rule 9
		 'func', 4,
sub
#line 16 "ipf.yp"
{ main::do_tag($_[1], $_[3]); return ""; }
	],
	[#Rule 10
		 'func', 3,
sub
#line 17 "ipf.yp"
{ main::do_empty_tag($_[1]); return ""; }
	]
],
                                  @_);
    bless($self,$class);
}

#line 20 "ipf.yp"


1;
