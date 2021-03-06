/*
 * Memory Setup stuff - taken from blob memsetup.S
 *
 * Copyright (C) 1999 2000 2001 Erik Mouw (J.A.K.Mouw@its.tudelft.nl) and
 *                     Jan-Derk Bakker (J.D.Bakker@its.tudelft.nl)
 *
 * Modified for the Samsung SMDK2450 by
 * (C) Copyright 2008 Samsung Electronics
 * Seungchull, Suh <sc.suh@samsung.com>
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */


#include <config.h>
#include <version.h>

#include <regs.h>

_TEXT_BASE:
	.word	TEXT_BASE

	.globl lowlevel_init
lowlevel_init:
	mov	r12, lr

	/* LED on to show U-Boot code is running */

	ldr	r0, =ELFIN_GPIO_BASE
	ldr	r2, [r0, #GPCCON_OFFSET]
	bic	r2, #3
	orr	r1, r2, #1
	str	r1, [r0, #GPCCON_OFFSET]

	ldr	r2, [r0, #GPCDAT_OFFSET]
	bic	r2, #1
	orr	r1, r2, #1
	str	r1, [r0, #GPCDAT_OFFSET]

	/* Disable Watchdog */
	ldr	r0, =ELFIN_WATCHDOG_BASE
	mov	r1, #0
	str	r1, [r0]

	/* Disable main and sub interrupts */
	ldr	r0, =ELFIN_INTERRUPT_BASE
	mvn	r1, #0x0
	str	r1, [r0, #INTMSK_OFFSET]
	str	r1, [r0, #INTSUBMSK_OFFSET]

	/* Set all interrupts as IRQ */
	mov	r1, #0x0
	str	r1, [r0, #INTMOD_OFFSET]

	/* init system clock */
	bl system_clock_init

	/* for UART */
	bl uart_asm_init

	/* simple init for NAND */
	bl nand_asm_init

	/* when we already run in ram, we don't need to relocate U-Boot.
	 * and actually, memory controller must be configured before U-Boot
	 * is running in ram.
	 */
	ldr	r0, =0xff000fff
	bic	r1, pc, r0		/* r0 <- current base addr of code */
	ldr	r2, _TEXT_BASE		/* r1 <- original base addr in ram */
	bic	r2, r2, r0		/* r0 <- current base addr of code */
	cmp     r1, r2                  /* compare r0, r1                  */
	beq     1f			/* r0 == r1 then skip sdram init   */

	adr     r0, sdram_bank_set_val
	bl 	sdr_ctrl_asm_init

1:	ldr	r0, =ELFIN_UART_BASE
	ldr	r1, =0x4b4b4b4b
	str	r1, [r0, #0x20]

#ifdef CONFIG_PM
	/* PM check */
	@ Check if this is a wake-up from sleep
        ldr     r0, =INFORM0_REG	/* INFORM0 register */
        ldr     r1, [r0]
        ldr     r2, =0x2BED
        cmp     r2, r1

	ldreq 	r0, =INFORM1_REG	/* INFORM1 register */
        ldreq 	r1, [r0]
        moveq 	pc, r1 			 /* end PM check */
#endif

	mov	pc, r12

/*
 * system_clock_init: Initialize core clock and bus clock.
 * void system_clock_init(void)
 */
system_clock_init:

	ldr	r0, =ELFIN_CLOCK_POWER_BASE

	ldr	r1, [r0, #CLKDIV0CON_OFFSET]
	bic	r1, r1, #0x37	/* clear HCLKDIV, PREDIV, PCLKDIV */
	bic	r1, r1, #(0xf<<9) /* clear ARMCLKDIV */
	ldr	r2, =CLK_DIV_VAL
	orr	r1, r1, r2
	str	r1, [r0, #CLKDIV0CON_OFFSET]

	/*Set MPLL Locktime*/
	ldr	r1, =0xe10
	str	r1, [r0, #LOCKCON0_OFFSET]

	ldr	r1, =MPLL_VAL
	str	r1, [r0, #MPLLCON_OFFSET]

#if 1
	ldr	r1, =0x1780
	str	r1, [r0, #LOCKCON1_OFFSET]

	ldr	r1, =EPLL_VAL		/*Set EPLL*/
	str	r1, [r0, #EPLLCON_OFFSET]

	ldr	r1, [r0, #CLKSRCCON_OFFSET]
	orr	r1, r1, #0x40
	str	r1, [r0, #CLKSRCCON_OFFSET]

#endif

	/* set CLKSRC to fit MPLL and USB */
	ldr	r1, [r0, #CLKSRCCON_OFFSET]
	orr	r1, r1, #0x10
	str	r1, [r0, #CLKSRCCON_OFFSET]

#if 0
	/* wait at least 200us to stablize all clock */
	mov	r2, #0x10000
1:	subs	r1, r1, #1
	bne	1b
#endif

	mrc	p15, 0, r0, c1, c0, 0
	orr	r0, r0, #0xc0000000	/* clock setting in MMU */
	mcr	p15, 0, r0, c1, c0, 0

	mov	pc, lr

/*
 * uart_asm_init: Initialize UART in asm mode, 115200bps fixed.
 * void uart_asm_init(void)
 */
uart_asm_init:
	/* set GPIO to enable UART */
	ldr	r0, =ELFIN_GPIO_BASE
	ldr	r1, =0x0000aaaa
	str	r1, [r0, #GPHCON_OFFSET]    @GPIO

	ldr	r0, =ELFIN_UART_BASE
	mov	r1, #0x0
	str	r1, [r0, #UFCON_OFFSET]
	str	r1, [r0, #UMCON_OFFSET]

	mov	r1, #0x3                     @was 0.
	str	r1, [r0, #ULCON_OFFSET]

	ldr	r1, =0x245
	str	r1, [r0, #UCON_OFFSET]

	ldr 	r1, =0x3

	ldr	r1, =0x23			/* PCLK Is Fixed to 66Mhz */
	str	r1, [r0, #UBRDIV_OFFSET]

	ldr	r1, =0x0888
	str	r1, [r0, #UDIVSLOT_OFFSET]

	ldr	r1, =0x4f4f4f4f
	str	r1, [r0, #UTXH_OFFSET]

	mov	pc, lr

/*
 * Nand Interface Init for smdk2450
 */

nand_asm_init:
	ldr	r0, =ELFIN_GPIO_BASE
	ldr	r1, [r0]
	orr	r1, r1, #(0x3f<<17)
	str     r1, [r0]
	/* EVT1 has modification in NAND */
#if 1
	ldr	r1, =0x1aa8a
	str     r1, [r0, #GPADAT_OFFSET]
#endif

	ldr	r0, =ELFIN_NAND_BASE
	ldr	r1, [r0, #NFCONF_OFFSET]
	orr	r1, r1, #0x70
	orr	r1, r1, #0x7700
	str     r1, [r0, #NFCONF_OFFSET]

	ldr	r1, [r0, #NFCONT_OFFSET]
	orr	r1, r1, #0x03
	str     r1, [r0, #NFCONT_OFFSET]

	mov	pc, lr

	.ltorg
/*
 * struct sdram_val {
 *	ulong bankcfg_val;	r5, val of bankcfg
 *	ulong bankcon1_val;	r6, val of bankcon1
 *	ulong bankcon2_val;	r7, val of bankcon2
 *	ulong bankcon3_val;	r8, val of bankcon3
 *	ulong refresh_val;	r9, val of refresh
 * }
 */

sdram_bank_set_val:
	.word	CFG_BANK_CFG_VAL
	.word	CFG_BANK_CON1_VAL
	.word	CFG_BANK_CON2_VAL
	.word	CFG_BANK_CON3_VAL
	.word	CFG_BANK_REFRESH_VAL

sdram_bank_sel_val_alt:
	.word	CFG_BANK_CFG_VAL_ALT
	.word	CFG_BANK_CON1_VAL_ALT

#ifdef CONFIG_ENABLE_MMU

/*
 * MMU Table for SMDK2450
 */

#ifndef CONFIG_BUILD_MMU_TABLE_RUNTIME
	/* form a first-level section entry */
.macro FL_SECTION_ENTRY base,ap,d,c,b
	.word (\base << 20) | (\ap << 10) | \
	      (\d << 5) | (1<<4) | (\c << 3) | (\b << 2) | (1<<1)
.endm
.section .mmudata, "a"
	.align 14
	/* the following alignment creates the mmu table at address 0x4000. */
	.globl mmu_table
mmu_table:
	.set __base,0
	/* 1:1 mapping for debugging */
	.rept 0x600
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr

	/* access is not allowed. */
	.rept 0xC00 - 0x600
	.word 0x00000000
	.endr

	/* 64MB for SDRAM 0xC0000000 -> 0x30000000 */
	.set __base, 0x300
	.rept 0xC40 - 0xC00
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr

	/* access is not allowed. */
	.rept 0x1000 - 0xc40
	.word 0x00000000
	.endr
#endif

#endif

