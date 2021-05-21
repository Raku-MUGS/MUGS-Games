# ABSTRACT: Client for streaming particle effect updates

use MUGS::Core;
use MUGS::Client::Genre::Test;


#| Client side of PFX tech test "game"
class MUGS::Client::Game::PFX is MUGS::Client::Genre::Test {
    has @.update-queue;
    has Lock::Async $.update-lock .= new;


    method game-type() { 'pfx' }

    method send-pause-request(&on-success?) {
        self.action-promise: hash(:type<pause>), &on-success;
    }

    method validate-and-save-update($message) {
        constant %schema = {
            format         => 'effect-arrays',
            game-id        => GameID,
            character-name => Str,
            update-sent    => Instant(Num),
            game-time      => Duration(Num),
            dt             => Duration(Num),
            effects        => [
                               {
                                   type      => Str,
                                   id        => Int,
                                   particles => array[num32],
                               }
                           ],
        };

        my $validated = $message.validated-data(%schema);
        my $delay     = $message.created - $validated<update-sent>;

        # Estimate delivery delay with an EWMA (Exponentially Weighted Moving Average)
        # my $alpha          = .1e0;
        # $!delay-estimate //= $delay;
        # $!delay-estimate   = (1 - $alpha) * $!delay-estimate + $alpha * $delay;

        $!update-lock.protect: {
            @!update-queue.push: hash(:$message, :$validated, :$delay);
        }
    }
}


# Register this class as a valid client
MUGS::Client::Game::PFX.register;
