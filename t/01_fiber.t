use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception lives_ok);

use Fiber;

subtest 'single fiber runs correctly' => sub {
    my $counter = Fiber->new(sub {
        my $n = 0;
        while (1) {
            Fiber->yield($n++);
        }
    });

    is $counter->resume, 0;
    is $counter->resume, 1;
    is $counter->resume, 2;
};

subtest 'multiple fibers run correctly' => sub {
    my $counter1 = Fiber->new(sub {
        my $n = 0;
        while (1) {
            Fiber->yield($n);
            $n += 1;
        }
    });

    my $counter2 = Fiber->new(sub {
        my $n = 0;
        while (1) {
            Fiber->yield($n);
            $n += 2;
        }
    });

    is $counter1->resume, 0;
    is $counter2->resume, 0;
    is $counter1->resume, 1;
    is $counter2->resume, 2;
};

subtest 'resume can pass value' => sub {
    my $adder = Fiber->new(sub {
        my $n = 0;
        while (1) {
            my $ret = Fiber->yield($n);
            $n = $n + $ret;
        }
    });

    is $adder->resume, 0;
    is $adder->resume(1), 1;
    is $adder->resume(2), 3;
    is $adder->resume(3), 6;
};

subtest 'first resume has its arguments passed into its code block' => sub {
    my $fiber = Fiber->new(sub {
        my ($first) = @_;
        my $second = Fiber->yield($first + 2);
    });
    is $fiber->resume(10), 12;
    is $fiber->resume(14), 14;
    like exception { $fiber->resume(18) }, qr/dead fiber called/;
};

subtest 'nested fiber runs correctly' => sub {
    my $outer = Fiber->new(sub {
        my $inner = Fiber->new(sub {
            Fiber->yield('inner');
        });
        Fiber->yield($inner->resume);
        Fiber->yield('outer');
    });
    is $outer->resume, 'inner';
    is $outer->resume, 'outer';
};

subtest 'transfer works correctly' => sub {
    my $fiber1 = Fiber->new(sub {
        Fiber->yield('fiber1');
    });
    my $fiber2 = Fiber->new(sub {
        $fiber1->transfer;
        2;
    });
    my $fiber3 = Fiber->new(sub {
        3;
    });
    is $fiber2->resume, 'fiber1';
    is $fiber3->resume, 3;
};

subtest 'dead fiber resuming raises error' => sub {
    my $fiber = Fiber->new(sub { });
    lives_ok { $fiber->resume };
    like exception { $fiber->resume }, qr/dead fiber called/;
};

done_testing;
