package Progress::Any::Output::TermMessage;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub output_data {
    +{
        # do not throttle the frequency of update to this output
        freq => 0,
    };
}

sub new {
    my ($class, %args0) = @_;

    my %args;

    $args{fh} = delete($args0{fh});
    $args{fh} //= \*STDERR;

    $args{template}          = delete($args0{template}) // "(%P/%T) %m";
    $args{single_line_task}  = delete($args0{single_line_task}) // 0;

    keys(%args0) and die "Unknown output parameter(s): ".
        join(", ", keys(%args0));

    bless \%args, $class;
}

sub update {
    my ($self, %args) = @_;

    return unless $ENV{PROGRESS_TERM_MESSAGE} // $ENV{PROGRESS} // (-t $self->{fh});

    my $p = $args{indicator};

    my $s = $p->fill_template($self->{template}, %args);
    $s =~ s/\r?\n//g;

    if ($self->{single_line_task}) {
        if (defined($self->{prev_task}) && $self->{prev_task} ne $p->{task} ||
            $p->{finished}) {
            print { $self->{fh} } "\n";
        } elsif (defined $self->{prev_task}) {
            print { $self->{fh} } "\b" x length($self->{prev_str});
        }
    }
    print { $self->{fh} } $s;
    print { $self->{fh} } "\n" if !$self->{single_line_task} || $p->{finished};

    if ($p->{finished}) {
        undef $self->{prev_task};
        undef $self->{prev_str};
    } else {
        $self->{prev_task} = $p->{task};
        $self->{prev_str}  = $s;
    }
}

1;
# ABSTRACT: Output progress to terminal as simple message

=for Pod::Coverage ^(update|output_data)$

=head1 SYNOPSIS

 use Progress::Any::Output;
 Progress::Any::Output->set('TermMessage', template=>"[%n] (%P/%T) %m");


=head1 DESCRIPTION

This output displays progress indicators as messages on terminal.


=head1 METHODS

=head2 new(%args) => OBJ

Instantiate. Usually called through C<<
Progress::Any::Output->set("TermMessage", %args) >>.

Known arguments:

=over

=item * fh => GLOB (default: \*STDERR)

Wheere to send progress message.

=item * template => STR (default: '(%P/%T) %m')

Will be used to do C<< $progress->fill_template() >>. See L<Progress::Any> for
supported template strings.

=item * single_line_task => BOOL (default: 0)

If set to true, will reuse line using a series of C<\b> to get back to the
original position, as long as the previous update is for the same task and the
C<finished> attribute is false. For example:

 use Progress::Any;
 use Progress::Any::Output;

 Progress::Any::Output->set("TermMessage",
     single_line_task=>0, template=>"%t %m");
 my $progress = Progress::Any->get_indicator(
     task => 'copy', title => 'Copying file ... ');
 $progress->update(message=>'file1.txt');
 $progress->update(message=>'file2.txt');
 $progress->update(message=>'file3.txt');
 $progress->finish(message=>'success');

will result in:

 Copying file ... file1.txt_
 Copying file ... file2.txt_
 Copying file ... file3.txt_
 Copying file ... success
 _

all in one line.

=back


=head1 ENVIRONMENT

=head2 PROGRESS_TERM_MESSAGE

Bool. Forces disabling or enabling progress output (just for this output).

In the absence of PROGRESS_TERM_MESSAGE and PROGRESS, will default to 1 if
filehandle is tested to be in interactive mode (using C<-t>).

=head2 PROGRESS

Bool. Forces disabling or enabling progress output (for all outputs).


=head1 SEE ALSO

L<Progress::Any>

=cut
