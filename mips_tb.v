`timescale 1ns/1ps

module mips_tb;
    reg clk;
    reg rst_n;
    reg [7:0] switches;
    wire pwm_out;

    mips dut(.clk(clk), .rst_n(rst_n), .switches(switches), .pwm_out(pwm_out));

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    integer duty_changes;
    integer saw_rise;
    integer saw_fall;
    integer saw_pwm_high;
    integer saw_pwm_low;
    reg [7:0] last_duty;
    reg [7:0] max_duty;

    initial begin
        rst_n = 1'b0;
        switches = 8'h00;
        duty_changes = 0;
        saw_rise = 0;
        saw_fall = 0;
        saw_pwm_high = 0;
        saw_pwm_low = 0;
        last_duty = 8'd0;
        max_duty = 8'd0;

        $dumpfile("wave.vcd");
        $dumpvars(0, mips_tb);

        #40 rst_n = 1'b1;
        #200000;

        if (duty_changes < 20) begin
            $display("TEST FAIL: expected many PWM duty updates, saw %0d", duty_changes);
            $finish;
        end
        if (!saw_rise || !saw_fall) begin
            $display("TEST FAIL: duty did not both rise and fall");
            $finish;
        end
        if (!saw_pwm_high || !saw_pwm_low) begin
            $display("TEST FAIL: pwm_out did not toggle");
            $finish;
        end

        $display("TEST PASS: option A profile changed duty %0d times, max duty %0d", duty_changes, max_duty);
        $finish;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (dut.data_mem.pwm_duty != last_duty) begin
                duty_changes = duty_changes + 1;
                if (dut.data_mem.pwm_duty > last_duty) saw_rise = 1;
                if (dut.data_mem.pwm_duty < last_duty) saw_fall = 1;
                last_duty = dut.data_mem.pwm_duty;
            end
            if (dut.data_mem.pwm_duty > max_duty) max_duty = dut.data_mem.pwm_duty;
            if (pwm_out) saw_pwm_high = 1;
            else if (dut.data_mem.pwm_enable) saw_pwm_low = 1;
        end
    end
endmodule
