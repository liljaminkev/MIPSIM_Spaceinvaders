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
boss:	.word	0xdddddddd
buffer:	.space 	25*81       	# A 256 bytes buffer  
bitmap:	.space 	1:11*4
bu:	.byte	0xa7
bom:	.byte	0x40:1

#begin keyboard struct
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
#end keyboard struct

#begin timer struct
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
#end timer struct
#begin main
main:  
#begin timers
#alien timer
	la	$a0,timer.t1		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,700		# timer interval every five seconds
	syscall	$IO_write
#mothership timer
	la	$a0,timer.t2		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,100		# timer interval every five seconds
	syscall	$IO_write
	
	la	$a0,timer.t5		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,20000		# timer interval every five seconds
	syscall	$IO_write
	
#bullet timer
	la	$a0,timer.t3		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,500 		# timer interval every five seconds
	syscall	$IO_write
#bomb timer
	la	$a0,timer.t4		# hardware address of timer1
	addi	$a1,$0,4		# 4 byte data
	addi	$a2,$0,500		# timer interval every five seconds
	syscall	$IO_write
#end timers
#begin variables 
	add	$s2,$0,$0		#Alien movement tracker
	li	$s6,25			#number of rows down
	li	$s5,40			#ship position
	add	$s4,$0,$0		#bullet pos
	add	$s3,$0,$0		#mother ship pos
#end variables

	jal	render
#move aliens 25 lines	
1:	li	$s7,26			#spaces for aliens to move:
	andi 	$t5,$s6,1		#odd or even line
	bnez	$t5,2f			#
	addi	$t5,$0,-1		#start subtracting if odd
	
#reload flags

2:	la	$a0,timer.flags		#get flags
	syscall	$IO_read
	mov	$t8,$v0
#move alien				
	andi	$t0,$t8,0x02		#move aliens every .7 seconds
	beqz	$t0,3f
	la	$a0,timer.t1		#load timer t1
	syscall	$IO_read		#clear flag
	add	$s2,$s2,$t5		#if true incrment by 1 or -1
	addi	$s7,$s7,-1		#spaces for aliens --
	jal	render			#print screen

	

#move mothership	
3:	
	andi	$t0,$t8,0x04		#move ship every .5 seconds
	beqz	$t0,4f			
	la	$a0,timer.t2		#load timer t2 
	syscall	$IO_read		#clear flag
	li	$t1,25			#if aliens are still on top line branch down
	li	$t2,76			#if ship is at right of screen
	beq	$t1,$s6,4f		
	bgt	$s3,$t2,4f		#skip to next timer to restart ship
	addi	$s3,$s3,1		#else add 1
	jal	render			#render screen
		
31:	andi	$t0,$t8,0x20		#wait until new ship timer expires to reset 
	beqz	$t0,4f			#mother ship
	la	$a0,timer.t5		#
	syscall	$IO_read		#load and clear flags
	li	$s3,0			#set back to -1




#move bullet
4:	
	andi	$t0,$t8,0x08		#every .2 seconds move bullet
	beqz	$t0,5f
	la	$a0,timer.t3		#load timer
	syscall	$IO_read		#clear timer
	bgtz	$s4,41f			#when ready 
	li	$s4,0
	
41:#	la	$t0,buffer
	#add	$t0,$t0,$s4
	#addi	$t0,$t0,-81
	#lw	$t1,($t0) 	
#	li	$t0,0x20
#	beq	$t1,$t0,42f
	
	
42:	addi	$s4,$s4,-81		#decrment bullet


#move bomb
5:	
	andi	$t0,$t8,0x10
	beqz	$t0,6f
	la	$a0,timer.t4
	syscall	$IO_read
	jal 	bomb

#move ship/fire
6:	la	$a0,keyboard.flags	# hardware address of keyboard flags
	addi	$a1,$0,1		# 1 byte of data
	syscall 	$IO_read		# read flags
	andi	$t0,$v0,0b10		
	beqz	$t0,7f			
	addi	$a0,$a0,8		
	addi	$a1,$0,2		# 2 bytes of data
	syscall	$IO_read
	mov	$a0,$v0
	jal	input


	
	
	
7:	bgtz	$s7,2b			#branch to 2 while aliens are traversing line
	addi	$s6,$s6,-1		#once line traversed linecounter--
	addi	$s2,$s2,81		#add 81 chars for movement offset
	bgtz	$s6,1b			#branch back to 1
	
	syscall	$exit
#end main
#begin ship
#moveship/makebullet
input:
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	addi	$t0,$0,37		#detect left arrow
	bne	$a0,$t0,1f		
	addi	$t0,$0,1
	beq	$t0,$s5,4f
	addi	$s5,$s5,-1		#sub 1 if detected
	j	3f
1:	addi	$t0,$0,39		#dectect right arrow
	bne	$a0,$t0,2f
	addi	$t0,$0,76
	beq	$t0,$s5,4f
	addi	$s5,$s5,1		#add 1 if detected 
	j	3f
2:	addi	$t0,$0,32		#detect space
	bne	$a0,$t0,4f
	bgtz	$s4,4f
	addi	$s4,$s5,1863			#start bullet counter if detected
3:	jal	render
4:	lw	$ra,0($sp)
	addi	$sp,$sp,-4
	jr	$ra

placeShip:
	addi	$sp,$sp,-20
	sw	$t3,16($sp)
	sw	$t0,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	la 	$t0,ship		#get add of ship
	lw	$t1,($t0)		#load ship
	la	$t2,buffer		#get buffer
	addi	$t3,$s5,1944		#find pos via t3
	add	$t2,$t2,$t3		#increment buffer to correct pos 
	usw	$t1,($t2)		#add ship to buffer at pos
	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t0,12($sp)
	lw	$t3,16($sp)	
	addi	$sp,$sp,20
	jr	$ra

#end

#begin bullet
placeBullet:
	addi	$sp,$sp,-16
	sw	$t0,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	la 	$t0,bu			#load bullet
	lb	$t1,($t0)		
	la	$t2,buffer		#load buffer
	add	$t2,$t2,$s4		#increment buffer to bullet location 
	sb	$t1,($t2)		#place bullet
	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t0,12($sp)
	addi	$sp,$sp,16
	jr	$ra
	
#end

#begin bomb
bomb:
	addi	$sp,$sp,-16
	sw	$t0,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	li	$t0,2025
	blt	$s1,$t0,1f
	li	$s1,0
	jal	3f
	
1:	bgtz	$s1,2f 
	addi	$s1,$s2,1215
	add	$s1,$s1,$s5
	j	3f
	
2:	addi	$s1,$s1,81
3:	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t0,12($sp)
	addi	$sp,$sp,16
	jr	$ra

placeBomb:
	addi	$sp,$sp,-16
	sw	$t0,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	la	$t0,bom
	la	$t2,buffer
	lb	$t1,($t0)
	add	$t2,$t2,$s1
	sb	$t1,($t2)

	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t0,12($sp)
	addi	$sp,$sp,16
2:	jr	$ra
	


#end bomb

#begin mShip
mShip:
	addi	$sp,$sp,-16
	sw	$t0,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	la 	$t0,boss		#load mother ship
	lw	$t1,($t0)			
	la	$t2,buffer		#load buffer
	add	$t2,$t2,$s3		#increment buffer to mother ship location
	usw	$t1,($t2)		#place mothership at location
	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t0,12($sp)
	addi	$sp,$sp,16
	jr	$ra

#end

#begin barriers

#end barriers

#begin killAlien



#end killAlien
		
render:
	addi	$sp,$sp,-12
	sw	$t0,8($sp)
	sw	$ra,4($sp)
	sw	$a0,($sp)
	jal	clearBuffer
	li	$t0,77		#if s3 is greater than 77 
	bgt	$s3,$t0,1f	#	skip to next
	beqz	$s3,1f		#if less than zero skip to place bullet
	jal	mShip		#else place ship
1:	jal	movAi		#place aleins
	blez	$s5,2f		#if less than zero dont place bullet
	jal	placeBullet	#else place bullet 
2:	jal	placeShip	#place ship

	li	$t0,2025
	bgt 	$s1,$t0,3f
	jal 	placeBomb

3:	li	$a0,0		
	li	$a1,0
	syscall	$xy		#mover curser to a0,a1
	la	$a0,buffer	#get a0 ready for printing
	syscall	$print_string	#cout a0
	lw	$a0,($sp)
	lw	$ra,4($sp)
	lw	$t0,8($sp)
	addi	$sp,$sp,12
	jr	$ra
	



#begin Move Alien	
#takes s2:alien tracker
#local	t9:even/odd
movAi:
	addi	$sp,$sp,-4		
	sw	$ra,0($sp)		
1:	la	$a0,buffer		#load buffer
	add	$a0,$a0,$s2		#incrment buffer by s2
	andi	$t9,$s2,1		#find out if on an odd space
	jal	renai			#renai screen

	lw	$ra,0($sp)	
	addi	$sp,$sp,4
	jr	$ra
#end
#begin render aliens

	#renai screen
	#takes buffer pointer:a0, alien:t6
	#local t0:numRows t1:twofows for diffrent alien
renai:
	addi	$sp,$sp,-4
	sw	$ra,0($sp)

	li	$t0,4		#row counter
	li	$t1,2		#counter for first 2 rows of aliens 
	li	$t2,bitmap	#do
row:	la	$t6,al1		#{alien 1 to t6
	bnez	$t9,col		#if even go to col
	la	$t6,al12	#if odd change alien 1-2
col:	li	$t3,11			#start dowhile counter
1:					#do
	lb	$t4,0($t2)		#load dead/alive status
	bgtz	$t4,2f
	jal 	placeAlien		#{place alien
2:	addi	$a0,$a0,5		#incrment pointer:a0
	addi	$t3,$t3,-1		#decremnt col counter:t3
	addi	$t2,$t2,1		#bitmap
	bgtz	$t3,1b			#}while(t3<11)
	addi	$a0,$a0,269	#move pointer back to left side of screen

	addi	$t0,$t0,-1	#rowcounter--
	addi	$t1,$t1,-1	#firstrows--
	bgtz	$t1,3f		#if first two rows have been printed
	la	$t6,al2			#load second alien
	bnez	$t9,3f			#if odd load alien2-2
	la	$t6,al22		#alien2-2 to t6
3:	bgtz	$t0,col		#}while(t0<4)
	lw	$ra,0($sp)	#restore ra 
	addi	$sp,$sp,4	#resotre stack pointer
	jr	$ra		
#end
#begin Place alien
############################
#Place alien 
#takes a0:buffer
placeAlien:  
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	lw 	$t7,0($t6)               # get character at address  
	usw 	$t7,0($a0)               # else store current character in the buffer  
	lw	$t7,4($t6)
	usw 	$t7,81($a0)               # else store current character in the buffer 
	lw	$t7,8($t6)
	usw 	$t7,162($a0)               # else store current character in the buffer
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
	addi	$t2,$0,25		#t2:counter
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
	sb	$0,-1($t0)
	jr 	$ra
#end
