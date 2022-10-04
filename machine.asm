.data
_s1: .asciiz "Hello, World!"
.text 
.globl main 
main:

#funCall main.main

#call label2
addiu $sp, $sp, -16
jal label2

#exit
li $v0, 10
syscall

#label1:
label1:

#function start main.printString

#setReturn
sw $ra, 0($sp)

#print string s_1
li $2, 4
lw $4, 4($sp)
syscall

#print newline
li $4, 10
li $2, 11
syscall

#return
lw $ra, 0($sp)
addiu $sp, $sp, 12
jr $ra

#label2:
label2:

#function start main.main

#setReturn
sw $ra, 0($sp)

#funCall main.printString

#strconst _s1 _t1_2 #"Hello, World!"
la $8, _s1
sw $8, 8($sp)

#param _t1_2 4
li $9, 0
li $10, -8
add $10, $10, $sp
li $11, 8
add $11, $11, $sp
add $10, $10, $9
add $11, $11, $9
lw $8, ($11)
sw $8, ($10)
addi $9, $9, 4

#call label1
addiu $sp, $sp, -12
jal label1

#_t2_2 = returnVal
lw $8 -4($sp)
sw $8 4($sp)

#return
lw $ra, 0($sp)
addiu $sp, $sp, 16
jr $ra
