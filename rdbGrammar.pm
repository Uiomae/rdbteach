########################################################################################
#
#    This file was generated using Parse::Eyapp version 1.132.
#
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon. Universidad de La Laguna.
#        Don't edit this file, use source file "rdbGrammar.eyp" instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package rdbGrammar;
use strict;

push @rdbGrammar::ISA, 'Parse::Eyapp::Driver';


BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  

#line 7 "rdbGrammar.eyp"

	use Tie::IxHash;
	our $VERSION = '0.01';
	my (%s, %rel, $currentRel);
	tie (%rel, "Tie::IxHash");
	my @errors = undef;

	use constant S_ERR_ATTRTYPE => 10;
	use constant S_ERR_ATTRNONEXIST => 11;
	use constant S_ERR_RELEXISTS => 12;

#line 39 .\rdbGrammar.pm

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@rdbGrammar::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '1.132',
    yyGRAMMAR  =>
[
  [ _SUPERSTART => '$start', [ 'start', '$end' ], 0 ],
  [ start_1 => 'start', [ 'prog' ], 0 ],
  [ _STAR_LIST => 'STAR-1', [ 'STAR-1', 'tuple' ], 0 ],
  [ _STAR_LIST => 'STAR-1', [  ], 0 ],
  [ _STAR_LIST => 'STAR-2', [ 'STAR-2', 'NEWLINE' ], 0 ],
  [ _STAR_LIST => 'STAR-2', [  ], 0 ],
  [ _PAREN => 'PAREN-3', [ 'relation', 'STAR-1', 'STAR-2' ], 0 ],
  [ _PLUS_LIST => 'PLUS-4', [ 'PLUS-4', 'PAREN-3' ], 0 ],
  [ _PLUS_LIST => 'PLUS-4', [ 'PAREN-3' ], 0 ],
  [ prog_9 => 'prog', [ 'PLUS-4' ], 0 ],
  [ tuple_10 => 'tuple', [ 'constants', 'NEWLINE' ], 0 ],
  [ _PAREN => 'PAREN-5', [ ',', 'constant' ], 0 ],
  [ _STAR_LIST => 'STAR-6', [ 'STAR-6', 'PAREN-5' ], 0 ],
  [ _STAR_LIST => 'STAR-6', [  ], 0 ],
  [ constants_14 => 'constants', [ 'constant', 'STAR-6' ], 0 ],
  [ relation_15 => 'relation', [ '@', 'ID', '(', 'attributes', ')', ':', 'identifiers', 'NEWLINE' ], 0 ],
  [ _PAREN => 'PAREN-7', [ ',', 'attribute' ], 0 ],
  [ _STAR_LIST => 'STAR-8', [ 'STAR-8', 'PAREN-7' ], 0 ],
  [ _STAR_LIST => 'STAR-8', [  ], 0 ],
  [ attributes_19 => 'attributes', [ 'attribute', 'STAR-8' ], 0 ],
  [ attribute_20 => 'attribute', [ 'ID', '/', 'typename' ], 0 ],
  [ _PAREN => 'PAREN-9', [ ',', 'ID' ], 0 ],
  [ _STAR_LIST => 'STAR-10', [ 'STAR-10', 'PAREN-9' ], 0 ],
  [ _STAR_LIST => 'STAR-10', [  ], 0 ],
  [ identifiers_24 => 'identifiers', [ 'ID', 'STAR-10' ], 0 ],
  [ constant_25 => 'constant', [ 'CHAR' ], 0 ],
  [ constant_26 => 'constant', [ 'NUM' ], 0 ],
  [ typename_27 => 'typename', [ 'char' ], 0 ],
  [ typename_28 => 'typename', [ 'numeric' ], 0 ],
],
    yyTERMS  =>
{ '$end' => 0, '(' => 0, ')' => 0, ',' => 0, '/' => 0, ':' => 0, '@' => 0, 'char' => 0, 'numeric' => 0, CHAR => 1, ID => 1, NEWLINE => 1, NUM => 1 },
    yyFILENAME  => "rdbGrammar.eyp",
    yystates =>
[
	{#State 0
		ACTIONS => {
			"\@" => 1
		},
		GOTOS => {
			'prog' => 2,
			'relation' => 4,
			'PAREN-3' => 3,
			'start' => 6,
			'PLUS-4' => 5
		}
	},
	{#State 1
		ACTIONS => {
			'ID' => 7
		}
	},
	{#State 2
		DEFAULT => -1
	},
	{#State 3
		DEFAULT => -8
	},
	{#State 4
		DEFAULT => -3,
		GOTOS => {
			'STAR-1' => 8
		}
	},
	{#State 5
		ACTIONS => {
			"\@" => 1
		},
		DEFAULT => -9,
		GOTOS => {
			'PAREN-3' => 9,
			'relation' => 4
		}
	},
	{#State 6
		ACTIONS => {
			'' => 10
		}
	},
	{#State 7
		ACTIONS => {
			"(" => 11
		}
	},
	{#State 8
		ACTIONS => {
			'NUM' => 12,
			'CHAR' => 15
		},
		DEFAULT => -5,
		GOTOS => {
			'constants' => 13,
			'STAR-2' => 14,
			'tuple' => 17,
			'constant' => 16
		}
	},
	{#State 9
		DEFAULT => -7
	},
	{#State 10
		DEFAULT => 0
	},
	{#State 11
		ACTIONS => {
			'ID' => 18
		},
		GOTOS => {
			'attribute' => 19,
			'attributes' => 20
		}
	},
	{#State 12
		DEFAULT => -26
	},
	{#State 13
		ACTIONS => {
			'NEWLINE' => 21
		}
	},
	{#State 14
		ACTIONS => {
			'NEWLINE' => 22
		},
		DEFAULT => -6
	},
	{#State 15
		DEFAULT => -25
	},
	{#State 16
		DEFAULT => -13,
		GOTOS => {
			'STAR-6' => 23
		}
	},
	{#State 17
		DEFAULT => -2
	},
	{#State 18
		ACTIONS => {
			"/" => 24
		}
	},
	{#State 19
		DEFAULT => -18,
		GOTOS => {
			'STAR-8' => 25
		}
	},
	{#State 20
		ACTIONS => {
			")" => 26
		}
	},
	{#State 21
		DEFAULT => -10
	},
	{#State 22
		DEFAULT => -4
	},
	{#State 23
		ACTIONS => {
			"," => 28
		},
		DEFAULT => -14,
		GOTOS => {
			'PAREN-5' => 27
		}
	},
	{#State 24
		ACTIONS => {
			"numeric" => 30,
			"char" => 31
		},
		GOTOS => {
			'typename' => 29
		}
	},
	{#State 25
		ACTIONS => {
			"," => 32
		},
		DEFAULT => -19,
		GOTOS => {
			'PAREN-7' => 33
		}
	},
	{#State 26
		ACTIONS => {
			":" => 34
		}
	},
	{#State 27
		DEFAULT => -12
	},
	{#State 28
		ACTIONS => {
			'NUM' => 12,
			'CHAR' => 15
		},
		GOTOS => {
			'constant' => 35
		}
	},
	{#State 29
		DEFAULT => -20
	},
	{#State 30
		DEFAULT => -28
	},
	{#State 31
		DEFAULT => -27
	},
	{#State 32
		ACTIONS => {
			'ID' => 18
		},
		GOTOS => {
			'attribute' => 36
		}
	},
	{#State 33
		DEFAULT => -17
	},
	{#State 34
		ACTIONS => {
			'ID' => 37
		},
		GOTOS => {
			'identifiers' => 38
		}
	},
	{#State 35
		DEFAULT => -11
	},
	{#State 36
		DEFAULT => -16
	},
	{#State 37
		DEFAULT => -23,
		GOTOS => {
			'STAR-10' => 39
		}
	},
	{#State 38
		ACTIONS => {
			'NEWLINE' => 40
		}
	},
	{#State 39
		ACTIONS => {
			"," => 41
		},
		DEFAULT => -24,
		GOTOS => {
			'PAREN-9' => 42
		}
	},
	{#State 40
		DEFAULT => -15
	},
	{#State 41
		ACTIONS => {
			'ID' => 43
		}
	},
	{#State 42
		DEFAULT => -22
	},
	{#State 43
		DEFAULT => -21
	}
],
    yyrules  =>
[
	[#Rule _SUPERSTART
		 '$start', 2, undef
#line 331 .\rdbGrammar.pm
	],
	[#Rule start_1
		 'start', 1,
sub {
#line 22 "rdbGrammar.eyp"
 [\%rel, \@errors]; }
#line 338 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-1', 2,
sub {
#line 26 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
#line 345 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-1', 0,
sub {
#line 26 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_empty }
#line 352 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-2', 2,
sub {
#line 26 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
#line 359 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-2', 0,
sub {
#line 26 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_empty }
#line 366 .\rdbGrammar.pm
	],
	[#Rule _PAREN
		 'PAREN-3', 3,
sub {
#line 26 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforParenthesis}
#line 373 .\rdbGrammar.pm
	],
	[#Rule _PLUS_LIST
		 'PLUS-4', 2,
sub {
#line 26 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
#line 380 .\rdbGrammar.pm
	],
	[#Rule _PLUS_LIST
		 'PLUS-4', 1,
sub {
#line 26 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_single }
#line 387 .\rdbGrammar.pm
	],
	[#Rule prog_9
		 'prog', 1, undef
#line 391 .\rdbGrammar.pm
	],
	[#Rule tuple_10
		 'tuple', 2,
sub {
#line 30 "rdbGrammar.eyp"
 _AddTuple(@_); }
#line 398 .\rdbGrammar.pm
	],
	[#Rule _PAREN
		 'PAREN-5', 2,
sub {
#line 34 "rdbGrammar.eyp"
 $_[2]; }
#line 405 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-6', 2,
sub {
#line 34 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
#line 412 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-6', 0,
sub {
#line 34 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_empty }
#line 419 .\rdbGrammar.pm
	],
	[#Rule constants_14
		 'constants', 2,
sub {
#line 34 "rdbGrammar.eyp"
 unshift(@{$_[2]}, $_[1]); return $_[2]; }
#line 426 .\rdbGrammar.pm
	],
	[#Rule relation_15
		 'relation', 8,
sub {
#line 38 "rdbGrammar.eyp"
 my $id = _CheckAttrs($_[7]); _SemanticError($_[0], S_ERR_ATTRNONEXIST, $id) if defined $id; _NewRel(@_); }
#line 433 .\rdbGrammar.pm
	],
	[#Rule _PAREN
		 'PAREN-7', 2,
sub {
#line 42 "rdbGrammar.eyp"
 $_[2]; }
#line 440 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-8', 2,
sub {
#line 42 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
#line 447 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-8', 0,
sub {
#line 42 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_empty }
#line 454 .\rdbGrammar.pm
	],
	[#Rule attributes_19
		 'attributes', 2,
sub {
#line 42 "rdbGrammar.eyp"
 unshift(@{$_[2]}, $_[1]); return $_[2]; }
#line 461 .\rdbGrammar.pm
	],
	[#Rule attribute_20
		 'attribute', 3,
sub {
#line 46 "rdbGrammar.eyp"
 my ($id, $type) = ($_[1], $_[3]); _SemanticError($_[0], S_ERR_ATTRTYPE, $id, $type) if ((defined $s{@$id[0]}) and (@{$s{@$id[0]}}[0] ne @$type[0])); $s{@$id[0]} = $type; [@$id[0], @$type[0]]; }
#line 468 .\rdbGrammar.pm
	],
	[#Rule _PAREN
		 'PAREN-9', 2,
sub {
#line 50 "rdbGrammar.eyp"
 $_[2]; }
#line 475 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-10', 2,
sub {
#line 50 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
#line 482 .\rdbGrammar.pm
	],
	[#Rule _STAR_LIST
		 'STAR-10', 0,
sub {
#line 50 "rdbGrammar.eyp"
 goto &Parse::Eyapp::Driver::YYActionforT_empty }
#line 489 .\rdbGrammar.pm
	],
	[#Rule identifiers_24
		 'identifiers', 2,
sub {
#line 50 "rdbGrammar.eyp"
 unshift(@{$_[2]}, $_[1]); return $_[2]; }
#line 496 .\rdbGrammar.pm
	],
	[#Rule constant_25
		 'constant', 1, undef
#line 500 .\rdbGrammar.pm
	],
	[#Rule constant_26
		 'constant', 1, undef
#line 504 .\rdbGrammar.pm
	],
	[#Rule typename_27
		 'typename', 1, undef
#line 508 .\rdbGrammar.pm
	],
	[#Rule typename_28
		 'typename', 1, undef
#line 512 .\rdbGrammar.pm
	]
],
#line 515 .\rdbGrammar.pm
    yybypass       => 0,
    yybuildingtree => 0,
    yyprefix       => '',
    yyaccessors    => {
   },
    @_,
  );
  bless($self,$class);

  $self->make_node_classes( qw{TERMINAL _OPTIONAL _STAR_LIST _PLUS_LIST 
         _SUPERSTART
         start_1
         _PAREN
         prog_9
         tuple_10
         constants_14
         relation_15
         attributes_19
         attribute_20
         identifiers_24
         constant_25
         constant_26
         typename_27
         typename_28} );
  $self;
}

#line 63 "rdbGrammar.eyp"


my $lineno = 1;

sub _AddTuple {
	my ($parser, $constants) = @_;

	# TODO: Check tuple types
	my @tuple;
	foreach my $constant (@$constants) {
		push(@tuple, @$constant[0]);
	}
	push(@{$currentRel->{tuples}}, [@tuple]);
}

sub _NewRel {
	my ($parser, $relName, $attribs, $keys) = ($_[0], $_[2], $_[4], $_[7]);
	_SemanticError($parser, S_ERR_RELEXISTS, $relName) if defined $rel{@$relName[0]};

	$rel{@$relName[0]} = { "tuples" => [], "attribs" => {}, "keys" => [], "line" => @$relName[1] };
	$currentRel = \%{$rel{@$relName[0]}};
	# Add attributes
	tie (%{$currentRel->{attribs}}, "Tie::IxHash");
	foreach my $attrib (@$attribs) {
		$currentRel->{attribs}{$attrib->[0]} = $attrib->[1];
	}
	# Add keys
	foreach my $key (@$keys) {
		push(@{$currentRel->{"keys"}}, @$key[0]);
	}
}

sub _CheckAttrs {
	my ($attrs) = shift;

	foreach my $attr (@$attrs) {
		return $attr unless defined $s{@$attr[0]};
	}
	return undef;
}

sub _SemanticError {
	my $parser = shift;
	my $errType = shift;
	
	my ($err, $lineno);
	for ($errType) {
		$_ == S_ERR_ATTRTYPE and do {
			my ($id, $type) = @_;
			$lineno = @$id[1];
			$err = "Type of previous declared attribute '@$id[0]' (@{$s{@$id[0]}}[0]) at line @{$s{@$id[0]}}[1]\ndoesn't match with new declared type (@$type[0])";
		};
		$_ == S_ERR_ATTRNONEXIST and do {
			my ($id) = @_;
			$lineno = @$id[1];
			$err = "Attribute '@$id[0]' doesn't exist";
		};
		$_ == S_ERR_RELEXISTS and do {
			my ($id) = @_;
			$lineno = @$id[1];
			my %temp = %{$rel{@$id[0]}};
			$err = "Relation '@$id[0]' already exists (previously defined at line $temp{line})";
		};
	}
	@errors = ["Semantic error: $err at line $lineno", $lineno];
}

sub _Error {
	my $parser = shift;
	my $yydata = $parser->YYData;

	my($token)=$parser->YYCurval;
	exists $yydata->{ERRMSG}
	and do {
		@errors = [$yydata->{ERRMSG}, $token->[1]];
		delete $yydata->{ERRMSG};
		return;
	};
	my($what)= $token->[0] ? "input: '$token->[0]'" : "end of input";
	my @expected = $parser->YYExpect();
	local $" = ', ';
	@errors = ["Syntax error near $what (lin num $token->[1]).\nExpected one of these terminals: @expected", $token->[1]];
}

sub make_lexer {
	my $input = shift;
	my ($beginline, $lineno) = (1, 1);

	return sub {
		my $parser = shift;
		$beginline = $lineno;
		for ($input) {    # contextualize
			m{\G[ \t]*(\#.*)?}gc;

			m{\G(char|numeric)}gc           and return ($1, [$1, $beginline]);
			m{\G([0-9]+(?:\.[0-9]+)?)}gc    and return ('NUM', [$1, $beginline]);
			m{\G([A-Za-z_][A-Za-z0-9_]*)}gc and return ('ID', [$1, $beginline]);
			m{\G((["'])(.*?)\2)}gc           and return ('CHAR', [$3, $beginline]);	# Just for Vim syntax highlighting matching the '"
			#m{\G\r}gc                       and return ("\r", ["\r", $beginline]);
			m{\G\n}gc                       and do { $lineno++; return ("NEWLINE", ["\n", $beginline]) };
			m{\G(.)}gc                      and return ($1,    [$1, $beginline]);

			return('',undef);
		}
	}
}

sub Run {
	my ($self) = shift;

	my $input = shift;
	return $self->YYParse( yylex => make_lexer($input), yyerror => \&_Error );
}



=for None

=cut



#line 666 .\rdbGrammar.pm

1;
