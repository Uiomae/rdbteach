#!/usr/bin/perl -w
use strict;
use Parse::RecDescent;
use Data::Dumper;
use Data::Compare;

my $temp = $/;
undef $/;

# Try to open RDB file
open (FILE, "$ARGV[0]") || die "Can't open '$ARGV[0]': $!\n";
my $rdbText = <FILE>;
close FILE;

# Try to open ALG file
open (FILE, "$ARGV[1]") || die "Can't open '$ARGV[1]': $!\n";
my $algText = <FILE>;
close FILE;

$/ = $temp;


sub printEnd {
    print "FIN\n\n";
}

sub printIdentifier {
    shift;
    #print "Identifiers: " . Dumper(@_);
    return 1;
}

sub printAttrib {
    shift;
    print Dumper(@_);
}

sub printOP {
    shift;
    #print "Operand: " . Dumper(@_) . "\n";
    return 1;
}

$RD_HINT = 1;

my @currentAttribs = [];
my %relation = ();
my $currentRelation;

sub checkAssignment {
    shift;
    
    my $relationName = $_[0];
    my $queryResult = $_[-1];
    
    #print "RelationName: $relationName QueryResult: " . Dumper($queryResult);
    $relation{$relationName} = $queryResult;
}

my $generalGrammar = q(
    startrule : query_definition(s?) eofile | <error>

    eofile : /^\\Z/ { main::printEnd(); return 1; }
    
    comment : /^%+(.*?)$/m
    identifier : /[a-zA-Z][a-zA-Z0-9]*/m
    
    # Types
    # TODO: Add double quotes to "char" type
    char : /'(.*?)'/i
    int : /[+-]?\\d+/
    float : /[+-]?\\d+(?:\\.\\d+)?/
    numeric : float | int
    
    constant : char | numeric
    
    query_definition : comment | assignment_statement ';' | query ';'
    
    assignment_statement : relation_name '(' attribute_list(s /,/) ')' ':=' query | relation_name ':=' query { main::checkAssignment(@item); }
    
    attribute_list : identifier
    relation_name : identifier
);

sub parseProject {
    shift;
    my $attributes = $_[1];
    my $expression = $_[3];
    
    # print "Attr: " . Dumper($attributes) . "\nExpr: " . Dumper($expression) . "\n";

    # Check attributes
    
    # Do the actual projection
    my @temp;
    foreach my $tempHash (@{$relation{$expression}}) {
        my %anotherHash;
        # Slice and recombine into a hash
        @anotherHash{@{$attributes}} = @{$tempHash}{@{$attributes}};
        my $found = 0;
        foreach my $tempAnother (@temp) {
            if (Compare($tempAnother, {%anotherHash})) { $found = 1; last; }
        }
        push(@temp, {%anotherHash}) unless $found;
    }
    
    #print "Temp: " . Dumper(@temp);
    return \@temp;
}

my $algGrammar = $generalGrammar . q(
    query : expression
    
    liteExpression : '(' expression ')' | identifier
    expression : select_expr | project_expr | binary_expr | liteExpression
    select_expr : 'select' condition '(' expression ')'
    project_expr : 'project' attribute(s /,/) '(' expression ')' { $return = main::parseProject(@item); }
    binary_expr : liteExpression binary_op liteExpression  { main::printOP(@item); }
    
    condition : and_condition 'or' condition | and_condition
    and_condition : rel_formula 'and' and_condition | rel_formula
    rel_formula : operand relational_op operand | '(' condition ')'
    binary_op : 'union' | 'njoin' | 'product' | 'difference' | 'intersect'
    
    # subAttribute : '.' identifier { $return = $item[2]; }
    attribute : identifier # subAttribute(?) { $return = [$item[1], $item[2]]; }
    operand : attribute | constant
    
    relational_op : '=' | '>' | '<' | '<>' | '>=' | '<='
);

sub addKey {
    shift;
    print "Key: " . $_[0] . "\n";
    return 1;
}

sub printRel {
    shift;
    $relation{$_[1]} = [];
    $currentRelation = \$relation{$_[1]};
    @currentAttribs = @{$_[3]};
}

sub printTuple {
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

    eofile : /^\\Z/ { main::printEnd(); return 1; }
    
    # Types
    # TODO: Add double quotes to "char" type
    char : /'(.*?)'/i { $return = main::checkChar(@item); }
    int : /[+-]?\\d+/
    float : /[+-]?\\d+(?:\\.\\d+)?/
    numeric : float | int
    
    constant : char | numeric
    
    identifier : /[a-zA-Z][a-zA-Z0-9]*/m
    
    typeName : 'char' | 'numeric'
    
    attribute : identifier '/' typeName { $return = $item[1]; }
    
    relation : '@' identifier '(' attribute(s /,/) ')' ':' identifier(s /,/) { main::printRel(@item); }
    
    tuple : constant(s /,/) { main::printTuple(@item, $thisline); }
);

# Create and compile the source file
my $rdbParser = Parse::RecDescent->new($rdbGrammar);
my $algParser = Parse::RecDescent->new($algGrammar);

# Parse database file

my $validRDB = $rdbParser->startrule($rdbText);
print "Valid RDB FILE\n" if $validRDB;
print "Invalid RDB FILE\n" unless $validRDB;

#print "CurrentTuple:" . Dumper(%currentTuple);

my $validALG = $algParser->startrule($algText);
print "Valid ALG FILE\n" if $validALG;
print "Invalid ALG FILE\n" unless $validALG;

print Dumper(%relation);

#my $main = MainWindow->new();
#$main->Button(
#        -text    => 'Quit',
#        -command => sub { exit },
#    )->pack;
#my $newtop = $main->Toplevel;
#
#MainLoop;