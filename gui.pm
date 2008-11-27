package Module;
use strict;
use warnings;
use Wx;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(initGUI);

package RDBTeachApp;

use base 'Wx::App';
my $ID_FILE_OPEN = 1;
my $ID_FILE_NEWDB = 2;
my $ID_FILE_NEWQUERY = 3;
my $ID_FILE_EXIT = 4;

# this method is called automatically when an application object is
# first constructed, all application-level initialization is done here
sub OnInit {
    my $self = shift;
    # create a new frame (a frame is a top level window)
    my $frame = Wx::Frame->new( undef,           # parent window
                                -1,              # ID -1 means any
                                'RDBTeach beta 1',  # title
                                [-1, -1],         # default position
                                [250, 150],       # size
                               );
    my $panel = Wx::Panel->new($frame, -1);
    
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
    
    # Append all menus
    $menuBar->Append($fileMenu, "&File");
        
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
