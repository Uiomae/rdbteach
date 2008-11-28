package gui;
use strict;
use warnings;
use Wx;
use Wx::MDI;
use Wx::Perl::Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(initGUI);

package GridWindow;

use Wx::Grid;
use Wx::Perl::Carp;
use parser;

use Wx::Event qw(EVT_GRID_CMD_SELECT_CELL);

# General constants
use Wx qw(wxID_ANY wxPOINT wxSIZE);
# Sizer constants
use Wx qw(wxVERTICAL wxHORIZONTAL wxALL wxEXPAND);
# Grid constants
use Wx qw(wxGridSelectRows);

my $ID_RELATION_GRID = 10;

use base 'Wx::MDIChildFrame';

my (%relation, %attribs, $splitter);

sub onRelationSelect {
    my ($self, $event) = @_;

    my $object = $event->GetEventObject();
    my $tableData = $relation{$object->GetCellValue($event->GetRow(), 0)};

    my $win2 = $splitter->GetWindow2();

    # Stop redrawing
    $win2->Freeze();
    # Destroy existing grid if any
    $win2->DestroyChildren();

    # Add a new grid
    my $grid = Wx::Grid->new($win2, wxID_ANY);

    $grid->CreateGrid(scalar @{$tableData}, 4);
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

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);  # call the superclass' constructor
    # Stop redrawing
    $self->Freeze();
    my $title = $self->GetTitle();

    $splitter = Wx::SplitterWindow->new($self, wxID_ANY);
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
    if ($title eq "RDB") {
        my @temp = parser::parseRDB($fileText);
        if (@temp == 0) {
            croak "Error parsing RDB file";
        } else {
            %relation = %{$temp[0][0]};
            %attribs = %{$temp[0][1]};
        }
    }

    my $nRows = scalar keys(%relation);

    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $grid = Wx::Grid->new($win1, $ID_RELATION_GRID);
    $grid->CreateGrid( $nRows, 2 );

    my $counter = 0;
    while(my ($key, $value) = each(%relation)) {
        $grid->SetCellValue($counter, 0, $key);
        $grid->SetCellValue($counter++, 1, scalar @{$value});
    }

    EVT_GRID_CMD_SELECT_CELL($self, $ID_RELATION_GRID, \&onRelationSelect);

    $grid->SetColLabelValue(0, "Relation Name");
    $grid->SetColLabelValue(1, "# Tuples");

    $sizer->Add($grid, 1, wxEXPAND);
    # Get rid of border
    $grid->SetCellHighlightPenWidth(0);
    $grid->SetSelectionMode(wxGridSelectRows);
    $grid->EnableEditing(0);
    $grid->AutoSize();
    $grid->SetRowLabelSize(40);

    $win1->SetSizer($sizer);

    $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $win2->SetSizer($sizer);

    $splitter->SplitVertically($win1, $win2, $grid->GetSize()->GetWidth());
    $win1->GetSizer()->Layout();

    # Restart redrawing
    $self->Thaw();
}

package RDBTeachApp;

use base 'Wx::App';
use Wx::Event qw(EVT_BUTTON EVT_MENU);

# General constants
use Wx qw(wxID_ANY);
# wxMessageDialog constants
use Wx qw(wxYES_NO wxYES wxNO wxCANCEL wxOK wxICON_ERROR wxICON_QUESTION wxICON_INFORMATION);

my $ID_FILE_OPEN = 1;
my $ID_FILE_NEWDB = 2;
my $ID_FILE_NEWQUERY = 3;
my $ID_FILE_EXIT = 4;

my $frame;

# TODO: Replace that with an override of wxApp::OnExit
sub onFileExit {
    my ($self, $event) = @_;
    if (Wx::MessageBox("Do you really want to quit?", "Exit RDBTeach", wxYES_NO) == wxYES) {
        # The "Good Thing To Do" is remove the top level window
        $self->ExitMainLoop();
    }
}

sub onOpen {
    my ($self, $event) = @_;

    my $file = Wx::FileSelector("Select file to open", ".", "", "", "WinRDBI files (*.rdb, *.alg)|*.rdb;*.alg|RDB Database (*.rdb)|*.rdb|Relational Algebra files (*.alg)|*.alg");
    if ($file) {
        my $newChild = GridWindow->new($frame, wxID_ANY, $file);
    }
}

# this method is called automatically when an application object is
# first constructed, all application-level initialization is done here
sub OnInit {
    my $self = shift;
    # create a new frame (a frame is a top level window)
    $frame = Wx::MDIParentFrame->new( undef,           # parent window
                                wxID_ANY,              # ID -1 means any
                                'RDBTeach beta 1',  # title
                                [-1, -1],         # default position
                                [800, 600],       # size
                               );
    # Creates the menu
    my $menuBar = Wx::MenuBar->new();

    # File menu
    my $fileMenu = Wx::Menu->new();
    $fileMenu->Append($ID_FILE_OPEN, "&Open");
    $fileMenu->AppendSeparator();
    $fileMenu->Append($ID_FILE_NEWDB, "New &Database");
    $fileMenu->Append($ID_FILE_NEWQUERY, "New &Query");
    $fileMenu->AppendSeparator();
    $fileMenu->Append($ID_FILE_EXIT, "&Exit");

    # Help menu
    my $helpMenu = Wx::Menu->new();
    $helpMenu->Append(wxID_ANY, "&Help");
    $helpMenu->AppendSeparator();
    $helpMenu->Append(wxID_ANY, "&About");

    # Events
    EVT_MENU($self, $ID_FILE_EXIT, \&onFileExit);
    EVT_MENU($self, $ID_FILE_OPEN, \&onOpen);

    # Append all menus
    $menuBar->Append($fileMenu, "&File");
    $menuBar->Append($helpMenu, "&Help");

    $frame->SetMenuBar($menuBar);
    # End creating the menu

    $self->SetTopWindow($frame);
    # show the frame
    $frame->Show( 1 );
}

package main;

sub initGUI {
    # create the application object, this will call OnInit
    my $app = RDBTeachApp->new;
    # process GUI events from the application this function will not
    # return until the last frame is closed
    $app->MainLoop;
}

1;
