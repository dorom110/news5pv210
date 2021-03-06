/*
 * 文件名：	led.s	
 * 作者：	朱老师
 * 描述：	这是我们一步步点亮LED教程的自己写的第一个裸机程序
 */
 
#define GPJ0CON	0xE0200240
#define GPJ0DAT	0xE0200244

.global _start					// 把_start链接属性改为外部，这样其他文件就可以看见_start了
_start:
	// 第一步：把所有引脚都设置为输出模式，代码不变
	ldr r0, =0x11111111			// 从后面的=可以看出用的是ldr伪指令，因为需要编译器来判断这个数
	ldr r1, =GPJ0CON			// 是合法立即数还是非法立即数。一般写代码都用ldr伪指令
	str r0, [r1]				// 寄存器间接寻址。功能是把r0中的数写入到r1中的数为地址的内存中去

	// 第二步：把中间LED（GPJ0_4）的输出设置为0，其余两颗设置为1，剩下的其他位不管
	ldr r0, =0x28
	ldr r1, =GPJ0DAT
	str r0, [r1]				// 把0写入到GPJ0DAT寄存器中，引脚即输出低电平，LED点亮

	b .							// .代表当前这一句指令的地址，这个就是高大上的死循环







