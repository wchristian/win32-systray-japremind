use strict;
use warnings;

use lib 'local/lib/perl5';

use Win32::SysTray;
use Win32::Detached;

my $tray = Win32::SysTray->new( 'icon' => 'unknown.ico', 'single' => 1 ) or exit 0;

$tray->{do_icon}   = Win32::GUI::Icon->new( "jap.ico" );
$tray->{stop_icon} = Win32::GUI::Icon->new( "english.ico" );
die "Error - Could not load icon ($tray->{icon})" if !$tray->{stop_icon};

$tray->{icon_active} = 1;

$tray->setMenu(
    "> &Doing English" => \&not_doing_jap,
    "> &Doing Jap"     => \&doing_jap,
    ">-"               => 0,
    "> E&xit"          => sub { return -1 },
);

my $timers = $tray->{timers} ||= { map { $_ => $tray->{DummyWindow}->AddTimer( $_ ) } qw( do_jap stop_jap blink ) };

$tray->runApplication;

sub blink_Timer {
    if ( $tray->{icon_active} ) {
        $tray->{Tray}->Change( -icon => undef );
        $tray->{icon_active} = 0;
        return;
    }
    $tray->{Tray}->Change( -icon => $tray->{trayicon} );
    $tray->{icon_active} = 1;
    return;
}

sub do_jap_Timer   { start_blink( $tray, $timers, 'do_icon',   'do_jap' ) }
sub stop_jap_Timer { start_blink( $tray, $timers, 'stop_icon', 'stop_jap' ) }

sub not_doing_jap { change_state( $tray, $timers, 'stop_icon', 'do_jap',   ( 60 * 60 * 1000 ) ) }
sub doing_jap     { change_state( $tray, $timers, 'do_icon',   'stop_jap', ( 3 * 60 * 1000 ) ) }

sub start_blink {
    my ( $tray, $timers, $icon_to_show, $timer_to_stop ) = @_;
    $timers->{$timer_to_stop}->Kill;
    $tray->{trayicon} = $tray->{$icon_to_show};
    $timers->{blink}->Interval( 250 );
    return;
}

sub change_state {
    my ( $tray, $timers, $icon_to_show, $timer_to_start, $interval ) = @_;

    show_icon( $tray, $timers, $icon_to_show );

    $timers->{$timer_to_start}->Interval( $interval );
    return;
}

sub show_icon {
    my ( $tray, $timers, $icon_to_show ) = @_;

    $timers->{blink}->Kill;
    $tray->{trayicon} = $tray->{$icon_to_show};
    $tray->{Tray}->Change( -icon => $tray->{trayicon} );
    $tray->{icon_active} = 1;

    return;
}
