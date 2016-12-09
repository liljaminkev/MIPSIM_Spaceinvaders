	.data
	
r1:	.asciiz "Timer 1\n"
r2:	.asciiz	"Timer 2\n"
r3:	.asciiz	"Timer 3\n"
r4:	.asciiz	"Timer 4\n"

timer.int = 6
timer:	.struct 0xa0000050
flags:	.byte	0
mask:	.byte	0
	.half	0
t1:	.word	0
t2:	.word	0
t3:	.word	0
t4:	.word	0
t5:	.word	0
t6:	.word	0
t7:	.word	0
	.code  
	
main:

	la	$a0,timer.t1		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,1000		# timer interval every five seconds
	syscall	$IO_write
	
	la	$a0,timer.t2		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,2000		# timer interval every five seconds
	syscall	$IO_write
	
	la	$a0,timer.t3		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,3000		# timer interval every five seconds
	syscall	$IO_write
	
	la	$a0,timer.t4		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,4000		# timer interval every five seconds
	syscall	$IO_write
	
	
1:	la	$a0,timer.flags
	syscall	$IO_read
	andi	$t0,$v0,0x02
	beqz	$t0,2f
	
	la	$a0,timer.t1
	syscall	$IO_read
	la	$a0,r1
	syscall	$print_string
2:	andi	$t0,$v0,0x04
	beqz	$t0,3f
	
	la	$a0,timer.t2
	syscall	$IO_read
	la	$a0,r2
	syscall	$print_string
3:#	andi	$t0,$v0,0b000100
#	beqz	$t0,4f
#	addi	$a0,$a0,20
#	syscall	$IO_read
#	la	$a0,r3
#	syscall	$print_string
#4:	andi	$t0,$v0,0b001000
#	beqz	$t0,5f
#	addi	$a0,$a0,20
#	syscall	$IO_read
#	la	$a0,r4
#	syscall	$print_string
5:	j	1b
	
	syscall	$exit
	
	
	
	