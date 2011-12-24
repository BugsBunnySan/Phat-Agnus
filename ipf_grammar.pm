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
			'FILENAME_IPF' => 1,
			'FILENAME_I' => 3
		},
		GOTOS => {
			'ipf' => 2,
			'image' => 4
		}
	},
	{#State 1
		DEFAULT => -3
	},
	{#State 2
		ACTIONS => {
			'' => 5
		}
	},
	{#State 3
		DEFAULT => -4
	},
	{#State 4
		ACTIONS => {
			'FUNCCALL' => 7
		},
		DEFAULT => -2,
		GOTOS => {
			'functions' => 6
		}
	},
	{#State 5
		DEFAULT => 0
	},
	{#State 6
		DEFAULT => -1
	},
	{#State 7
		ACTIONS => {
			'FUNCTION_IPF' => 8,
			'FUNCTION' => 9,
			'FUNCTION_I' => 11
		},
		GOTOS => {
			'func' => 10
		}
	},
	{#State 8
		ACTIONS => {
			'OPENC_IPF' => 12
		}
	},
	{#State 9
		ACTIONS => {
			'OPENC' => 13
		}
	},
	{#State 10
		ACTIONS => {
			'FUNCCALL' => 7
		},
		DEFAULT => -6,
		GOTOS => {
			'functions' => 14
		}
	},
	{#State 11
		ACTIONS => {
			'OPENC_I' => 15
		}
	},
	{#State 12
		ACTIONS => {
			'FILENAME_IPF' => 1,
			'FILENAME_I' => 3
		},
		GOTOS => {
			'ipf' => 16,
			'image' => 4
		}
	},
	{#State 13
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		DEFAULT => -10,
		GOTOS => {
			'arglist' => 17
		}
	},
	{#State 14
		DEFAULT => -5
	},
	{#State 15
		ACTIONS => {
			'FILENAME_IPF' => 1,
			'FILENAME_I' => 3
		},
		GOTOS => {
			'image' => 20
		}
	},
	{#State 16
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		DEFAULT => -10,
		GOTOS => {
			'arglist' => 21
		}
	},
	{#State 17
		ACTIONS => {
			'CLOSEC' => 22
		}
	},
	{#State 18
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		DEFAULT => -10,
		GOTOS => {
			'arglist' => 23
		}
	},
	{#State 19
		ACTIONS => {
			'COMMA' => 24
		},
		DEFAULT => -9
	},
	{#State 20
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		DEFAULT => -10,
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
		DEFAULT => -13
	},
	{#State 23
		DEFAULT => -7
	},
	{#State 24
		ACTIONS => {
			'COMMA' => 18,
			'ARG' => 19
		},
		DEFAULT => -10,
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
		DEFAULT => -11
	},
	{#State 27
		DEFAULT => -8
	},
	{#State 28
		DEFAULT => -12
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
		 'image', 1,
sub
#line 6 "ipf.yp"
{ main::read_image($_[1]); return $_[1];  }
	],
	[#Rule 5
		 'functions', 3, undef
	],
	[#Rule 6
		 'functions', 2, undef
	],
	[#Rule 7
		 'arglist', 2,
sub
#line 12 "ipf.yp"
{ return main::get_args(); }
	],
	[#Rule 8
		 'arglist', 3,
sub
#line 13 "ipf.yp"
{ main::push_arg($_[1]); return main::get_args(); }
	],
	[#Rule 9
		 'arglist', 1,
sub
#line 14 "ipf.yp"
{ main::push_arg($_[1]); $_[1] }
	],
	[#Rule 10
		 'arglist', 0, undef
	],
	[#Rule 11
		 'func', 5,
sub
#line 18 "ipf.yp"
{ main::do_tag($_[1], $_[4]); }
	],
	[#Rule 12
		 'func', 5,
sub
#line 19 "ipf.yp"
{ main::do_tag($_[1], $_[4]); }
	],
	[#Rule 13
		 'func', 4,
sub
#line 20 "ipf.yp"
{ main::do_tag($_[1], $_[3]); }
	]
],
                                  @_);
    bless($self,$class);
}

#line 23 "ipf.yp"


1;
