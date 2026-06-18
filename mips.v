`timescale 1ns/1ps

module mips(
    input wire clk,
    input wire rst_n,
    input wire [7:0] switches,
    output wire pwm_out
);
    wire [31:0] pc;
    wire [31:0] instr;
    wire mem_write;
    wire mem_read;
    wire [31:0] data_addr;
    wire [31:0] write_data;
    wire [31:0] read_data;
    wire [7:0] pwm_duty;
    wire pwm_enable;

    instruction_memory instr_mem(.addr(pc), .instr(instr));
    datapath cpu_datapath(.clk(clk), .rst_n(rst_n), .instrF(instr), .read_dataM(read_data), .pcF(pc), .mem_writeM(mem_write), .mem_readM(mem_read), .alu_outM(data_addr), .write_dataM(write_data));
    data_memory data_mem(.clk(clk), .rst_n(rst_n), .mem_write(mem_write), .mem_read(mem_read), .addr(data_addr), .write_data(write_data), .switches(switches), .read_data(read_data), .pwm_duty(pwm_duty), .pwm_enable(pwm_enable));
    pwm_controller pwm(.clk(clk), .rst_n(rst_n), .en(pwm_enable), .duty(pwm_duty), .pwm_out(pwm_out));
endmodule

module instruction_memory(
    input wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] rom [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            rom[i] = 32'd0;
        end
        $readmemh("memfile.dat", rom);
    end

    assign instr = rom[addr[9:2]];
endmodule
