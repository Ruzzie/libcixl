//
// Created by dorus on 29-9-2020.
//

#ifndef LIBCIXL_MACHINE_H
#define LIBCIXL_MACHINE_H

static union
{
    char int8_t_incorrect[sizeof(char) == 1];
    char uint8_t_incorrect[sizeof(unsigned char) == 1];
    char int16_t_incorrect[sizeof(short) == 2];
    char uint16_t_incorrect[sizeof(unsigned short) == 2];
    char int32_t_incorrect[sizeof(long) == 4];
    char uint32_t_incorrect[sizeof(unsigned long) == 4];
} DETECT_SIZE_ERRS;

typedef unsigned char byte;

enum OPCODES
{
    NOP = 0,
    ADD = 1,
    SUB = 2,
    PUSH = 3,
    POP,
    POP_R, //(count: 1-4) Pops the stack into the main registers
    PUSH_R, //(mask:1111_0000) Pushes the values of the register(s) onto the stack
    INCR,
    DECR,
    DIV,
    MUL,
    AND,
    OR,
    XOR,
    LEFT_SHIFT,
    RIGHT_SHIFT,
    NEGATE,

    BRANCH_IF_LTE,
    BRANCH_IF_LT,
    BRANCH_IF_EQ,
    BRANCH_IF_NEQ,
    BRANCH_IF_GTE,
    BRANCH_IF_GT,

    LDC,//Load constant
    LDC_STR, //Load string constant (value or reference?)
    APPEND_STR, // Pops the current value for the constant Id and Appends the constant to the result.
    APPEND_ARG_0_STR,
    APPEND_ARG_1_STR,


    JMP,
    RET,

    CALL,
    CALL_T,// Tail call (nfi how that works)


    HALT = 16
};

//1 Kb
#define LIBCIXL_MAIN_MEMORY_SIZE 1024
//32 Kb
#define LIBCIXL_PROGRAM_MEMORY_SIZE 32768

//512 bytes
#define LIBCIXL_MAIN_STACK_SIZE 512

//internally byte addressable memory
static byte MAIN_STACK[LIBCIXL_MAIN_STACK_SIZE];
static byte MAIN_MEMORY[LIBCIXL_MAIN_MEMORY_SIZE];

//available program memory
static byte PROGRAM_MEMORY[LIBCIXL_PROGRAM_MEMORY_SIZE];

typedef struct CIXL_RegisterInfo
{
    char register_id;
    char register_name[4];
    char register_size;

} CIXL_REGISTER_INFO;

#define LIBCIXL_MAIN_REGISTER_TYPE long
#define LIBCIXL_MAIN_REGISTER_SIZE sizeof(LIBCIXL_MAIN_REGISTER_TYPE)

enum MAIN_REGISTER_IDS
{
    RAX = 0, RBX = 1, RCX = 2, RDX = 3,
    MAIN_REGISTER_COUNT
};

static CIXL_REGISTER_INFO MAIN_REGISTERS_INFO[] = {{RAX, "RAX", LIBCIXL_MAIN_REGISTER_SIZE},
                                                   {RBX, "RBX", LIBCIXL_MAIN_REGISTER_SIZE},
                                                   {RCX, "RCX", LIBCIXL_MAIN_REGISTER_SIZE},
                                                   {RDX, "RDX", LIBCIXL_MAIN_REGISTER_SIZE}};

static LIBCIXL_MAIN_REGISTER_TYPE MAIN_REGISTERS[MAIN_REGISTER_COUNT];



#endif //LIBCIXL_MACHINE_H
