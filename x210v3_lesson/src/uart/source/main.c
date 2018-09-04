/*
 * ʵ�����ƣ�������������ַ�ʵ��
 * ʵ�����󣺲���SD����������ʹ�ô��ڵ�������V2.2�����뵥���ַ������Ҳ����ʾ��Ӧ�ַ�
 * ���ӳ��uart.bin
 * ��          �ƣ��Ŷ���չ�Ƽ�
 * ��	  ַ��http://www.9tripod.com
 * ��	  ̳��http://bbs.9tripod.com
 * ��          �ڣ�2013-8-21
 */
#include <types.h>
#include <io.h>
#include <s5pv210/reg-gpio.h>
#include <s5pv210/reg-serial.h>

void uart_init(void)
{
	/* configure GPA01, GPA00 for TXD0, RXD0 */
	writel(S5PV210_GPA0CON, 0x22222222);

	/* pull up GPA01 and GPA00 */
	//writel(S5PV210_GPA0PUD, (readl(S5PV210_GPA0PUD) & ~(0x3<<0 | 0x03<<2)) | (0x2<<0 | 0x2<<2));

	/* configure clk source (pclk), mode, etc */
	writel(S5PV210_UCON0,     0x00000005);
	writel(S5PV210_UFCON0,    0x00000000);
	writel(S5PV210_UMON0,     0x00000000);
	writel(S5PV210_ULCON0,    0x00000003);
	writel(S5PV210_UBRDIV0,   0x00000023);
	writel(S5PV210_UDIVSLOT0, 0x00000001);
}

char  uart_getc(void)//����һ���ֽ�
{
	char buf;
	if( (readl(S5PV210_UTRSTAT0) & S5PV210_UTRSTAT_RXDR) )
			buf = readb(S5PV210_URXH0);
     return buf;
}
void  uart_putc(char c) //����һ���ֽ�
{

	/* wait for transmit buffer & shifter register empty */
	while( !(readl(S5PV210_UTRSTAT0) & S5PV210_UTRSTAT_TXE) );
	/* transmit a character */
	writeb(S5PV210_UTXH0, c);
}

int main(int argc, char * argv[])
{
	char c;
	uart_init();
	while(1)
	{
		c=uart_getc();
		if(c<=1)//ȥ�����⿪ʼ
			break;
		uart_putc(c);
	}
	return 0;
}

