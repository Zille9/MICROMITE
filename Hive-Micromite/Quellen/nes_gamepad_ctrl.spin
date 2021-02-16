CON
'' gamepad pin configuration 
  JOY_CLK       = 2
  JOY_LCH       = 3
  JOY_DATAOUT0  = 4
  JOY_DATAOUT1  = 5

  ' NES bit encodings for NES gamepad 0
  NES0_RIGHT    = %00000000_00000001
  NES0_LEFT     = %00000000_00000010
  NES0_DOWN     = %00000000_00000100
  NES0_UP       = %00000000_00001000
  NES0_START    = %00000000_00010000
  NES0_SELECT   = %00000000_00100000
  NES0_B        = %00000000_01000000
  NES0_A        = %00000000_10000000  

VAR
  word Nes_Pad

' //////////////////////////////////////////////////////////////////
' NES Game Paddle Read
' //////////////////////////////////////////////////////////////////
' reads both gamepads in parallel encodes 8-bits for each in format
' right game pad #1 [15..8] : left game pad #0 [7..0]
'
' set I/O ports to proper direction
' P3 = JOY_CLK      (4)
' P4 = JOY_SH/LDn   (5)
' P5 = JOY_DATAOUT0 (6)
' P6 = JOY_DATAOUT1 (7)
' NES Bit Encoding
'
' RIGHT  = %00000001
' LEFT   = %00000010
' DOWN   = %00000100
' UP     = %00001000
' START  = %00010000
' SELECT = %00100000
' B      = %01000000
' A      = %10000000

PUB read_gamepad : nes_bits | i

  ' step 1: set I/Os
  DIRA [JOY_CLK] := 1 ' output
  DIRA [JOY_LCH] := 1 ' output
  DIRA [JOY_DATAOUT0] := 0 ' input
  DIRA [JOY_DATAOUT1] := 0 ' input

  ' step 2: set clock and latch to 0
  OUTA [JOY_CLK] := 0 ' JOY_CLK = 0
  OUTA [JOY_LCH] := 0 ' JOY_SH/LDn = 0
  'Delay(1)

  ' step 3: set latch to 1
  OUTA [JOY_LCH] := 1 ' JOY_SH/LDn = 1
  'Delay(1)

  ' step 4: set latch to 0
  OUTA [JOY_LCH] := 0 ' JOY_SH/LDn = 0

  ' data is now ready to shift out, clear storage
  nes_bits := 0

  ' step 5: read 8 bits, 1st bits are already latched and ready, simply save and clock remaining bits
  repeat i from 0 to 7

    nes_bits := (nes_bits << 1)
    nes_bits := nes_bits | INA[JOY_DATAOUT0] | (INA[JOY_DATAOUT1] << 8)

    OUTA [JOY_CLK] := 1 ' JOY_CLK = 1
    'Delay(1)
    OUTA [JOY_CLK] := 0 ' JOY_CLK = 0
 
    'Delay(1)

  ' invert bits to make positive logic
  nes_bits := (!nes_bits & $FFFF)

' //////////////////////////////////////////////////////////////////
' End NES Game Paddle Read
' //////////////////////////////////////////////////////////////////             
