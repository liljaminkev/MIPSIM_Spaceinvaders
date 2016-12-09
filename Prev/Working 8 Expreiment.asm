	.data   
al1:	.word	0x3e6f6f3c
	.word	0x5d20205b
	.word	0x305f5f30
al12:	.word	0x3e4f4f3c
	.word	0x5d20205b
	.word	0x20303020
al2:	.word	0xdb2020db
	.word	0x20dbdb20
	.word	0xdb2020db
al22:	.word	0x20202020
	.word	0x20dbdb20
	.word	0x20202020
ship:	.word	0x20db1edb
buffer:	.space 	25*81       	# A 256 bytes buffer  
bitmap:	.space 	1:11*5

######
#keyboard
######################
keyboard:	.struct 0xa0000000	#start from hardware base address
flags:		.byte 0
mask:		.byte 0
		.half 0
keypress: 	.byte 0,0,0
presscon: 	.byte 0
keydown:	.half 0
shiftdown:	.byte 0
downcon:	.byte 0
keyup:		.half 0
upshift:	.byte 0
upcon:		.byte 0
		.data
		
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

#alien timer
	la	$a0,timer.t1		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,700		# timer interval every five seconds
	syscall	$IO_write
#mothership timer
	la	$a0,timer.t2		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,2000		# timer interval every five seconds
	syscall	$IO_write
#bullet timer
	la	$a0,timer.t3		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,3000		# timer interval every five seconds
	syscall	$IO_write
#bomb timer
	la	$a0,timer.t4		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,4000		# timer interval every five seconds
	syscall	$IO_write

#variables 
	la	$s2,0			#movement tracker
	li	$s6,25
	

1:	li	$s7,26			#spaces to move:
	andi 	$s3,$s6,1		#odd or even line
	bnez	$s3,2f			#
	addi	$s3,$0,-1
	
#move alien

2:	la	$a0,timer.flags	
	syscall	$IO_read
	mov	$t8,$v0
	andi	$t0,$t8,0x02
	beqz	$t0,3f
	la	$a0,timer.t1
	syscall	$IO_read
	jal 	movAi
	jal	render
	add	$s2,$s2,$s3
	addi	$s7,$s7,-1

	


	
#move mothership	
3:	
	andi	$t0,$t8,0x04
	beqz	$t0,4f
	la	$a0,timer.t2
	syscall	$IO_read
	jal 	mShip



#move bullet
4:	
	andi	$t0,$t8,0x08
	beqz	$t0,5f
	la	$a0,timer.t3
	syscall	$IO_read
	jal 	bullet


#move bomb
5:	
	andi	$t0,$t8,0x10
	beqz	$t0,6f
	la	$a0,timer.t4
	syscall	$IO_read
	jal 	bomb

#move ship
6:	#jal	io



	#jal	placeShip

	
	bgtz	$s7,2b
	addi	$s6,$s6,-1
	addi	$s2,$s2,81
	bgtz	$s6,1b
	

	syscall	$exit

#begin ship
ship:
	jr	$ra
#end

#begin bullet
bullet:
	jr	$ra
#end

#begin bomb
bomb:
	jr	$ra
#end

#begin mShip
mShip:
	jr	$ra
#end

#begin barriers

#end
	
	
	
render:
	addi	$sp,$sp,-4
	sw	$a0,($sp)
	la	$a0,buffer	#get a0 ready for printing
	syscall	$print_string	#cout a0
	lw	$a0,($sp)
	addi	$sp,$sp,4
	jr	$ra
	

#begin io
io:
	addi	$sp,$sp,-16
	sw	$t0,12($sp)
	sw	$a0,8($sp)
	sw	$a2,4($sp)
	sw	$a1,0($sp)
	
	la	$a0,keyboard.flags	# hardware address of keyboard flags
	addi	$a1,$0,1		# 1 byte of data
	syscall 	$IO_read		# read flags
	andi	$t0,$v0,0b10
#	beqz	$t0,#event
	addi	$a0,$a0,8
#	blez	$v0,1f			# branch if no keyboard flags
#	move	$t0,$v0

	
	la	$a0,keyboard.keydown	# hardware address of keyboard code
	addi	$a1,$0,2		# 2 bytes of data
	syscall	$IO_read
	move	$a0,$v0
	syscall 	$print_int		# character code
	andi	$t1,$t0,4		# flag bit 2
	neg	$t1,$t1			# allows use of bltzal
	
		
1:	lw	$t0,12($sp)
	lw	$a0,8($sp)
	lw	$a2,4($sp)
	lw	$a1,0($sp)
	addi	$sp,$sp,12
	
	jr	$ra
#end	
#begin Ship
placeShip:
	la	$s1,buffer
	la 	$t0,ship
	lw	$t1,($t0)
	usw	$t1,1920($s1)
	jr	$ra

#end
#begin Move Alien	
movAi:
	addi	$sp,$sp,-4		
	sw	$ra,0($sp)		
1:	la	$s1,buffer		#load buffer
	add	$s1,$s1,$s2		#incrment buffer by s2
	andi	$s4,$s2,1		#find out if on an odd space
	jal	renai			#renai screen

	lw	$ra,0($sp)	
	addi	$sp,$sp,4
	jr	$ra
#end
#begin render aliens
############################
#renai screen
#takes buffer pointer:s1, alien:t6
#local t0:numRows t1:twofows for diffrent alien
renai:
	addi	$sp,$sp,-8
	sw	$ra,4($sp)
	sw	$s2,0($sp)
	jal	clearBuffer

	li	$t0,4		#row counter
	li	$t1,2		#counter for first 2 rows of aliens 
	li	$t2,bitmap	#do
row:	la	$t6,al1		#{alien 1 to t6
	bnez	$s4,col		#if even go to col
	la	$t6,al12	#if odd change alien 1-2
col:	li	$t3,11			#start dowhile counter
1:					#do
	lb	$t4,0($t2)		#load dead/alive status
	bgtz	$t4,2f
	jal 	printAlien		#{place alien
2:	addi	$s1,$s1,5		#incrment pointer:s1
	addi	$t3,$t3,-1		#decremnt col counter:t3
	addi	$t2,$t2,1		#bitmap
	bgtz	$t3,1b			#}while(t3<11)
	addi	$s1,$s1,269	#move pointer back to left side of screen

	addi	$t0,$t0,-1	#rowcounter--
	addi	$t1,$t1,-1	#firstrows--
	bgtz	$t1,3f		#if first two rows have been printed
	la	$t6,al2			#load second alien
	bnez	$s4,3f			#if odd load alien2-2
	la	$t6,al22		#alien2-2 to t6
3:	bgtz	$t0,col		#}while(t0<4)
	lw	$s2,0($sp)	#take info off stack
	lw	$ra,4($sp)	#restore ra 
	addi	$sp,$sp,8	#resotre stack pointer
	jr	$ra		
#end
#begin Place alien
############################
#Place alien 
#takes s1:buffer
printAlien:  
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	lw 	$t7,0($t6)               # get character at address  
	usw 	$t7,0($s1)               # else store current character in the buffer  
	lw	$t7,4($t6)
	usw 	$t7,81($s1)               # else store current character in the buffer 
	lw	$t7,8($t6)
	usw 	$t7,162($s1)               # else store current character in the buffer
	lw	$ra,0($sp)	
	addi	$sp,$sp,4
	jr	$ra

#end
#begin clear screen	
############################
#clear screen
#clear the buffer with spaces and newlines
clearBuffer:
	la	$t0,buffer		#t0:bufferpointer
	addi	$t2,$0,24		#t2:counter
	li	$t3,0x20202020		#t3:space
	addi	$t4,$0,'\n		#t4:new line
1:
	addi	$t1,$0,4		#charCounter = 80
2:	
	usw	$t3,($t0)		#store space in char 
	usw	$t3,4($t0)
	usw	$t3,8($t0)
	usw	$t3,12($t0)
	usw	$t3,16($t0)
	addi	$t0,$t0,20		#incremnt buffer pointer
	addi	$t1,$t1,-1		#charCounter--
	bgtz	$t1,2b			#fill char while less than 80 chars
	
	sb	$t4,($t0)
	addi	$t0,$t0,1
	addi	$t2,$t2,-1		#counter--
	bgtz	$t2,1b			#branch back to 1 while less then 25 lines
	jr 	$ra
#end
