#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use LWP::UserAgent;
use HTTP::Request::Common;
use File::Find;
use Time::HiRes;
use Cwd;

my $abspath;
$abspath = "^\/";

my $opt_host = "localhost";
my $opt_port = "8088";
my $opt_stream = 0;
my $opt_mailfrom = 'sender@domain.com';
my $opt_senderip = '1.2.3.4';
my $opt_key;
my $opt_help;

sub usage()
{
    print STDERR
    "USAGE: $0 [OPTION] DIR-NAME...\n"
    ."Scan DIR-NAME with ctasd\n"
    ."\n"
    ." --host     - Server host. default: $opt_host\n"
    ." --port     - Server port. default: $opt_port\n"
    ." --stream   - Send a ClassifyMessage_inline request. default: $opt_stream\n"
    ." --mailfrom - Set smtp envelope mailfrom. default: $opt_mailfrom\n"
    ." --senderip - Set smtp envelope senderip. default: $opt_senderip\n"
    ." --key     - Client authentication key (for ctasd running in authenticated mode)\n"
    ." --help    - Show this help message\n"
    ;
    exit 0;
}

my $result = GetOptions(
    'host=s'    => \$opt_host,
    'port=s'    => \$opt_port,
    'stream'    => \$opt_stream,
    'mailfrom=s'    => \$opt_mailfrom,
    'senderip=s'    => \$opt_senderip,
    'key=s'     => \$opt_key,
    'help'      => \$opt_help);

if (defined $opt_help)
{
        usage();
}

my $foldername = shift(@ARGV) || usage();
my $wd = Cwd::cwd();
chomp($wd);

my $ua = new LWP::UserAgent;

find(   sub
    {
        my $filename = $File::Find::name;
        $filename = "$wd/$filename" unless $filename =~ /$abspath/;
        return unless -f $filename;

        my $request =   "X-CTCH-PVer: 0000001\r\n".
                "X-CTCH-MailFrom: $opt_mailfrom\r\n".
                "X-CTCH-SenderIP: $opt_senderip\r\n".
                "X-CTCH-QueryOnly: false\r\n";

        # if ctasd runs in authenticated mode,
        # we append the key to the request headers
        $request .= "X-CTCH-Key: $opt_key\r\n"
            if (defined $opt_key);

        my $classify_method;
        if ($opt_stream)
        {
            $classify_method = "http://$opt_host:$opt_port/ctasd/ClassifyMessage_Inline";
            if (!open (INPUT, $filename))
            {
                 printf "couldn't open the file $filename\n";
                 return;
            }
            my $msg;
            read(INPUT, $msg, -s INPUT);
            $request .= "\r\n" . $msg;
        }
        else
        {
            $classify_method = "http://$opt_host:$opt_port/ctasd/ClassifyMessage_File";
            $request .= "X-CTCH-FileName: $filename\r\n";
        }

        my $response = $ua->request(
            POST $classify_method,
            Content => $request);

        my $data = $response->status_line . "\n";
        chomp $data;
        print "=== $filename [$data]\n";
        $data = $response->content;
        print "$data";


    },
    $foldername
);

