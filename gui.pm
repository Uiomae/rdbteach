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
use Wx::STC;
use Wx::Perl::Carp;
use parser;

use Wx::Event qw(EVT_GRID_CMD_SELECT_CELL);

# General constants
use Wx qw(wxID_ANY wxPOINT wxSIZE);
# Sizer constants
use Wx qw(wxVERTICAL wxHORIZONTAL wxALL wxEXPAND);
# Grid constants
use Wx qw(wxGridSelectRows);
# StyledTextCtrl constants
use Wx qw(wxSTC_STYLE_DEFAULT);

my $ID_RELATION_GRID = 10;
my $ID_CODE_EDITOR = 11;

use base 'Wx::MDIChildFrame';

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
    my $codeEditor = Wx::StyledTextCtrl->new($mainWin1, $ID_CODE_EDITOR);
    $self->{codeEditor} = \$codeEditor;

    $codeEditor->StyleSetFontAttr(wxSTC_STYLE_DEFAULT, 10, "Courier New", 0, 0, 0);

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
        $mainWin1->Show(0);
        $mainSplitter->Initialize($mainWin2);
        $mainWin2->Layout();
        my @temp = parser::parseRDB($fileText);
        if (@temp == 0) {
            croak "Error parsing RDB file";
        } else {
            %relation = %{$temp[0][0]};
            %attribs = %{$temp[0][1]};
        }
    } else {
        if ($title eq "ALG") {
            $codeEditor->SetText($fileText);
            %relation = ();
            %attribs = ();
        } else {
            croak "Filetype '$title' not recognized";
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

use Wx qw(wxSIZE);

# General constants
use Wx qw(wxID_ANY wxNO_BORDER);
# wxMessageDialog constants
use Wx qw(wxYES_NO wxYES wxNO wxCANCEL wxOK wxICON_ERROR wxICON_QUESTION wxICON_INFORMATION);
# Image constants
use Wx qw(wxBITMAP_TYPE_PNG);
# Toolbar constants
use Wx qw(wxTB_FLAT wxTB_HORIZONTAL);

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

    # Load images
    my $iconOpen = Wx::Bitmap->new("icons/folder.png", wxBITMAP_TYPE_PNG);
    my $iconNewDB = Wx::Bitmap->new("icons/database_lightning.png", wxBITMAP_TYPE_PNG);
    my $iconNewQuery = Wx::Bitmap->new("icons/script_lightning.png", wxBITMAP_TYPE_PNG);
    # End loading images

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

    # Creates the toolbar
    my $toolBar = $frame->CreateToolBar(wxNO_BORDER | wxTB_FLAT | wxTB_HORIZONTAL);
    $toolBar->SetToolBitmapSize(wxSIZE(16, 16));
    # Using the same IDs as their menu counterparts make the events working for all of them!
    $toolBar->AddTool($ID_FILE_OPEN, "Open", $iconOpen);
    $toolBar->AddSeparator();
    $toolBar->AddTool($ID_FILE_NEWDB, "New Database", $iconNewDB);
    $toolBar->AddTool($ID_FILE_NEWQUERY, "New Query", $iconNewQuery);
    $toolBar->Realize();
    # End creating the toolbar

    # Creates the statusbar
    my $statusBar = $frame->CreateStatusBar();
    $statusBar->SetStatusText("RDBTeach ready");
    # End creating the statusbar

    $self->SetTopWindow($frame);
    # show the frame
    $frame->Show( 1 );
}

package gui;

sub initGUI {
    # Init image handlers
    Wx::InitAllImageHandlers();
    # create the application object, this will call OnInit
    my $app = RDBTeachApp->new;
    # process GUI events from the application this function will not
    # return until the last frame is closed
    $app->MainLoop;
}

1;
