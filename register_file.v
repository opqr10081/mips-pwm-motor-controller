`timescale 1ns/1ps

module register_file(
    input wire clk,
    input wire reg_write,
    input wire [4:0] read_addr1,
    input wire [4:0] read_addr2,
    input wire [4:0] write_addr,
    input wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] = 32'd0;
        end
    end

    always @(posedge clk) begin
        if (reg_write && write_addr != 5'd0) begin
            regs[write_addr] <= write_data;
        end
    end

    assign read_data1 = (read_addr1 == 5'd0) ? 32'd0 : regs[read_addr1];
    assign read_data2 = (read_addr2 == 5'd0) ? 32'd0 : regs[read_addr2];
endmodule
