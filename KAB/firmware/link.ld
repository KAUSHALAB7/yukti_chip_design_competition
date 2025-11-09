OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
  .text : {
    *(.text)
    *(.text*)
  } > RAM

  .rodata : {
    *(.rodata)
    *(.rodata*)
  } > RAM

  .data : {
    *(.data)
    *(.data*)
  } > RAM

  .bss : {
    *(.bss)
    *(.bss*)
  } > RAM
}
