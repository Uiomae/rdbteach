package parser;

$main::RD_HINT = 1;

use strict;
use warnings;
use Parse::RecDescent;
use Data::Dumper;
use Data::Compare;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parseRDB parseALG);

my @currentAttribs = [];
my %relation = ();
my %attribs = ();
my $currentRelation;

sub checkAssignment {
    shift;

    my $relationName = $_[0];
    my $queryResult = $_[-1];

    #print "RelationName: $relationName QueryResult: " . Dumper($queryResult);
    $relation{$relationName} = @{$queryResult}[0];
    $attribs{$relationName} = @{$queryResult}[1];
}

sub errorCheck {
    my $msg = $_[0];
    my $item = $_[1];
    print @{$msg}[0] . ":" . $item . "\n";
}

my $generalGrammar = q(
    startrule : query_definition(s?) eofile | <error>

    eofile : /^\\Z/ { $return = 1; }

    comment : /^%+(.*?)$/m
    identifier : /[a-zA-Z][a-zA-Z0-9]*/m | <error>

    # Types
    # TODO: Add double quotes to "char" type
    char : /'(.*?)'/i
    int : /[+-]?\\d+/
    float : /[+-]?\\d+(?:\\.\\d+)?/
    numeric : float | int

    constant : char | numeric | <error>

    query_definition : comment | assignment_statement ';' | query ';' | <error>

    assignment_statement : relation_name '(' attribute_list(s /,/) ')' ':=' query { parser::checkAssignment(@item); } | relation_name ':=' query { parser::checkAssignment(@item); } | <error>

    attribute_list : identifier | <error>
    relation_name : identifier | <error>
);

sub parseProject {
    shift;
    my $attributes = $_[2];
    my @expression = @{$_[4]};

    # Check attributes
    my %tempAttribs;

    my $ref = $expression[1];
    my %currentAttribs = %$ref;
    @tempAttribs{@{$attributes}} = @currentAttribs{@{$attributes}};

    # Do the actual projection
    my @tempRelation;
    $ref = $expression[0];
    my @currentRelation = @$ref;
    foreach my $tempHash (@currentRelation) {
        my %anotherHash;
        # Slice and recombine into a hash
        @anotherHash{@{$attributes}} = @{$tempHash}{@{$attributes}};
        my $found = 0;
        foreach my $tempAnother (@tempRelation) {
            if (Compare($tempAnother, {%anotherHash})) { $found = 1; last; }
        }
        push(@tempRelation, {%anotherHash}) unless $found;
    }

    #print "Temp: " . Dumper(@temp);
    return [\@tempRelation, \%tempAttribs];
}

sub parseLiteExpression {
    shift;
    return $_[0] if (ref($_[0]) eq "ARRAY");

    my $itemName = $_[0];
    return [$relation{$itemName}, $attribs{$itemName}];
}

my $algGrammar = $generalGrammar . q(
    query : expression | <error>

    liteExpression : '(' expression ')' { $return = $item[2]; } | identifier | <error>
    expression : select_expr | project_expr | binary_expr | liteExpression { $return = parser::parseLiteExpression(@item); } | <error>
    select_expr : 'select' <commit> condition '(' expression ')' | <error>
    project_expr : 'project' <commit> attribute(s /,/) '(' expression ')' { $return = parser::parseProject(@item); } | <error>
    binary_expr : liteExpression binary_op liteExpression | <error>

    condition : and_condition 'or' condition | and_condition | <error>
    and_condition : rel_formula 'and' and_condition | rel_formula
    rel_formula : operand relational_op operand | '(' condition ')'
    binary_op : 'union' | 'njoin' | 'product' | 'difference' | 'intersect'

    # subAttribute : '.' identifier { $return = $item[2]; }
    attribute : identifier # subAttribute(?) { $return = [$item[1], $item[2]]; }
    operand : attribute | constant | <error>

    relational_op : '=' | '>' | '<' | '<>' | '>=' | '<='
);

sub addRelation {
    shift;
    $relation{$_[1]} = [];
    my %tempHash;
    # Join attributes
    foreach my $temp (@{$_[3]}) {
        %tempHash = (%tempHash, %$temp);
    }
    $attribs{$_[1]} = {%tempHash};
    $currentRelation = \$relation{$_[1]};
    @currentAttribs = keys %tempHash;
}

sub addTuple {
    shift;
    my @tempTuple = @{$_[0]};
    if (scalar @tempTuple != scalar @currentAttribs) {
        die "Invalid tuple at line " . $_[1] . ". Expecting " . scalar @currentAttribs . " attributes, but got " . scalar @tempTuple . "\n";
    }
    my %temp;
    # Match attributes with values... I LOVE PERL!!!
    @temp{@currentAttribs} = @tempTuple;
    push(@{${$currentRelation}}, {%temp});
    return 1;
}

sub checkChar {
    shift;
    my $tempString = $_[0];
    $tempString =~ s/'//g;
    return $tempString;
}

my $rdbGrammar = q(
    startrule : (relation tuple(s?))(s?) eofile | <error>

    eofile : /^\\Z/ { $return = 1; }

    # Types
    # TODO: Add double quotes to "char" type
    char : /'(.*?)'/i { $return = parser::checkChar(@item); }
    int : /[+-]?\\d+/
    float : /[+-]?\\d+(?:\\.\\d+)?/
    numeric : float | int

    constant : char | numeric

    identifier : /[a-zA-Z][a-zA-Z0-9]*/m

    typeName : 'char' | 'numeric'

    attribute : identifier '/' typeName { $return = {$item[1] => $item[3]}; }

    relation : '@' identifier '(' attribute(s /,/) ')' ':' identifier(s /,/) { parser::addRelation(@item); }

    tuple : constant(s /,/) { parser::addTuple(@item, $thisline); }
);

# Compile grammars
my $rdbParser = Parse::RecDescent->new($rdbGrammar);
my $algParser = Parse::RecDescent->new($algGrammar);

sub parseRDB {
    my ($rdbText) = @_;

    %relation = ();
    %attribs = ();
    my $validRDB = $rdbParser->startrule($rdbText);
    my %newRel = %relation;
    my %newAttribs = %attribs;
    return [\%newRel, \%newAttribs] if $validRDB;
    return 0 unless $validRDB;
}

sub parseALG {
    my ($algText, $DBRelation, $DBAttribs) = @_;
    # Make a copy of the passed values
    %relation = %{$DBRelation};
    %attribs = %{$DBAttribs};
    my $valid = $algParser->startrule($algText);
    my %newRel = %relation;
    my %newAttribs = %attribs;
    return [\%newRel, \%newAttribs] if $valid;
    return @{$algParser->{errors}}[0] unless $valid;
}

1;
