#    RDBTeach: An open source software to teach and learn query languages for relational databases
#    Copyright (C) 2008  Uiomae <uiomae@gmail.com>
#
#    This file is part of RDBTeach.
#
#    RDBTeach is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    RDBTeach is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with RDBTeach.  If not, see <http://www.gnu.org/licenses/>.

=begin nd
    Package: parser
        Holds the grammars and functions to parse databases and queries.
=cut
package parser;

$main::RD_HINT = 1;

=begin nd
    Group: Generic Variables
=cut

use strict;
use warnings;
use Parse::RecDescent;
use Data::Dumper;
use Data::Compare;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parseRDB parseALG);

=begin nd
    Variables: Global Variables
        This list of variables has to be substituted to package variables.

        %relation - Holds a list of the current compiled relations
        %attribs - Holds a list of the current compiled attributes (name / type)
        $currentRelation - Holds a reference to the current relation in use (for
            adding, etc) from <%relation>
        @currentAttribs - Holds a list to the current attributes in use (for
            adding, etc).
=cut
my %relation = ();
my %attribs = ();
my $currentRelation;
my @currentAttribs = [];

=begin nd
    Group: General Grammar
=cut

=begin nd
    Function: checkAssignment
        This function assigns the query and attributes passed by parameter to the
        relation variable also passed.

    Parameters:
        $relationName - The name of the relation to assign to.
        $queryResult - Query result and attributes name / type.

    Returns:
        Nothing
=cut
sub checkAssignment {
    shift;

    my $relationName = $_[0];
    my $queryResult = $_[-1];

    #print "RelationName: $relationName QueryResult: " . Dumper($queryResult);
    $relation{$relationName} = @{$queryResult}[0];
    $attribs{$relationName} = @{$queryResult}[1];
}


=begin nd
    Variable: $generalGrammar
        Holds the grammar for all the querys common format (identifiers, comments,
        etc).
=cut
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

=begin nd
    Group: Relational Algebra Grammar
=cut

=begin nd
    Function: parseProject
        This function is called when a project operation is made. Makes the actual
        projection.

    Parameters:
        $attributes - The attributes to project
        @expression - The expression on which the projection has to be made

    Returns:
        The resulting projection (a pair of relation and attributes name / type)
=cut
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

=begin nd
    Function: parseLiteExpression
        This function checks if the liteExpression on the grammar was an identifier
        or a resulting query.

    Parameters:
        An expression or an identifier

    Returns:
        The passed expression or a new one from the passed identifier
=cut
sub parseLiteExpression {
    shift;
    return $_[0] if (ref($_[0]) eq "ARRAY");

    my $itemName = $_[0];
    return [$relation{$itemName}, $attribs{$itemName}];
}

=begin nd
    Function: opUnion
        This function performs a binary operation (union) on two operands.

    Parameters:
        $op1 - The first operand
        $op2 - The second operand

    Returns:
        The result of the operation as pair of relation and attributes name / type
=cut
sub opUnion {
    my @op1 = @{$_[0]};
    my @op2 = @{$_[1]};

}

=begin nd
    Function: opNJoin
        This function performs a binary operation (natural join) on two operands.

    Parameters:
        $op1 - The first operand
        $op2 - The second operand

    Returns:
        The result of the operation as pair of relation and attributes name / type
=cut
sub opNJoin {
    my @op1 = @{$_[0]};
    my @op2 = @{$_[1]};

}

=begin nd
    Function: opProduct
        This function performs a binary operation (product) on two operands.

    Parameters:
        $op1 - The first operand
        $op2 - The second operand

    Returns:
        The result of the operation as pair of relation and attributes name / type
=cut
sub opProduct {
    my @op1 = @{$_[0]};
    my @op2 = @{$_[1]};

}

=begin nd
    Function: opDifference
        This function performs a binary operation (difference) on two operands.

    Parameters:
        $op1 - The first operand
        $op2 - The second operand

    Returns:
        The result of the operation as pair of relation and attributes name / type
=cut
sub opDifference {
    my @op1 = @{$_[0]};
    my @op2 = @{$_[1]};

}

=begin nd
    Function: opIntersect
        This function performs a binary operation (intersection) on two operands.

    Parameters:
        $op1 - The first operand
        $op2 - The second operand

    Returns:
        The result of the operation as pair of relation and attributes name / type
=cut
sub opIntersect {
    my @op1 = @{$_[0]};
    my @op2 = @{$_[1]};

}

=begin nd
    Variable: $algGrammar
        Holds the grammar for the relational algebra querys.
=cut
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

=begin nd
    Group: RDB Database Grammar
=cut

=begin nd
    Function: addRelation
        This function adds a new relation to <%relation>.

    Parameters:
        $relationName - The name of the relation

    Returns:
        Nothing
=cut
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

=begin nd
    Function: addTuple
        This function adds a new tuple to <%currentRelation>.

    Parameters:
        @tuple - The tuple to add

    Returns:
        Nothing
=cut
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

=begin nd
    Function: checkChar
        This function removes the quotes from strings

    Parameters:
        $string - The string to modify

    Returns:
        The new string without quotes
=cut
sub checkChar {
    shift;
    my $tempString = $_[0];
    $tempString =~ s/'//g;
    return $tempString;
}

=begin nd
    Variable: $rdbGrammar
        Holds the grammar for the RDB databases.
=cut
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

=begin nd
    Group: External Interface
=cut

=begin nd
    Variables: Actual parsers
        $rdbParser - Contains the compiled RDB database parser
        $algParser - Contains the compiled relational algebra parser
=cut
# Compile grammars
my $rdbParser = Parse::RecDescent->new($rdbGrammar);
my $algParser = Parse::RecDescent->new($algGrammar);

=begin nd
    Function: parseRDB
        This function parses a relation.

    Parameters:
        $rdbText - The text of the RDB database

    Returns:
        An array with the relation and its attributes, or 0 if any error was encountered
=cut
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

=begin nd
    Function: parseALG
        This function parses a relational algebra code.

    Parameters:
        $algText - The code of the relational algebra queries.
        $DBRelation - A reference to the database relations
        $DBAttribs - A reference to the database relations attributes

    Returns:
        An array with the relation and its attributes, or with the text and line
        number if any error was encountered
=cut
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
