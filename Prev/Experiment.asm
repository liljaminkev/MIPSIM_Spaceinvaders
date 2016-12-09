	.data  
al1:	.asciiz	"0000"
	.asciiz	" 00 "
	.asciiz	"0000"
al12:	.asciiz	"0000"
	.asciiz	"0  0"
	.asciiz	"0000"
al2:	.asciiz	"xxxx"
	.asciiz	"x  x"
	.asciiz	"xxxx"
al22:	.asciiz	"xxxx"
	.asciiz	" xx "
	.asciiz	"xxxx"
	
buffer:	.space 	25*81       	# A 256 bytes buffer  
	   
	.code  
main:  
	la 	$a1,buffer  
	la 	$a2,al1
	la 	$a3,al12  
#	li	$a4,25
	
#1:	li	$a5,80
	
2:	jal	clearBuffer
	jal	wait
	jal	printAlien1
#	addi	$t1,$t1,-1
#	jal	wait
#	jal	clearBuffer
#	jal	printAlien12
#	jal	wait
#	addi	$t1,$t1,-1
#	addi	$t2,$t2,-1
	
#	addi	$a1,$a1,-1
#	addi	$a1,$a1,81
#	li	$t1,80
	
#3:	jal	clearBuffer
#	jal	printAlien1
#	addi	$t1,$t1,-1
#	addi	$a1,$a1,-1
#	jal	clearBuffer
#	jal	wait
#	jal	printAlien12
#	jal	wait
#	addi	$t1,$t1,-1
#	addi	$a1,$a1,-1
#	bgtz	$t1,3b
#	addi	$t2,$t2,-1
	
	
#	addi	$a1,$a1,82
#	bgtz	$t2,1b
	
	syscall	$exit
	
	

	
printAlien1:  
	lw 	$t0,($a2)               # get character at address  
	usw 	$t0,($a1)               # Store first part
	lw	$t0,4($a2)
	usw	$t0,81($a1)
	lw	$t0,4($a2)
	usw	$t0,162($a1)
	la	$a0,buffer
	syscall	$print_string
	jr	$ra

#printAlien12:  
#	lw 	$t0,($a3)               # get character at address  
#	usw 	$t0,($a1)               # else store current character in the buffer  
#	la	$a0,buffer
#	syscall	$print_string
#1:	jr	$ra 

#clear the buffer with spaces
#
#
clearBuffer:
	la	$t0,buffer		#s4:bufferpointer
	addi	$t1,$0,24		#t1:counter
	li	$t3,0x20202020		#t3:space
	addi	$t4,$0,'\n		#t4:new line
1:
	addi	$t2,$0,4		#t2:4 counter
2:	
	usw	$t3,($t0)		#store space in word 
	usw	$t3,4($t0)
	usw	$t3,8($t0)
	usw	$t3,12($t0)
	usw	$t3,16($t0)
	addi	$t0,$t0,20		#incremnt buffer pointer
	addi	$t2,$t2,-1		#t2--
	bgtz	$t2,2b			#fill char while less than 80 
	
	sb	$t4,($t0)
	addi	$t0,$t0,1
	addi	$t1,$t1,-1		#counter--
	bgtz	$t1,1b			#branch back to 1 while less then 25 lines
	
	mov	$a0,$t0
	syscall	$print_string
	jr 	$ra

	
	


#takes no input t0:counter
wait:
	li	$t0,4320000000
1:	addi	$t0,$t0,-1
	bgtz	$t0,1b
	jr	$ra
	