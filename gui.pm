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
    Package: gui
        Main class holding the <initGUI> function.
=cut
package gui;
use strict;
use warnings;
use Wx;
use Wx::MDI;
use Wx::Perl::Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(initGUI);

=begin nd
    Function: initGUI
        This function is called the very first time the program is run. Just initializes
        wxWidgets graphics handlers and creates a new RDBTeachApp.

    Parameters:
        None

    Returns:
        Nothing (and never until end of program execution)
=cut
sub initGUI {
    # Init image handlers
    Wx::InitAllImageHandlers();
    # create the application object, this will call OnInit
    my $app = RDBTeachApp->new;
    # process GUI events from the application this function will not
    # return until the last frame is closed
    $app->MainLoop;
}

=begin nd
    Package: GridWindow
        This class holds the grids with the results and a code editor if needed.
=cut
package GridWindow;
use strict;
use warnings;
use Wx::Grid;
use Wx::STC;
use Wx::Perl::Carp;
use parser;

use Wx::Event qw(EVT_GRID_CMD_SELECT_CELL);
use Wx::Event qw(EVT_STC_STYLENEEDED EVT_STC_CHANGE);

# General constants
use Wx qw(wxID_ANY wxPOINT wxSIZE);
use Wx qw(wxRED wxGREEN wxBLUE);
# Sizer constants
use Wx qw(wxVERTICAL wxHORIZONTAL wxALL wxEXPAND);
# Grid constants
use Wx qw(wxGridSelectRows);
# StyledTextCtrl constants
use Wx qw(wxSTC_STYLE_DEFAULT wxSTC_LEX_CONTAINER);
use Wx qw(wxSTC_INDICS_MASK wxSTC_INDIC0_MASK wxSTC_INDIC1_MASK wxSTC_INDIC2_MASK);

=begin nd
    Constants: IDs
        ID_RELATION_GRID - ID assigned to the grid for the relations
        ID_CODE_EDITOR - ID assigned to the Scintilla code editor
=cut
use constant ID_RELATION_GRID => 10;
use constant ID_CODE_EDITOR => 11;

=begin nd
    Constants: Styles
        STYLE_COMMENT - Scintilla style used on the code comments
        STYLE_KEYWORD - Scintilla style used on the code keywords
        STYLE_OPERAND - Scintilla style used on the code operands
        STYLE_STRING  - Scintilla style used on the code strings (enclosed by single quotes)
        STYLE_NUMBER  - Scintilla style used on the code numbers
=cut
use constant STYLE_COMMENT => 1;
use constant STYLE_KEYWORD => 2;
use constant STYLE_OPERAND => 3;
use constant STYLE_STRING  => 4;
use constant STYLE_NUMBER  => 5;

=begin nd
    Constants: Characters
        CHAR_LF - Line feed ASCII code
        CHAR_CR - Carriage return ASCII code
        CHAR_SPACE - Space ASCII code
        CHAR_PERCENT - Percent sign [%] ASCII code
        CHAR_SINGLEQUOTE - Single quote ['] ASCII code
        CHAR_PAREN_OPEN - Open parenthesis [(] ASCII code
        CHAR_PAREN_CLOSE - Closed parenthesis [)] ASCII code
=cut
use constant CHAR_LF => 0x0A;
use constant CHAR_CR => 0x0D;
use constant CHAR_SPACE => 0x20;
use constant CHAR_PERCENT => 0x25;
use constant CHAR_SINGLEQUOTE => 0x27;
use constant CHAR_PAREN_OPEN => 0x28;
use constant CHAR_PAREN_CLOSE => 0x29;

use base 'Wx::MDIChildFrame';

=begin nd
    Function: fillRelation
        This function creates a new grid and fills it with the contents of the
        relations present in the object. Used when loading a database or executing
        any query.

    Parameters:
        $self - Object owner

    Returns:
        The new created grid.
=cut
sub fillRelation {
    my $self = shift;
    my $splitter = ${$self->{splitter}};
    my %relation = %{$self->{relation}};

    my $win1 = $splitter->GetWindow1();
    my $nRows = scalar keys(%relation);

    # Stop redrawing
    $win1->Freeze();
    # Destroy existing grid if any
    $win1->DestroyChildren();

    # Add a new grid
    my $grid = Wx::Grid->new($win1, ID_RELATION_GRID);

    $grid->CreateGrid($nRows, 2);

    # Fill relation grid
    my $counter = 0;
    while(my ($key, $value) = each(%relation)) {
        $grid->SetCellValue($counter, 0, $key);
        $grid->SetCellValue($counter++, 1, scalar @{$value});
    }

    $grid->SetColLabelValue(0, "Relation Name");
    $grid->SetColLabelValue(1, "# Tuples");

    # Get rid of border
    $grid->SetCellHighlightPenWidth(0);
    $grid->SetSelectionMode(wxGridSelectRows);
    $grid->EnableEditing(0);
    $grid->AutoSize();
    $grid->SetRowLabelSize(40);

    $win1->GetSizer()->Add($grid, 1, wxEXPAND);
    my $width = $grid->GetSize()->GetWidth();
    $win1->GetSizer()->Layout();

    $splitter->SetSashPosition($width);

    # Restart redrawing
    $win1->Thaw();

    return $grid;
}

=begin nd
    Function: onChange
        This function fires when any change happen within the code editor
        (EVT_STC_CHANGE event). Currently used for restoring any marked line,
        but THIS DOESN'T WORK! (styles can't be changed in EVT_STC_CHANGE or
        EVT_STC_MODIFIED events)

    Parameters:
        $self - Object owner
        $event - Event information

    Returns:
        Nothing
=cut
sub onChange {
    my ($self, $event) = @_;
    my $codeEditor = ${$self->{codeEditor}};

    my $style = $codeEditor->GetStyleAt($event->GetPosition());
    if (($style & wxSTC_INDICS_MASK) == wxSTC_INDIC0_MASK) {
        $self->markLine($codeEditor->LineFromPosition($event->GetPosition()));
    }
}

=begin nd
    Function: unmarkLine
        This function unmarks any previously marked line.

    Parameters:
        $self - Object owner
        $line - Line number (starting from 0)

    Returns:
        Nothing
=cut
sub unmarkLine {
    my ($self, $line) = @_;
    my $codeEditor = ${$self->{codeEditor}};

    my ($start, $end) = (0, $codeEditor->GetLineEndPosition($line));
    $start = $codeEditor->GetLineEndPosition($line - 1) if ($line > 0);
    $codeEditor->StartStyling($start, wxSTC_INDICS_MASK);
    print "Unmarking $start $end\n";
    $codeEditor->SetStyling($end - $start, wxSTC_INDIC1_MASK);
}

=begin nd
    Function: markLine
        This function marks the line number $line.

    Parameters:
        $self - Object owner
        $line - Line number (starting from 0)

    Returns:
        Nothing
=cut
sub markLine {
    my ($self, $line) = @_;
    my $codeEditor = ${$self->{codeEditor}};

    my ($start, $end) = (0, $codeEditor->GetLineEndPosition($line));
    $start = $codeEditor->GetLineEndPosition($line - 1) if ($line > 0);
    $codeEditor->StartStyling($start, wxSTC_INDICS_MASK);
    $codeEditor->SetStyling($end - $start, wxSTC_INDIC0_MASK);
}

=begin nd
    Function: parse
        This function parses the content of the code editor in the object owner.
        The result is stored in the object internal variables relation and attribs,
        and the relation grid is filled with the new results, unless there is any
        error in the code. In this case, the first wrong line is marked and
        the error message is put on the status bar of the window.

    Parameters:
        $self - Object owner

    Returns:
        Nothing
=cut
sub parse {
    my $self = $_[0];
    my $DBRelation = $_[1];
    my $DBAttribs = $_[2];
    my $codeEditor = ${$self->{codeEditor}};
    $self->SetStatusText("");
    my @result = &{$self->{parser}}($codeEditor->GetText(), $DBRelation, $DBAttribs);
    if (ref($result[0][0]) eq "HASH") {
        $self->{relation} = $result[0][0];
        $self->{attribs} = $result[0][1];

        $self->fillRelation();
    } else {
        $self->SetStatusText($result[0][0]);
        $self->markLine($result[0][1] - 1);
    }
}

=begin nd
    Function: onStyleNeeded
        This function is called everytime an EVT_STC_STYLENEEDED event is fired.
        That happens when the user load or modify the code in the Scintilla editor.
        The function does the actual syntax highlighting. This function badly
        needs a code reformatting...

    Parameters:
        $self - Object owner
        $event - Event information

    Returns:
        Nothing
=cut
sub onStyleNeeded {
    my ($self, $event) = @_;
    my $insideAnything = 0;

    my $codeEditor = ${$self->{codeEditor}};
    my @keywords = @{$self->{keywords}};
    my @operands = @{$self->{operands}};
    my $start = $codeEditor->GetEndStyled();    # this is the first character that needs styling
    my $end = $event->GetPosition();          # this is the last character that needs styling
    my $endText = $codeEditor->GetTextLength();
    my $pos = $start;

    $codeEditor->StartStyling($start, 31);   # Style text
    my $tempStyle = $codeEditor->GetStyleAt($start - 1);
    if ($tempStyle == STYLE_COMMENT) {
        my $lineNum = $codeEditor->LineFromPosition($start);
        my $lineLast = $codeEditor->GetLineEndPosition($lineNum);
        $codeEditor->SetStyling($lineLast - $start, STYLE_COMMENT);
        $pos = $lineLast;
        # Skip endline
        while ($lineNum == $codeEditor->LineFromPosition($pos)) {
            $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
            $pos++;
        }
    } else {
        if (($tempStyle == STYLE_STRING) && ($codeEditor->GetCharAt($start - 1) != CHAR_SINGLEQUOTE)) {
            # Inside a string
            my $pos2 = $start - 1;
            while (($pos2 < $endText) && ($codeEditor->GetCharAt($pos2) != CHAR_SINGLEQUOTE)) {
                $pos2++;
            }
            $pos2++;
            $codeEditor->SetStyling($pos2 - $pos, STYLE_STRING);
            $codeEditor->SetStyling(1, STYLE_STRING);
            $pos = ++$pos2;
        }
    }
    while ($pos < $end) {
        # Iterate over lines
        my $lineNum = $codeEditor->LineFromPosition($pos);
        my $lineLast = $codeEditor->GetLineEndPosition($lineNum);
        #if ($end < $lineLast) {
        #    $lineLast = $end;
        #}
        while ($pos < $lineLast) {
            my $entered = 0;
            my $lastChar = $codeEditor->GetCharAt($pos - 1);
            while ((($pos - 1) > 0) && ($lastChar != CHAR_SPACE) && ($lastChar != CHAR_CR) && ($lastChar != CHAR_LF)
                   && ($lastChar != CHAR_PAREN_OPEN) && ($lastChar != CHAR_PAREN_CLOSE)) {
                $entered = 1;
                $pos--;
                $lastChar = $codeEditor->GetCharAt($pos - 1);
            }
            $codeEditor->StartStyling($pos, 31) if ($entered);
            $lastChar = $codeEditor->GetCharAt($pos);
            while (($pos < $lineLast) && ($lastChar == CHAR_SPACE)
                   && ($lastChar != CHAR_PAREN_OPEN) && ($lastChar != CHAR_PAREN_CLOSE)) {
                $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
                $pos++;
                $lastChar = $codeEditor->GetCharAt($pos);
            }
            my $currChar = $codeEditor->GetCharAt($pos);
            if ($currChar == CHAR_PAREN_OPEN || $currChar == CHAR_PAREN_CLOSE) {
                $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
                $pos++;
                next;
            }
            if (($currChar >= 0x30) && ($currChar <= 0x39)) {
                my $pos2 = $pos + 1;
                $lastChar = $codeEditor->GetCharAt($pos2);
                while (($pos2 < $lineLast) && ($lastChar >= 0x30) && ($lastChar <= 0x39) && ($lastChar != CHAR_CR) && ($lastChar != CHAR_LF)
                        && ($lastChar != CHAR_PAREN_OPEN) && ($lastChar != CHAR_PAREN_CLOSE)) {
                    $pos2++;
                    $lastChar = $codeEditor->GetCharAt($pos2);
                }
                $lastChar = $codeEditor->GetCharAt($pos2 - 1);
                my $nextChar = $codeEditor->GetCharAt($pos2);

                if (($lastChar >= 0x30) && ($lastChar <= 0x39) && (($nextChar == CHAR_SPACE) || ($nextChar == CHAR_CR) || ($nextChar == CHAR_LF)
                        || ($nextChar == CHAR_PAREN_OPEN) || ($nextChar == CHAR_PAREN_CLOSE))) {
                    $codeEditor->SetStyling($pos2 - $pos, STYLE_NUMBER);
                    # Style space
                    $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
                    $pos = ++$pos2;
                    next;
                }
            }
            if (($currChar == CHAR_PERCENT) && (not $insideAnything)) {
                $codeEditor->SetStyling($lineLast - $pos, STYLE_COMMENT);
                $pos = $lineLast;
            } else {
                if ($currChar == CHAR_SINGLEQUOTE) {
                    my $pos2 = $pos + 1;
                    while (($pos2 < $endText) && ($codeEditor->GetCharAt($pos2) != CHAR_SINGLEQUOTE)) {
                        $pos2++;
                    }

                    $pos2++;
                    $codeEditor->SetStyling($pos2 - $pos, STYLE_STRING);
                    # Style space
                    $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
                    $pos = ++$pos2;
                } else {
                    my $pos2 = $pos + 1;
                    $lastChar = $codeEditor->GetCharAt($pos2);
                    while (($pos2 < $lineLast) && ($lastChar != CHAR_SPACE) && ($lastChar != CHAR_CR) && ($lastChar != CHAR_LF)
                            && ($lastChar != CHAR_PAREN_OPEN) && ($lastChar != CHAR_PAREN_CLOSE)) {
                        $pos2++;
                        $lastChar = $codeEditor->GetCharAt($pos2);
                    }
                    my $word = $codeEditor->GetTextRange($pos, $pos2);

                    # Search in the list of keywords
                    if ( grep {$_ eq $word} @keywords ) {
                        # In the list of keywords, style as keyword
                        $codeEditor->SetStyling($pos2 - $pos, STYLE_KEYWORD);
                        # Style space
                        $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
                        $pos2++;
                    } else {
                        # Search in the list of operands
                        if ( grep {$_ eq $word} @operands ) {
                            # In the list of operands, style as operand
                            $codeEditor->SetStyling($pos2 - $pos, STYLE_OPERAND);
                            # Style space
                            $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
                            $pos2++;
                        } else {
                            # Not in the list of keywords or operands, style as normal (INCLUDING space)
                            $pos2++;
                            $codeEditor->SetStyling($pos2 - $pos, wxSTC_STYLE_DEFAULT);
                        }
                    }
                    $pos = $pos2;
                }
            }
        }
        # Skip endline
        while ($lineNum == $codeEditor->LineFromPosition($pos)) {
            $codeEditor->SetStyling(1, wxSTC_STYLE_DEFAULT);
            $pos++;
        }
    }
}

=begin nd
    Function: onRelationSelect
        This function is called everytime an EVT_GRID_CMD_SELECT_CELL event is fired.
        That happens when the user selects any row in the relations grid. The
        function actually creates the right grid and fills it with the selected
        relation on the left.

    Parameters:
        $self - Object owner
        $event - Event information

    Returns:
        Nothing
=cut
sub onRelationSelect {
    my ($self, $event) = @_;
    my $splitter = ${$self->{splitter}};
    my %relation = %{$self->{relation}};
    my %attribs = %{$self->{attribs}};

    my $object = $event->GetEventObject();
    my $relName = $object->GetCellValue($event->GetRow(), 0);
    my @tableData = @{$relation{$relName}};

    my $win2 = $splitter->GetWindow2();

    # Stop redrawing
    $win2->Freeze();
    # Destroy existing grid if any
    $win2->DestroyChildren();

    # Add a new grid
    my $grid = Wx::Grid->new($win2, wxID_ANY);

    my %currentAttribs = %{$attribs{$relName}};
    $grid->CreateGrid(scalar @tableData, scalar keys %currentAttribs);

    # Fill table
    my $counter = 0;
    my %colOrder = ();
    # First set the column labels
    while(my ($key, $value) = each(%currentAttribs)) {
        $colOrder{$key} = $counter;
        $grid->SetColLabelValue($counter++, $key . '/' . $value);
    }

    # Next, fill the current values
    $counter = 0;
    foreach my $tuple (@tableData) {
        while(my ($key, $value) = each(%$tuple)) {
            $grid->SetCellValue($counter, $colOrder{$key}, $value);
        }
        $counter++;
    }

    $grid->SetCellHighlightPenWidth(0);
    $grid->SetSelectionMode(wxGridSelectRows);
    $grid->EnableEditing(0);
    $grid->AutoSize();
    $grid->SetRowLabelSize(40);

    $win2->GetSizer()->Add($grid, 1, wxEXPAND);
    $win2->GetSizer()->Layout();

    # Restart redrawing
    $win2->Thaw();
}

=begin nd
    Function: isDB
        This function indicates if an object stores a database.

    Parameters:
        $self - Object owner

    Returns:
        1 - if is a database
        0 - if is not a database.
=cut
sub isDB {
    my $self = shift;
    return $self->{_isDB};
}

=begin nd
    Constructor: new
        This function is called to create a new GridWindow.

    Parameters:
        $class - Object class (GridWindow)

    Returns:
        A reference to the new created object.
=cut
sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);  # call the superclass' constructor
    # Stop redrawing
    $self->Freeze();
    my $title = $self->GetTitle();

    # Create horizontal splitter window and childs
    my $mainSplitter = Wx::SplitterWindow->new($self, wxID_ANY);
    $mainSplitter->SetSashGravity(1);
    my $mainWin1 = Wx::Panel->new($mainSplitter, wxID_ANY);
    my $mainSizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $mainWin1->SetSizer($mainSizer);

    # Create styled code editor
    my $codeEditor = Wx::StyledTextCtrl->new($mainWin1, ID_CODE_EDITOR);
    $self->{codeEditor} = \$codeEditor;

    $codeEditor->SetLexer(wxSTC_LEX_CONTAINER);
    EVT_STC_STYLENEEDED($self, ID_CODE_EDITOR, \&onStyleNeeded);
    EVT_STC_CHANGE($self, ID_CODE_EDITOR, \&onChange);

    # Styles
    $codeEditor->StyleSetFontAttr(wxSTC_STYLE_DEFAULT, 10, "Courier New", 0, 0, 0);
    $codeEditor->StyleSetForeground(STYLE_COMMENT, Wx::Colour->new(0x40, 0x80, 0x80));
    $codeEditor->StyleSetFontAttr(STYLE_KEYWORD, 10, "Courier New", 1, 0, 0);
    $codeEditor->StyleSetFontAttr(STYLE_OPERAND, 10, "Courier New", 1, 0, 0);
    $codeEditor->StyleSetForeground(STYLE_OPERAND, Wx::Colour->new(0x80, 0x50, 0x50));
    $codeEditor->StyleSetForeground(STYLE_STRING, Wx::Colour->new(0, 128, 192));
    $codeEditor->StyleSetForeground(STYLE_NUMBER, Wx::Colour->new(0x80, 0x00, 0xFF));
    # End of styles
    # End creating styled code editor

    $mainSizer->Add($codeEditor, 1, wxEXPAND);
    $mainWin1->Layout();

    my $mainWin2 = Wx::Panel->new($mainSplitter, wxID_ANY);
    $mainSizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $mainWin2->SetSizer($mainSizer);

    $mainSplitter->SplitHorizontally($mainWin1, $mainWin2, $mainSplitter->GetSize()->GetHeight() - 200);

    # Create vertical splitter, child windows and relation grid
    my $splitter = Wx::SplitterWindow->new($mainWin2, wxID_ANY);
    $mainSizer->Add($splitter, 1, wxEXPAND);

    $self->{splitter} = \$splitter;

    my $win1 = Wx::Panel->new($splitter, wxID_ANY);
    my $win2 = Wx::Panel->new($splitter, wxID_ANY);

    # Parse the file
    # Try to open and read
    my $dummy = $/;
    undef $/;
    open (FILE, "$title") || croak "Can't open '$title': $!\n";
    my $fileText = <FILE>;
    close FILE;
    $/ = $dummy;
    # Get only the extension in uppercase
    $title =~ s/.*\.(.*)/\U$1\E/;
    my (%relation, %attribs);
    $self->{relation} = \%relation;
    $self->{attribs}  = \%attribs;
    if ($title eq "RDB") {
        # Hide code editor window
        $mainWin1->Show(0);
        $mainSplitter->Initialize($mainWin2);
        $mainWin2->Layout();

        my @temp = parser::parseRDB($fileText);
        if (@temp == 0) {
            croak "Error parsing RDB file";
        } else {
            $self->{_isDB} = 1;
            %relation = %{$temp[0][0]};
            %attribs = %{$temp[0][1]};
        }
    } else {
        $self->{_isDB} = 0;
        if ($title eq "ALG") {
            $codeEditor->SetText($fileText);
            $codeEditor->EmptyUndoBuffer();
            my @keywords = qw(select project);
            my @operands = qw(union njoin product difference intersect);
            $self->{keywords} = \@keywords;
            $self->{operands} = \@operands;
            $self->{parser} = \&parser::parseALG;
            %relation = ();
            %attribs = ();
        } else {
            croak "Filetype '$title' not recognized";
        }
    }


    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);

    EVT_GRID_CMD_SELECT_CELL($self, ID_RELATION_GRID, \&onRelationSelect);

    $win1->SetSizer($sizer);

    $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $win2->SetSizer($sizer);

    #, $grid->GetSize()->GetWidth()
    $splitter->SplitVertically($win1, $win2);
    $self->fillRelation();

    my $statusBar = $self->CreateStatusBar();

    # Restart redrawing
    $self->Thaw();
    return $self;
}

=begin nd
    Package: RDBTeachApp
        Main application package. Creates the main MDI window, menus and toolbar.
=cut
package RDBTeachApp;
use strict;
use warnings;
use Wx::Perl::Carp;
use parser;

use base 'Wx::App';
use Wx::Event qw(EVT_BUTTON EVT_MENU EVT_TOOL);

use Wx qw(wxSIZE);

# General constants
use Wx qw(wxID_ANY wxNO_BORDER);
# wxMessageDialog constants
use Wx qw(wxYES_NO wxYES wxNO wxCANCEL wxOK wxICON_ERROR wxICON_QUESTION wxICON_INFORMATION);
# Image constants
use Wx qw(wxBITMAP_TYPE_PNG);
# Toolbar constants
use Wx qw(wxTB_FLAT wxTB_HORIZONTAL);

=begin nd
    Constants: IDs
        ID_FILE_OPEN - ID assigned to the menu entry "File->Open" and "Open" toolbar button
        ID_FILE_NEWDB - ID assigned to the menu entry "File->New Database" and "New Database" toolbar button
        ID_FILE_NEWQUERY - ID assigned to the menu entry "File->New Query" and "New Query" toolbar button
        ID_FILE_EXIT - ID assigned to the menu entry "File->Exit"

        ID_CODE_EXECUTE - ID assigned to the "Execute" toolbar button
=cut
use constant ID_FILE_OPEN => 1;
use constant ID_FILE_NEWDB => 2;
use constant ID_FILE_NEWQUERY => 3;
use constant ID_FILE_EXIT => 4;

use constant ID_CODE_EXECUTE => 5;

=begin nd
    Function: onFileExit
        This function is called when the "File->Exit" menu entry is selected, and
        asks the user before exiting if he really wants to close the application.

    Parameters:
        $self - Object owner
        $event - Event information

    Returns:
        Nothing
=cut
# TODO: Replace that with an override of wxApp::OnExit
sub onFileExit {
    my ($self, $event) = @_;
    if (Wx::MessageBox("Do you really want to quit?", "Exit RDBTeach", wxYES_NO) == wxYES) {
        # The "Good Thing To Do" is remove the top level window
        $self->ExitMainLoop();
    }
}

=begin nd
    Function: onOpen
        This function is fired when the user selects "File->Open" or clicks on the
        "Open" toolbar button. It opens a file and creates a new child window for
        it. Also, if the file is a database, gets its relation and attribs.

    Parameters:
        $self - Object owner
        $event - Event information

    Returns:
        Nothing
=cut
sub onOpen {
    my ($self, $event) = @_;

    my $file = Wx::FileSelector("Select file to open", ".", "", "", "WinRDBI files (*.rdb, *.alg)|*.rdb;*.alg|RDB Database (*.rdb)|*.rdb|Relational Algebra files (*.alg)|*.alg");
    if ($file) {
        my $frame = ${$self->{frame}};
        my $newChild = GridWindow->new($frame, wxID_ANY, $file);
        if ($newChild->isDB()) {
            # TODO: Check if this relation is still valid at every execution (we can close the database)
            $self->{DBRelation} = $newChild->{relation};
            $self->{DBAttribs} = $newChild->{attribs};
        }
    }
}

=begin nd
    Function: onExecute
        This function is fired when the user clicks on the "Execute" toolbar button.
        It tries to parse the code present in the focused child window.

    Parameters:
        $self - Object owner
        $event - Event information

    Returns:
        Nothing
=cut
sub onExecute {
    my ($self, $event) = @_;

    my $frame = ${$self->{frame}};
    my $child = $frame->GetActiveChild();
    if ($child) {
        $child->parse($self->{DBRelation}, $self->{DBAttribs});
    }
}

=begin nd
    Function: OnInit
        This method is called automatically when an application object is
        first constructed, all application-level initialization is done here.

    Parameters:
        $self - RDBTeachApp class

    Returns:
        Nothing
=cut
sub OnInit {
    my $self = shift;

    # create a new frame (a frame is a top level window)

    # Variable: $frame
    # Stores the current MDI parent of all child windows
    my $frame = Wx::MDIParentFrame->new( undef,           # parent window
                                wxID_ANY,              # ID -1 means any
                                'RDBTeach beta 1',  # title
                                [-1, -1],         # default position
                                [800, 600],       # size
                               );
    $self->{frame} = \$frame;
    # Load images

=begin nd
    Variables: Icons
        iconOpen - Icon used for the "Open" command (see folder.png)
        iconNewDB - Icon used for the "New Database" command (see database_lightning.png)
        iconNewQuery - Icon used for the "New Query" command (see script_lightning.png)
        iconExecute - Icon used for the "Execute" command (see flag_green.png)
=cut
    my $iconOpen = Wx::Bitmap->new("icons/folder.png", wxBITMAP_TYPE_PNG);
    my $iconNewDB = Wx::Bitmap->new("icons/database_lightning.png", wxBITMAP_TYPE_PNG);
    my $iconNewQuery = Wx::Bitmap->new("icons/script_lightning.png", wxBITMAP_TYPE_PNG);
    my $iconExecute = Wx::Bitmap->new("icons/flag_green.png", wxBITMAP_TYPE_PNG);
    # End loading images

    # Creates the menu
    my $menuBar = Wx::MenuBar->new();

    # File menu
    my $fileMenu = Wx::Menu->new();
    $fileMenu->Append(ID_FILE_OPEN, "&Open");
    $fileMenu->AppendSeparator();
    $fileMenu->Append(ID_FILE_NEWDB, "New &Database");
    $fileMenu->Append(ID_FILE_NEWQUERY, "New &Query");
    $fileMenu->AppendSeparator();
    $fileMenu->Append(ID_FILE_EXIT, "&Exit");

    # Help menu
    my $helpMenu = Wx::Menu->new();
    $helpMenu->Append(wxID_ANY, "&Help");
    $helpMenu->AppendSeparator();
    $helpMenu->Append(wxID_ANY, "&About");

    # Events
    EVT_MENU($self, ID_FILE_EXIT, \&onFileExit);
    EVT_MENU($self, ID_FILE_OPEN, \&onOpen);

    # Append all menus
    $menuBar->Append($fileMenu, "&File");
    $menuBar->Append($helpMenu, "&Help");

    $frame->SetMenuBar($menuBar);
    # End creating the menu

    # Creates the toolbar
    my $toolBar = $frame->CreateToolBar(wxNO_BORDER | wxTB_FLAT | wxTB_HORIZONTAL);
    $toolBar->SetToolBitmapSize(wxSIZE(16, 16));
    # Using the same IDs as their menu counterparts make the events working for all of them!
    $toolBar->AddTool(ID_FILE_OPEN, "Open", $iconOpen);
    $toolBar->AddSeparator();
    $toolBar->AddTool(ID_FILE_NEWDB, "New Database", $iconNewDB);
    $toolBar->AddTool(ID_FILE_NEWQUERY, "New Query", $iconNewQuery);
    $toolBar->AddSeparator();
    $toolBar->AddTool(ID_CODE_EXECUTE, "Execute", $iconExecute);
    $toolBar->Realize();
    # End creating the toolbar

    EVT_TOOL($self, ID_CODE_EXECUTE, \&onExecute);

    # Creates the statusbar
    my $statusBar = $frame->CreateStatusBar();
    $statusBar->SetStatusText("RDBTeach ready");
    # End creating the statusbar

    $self->SetTopWindow($frame);
    # show the frame
    $frame->Show( 1 );
}

1;
