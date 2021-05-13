# ABSTRACT: Server for particle effect tech test

use MUGS::Core;
use MUGS::Server::Genre::Test;
use MUGS::Server::LogTimelineSchema;


role ParticleEffect {
    has Num() $.start-game-time;
    has @.particles;

    method remove-particles(  num $et, num $dt) { ... }
    method update-particles(  num $et, num $dt) { ... }
    method generate-particles(num $et, num $dt) { ... }

    method update-effect(Num() :$game-time, Num() :$delta-time) {
        my num $et = $game-time - $.start-game-time;
        my num $dt = $delta-time;

        self.remove-particles(  $et, $dt);
        self.update-particles(  $et, $dt);
        self.generate-particles($et, $dt);
    }
}


# XXXX: Wanted to parametrize this so as to be able to initialize
#       $!particle-attributes with `array[T].new`, and skip the boilerplate
#       TWEAK in composing classes.  Alas, see this issue for why I haven't:
#
#           https://github.com/rakudo/rakudo/issues/4361

role ParticleEffectStorage {
    has UInt:D $.attributes-per-particle is required;
    has $!particle-attributes;

    method particle-storage() { $!particle-attributes }
    method particle-count()   { $!particle-attributes.elems div $!attributes-per-particle }

    method particle-info($particle-index) {
        my $start-pos = $!attributes-per-particle * $particle-index;
        $!particle-attributes[$start-pos ..^ ($start-pos + $!attributes-per-particle)]
    }

    method particle-attribute($particle-index, $attribute-index) is raw {
        $!particle-attributes[$!attributes-per-particle * $particle-index
                              + $attribute-index]
    }
}


my class PFXNumStorage does ParticleEffectStorage {
    submethod TWEAK() {
        $!particle-attributes = array[num32].new;
    }

    method add-particle(Num:D :$x, Num:D :$y, Num:D :$vx, Num:D :$vy,
                        Num:D :$ax, Num:D :$ay, Num:D :$tc) {
        $!particle-attributes.append($x, $y, $vx, $vy, $ax, $ay, $tc);
    }
}


my class Particle {
    has PFXNumStorage:D $.num-storage is required;
    has UInt:D          $.index       is required;

    method attribute-counts() { num32 => 7 }

    method x  is raw { $!num-storage.particle-attribute($!index, 0) }  # Position
    method y  is raw { $!num-storage.particle-attribute($!index, 1) }
    method vx is raw { $!num-storage.particle-attribute($!index, 2) }  # Velocity
    method vy is raw { $!num-storage.particle-attribute($!index, 3) }
    method ax is raw { $!num-storage.particle-attribute($!index, 4) }  # Acceleration
    method ay is raw { $!num-storage.particle-attribute($!index, 5) }
    method tc is raw { $!num-storage.particle-attribute($!index, 6) }  # Time created
}


my class ParticleFountain does ParticleEffect {
    has $.num-storage = PFXNumStorage.new(:attributes-per-particle(Particle.attribute-counts()<num32>));


    # For now, just never remove a particle
    method remove-particles(num $et, num $dt) { }

    method update-particles(num $et, num $dt) {
        my num $dt2 = $dt / 2e0;

        for @.particles {
            # "Velocity Verlet" integration
            .x += (.vx + .ax * $dt2) * $dt;
            .y += (.vy + .ay * $dt2) * $dt;

            # XXXX: Recalc new acceleration at end of timestamp into $ax₁, $ay₁
            # XXXX: For now, just make acceleration constant
            my $ax1 =    0e0;
            my $ay1 = -9.8e0/3e1;
            # my $ax1 = .ax;
            # my $ay1 = .ay;

            .vx += (.ax + $ax1) * $dt2;
            .vy += (.ay + $ay1) * $dt2;

            .ax = $ax1;
            .ay = $ay1;
        }
    }

    method generate-particles(num $et, num $dt) {
        my $count = $.num-storage.particle-count;
        if $count < 200 {
            $.num-storage.add-particle(x  => 0e0,  y  => 0e0,
                                       vx => rand - 0.5e0,
                                       vy => rand - 0.5e0,
                                       ax => 0e0,  ay => 0e0,
                                       tc => $et,
                                      );
            @.particles.push(Particle.new(:$.num-storage, :index($count)));
        }
    }

    method state-info() {
        hash(:type($?CLASS.^name), :particles($.num-storage.particle-storage))
    }
}


#| Server side of PFX tech test "game"
class MUGS::Server::Game::PFX is MUGS::Server::Genre::Test {
    has $.dt;
    has @.effects;


    method game-type() { 'pfx' }
    method game-desc() { 'Test "game" that generates particle effects' }

    method valid-action-types() { < nop pause > }

    method ensure-action-valid(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        callsame;
    }

    method process-action-pause(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        self.set-gamestate($.gamestate == Paused ?? InProgress !! Paused);
        Empty
    }

    method update-time() {
        my $gt = $.game-time;
        callsame;
        $!dt = $.game-time - $gt;
    }

    method state-info() {
        my @effects = @.effects.map(*.state-info);
        hash(:$.dt, :$.game-time, :format('effect-arrays'), :@effects,
             :update-sent(now))
    }

    method start-game() {
        callsame;

        @!effects.push: ParticleFountain.new(:start-game-time($.game-time));

        start react whenever Supply.interval(.1) {
            done if $.gamestate >= Finished;

            MUGS::Server::LogTimelineSchema::GameStateUpdate.log: :$.game-type, :$.id, {
                self.update-time;
                if $.dt -> $delta-time {
                    my $t0 = now;
                    .update-effect(:$.game-time, :$delta-time) for @!effects;
                    printf "Update time: %6.3fms\n", (now - $t0) * 1000;
                }

                my $t0 = now;
                VM.request-garbage-collection;
                printf "GC time:     %6.3fms\n", (now - $t0) * 1000;

                my %update := self.state-info;
                for self.participants -> (:$character, :$session, :$instance) {
                    $session.push-game-update(:game-id($.id), :$character, :%update);
                }
            }
        }
    }
}


# Register this class as a valid server class
MUGS::Server::Game::PFX.register;
