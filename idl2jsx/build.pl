#!/usr/bin/env perl
use 5.10.0;
use strict;
use warnings;
use Text::Xslate;
use File::Path qw(mkpath);
use Data::Section::Simple;
use Fatal qw(open close);
use File::Basename qw(dirname);
use Storable qw(lock_retrieve);
use Tie::IxHash;
use String::ShellQuote;

my $lib = "lib/js/js";
mkpath $lib;

# the order is important!

my $root = dirname(__FILE__);
unlink "$root/.idl2jsx.bin";

my @specs = (
    ['web.jsx' =>
        # DOM spec
        #'http://www.w3.org/TR/DOM-Level-3-Core/idl/dom.idl',
        'dom; http://www.w3.org/TR/dom/',
        'DOM-Level-2-Views; http://www.w3.org/TR/DOM-Level-2-Views/idl/views.idl',
        'DOM-Level-3-Events; http://www.w3.org/TR/DOM-Level-3-Events/',
        "$root/extra/events.idl",

        'XMLHTTPRequest; http://www.w3.org/TR/XMLHttpRequest/',

        #'http://html5labs.interoperabilitybridges.com/dom4events/', # no correct IDL

        # CSS
        'cssom; http://dev.w3.org/csswg/cssom/',
        'cssom-view; http://dev.w3.org/csswg/cssom-view/',
        "$root/extra/chrome.idl",
        "$root/extra/firefox.idl",

        # SVG
        #"http://www.w3.org/TR/2011/REC-SVG11-20110816/svg.idl",

        # HTML5
        #'http://dev.w3.org/html5/spec/single-page.html', # too new
        'html5; http://www.w3.org/TR/html5/single-page.html',
        # 'http://www.w3.org/TR/FileAPI/', # has an union member FileReader#result
        'FileAPI; http://www.w3.org/TR/2011/WD-FileAPI-20111020/',

        #"http://www.w3.org/TR/webaudio/", # no correct IDL
        "webaudio; https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html",
        "touch-events; http://www.w3.org/TR/touch-events/",
        #"http://www.w3.org/TR/websockets/",
        "websockets; http://www.w3.org/TR/2012/WD-websockets-20120524/",
        #"http://dev.w3.org/html5/websockets/", # too new
        "geo; http://dev.w3.org/geo/api/spec-source.html",
        "webstorage; http://dev.w3.org/html5/webstorage/",
        'selectors-api; http://www.w3.org/TR/selectors-api/',
        "webmessaging; http://www.w3.org/TR/webmessaging/",
        "workers; http://www.w3.org/TR/workers/",
        "eventsource; http://www.w3.org/TR/eventsource/",
        #"http://dev.w3.org/html5/eventsource/", # too new

        # WebRTC has no correct IDL
        #"http://dev.w3.org/2011/webrtc/editor/webrtc.html",
        #"http://dev.w3.org/2011/webrtc/editor/getusermedia.html",
        "mediacapture-streams; http://www.w3.org/TR/mediacapture-streams/",

        # by html5.org
        "dom-parsing; http://html5.org/specs/dom-parsing.html",

        # graphics
        'typedarray; https://www.khronos.org/registry/typedarray/specs/latest/typedarray.idl',
        '2dcontext; http://dev.w3.org/html5/2dcontext/',
        'webgl; https://www.khronos.org/registry/webgl/specs/latest/webgl.idl',

        # vender extensions
        'GamepadAPI; https://wiki.mozilla.org/GamepadAPI',

        # additionals
        "$root/extra/timers.idl",
        "$root/extra/draft.idl",
        "$root/extra/legacy.idl",
        "$root/extra/sequence.idl",
    ],
);

my $HEADER = <<'T';
// THIS FILE IS AUTOMATICALLY GENERATED.
T

my $xslate = Text::Xslate->new(
    path  => [ Data::Section::Simple->new->get_data_section() ],
    type => "text",

    function => {
    },
);

foreach my $spec(@specs) {
    my($file, @idls) = @{$spec};
    say "generate $file from ", join ",", @idls;

    my $args = shell_quote(@idls);
    my %param = (
        idl => scalar(`idl2jsx/idl2jsx.pl --refresh-specs --continuous $args`),
    );
    if($? != 0) {
        die "Cannot convert @idls to JSX.\n";
    }

    $param{classdef} = lock_retrieve("$root/.idl2jsx.bin");
    $param{html_elements} = [
        map  {
            ($_->{func_name} = $_->{name}) =~ s/^HTML//;
            my $tag_name = lc $_->{func_name};
            $tag_name =~ s/element$//;
            $_->{tag_name} = $tag_name;
            $_; }
        grep { $_->{base} ~~ "HTMLElement"  } values %{ $param{classdef} },
    ];

    my $src = $xslate->render($file, \%param);

    open my($fh), ">", "$lib/$file";
    print $fh $HEADER;
    print $fh $src;
    close $fh;
}

__DATA__
@@ web.jsx
/**

Web Browser Interface

*/
import "js.jsx";

/**

Document Object Model in Web Browsers

*/
final class dom {
	static const window   = js.global["window"]   as __noconvert__ Window;       // dom.window
	static const document = js.global["document"] as __noconvert__ HTMLDocument; // dom.document

	/** alias to <code>dom.document.getElementById(id) as HTMLElement</code> */
	static function id(id : string) : HTMLElement {
		return dom.document.getElementById(id) as HTMLElement;
	}
	/** alias to <code>dom.document.getElementById(id) as HTMLElement</code> */
	static function getElementById(id : string) : HTMLElement {
		return dom.document.getElementById(id) as HTMLElement;
	}


	/** alias to <code>dom.document.createElement(id) as HTMLElement</code> */
	static function createElement(tag : string) : HTMLElement {
		return dom.document.createElement(tag) as __noconvert__ HTMLElement;
	}

}

: $idl

