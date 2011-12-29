####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package wml_grammar;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = 1.05;
$COMPATIBLE = 0.07;
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'VAREQUALS' => 11,
			'FILENAME_IPF' => 2,
			'PP_IFDEF' => 5,
			'PP_SKIP' => 4,
			'VAR' => 18,
			'ADD_TAG' => 7,
			'PP_ENDIF' => 17,
			'OPEN_TAG' => 19,
			'HASH' => 8,
			'FILENAME_I' => 20,
			'VAREQUALSTEXT' => 9,
			'NEWLINE' => 10
		},
		GOTOS => {
			'assignment' => 12,
			'wml' => 1,
			'ipf' => 3,
			'preproc' => 14,
			'image' => 13,
			'wml_line' => 15,
			'open_tags' => 6,
			'comment' => 16
		}
	},
	{#State 1
		ACTIONS => {
			'' => 21
		}
	},
	{#State 2
		DEFAULT => -22
	},
	{#State 3
		DEFAULT => -3
	},
	{#State 4
		DEFAULT => -13
	},
	{#State 5
		ACTIONS => {
			'PP_DEF' => 22
		}
	},
	{#State 6
		ACTIONS => {
			'VAREQUALS' => 11,
			'FILENAME_IPF' => 2,
			'PP_IFDEF' => 5,
			'PP_SKIP' => 4,
			'PP_ENDIF' => 17,
			'ADD_TAG' => 7,
			'VAR' => 18,
			'OPEN_TAG' => 19,
			'HASH' => 8,
			'FILENAME_I' => 20,
			'VAREQUALSTEXT' => 9,
			'NEWLINE' => 10
		},
		GOTOS => {
			'assignment' => 12,
			'wml' => 23,
			'ipf' => 3,
			'preproc' => 14,
			'image' => 13,
			'wml_line' => 15,
			'open_tags' => 6,
			'comment' => 16
		}
	},
	{#State 7
		DEFAULT => -15
	},
	{#State 8
		ACTIONS => {
			'WML_SKIP' => 25,
			'NEWLINE_SKIP' => 24
		}
	},
	{#State 9
		DEFAULT => -19
	},
	{#State 10
		DEFAULT => -8
	},
	{#State 11
		ACTIONS => {
			'TEXT' => 26
		}
	},
	{#State 12
		ACTIONS => {
			'NEWLINE' => 27
		}
	},
	{#State 13
		ACTIONS => {
			'FUNCCALL' => 28
		},
		DEFAULT => -21,
		GOTOS => {
			'functions' => 29
		}
	},
	{#State 14
		ACTIONS => {
			'NEWLINE' => 30
		}
	},
	{#State 15
		ACTIONS => {
			'VAREQUALS' => 11,
			'FILENAME_IPF' => 2,
			'PP_IFDEF' => 5,
			'PP_SKIP' => 4,
			'PP_ENDIF' => 17,
			'VAR' => 18,
			'ADD_TAG' => 7,
			'OPEN_TAG' => 19,
			'HASH' => 8,
			'FILENAME_I' => 20,
			'VAREQUALSTEXT' => 9,
			'NEWLINE' => 10
		},
		DEFAULT => -2,
		GOTOS => {
			'assignment' => 12,
			'wml' => 31,
			'ipf' => 3,
			'preproc' => 14,
			'image' => 13,
			'wml_line' => 15,
			'open_tags' => 6,
			'comment' => 16
		}
	},
	{#State 16
		DEFAULT => -4
	},
	{#State 17
		DEFAULT => -12
	},
	{#State 18
		ACTIONS => {
			'EQUALS' => 32
		}
	},
	{#State 19
		DEFAULT => -14
	},
	{#State 20
		DEFAULT => -23
	},
	{#State 21
		DEFAULT => 0
	},
	{#State 22
		DEFAULT => -11
	},
	{#State 23
		ACTIONS => {
			'CLOSE_TAG' => 33
		},
		GOTOS => {
			'close_tags' => 34
		}
	},
	{#State 24
		DEFAULT => -10
	},
	{#State 25
		ACTIONS => {
			'NEWLINE_SKIP' => 35
		}
	},
	{#State 26
		DEFAULT => -18
	},
	{#State 27
		DEFAULT => -7
	},
	{#State 28
		ACTIONS => {
			'FUNCTION_IPF' => 38,
			'FUNCTION' => 37,
			'FUNCTION_I' => 36
		},
		GOTOS => {
			'func' => 39
		}
	},
	{#State 29
		DEFAULT => -20
	},
	{#State 30
		DEFAULT => -5
	},
	{#State 31
		DEFAULT => -1
	},
	{#State 32
		ACTIONS => {
			'TEXT' => 40
		}
	},
	{#State 33
		DEFAULT => -16
	},
	{#State 34
		ACTIONS => {
			'NEWLINE' => 41
		}
	},
	{#State 35
		DEFAULT => -9
	},
	{#State 36
		ACTIONS => {
			'OPENC_I' => 42
		}
	},
	{#State 37
		ACTIONS => {
			'OPENC' => 43
		}
	},
	{#State 38
		ACTIONS => {
			'OPENC_IPF' => 44
		}
	},
	{#State 39
		ACTIONS => {
			'FUNCCALL' => 28
		},
		DEFAULT => -25,
		GOTOS => {
			'functions' => 45
		}
	},
	{#State 40
		DEFAULT => -17
	},
	{#State 41
		DEFAULT => -6
	},
	{#State 42
		ACTIONS => {
			'FILENAME_IPF' => 2,
			'FILENAME_I' => 20
		},
		GOTOS => {
			'image' => 46
		}
	},
	{#State 43
		ACTIONS => {
			'COMMA' => 47,
			'ARG' => 48
		},
		DEFAULT => -29,
		GOTOS => {
			'arglist' => 49
		}
	},
	{#State 44
		ACTIONS => {
			'FILENAME_IPF' => 2,
			'FILENAME_I' => 20
		},
		GOTOS => {
			'ipf' => 50,
			'image' => 13
		}
	},
	{#State 45
		DEFAULT => -24
	},
	{#State 46
		ACTIONS => {
			'COMMA' => 47,
			'ARG' => 48
		},
		DEFAULT => -29,
		GOTOS => {
			'arglist' => 51
		}
	},
	{#State 47
		ACTIONS => {
			'COMMA' => 47,
			'ARG' => 48
		},
		DEFAULT => -29,
		GOTOS => {
			'arglist' => 52
		}
	},
	{#State 48
		ACTIONS => {
			'COMMA' => 53
		},
		DEFAULT => -28
	},
	{#State 49
		ACTIONS => {
			'CLOSEC' => 54
		}
	},
	{#State 50
		ACTIONS => {
			'COMMA' => 47,
			'ARG' => 48
		},
		DEFAULT => -29,
		GOTOS => {
			'arglist' => 55
		}
	},
	{#State 51
		ACTIONS => {
			'CLOSEC' => 56
		}
	},
	{#State 52
		DEFAULT => -26
	},
	{#State 53
		ACTIONS => {
			'COMMA' => 47,
			'ARG' => 48
		},
		DEFAULT => -29,
		GOTOS => {
			'arglist' => 57
		}
	},
	{#State 54
		DEFAULT => -32
	},
	{#State 55
		ACTIONS => {
			'CLOSEC' => 58
		}
	},
	{#State 56
		DEFAULT => -31
	},
	{#State 57
		DEFAULT => -27
	},
	{#State 58
		DEFAULT => -30
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'wml', 2, undef
	],
	[#Rule 2
		 'wml', 1, undef
	],
	[#Rule 3
		 'wml', 1, undef
	],
	[#Rule 4
		 'wml_line', 1, undef
	],
	[#Rule 5
		 'wml_line', 2, undef
	],
	[#Rule 6
		 'wml_line', 4, undef
	],
	[#Rule 7
		 'wml_line', 2, undef
	],
	[#Rule 8
		 'wml_line', 1, undef
	],
	[#Rule 9
		 'comment', 3, undef
	],
	[#Rule 10
		 'comment', 2, undef
	],
	[#Rule 11
		 'preproc', 2, undef
	],
	[#Rule 12
		 'preproc', 1, undef
	],
	[#Rule 13
		 'preproc', 1, undef
	],
	[#Rule 14
		 'open_tags', 1,
sub
#line 20 "wml.yp"
{ Paula::set_current_tag($_[1], 'replace') }
	],
	[#Rule 15
		 'open_tags', 1,
sub
#line 21 "wml.yp"
{ Paula::set_current_tag($_[1], 'add') }
	],
	[#Rule 16
		 'close_tags', 1,
sub
#line 23 "wml.yp"
{ Paula::close_current_tag($_[1]) }
	],
	[#Rule 17
		 'assignment', 3,
sub
#line 25 "wml.yp"
{ Paula::assign($_[1], $_[2]) }
	],
	[#Rule 18
		 'assignment', 2,
sub
#line 26 "wml.yp"
{ $_[1] =~ s/=//; Paula::assign($_[1], $_[2]) }
	],
	[#Rule 19
		 'assignment', 1,
sub
#line 27 "wml.yp"
{ my ($var, $text) = split('=', $_[1]); Paula::assign($var, $text) }
	],
	[#Rule 20
		 'ipf', 2, undef
	],
	[#Rule 21
		 'ipf', 1, undef
	],
	[#Rule 22
		 'image', 1,
sub
#line 34 "wml.yp"
{ main::read_image($_[1]); return $_[1];  }
	],
	[#Rule 23
		 'image', 1,
sub
#line 35 "wml.yp"
{ main::read_image($_[1]); return $_[1];  }
	],
	[#Rule 24
		 'functions', 3, undef
	],
	[#Rule 25
		 'functions', 2, undef
	],
	[#Rule 26
		 'arglist', 2,
sub
#line 41 "wml.yp"
{ return main::get_args(); }
	],
	[#Rule 27
		 'arglist', 3,
sub
#line 42 "wml.yp"
{ main::push_arg($_[1]); return main::get_args(); }
	],
	[#Rule 28
		 'arglist', 1,
sub
#line 43 "wml.yp"
{ main::push_arg($_[1]); $_[1] }
	],
	[#Rule 29
		 'arglist', 0, undef
	],
	[#Rule 30
		 'func', 5,
sub
#line 47 "wml.yp"
{ main::do_tag($_[1], $_[4]); }
	],
	[#Rule 31
		 'func', 5,
sub
#line 48 "wml.yp"
{ main::do_tag($_[1], $_[4]); }
	],
	[#Rule 32
		 'func', 4,
sub
#line 49 "wml.yp"
{ main::do_tag($_[1], $_[3]); }
	]
],
                                  @_);
    bless($self,$class);
}

#line 51 "wml.yp"


1;
