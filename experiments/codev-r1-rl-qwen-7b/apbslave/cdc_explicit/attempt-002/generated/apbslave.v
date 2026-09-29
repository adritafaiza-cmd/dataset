module apbslave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam APBLSB = $clog2(C_APB_DATA_WIDTH) - 3
) (
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    output reg PREADY,
    input wire [AW-1:0] PADDR,
    input wire PWRITE,
    input wire [DW-1:0] PWDATA,
    input wire [(DW/8)-1:0] PWSTRB,
    input wire [2:0] PPROT,
    output reg [DW-1:0] PRDATA,
    output wire PSLVERR
);

    // PSLVERR tied low (no error handling)
    assign PSLVERR = 1'b0;

    // Combinational logic for PREADY (assert in access phase)
    always @* begin
        PREADY = PSEL & PENABLE;
    end

    // Read data output (dummy implementation)
    always @* begin
        PRDATA = '0;
    end

endmodule
