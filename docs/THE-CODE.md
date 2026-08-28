# The code

5,343 bytes of code and 11,041 of data. The main thread has been stuck in a
`jr $` since boot, so everything that follows happens inside the VDP interrupt,
fifty times a second.

## The interrupt

0x4034 does four things in this order: acknowledges the VDP — which is what
lowers the signal — steps the sound player, checks the latch at 0xE005 and, if it
is free, reads the controls and runs one step of the game.

The latch matters. Just before entering the game step, the routine does `ei`: it
**opens interrupts while it works**. If the step overruns a frame — and the
physics of seven balls does overrun — the next interrupt comes in, sees the latch
closed and leaves without doing anything but servicing the sound. The music does
not stutter even when the game is running tight.

## Sixteen states and a table with no pointer

The game step (0x4337) increments the frame counter and dispatches on 0xE000, the
state, which runs from 0 to 15.

The dispatcher (0x40A0) is not given the table's address. It does `pop hl` to
take **its own return address** and use it as the base, so the table of sixteen
words sits immediately behind the `call` that invoked it, and control never
returns there. It ends in `jp (hl)`.

There are three such tables in the cartridge: the sixteen states behind the
`call` at 0x434D, the three tally phases behind the one at 0x5ACA, and the four
demonstration steps behind the one at 0x5EB6.

The states do what you would expect: 0 to 7 are the title screen and menu, 8
confirms the selection, 9 racks a ball, 10 sets the table, 11 is the shot, 12
decides it, 13 changes player, 14 waits after GAME OVER and 15 celebrates a
cleared table. State 3 is a dead step: its table entry points at the instruction
that only increments the state.

## A ball's record

The table is eight sixteen-byte records from 0xE100:

| byte | what it is |
|---|---|
| +0 | 0xFF while the ball is still on the cloth |
| +1 | the energy it has left; at zero, it has stopped |
| +2 | the angle it is travelling at |
| +3 and +4 | Y in 16 bits, with the integer part in +4 |
| +5 and +6 | X in 16 bits, with the integer part in +6 |
| +7 and +8 | the Y velocity, signed |
| +9 and +10 | the X velocity |
| +11 and +12 | sprite pattern number and colour |
| +13 and +14 | the friction, split by component |
| +15 | which ball it last collided with |

The position is fixed point 8.8, and the integer byte lands exactly where the
sprite dump will read it: moving a ball is adding two 16-bit words to two others,
and the sprite finds out by itself.

The four bytes the VDP needs — +4, +6, +11 and +12 — are dumped by 0x466D in one
go through the data port, riding the VDP's auto-increment. And the order of the
two groups of four balls alternates with bit 0 of the frame counter, the usual
trick against the TMS9918's sprites-per-line limit.

## The physics, three routines

**Moving** (0x4E6B) adds the velocity to the position and checks whether the ball
has left: the table runs from X=0x14 to X=0xD8 and from Y=0x3E to Y=0xA1. If it
has left where there is a cushion, it reflects it — position minus twice the
overshoot — and negates that velocity component. If it has left where there is a
pocket, it goes to the routine that sinks it.

**Colliding** (0x4F25) walks the other six balls with a cheap sieve: if the two
coordinates differ by less than twelve pixels, contact is possible. Then 0x4F63
measures the real distance, with the two squares summed and compared against
0x9000, which at that scale is the same twelve pixels.

**Friction** (0x53DD) comes in one frame in every eight: it takes 3 off the
energy and adds to each velocity component the friction held in +13 and +14,
always with the opposite sign to the motion. Since those two bytes are the unit
vector components scaled to 24/256, the ball slows down along its own line and
does not veer as it stops.

## How a collision is shared out

If both balls are rolling, the cartridge **swaps their velocities** and that is
that (0x5192): the head-on collision between equal masses, solved without a
single multiplication.

If one was at rest, then there is a calculation. It measures the angle of the
line joining the two centres, compares it with the angle the ball was travelling
at, and that difference — saturated at 0x3C, nearly a right angle — goes into the
cosine table: the part of the motion falling along the line of centres is handed
over, the perpendicular part stays. The striking ball leaves along the
perpendicular, and for that the two components are crossed as they are written,
which is turning the vector ninety degrees without touching it.

## Directions with no sines or cosines

A direction is not kept as an angle, but as a **slope within an octant** plus two
mirror bits. The routine at 0x5430 takes the two velocity components, keeps their
absolute values, notes in 0xE1A2 which way each was heading, divides both by 32
and compares: the larger becomes the divisor and the smaller the dividend, so the
quotient always lands between 0 and 255 and tables of 256 entries are enough.

There are four, all checked against their formula with a maximum error of 1:

| table | what it holds |
|---|---|
| 0x539C | 65 values of 255·cos, for sharing out the collision |
| 0x54E6 | 256 values of 255·sin(atan(p)) |
| 0x55E6 | 256 values of 255·cos(atan(p)) |
| 0x56E6 | 64 values of atan, in 1/256 of a turn |

The one at 0x539C is read twice, with the index and with its complement to 0x40,
and out come the sine and the cosine from a single table. And when the final
angle is assembled, the two mirror bits are combined using **parity**: an `and a`
over 0xE1A2 and a `jp pe`, because negating the angle is needed when exactly one
of the two axes is mirrored.

## A twelve-byte square root

0x5376 takes the root of HL by subtracting odd numbers: 1, then 0, then 2 and 2,
then 4 and 4… and returns how many rounds it survived. Run over all 65,536
possible values, it returns exactly `round(sqrt(n))`, the root rounded to the
nearest integer rather than truncated.

It is used for the distance between the cue ball and the aiming point, which is
what divides the two shot components to leave them as a unit vector. Half a pixel
there shows up in the direction.

## The sound player

Three nine-byte channels from 0xE010, each with its counter, its pointer into the
score and the sound number it is playing, which doubles as its priority: a new
sound only gets in if its number is greater than or equal to the one playing.

What you request is not a channel but a **sound**, and depending on its number
one, two or three channels start at once with consecutive pointers from the table
at 0x5D1C. Below 0x87 it is a one-channel effect; from 0x8A up, three-channel
music.

Notes carry the duration in the high nibble and the semitone in the low one, and
semitone 12 is a rest. The frequency divisor comes from the table of twelve at
0x5D08 and is doubled once per octave to be dropped. The volume decays on its
own, in software, by comparing two counters.

And a detail of the kind that pleases: the channel's volume register comes from
rotating C — which holds 1, 3 or 5 — and adding 0x88. That gives 8, 9 and 10,
which are exactly the PSG's three volume registers.

## Things that are there and do nothing

- 0x5962 writes `(ix+002h)` **twice in a row with the same value**. Three bytes
  that change nothing.
- At 0x4462 there are four bytes (00 80 40 C0) that no instruction references,
  and the byte sequence of their address does not occur anywhere in the ROM. The
  menu code jumps over them. They look like an abandoned table.
- Sound pointer number 0 does not exist: its two bytes are durations 44 and 84
  from the table above, spliced into this one. Nobody asks for sound 0.

## And two that do, and are the best of it

`push hl` followed by `pop hl` turns up several times in the routines that write
sprites and cards (0x59E8, 0x5A01, 0x5B66). They move nothing: they are
twenty-one clock cycles of waiting so the VDP has time between two consecutive
writes.

And at 0x5488 there is an `ld a,r`. The R register is the dynamic memory refresh
counter, which changes on its own, so it serves as a random number for free. The
cartridge keeps its low bit and uses it to flip bit 0 of the slope it has just
computed: every direction comes out with one unit of noise on it.
