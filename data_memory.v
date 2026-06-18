`timescale 1ns/1ps

module data_memory(
    input wire clk,
    input wire rst_n,
    input wire mem_write,
    input wire mem_read,
    input wire [31:0] addr,
    input wire [31:0] write_data,
    input wire [7:0] switches,
    output reg [31:0] read_data,
    output reg [7:0] pwm_duty,
    output reg pwm_enable
);
    localparam [31:0] ADDR_SWITCHES = 32'h00000090;
    localparam [31:0] ADDR_PWM_DUTY = 32'h00000098;
    localparam [31:0] ADDR_PWM_ENABLE = 32'h0000009c;

    reg [31:0] ram [0:255];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_duty <= 8'd0;
            pwm_enable <= 1'b0;
            for (i = 0; i < 256; i = i + 1) begin
                ram[i] <= 32'd0;
            end
        end else if (mem_write) begin
            case (addr)
                ADDR_PWM_DUTY: pwm_duty <= write_data[7:0];
                ADDR_PWM_ENABLE: pwm_enable <= write_data[0];
                default: ram[addr[9:2]] <= write_data;
            endcase
        end
    end

    wire [31:0] ram_read_data = ram[addr[9:2]];

    always @(*) begin
        read_data = 32'd0;
        if (mem_read) begin
            case (addr)
                ADDR_SWITCHES: read_data = {24'd0, switches};
                ADDR_PWM_DUTY: read_data = {24'd0, pwm_duty};
                ADDR_PWM_ENABLE: read_data = {31'd0, pwm_enable};
                default: read_data = ram_read_data;
            endcase
        end
    end
endmodule
