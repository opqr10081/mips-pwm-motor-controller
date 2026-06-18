`timescale 1ns/1ps

module control_unit(
    input wire [31:0] instr,
    output reg reg_write,
    output reg mem_write,
    output reg mem_read,
    output reg mem_to_reg,
    output reg alu_src,
    output reg reg_dst,
    output reg branch,
    output reg branch_ne,
    output reg jump,
    output reg [3:0] alu_control
);
    localparam OP_RTYPE = 6'h00;
    localparam OP_J     = 6'h02;
    localparam OP_BEQ   = 6'h04;
    localparam OP_BNE   = 6'h05;
    localparam OP_ADDI  = 6'h08;
    localparam OP_ADDIU = 6'h09;
    localparam OP_SLTI  = 6'h0a;
    localparam OP_ANDI  = 6'h0c;
    localparam OP_ORI   = 6'h0d;
    localparam OP_LW    = 6'h23;
    localparam OP_SW    = 6'h2b;

    localparam FUNCT_ADD = 6'h20;
    localparam FUNCT_ADDU = 6'h21;
    localparam FUNCT_SUB = 6'h22;
    localparam FUNCT_AND = 6'h24;
    localparam FUNCT_OR  = 6'h25;
    localparam FUNCT_SLT = 6'h2a;

    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_AND = 4'd2;
    localparam ALU_OR  = 4'd3;
    localparam ALU_SLT = 4'd4;

    wire [5:0] opcode = instr[31:26];
    wire [5:0] funct = instr[5:0];

    always @(*) begin
        reg_write = 1'b0;
        mem_write = 1'b0;
        mem_read = 1'b0;
        mem_to_reg = 1'b0;
        alu_src = 1'b0;
        reg_dst = 1'b0;
        branch = 1'b0;
        branch_ne = 1'b0;
        jump = 1'b0;
        alu_control = ALU_ADD;

        case (opcode)
            OP_RTYPE: begin
                reg_write = (instr != 32'd0);
                reg_dst = 1'b1;
                case (funct)
                    FUNCT_ADD, FUNCT_ADDU: alu_control = ALU_ADD;
                    FUNCT_SUB: alu_control = ALU_SUB;
                    FUNCT_AND: alu_control = ALU_AND;
                    FUNCT_OR:  alu_control = ALU_OR;
                    FUNCT_SLT: alu_control = ALU_SLT;
                    default: begin
                        reg_write = 1'b0;
                        alu_control = ALU_ADD;
                    end
                endcase
            end
            OP_LW: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_ADD;
            end
            OP_SW: begin
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_ADD;
            end
            OP_ADDI, OP_ADDIU: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_ADD;
            end
            OP_ANDI: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_AND;
            end
            OP_ORI: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_OR;
            end
            OP_SLTI: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_SLT;
            end
            OP_BEQ: begin
                branch = 1'b1;
                alu_control = ALU_SUB;
            end
            OP_BNE: begin
                branch = 1'b1;
                branch_ne = 1'b1;
                alu_control = ALU_SUB;
            end
            OP_J: begin
                jump = 1'b1;
            end
            default: begin
                reg_write = 1'b0;
            end
        endcase
    end
endmodule
