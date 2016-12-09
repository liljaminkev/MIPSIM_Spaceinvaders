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
al21:	.word	0x20202020
	.word	0x20dbdb20
	.word	0x20202020
buffer:	.space 	25*81       	# A 256 bytes buffer  
#timer.int=	6
#timer:	.struct	0xa0000050
#flags:	.byte	0
#mask:	.byte	0
#	.half	0
#t1:	.word	1000
#t2:	.word	0
#t3:	.word	0
#t4:	.word	0
#t5:	.word	0
#t6:	.word	0
#t7:	.word	0
	.code  
main:  
	la 	$s1,buffer  
	la 	$t6,al1
	la	$s2,0			#movement tracker
	li	$a2,25
	
1:	li	$a1,41			#count down:
	jal 	right
	jal	left
	addi	$a2,$a2,-1
	bgtz	$a2,1b
	syscall	$exit

	

	
right:	addi	$sp,$sp,-4
	sw	$ra,0($sp)
1:	jal	clearBuffer		#animate
	la	$s1,buffer
	add	$s1,$s1,$s2
	jal	printR
	addi	$s2,$s2,1
	jal	wait
	addi	$a1,$a1,-1
	bgtz	$a1,1b
	addi	$s2,$s2,80
	li	$a1,41
	lw	$ra,0($sp)	
	addi	$sp,$sp,4
	jr	$ra

left:	addi	$sp,$sp,-4
	sw	$ra,0($sp)
1:	jal	clearBuffer		#animate
	la	$s1,buffer
	add	$s1,$s1,$s2
	jal	printR
	addi	$s2,$s2,-1
	jal	wait
	addi	$a1,$a1,-1
	bgtz	$a1,1b
	addi	$s2,$s2,82
	lw	$ra,0($sp)
	addi	$sp,$sp,4
	jr	$ra
	
	

	
	
############################
#print row
#takes buffer pointer:s1, alien:t6
#local s2:numRows s3:twofows for diffrent alien
printR:
	addi	$sp,$sp,-8
	sw	$ra,4($sp)
	sw	$s2,0($sp)
	li	$s2,4
	li	$s3,2
	la	$t6,al1
1:	jal 	printC
	addi	$s1,$s1,-40
	addi	$s1,$s1,324
	addi	$s2,$s2,-1
	addi	$s3,$s3,-1
	bgtz	$s3,2f
	la	$t6,al2			#print second row
2:	bgtz	$s2,1b
	la	$a0,buffer
	syscall	$print_string
	lw	$s2,0($sp)
	lw	$ra,4($sp)	
	addi	$sp,$sp,8
	jr	$ra
############################
#column 
#takes s1:bufferPointer
#local s2:numColumn, a1:odd
printC:
	addi	$sp,$sp,-8
	sw	$ra,4($sp)
	sw	$s2,0($sp)
	li	$s2,8
1:	jal 	printAlien1
	addi	$s1,$s1,5
	addi	$s2,$s2,-1
	bgtz	$s2,1b
	lw	$s2,0($sp)
	lw	$ra,4($sp)	
	addi	$sp,$sp,8
	jr	$ra
############################
#Place alien 
#takes s1:buffer
printAlien1:  
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	lw 	$t0,0($t6)               # get character at address  
	usw 	$t0,0($s1)               # else store current character in the buffer  
	lw	$t0,4($t6)
	usw 	$t0,81($s1)               # else store current character in the buffer 
	lw	$t0,8($t6)
	usw 	$t0,162($s1)               # else store current character in the buffer
	lw	$ra,0($sp)	
	addi	$sp,$sp,4
	jr	$ra
	
	
############################
#clear screen
#clear the buffer with spaces and newlines
clearBuffer:
	la	$s4,buffer		#s4:bufferpointer
	addi	$t2,$0,24		#t2:counter
	li	$t3,0x20202020		#t3:space
	addi	$t4,$0,'\n		#t4:new line
1:
	addi	$t1,$0,4		#charCounter = 80
2:	
	usw	$t3,($s4)		#store space in char 
	usw	$t3,4($s4)
	usw	$t3,8($s4)
	usw	$t3,12($s4)
	usw	$t3,16($s4)
	addi	$s4,$s4,20		#incremnt buffer pointer
	addi	$t1,$t1,-1		#charCounter--
	bgtz	$t1,2b			#fill char while less than 80 chars
	
	sb	$t4,($s4)
	addi	$s4,$s4,1
	addi	$t2,$t2,-1		#counter--
	bgtz	$t2,1b			#branch back to 1 while less then 25 lines
	
	la	$a0,buffer
	syscall	$print_string
	jr 	$ra
############################
#wait:
#takes no input t0:counter
wait:
	li	$t0,4300000000
1:	addi	$t0,$t0,-1
	bgtz	$t0,1b
	jr	$ra
