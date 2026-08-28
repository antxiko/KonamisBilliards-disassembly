# Findings

Things that turned up while reading the code instruction by instruction and that
do not fit on any of the other pages. Nearly all of them are of the same family:
someone squeezing bytes with a great deal of craft.

## Three bytes set with two writes

When the score overflows, the game pins it at 999999. Six nines are three BCD
bytes, and setting them costs this:

    ld bc,09999h
    ld (0e040h),bc
    ld (0e041h),bc

Two **overlapping** two-byte writes to leave three bytes at 0x99. The second one
overwrites the first one's high byte with the same value. That works out at one
byte of code per byte written, against the nine it would take done by hand.

## Two increments instead of two comparisons

The text list interpreter (0x472E) has to recognise two markers: 0xFF to finish
and 0xFE to change destination. The obvious way would be two `cp` with their two
jumps. What is there is this:

    ld b,a
    inc b
    ret z          ; it was 0xFF
    inc b
    jr z,L_4730    ; it was 0xFE

The byte is copied into B so as not to lose A, and incremented: 0xFF plus one is
zero and sets the flag, and another increment does the same for 0xFE. Two markers
recognised with two one-byte instructions.

## The blink has no variable: it looks at the screen

While there are balls on the table, the 1P or 2P label of whoever has the turn
blinks. There is no flag anywhere saying whether it is currently on or off. What
0x4858 does is **read from VRAM** the tile sitting in that position: if it is
empty it draws it, and if there is something there it erases it.

The screen itself acts as the memory. And since it only comes in one frame in
every thirty-two — the low five bits of the frame counter at zero — the blink
works out at a little over half a second per side.

## The bit that says "this one counts"

0xE002 keeps three things in three bits, and the one in bit 6 is the most useful
of the lot: it says whether a real game is in progress.

With that bit clear nothing scores (0x4786 leaves the scoring routine the moment
it looks at it) and nothing sounds (0x5BC7 does the same in the sound request
routine). That is exactly the state the demonstration runs in, which is why it
plays silently and without scoring. And the same bit also decides which joystick
port is read: always port 1, or the one belonging to whoever has the turn.

One bit, three consequences, and all three consistent.

## Nobody stares at the table forever

While you are aiming, a clock runs at 0xE202 that only advances when the frame
counter is zero, that is, **one frame in every 256**. When it reaches zero, the
shot is written off.

Since the counter is reset by any key and then counts 256 passes, the full
countdown is 65,536 frames: over twenty minutes without touching a thing. It is
meant for a machine left switched on, not to hurry anyone along.

## The keyboard dresses up as a joystick using rotations

The game's six inputs — four directions and two buttons — are read from the
joystick through the PSG and from the keyboard through the BIOS, and **both count
at all times**: there is nothing to choose, they are merged with an `or`.

For them to be mergeable, the keyboard bits have to land in the same positions as
the joystick ones, and that is achieved with five chained rotations that leave
each key where it belongs. Simulating the code key by key, the mapping is this:

| key | acts as |
|---|---|
| arrows | the four directions |
| SPACE | fire button |
| SELECT | second button |

And no other key on the two rows that are read produces anything at all.

## The stage wraps at a hundred

The stage number (0xE051) goes up in BCD with `add a,001h` and `daa`, and nothing
checks for overflow. Past 99 it goes back to 00 and the scoreboard carries on as
if nothing had happened.
