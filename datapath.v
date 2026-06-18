`timescale 1ns/1ps

module datapath(
    input wire clk,
    input wire rst_n,
    input wire [31:0] instrF,
    input wire [31:0] read_dataM,
    output wire [31:0] pcF,
    output wire mem_writeM,
    output wire mem_readM,
    output wire [31:0] alu_outM,
    output wire [31:0] write_dataM
);
    reg [31:0] pc_reg;
    assign pcF = pc_reg;

    wire [31:0] pcPlus4F = pc_reg + 32'd4;

    reg [31:0] instrD;
    reg [31:0] pcPlus4D;

    wire [4:0] rsD = instrD[25:21];
    wire [4:0] rtD = instrD[20:16];
    wire [4:0] rdD = instrD[15:11];
    wire [31:0] signImmD = {{16{instrD[15]}}, instrD[15:0]};
    wire [31:0] branchTargetD = pcPlus4D + (signImmD << 2);
    wire [31:0] jumpTargetD = {pcPlus4D[31:28], instrD[25:0], 2'b00};

    wire regWriteD;
    wire memWriteD;
    wire memReadD;
    wire memToRegD;
    wire aluSrcD;
    wire regDstD;
    wire branchD;
    wire branchNeD;
    wire jumpD;
    wire [3:0] aluControlD;

    control_unit control(
        .instr(instrD),
        .reg_write(regWriteD),
        .mem_write(memWriteD),
        .mem_read(memReadD),
        .mem_to_reg(memToRegD),
        .alu_src(aluSrcD),
        .reg_dst(regDstD),
        .branch(branchD),
        .branch_ne(branchNeD),
        .jump(jumpD),
        .alu_control(aluControlD)
    );

    wire regWriteW;
    wire [4:0] writeRegW;
    wire [31:0] resultW;
    wire [31:0] rd1D;
    wire [31:0] rd2D;

    register_file rf(
        .clk(clk),
        .reg_write(regWriteW),
        .read_addr1(rsD),
        .read_addr2(rtD),
        .write_addr(writeRegW),
        .write_data(resultW),
        .read_data1(rd1D),
        .read_data2(rd2D)
    );

    reg regWriteE;
    reg memWriteE;
    reg memReadE;
    reg memToRegE;
    reg aluSrcE;
    reg regDstE;
    reg [3:0] aluControlE;
    reg [31:0] rd1E;
    reg [31:0] rd2E;
    reg [31:0] signImmE;
    reg [4:0] rsE;
    reg [4:0] rtE;
    reg [4:0] rdE;

    reg regWriteM_reg;
    reg memWriteM_reg;
    reg memReadM_reg;
    reg memToRegM;
    reg [31:0] aluOutM_reg;
    reg [31:0] writeDataM_reg;
    reg [4:0] writeRegM;

    assign mem_writeM = memWriteM_reg;
    assign mem_readM = memReadM_reg;
    assign alu_outM = aluOutM_reg;
    assign write_dataM = writeDataM_reg;

    reg memToRegW;
    reg [31:0] readDataW;
    reg [31:0] aluOutW;
    reg regWriteW_reg;
    reg [4:0] writeRegW_reg;

    assign regWriteW = regWriteW_reg;
    assign writeRegW = writeRegW_reg;
    assign resultW = memToRegW ? readDataW : aluOutW;

    reg [31:0] branchSrcAD;
    reg [31:0] branchSrcBD;

    always @(*) begin
        branchSrcAD = rd1D;
        if (rsD != 5'd0 && rsD == writeRegM && regWriteM_reg && !memToRegM) begin
            branchSrcAD = aluOutM_reg;
        end else if (rsD != 5'd0 && rsD == writeRegW_reg && regWriteW_reg) begin
            branchSrcAD = resultW;
        end

        branchSrcBD = rd2D;
        if (rtD != 5'd0 && rtD == writeRegM && regWriteM_reg && !memToRegM) begin
            branchSrcBD = aluOutM_reg;
        end else if (rtD != 5'd0 && rtD == writeRegW_reg && regWriteW_reg) begin
            branchSrcBD = resultW;
        end
    end

    wire branchEqualD = (branchSrcAD == branchSrcBD);
    wire branchTakenD = branchD && (branchNeD ? !branchEqualD : branchEqualD);
    wire pcSrcD = branchTakenD || jumpD;
    wire [31:0] pcNextF = jumpD ? jumpTargetD : (branchTakenD ? branchTargetD : pcPlus4F);

    wire loadUseHazard = memReadE && ((rtE == rsD) || (rtE == rtD));
    wire stallF = loadUseHazard;
    wire stallD = loadUseHazard;
    wire flushE = loadUseHazard || pcSrcD;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'd0;
        end else if (!stallF) begin
            pc_reg <= pcNextF;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instrD <= 32'd0;
            pcPlus4D <= 32'd0;
        end else if (stallD) begin
            instrD <= instrD;
            pcPlus4D <= pcPlus4D;
        end else if (pcSrcD) begin
            instrD <= 32'd0;
            pcPlus4D <= 32'd0;
        end else begin
            instrD <= instrF;
            pcPlus4D <= pcPlus4F;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regWriteE <= 1'b0; memWriteE <= 1'b0; memReadE <= 1'b0; memToRegE <= 1'b0;
            aluSrcE <= 1'b0; regDstE <= 1'b0; aluControlE <= 4'd0;
            rd1E <= 32'd0; rd2E <= 32'd0; signImmE <= 32'd0;
            rsE <= 5'd0; rtE <= 5'd0; rdE <= 5'd0;
        end else if (flushE) begin
            regWriteE <= 1'b0; memWriteE <= 1'b0; memReadE <= 1'b0; memToRegE <= 1'b0;
            aluSrcE <= 1'b0; regDstE <= 1'b0; aluControlE <= 4'd0;
            rd1E <= 32'd0; rd2E <= 32'd0; signImmE <= 32'd0;
            rsE <= 5'd0; rtE <= 5'd0; rdE <= 5'd0;
        end else begin
            regWriteE <= regWriteD; memWriteE <= memWriteD; memReadE <= memReadD; memToRegE <= memToRegD;
            aluSrcE <= aluSrcD; regDstE <= regDstD; aluControlE <= aluControlD;
            rd1E <= rd1D; rd2E <= rd2D; signImmE <= signImmD;
            rsE <= rsD; rtE <= rtD; rdE <= rdD;
        end
    end

    wire [4:0] writeRegE = regDstE ? rdE : rtE;

    reg [1:0] forwardAE;
    reg [1:0] forwardBE;

    always @(*) begin
        forwardAE = 2'b00;
        if (rsE != 5'd0 && rsE == writeRegM && regWriteM_reg && !memToRegM) begin
            forwardAE = 2'b10;
        end else if (rsE != 5'd0 && rsE == writeRegW_reg && regWriteW_reg) begin
            forwardAE = 2'b01;
        end

        forwardBE = 2'b00;
        if (rtE != 5'd0 && rtE == writeRegM && regWriteM_reg && !memToRegM) begin
            forwardBE = 2'b10;
        end else if (rtE != 5'd0 && rtE == writeRegW_reg && regWriteW_reg) begin
            forwardBE = 2'b01;
        end
    end

    wire [31:0] srcAE = (forwardAE == 2'b10) ? aluOutM_reg :
                         (forwardAE == 2'b01) ? resultW : rd1E;
    wire [31:0] forwardedBE = (forwardBE == 2'b10) ? aluOutM_reg :
                               (forwardBE == 2'b01) ? resultW : rd2E;
    wire [31:0] srcBE = aluSrcE ? signImmE : forwardedBE;
    wire [31:0] aluResultE;
    wire aluZeroE;

    alu alu_core(.a(srcAE), .b(srcBE), .alu_control(aluControlE), .result(aluResultE), .zero(aluZeroE));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regWriteM_reg <= 1'b0; memWriteM_reg <= 1'b0; memReadM_reg <= 1'b0; memToRegM <= 1'b0;
            aluOutM_reg <= 32'd0; writeDataM_reg <= 32'd0; writeRegM <= 5'd0;
        end else begin
            regWriteM_reg <= regWriteE; memWriteM_reg <= memWriteE; memReadM_reg <= memReadE; memToRegM <= memToRegE;
            aluOutM_reg <= aluResultE; writeDataM_reg <= forwardedBE; writeRegM <= writeRegE;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regWriteW_reg <= 1'b0; memToRegW <= 1'b0; readDataW <= 32'd0; aluOutW <= 32'd0; writeRegW_reg <= 5'd0;
        end else begin
            regWriteW_reg <= regWriteM_reg; memToRegW <= memToRegM; readDataW <= read_dataM; aluOutW <= aluOutM_reg; writeRegW_reg <= writeRegM;
        end
    end
endmodule
