module apbxclk #(
        parameter C_APB_ADDR_WIDTH = 12,
        parameter C_APB_DATA_WIDTH = 32,
        parameter [0:0] OPT_REGISTERED = 1'b0,
        localparam AW = C_APB_ADDR_WIDTH,
        localparam DW = C_APB_DATA_WIDTH
    ) (
        input wire S_APB_PCLK, S_PRESETn,
        input wire S_APB_PSEL,
        input wire S_APB_PENABLE,
        output reg S_APB_PREADY,
        input wire [AW-1:0] S_APB_PADDR,
        input wire S_APB_PWRITE,
        input wire [DW-1:0] S_APB_PWDATA,
        input wire [DW/8-1:0] S_APB_PWSTRB,
        input wire [2:0] S_APB_PPROT,
        output wire [DW-1:0] S_APB_PRDATA,
        output wire S_APB_PSLVERR,
        input wire M_APB_PCLK,
        output reg M_PRESETn,
        output reg M_APB_PSEL,
        output reg M_APB_PENABLE,
        input wire M_APB_PREADY,
        output wire [AW-1:0] M_APB_PADDR,
        output wire M_APB_PWRITE,
        output wire [DW-1:0] M_APB_PWDATA,
        output wire [DW/8-1:0] M_APB_PWSTRB,
        output wire [2:0] M_APB_PPROT,
        input wire [DW-1:0] M_APB_PRDATA,
        input wire M_APB_PSLVERR
    );

    // Internal signals
    reg sreset;
    reg sel_ff, enable_ff;
    reg sel_sync, enable_sync, ready_sync;

    // Reset synchronizers
    cdc_sync sreset_sync (
        .in(S_PRESETn),
        .clk(M_APB_PCLK),
        .out(M_PRESETn)
    );

    cdc_sync mreset_sync (
        .in(S_PRESETn),
        .clk(S_APB_PCLK),
        .out(sreset)
    );

    // Control signal synchronizers
    cdc_ff sel_sync_ff (
        .in(S_APB_PSEL),
        .clk(S_APB_PCLK),
        .out(sel_sync)
    );

    cdc_ff enable_sync_ff (
        .in(S_APB_PENABLE),
        .clk(S_APB_PCLK),
        .out(enable_sync)
    );

    cdc_ff ready_sync_ff (
        .in(M_APB_PREADY),
        .clk(M_APB_PCLK),
        .out(ready_sync)
    );

    // Data synchronizers
    cdc_ff addr_sync_ff (
        .in(S_APB_PADDR),
        .clk(S_APB_PCLK),
        .out(M_APB_PADDR)
    );

    cdc_ff write_sync_ff (
        .in(S_APB_PWRITE),
        .clk(S_APB_PCLK),
        .out(M_APB_PWRITE)
    );

    cdc_ff wdata_sync_ff (
        .in(S_APB_PWDATA),
        .clk(S_APB_PCLK),
        .out(M_APB_PWDATA)
    );

    cdc_ff wstrb_sync_ff (
        .in(S_APB_PWSTRB),
        .clk(S_APB_PCLK),
        .out(M_APB_PWSTRB)
    );

    cdc_ff pprot_sync_ff (
        .in(S_APB_PPROT),
        .clk(S_APB_PCLK),
        .out(M_APB_PPROT)
    );

    cdc_ff prdata_sync_ff (
        .in(M_APB_PRDATA),
        .clk(M_APB_PCLK),
        .out(S_APB_PRDATA)
    );

    cdc_ff pslverr_sync_ff (
        .in(M_APB_PSLVERR),
        .clk(M_APB_PCLK),
        .out(S_APB_PSLVERR)
    );

    // Control logic for APB bridge
    always @(posedge S_APB_PCLK or negedge sreset) begin
        if (!sreset) begin
            S_APB_PREADY <= 1'b0;
            sel_ff <= 1'b0;
            enable_ff <= 1'b0;
        end else begin
            if (sel_sync && enable_sync) begin
                sel_ff <= 1'b1;
                enable_ff <= 1'b1;
            end else if (ready_sync) begin
                sel_ff <= 1'b0;
                enable_ff <= 1'b0;
                S_APB_PREADY <= 1'b1;
            end else begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
        end else begin
            if (sel_ff && enable_ff) begin
                M_APB_PSEL <= 1'b1;
                M_APB_PENABLE <= 1'b1;
            end else if (ready_sync) begin
                M_APB_PSEL <= 1'b0;
                M_APB_PENABLE <= 1'b0;
            end
        end
    end

endmodule

module cdc_sync (
    input wire in,
    input wire clk,
    output reg out
);
    reg sync1, sync2;

    always @(posedge clk) begin
        sync1 <= in;
        sync2 <= sync1;
        out <= sync2;
    end
endmodule

module cdc_ff #(
        parameter DW = 32
    ) (
        input wire [DW-1:0] in,
        input wire clk,
        output reg [DW-1:0] out
    );
    reg [DW-1:0] sync1, sync2;

    always @(posedge clk) begin
        sync1 <= in;
        sync2 <= sync1;
        out <= sync2;
    end
endmodule
