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
bar1:	.byte	0xdb,0xb2,0xb1,0xb0
barm:	.byte	4,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
buff:	.space 	25*81       	# A 256 bytes buff  
bitm:	.byte 	1:44
bu:	.byte	0xa7
bom:	.byte	0x40
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
	addi	$a2,$0,30000		# timer interval every five seconds
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
	addi	$s4,$0,-1		#bullet pos
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
3:	andi	$t0,$t8,0x04		#move ship every .5 seconds
	beqz	$t0,4f			
	la	$a0,timer.t2		#load timer t2 
	syscall	$IO_read		#clear flag
	addi	$t1,$0,25		#if aliens are still on top line branch down
	addi	$t2,$0,76		#if ship is at right of screen
	beq	$t1,$s6,4f		
	blt	$s3,$t2,31f		#skip to next timer to restart ship
	andi	$t0,$t8,0x20		#wait until new ship timer expires to reset 
	beqz	$t0,4f			#mother ship
	la	$a0,timer.t5		#
	syscall	$IO_read		#load and clear flags
	li	$s3,0			#set back to -1
	
31:	addi	$s3,$s3,1		#else add 1
	jal	render			#render screen
#move bullet
4:	andi	$t0,$t8,0x08		#every .2 seconds move bullet
	beqz	$t0,5f
	la	$a0,timer.t3		#load timer
	syscall	$IO_read		#clear timer
	bgtz	$s4,41f			#when ready 
	beqz	$s4,5f
	li	$s4,0
	j	5f
	
41:	addi	$s4,$s4,-81		#decrment bullet
#move bomb
5:	andi	$t0,$t8,0x10
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
input:	addi	$sp,$sp,-4
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
	addi	$s4,$s5,1864			#start bullet counter if detected
3:	jal	render
4:	lw	$ra,0($sp)
	addi	$sp,$sp,-4
	jr	$ra
placeShip:
	addi	$sp,$sp,-20
	sw	$t3,16($sp)
	sw	$t4,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	la 	$t4,ship		#get add of ship
	lw	$t1,($t4)		#load ship
	la	$t2,buff		#get buff
	addi	$t3,$s5,1944		#find pos via t3
	add	$t2,$t2,$t3		#increment buff to correct pos 
	usw	$t1,($t2)		#add ship to buff at pos
	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t4,12($sp)
	lw	$t3,16($sp)	
	addi	$sp,$sp,20
	jr	$ra
#end

#begin bullet
placeBullet:
	addi	$sp,$sp,-16
	sw	$t3,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	la 	$t3,bu			#load bullet
	la	$t2,buff		#load buff
	lb	$t1,($t3)		
	add	$t2,$t2,$s4		#increment buff to bullet location 
	sb	$t1,($t2)		#place bullet
	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t3,12($sp)
	addi	$sp,$sp,16
	jr	$ra
#end

#begin bomb
bomb:	addi	$sp,$sp,-12
	sw	$t3,8($sp)
	sw	$t1,4($sp)
	sw	$ra,0($sp)
	li	$t3,2025
	blt	$s1,$t3,1f
	li	$s1,0
	jal	3f	
1:	bgtz	$s1,2f 
	addi	$s1,$s2,1215
	add	$s1,$s1,$s5
	j	3f
2:	addi	$s1,$s1,81
3:	lw	$ra,0($sp)
	lw	$t1,4($sp)
	lw	$t3,8($sp)
	addi	$sp,$sp,12
	jr	$ra
placeBomb:
	addi	$sp,$sp,-16
	sw	$t3,12($sp)
	sw	$t1,8($sp)
	sw	$t2,4($sp)
	sw	$ra,0($sp)
	la	$t4,bom
	la	$t2,buff
	lb	$t1,($t4)
	add	$t2,$t2,$s1
	sb	$t1,($t2)

	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t3,12($sp)
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
	la 	$t3,boss		#load mother ship
	lw	$t1,($t3)			
	la	$t2,buff		#load buff
	add	$t2,$t2,$s3		#increment buff to mother ship location
	usw	$t1,($t2)		#place mothership at location
	lw	$ra,0($sp)
	lw	$t2,4($sp)
	lw	$t1,8($sp)
	lw	$t0,12($sp)
	addi	$sp,$sp,16
	jr	$ra
#end

#begin barriers
barrier:
	addi	$sp,$sp,-36
	sw	$t8,32($sp)
	sw	$t1,28($sp)
	sw	$t2,24($sp)
	sw	$t3,20($sp)
	sw	$t4,16($sp)
	sw	$t5,12($sp)
	sw	$t6,8($sp)
	sw	$t7,4($sp)
	sw	$ra,0($sp)
	la	$a0,buff	
	la	$t1,bar1
	la	$t2,barm
	addi	$a0,$a0,1875
	addi	$t7,$0,4	#barrier counter

1:	addi	$t6,$0,4	#barrier block counter	
2:	lb	$t3,($t2)
	lb	$t8,($a0)
	li	$a1,0x20
	beq	$t8,$a1,8f
	beqz	$t3,7f
	addi	$t3,$t3,-1
	add	$s4,$0,$0
	sb	$t3,($t2)
	
8:	andi	$t4,$t3,4
	bgtz	$t4,3f		#if equal 4 print solid block
	andi	$t4,$t3,3
	bgtz	$t4,4f		#if equal 3 
	andi	$t4,$t3,2
	bgtz	$t4,5f		#if equal 2
	andi	$t4,$t3,1	
	bgtz	$t4,6f		#if equal 1
	j	7f		#else do nothing and go to 7
		
3:	lb	$t5,($t1)	#load soid block
	sb	$t5,($a0)
	j	7f
	
4:	lb	$t5,1($t1)	#load degraded1 block
	sb	$t5,($a0)
	j	7f
	
5:	lb	$t5,2($t1)	#load degraded2 block
	sb	$t5,($a0)
	j	7f
	
6:	lb	$t5,3($t1)	#load degraded3 block
	sb	$t5,($a0)
	j	7f
	
7:	addi	$t6,$t6,-1	#decrement block counter
	addi	$a0,$a0,1	#incrment buffer pointer
	addi	$t2,$t2,1	#incrment bitmap
	bgtz	$t6,2b		#while four block barrier not complete
	addi	$t7,$t7,-1	#once complete decrment number of barriers
	addi	$a0,$a0,15	#add 15 to pointer for spacing 
	bgtz	$t7,1b		#branch back to 1 and add new barrier
	lw	$t8,32($sp)
	lw	$t1,28($sp)
	lw	$t2,24($sp)
	lw	$t3,20($sp)
	lw	$t4,16($sp)
	lw	$t5,12($sp)
	lw	$t6,8($sp)
	lw	$t7,4($sp)
	lw	$ra,0($sp)
	addi	$sp,$sp,36
	jr	$ra
#end barriers

		
render:
	addi	$sp,$sp,-12
	sw	$t0,8($sp)
	sw	$ra,4($sp)
	sw	$a0,($sp)
	jal	clearbuff
	blez	$s5,1f		#if less than zero dont place bullet
	jal	placeBullet	#else place bullet 
1:	addi	$t1,$0,2025
	bgt 	$s1,$t1,3f
	jal 	placeBomb	#drop bomb
	jal	placeShip	#place ship
#	addi	$t1,$0,77	#if s3 is greater than 77 or eq zero
#	bgt	$s3,$t1,2f	#	skip to next
#	beqz	$s3,2f		#
#	jal	mShip		#else place ship
2:	jal	barrier		
	jal	movAi		#place aleins

3:	add	$a0,$0,$0	
	add	$a1,$0,$0
	syscall	$xy		#mover curser to a0,a1
	la	$a0,buff	#get a0 ready for printing
	syscall	$print_string	#cout a0
	lw	$a0,($sp)
	lw	$ra,4($sp)
	lw	$t0,8($sp)
	addi	$sp,$sp,12
	jr	$ra
#begin Move Alien	
#takes s2:alien tracker
#local	t9:even/odd
movAi:	addi	$sp,$sp,-4		
	sw	$ra,0($sp)		
1:	la	$a0,buff		#load buff
	add	$a0,$a0,$s2		#incrment buff by s2
	andi	$t9,$s2,1		#find out if on an odd space
	jal	renai			#renai screen
	lw	$ra,0($sp)	
	addi	$sp,$sp,4
	jr	$ra
#end
#begin render aliens
	#renai screen
	#takes buff pointer:a0, alien:t6
	#local t0:numRows t1:twofows for diffrent alien
renai:	addi	$sp,$sp,-8
	sw	$t8,4($sp)
	sw	$ra,0($sp)
	li	$t0,4		#row counter
	li	$t1,2		#counter for first 2 rows of aliens 
	la	$t2,bitm	#do
row:	la	$t6,al1		#{alien 1 to t6
	bnez	$t9,col		#if even go to col
	la	$t6,al12	#if odd change alien 1-2
col:	li	$t3,11			#start dowhile counter
1:	lb	$t4,($t2)		#load dead/alive status
	beqz	$t4,2f			#{place alien

#alien killed
	li	$a1,0x20202020	
	ulw 	$t7,0($a0)
	bne	$a1,$t7,4f
	ulw 	$t7,81($a0)
	bne	$a1,$t7,4f
	ulw	$t7,162($a0)
	bne	$a1,$t7,4f
	
	lw 	$t7,0($t6)               # get character at address  
	usw 	$t7,0($a0)               # else store current character in the buff  
	lw	$t7,4($t6)
	usw 	$t7,81($a0)               # else store current character in the buff 
	lw	$t7,8($t6)
	usw 	$t7,162($a0)               # else store current character in the buff
2:	addi	$a0,$a0,5		#incrment pointer:a0
	addi	$t3,$t3,-1		#decremnt col counter:t3
	addi	$t2,$t2,1		#bitm
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
	lw	$t8,4($sp)
	addi	$sp,$sp,8	#resotre stack pointer
	jr	$ra		
	
4:	add	$t4,$0,$0	#make alien dead and reset bullet
	sb	$t4,($t2)	#go back to 1:
	add	$s4,$0,$0
	li	$a1,0x23232323
	usw	$a1,($a0)
	usw	$a1,81($a0)
	usw	$a1,162($a0)
	b	1b
#end
#begin clear screen	
############################
#clear screen
#clear the buff with spaces and newlines
clearbuff:
	la	$t0,buff		#t0:buffpointer
	addi	$t2,$0,25		#t2:counter
	li	$t3,0x20202020		#t3:space
	addi	$t4,$0,'\n		#t4:new line
1:	addi	$t1,$0,4		#charCounter = 80
2:	usw	$t3,($t0)		#store space in char 
	usw	$t3,4($t0)
	usw	$t3,8($t0)
	usw	$t3,12($t0)
	usw	$t3,16($t0)
	addi	$t0,$t0,20		#incremnt buff pointer
	addi	$t1,$t1,-1		#charCounter--
	bgtz	$t1,2b			#fill char while less than 80 chars
	sb	$t4,($t0)
	addi	$t0,$t0,1
	addi	$t2,$t2,-1		#counter--
	bgtz	$t2,1b			#branch back to 1 while less then 25 lines
	sb	$0,-1($t0)
	jr 	$ra
#end
