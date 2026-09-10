module apbslave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam APBLSB = $clog2(C_APB_DATA_WIDTH)-3
) (
    input wire            PCLK, PRESETn,
    input wire            PSEL,
    input wire            PENABLE,
    output reg            PREADY,
    input wire    [AW-1:0] PADDR,
    input wire            PWRITE,
    input wire    [DW-1:0] PWDATA,
    input wire    [DW/8-1:0] PWSTRB,
    input wire    [2:0]     PPROT,
    output reg    [DW-1:0] PRDATA,
    output wire           PSLVERR
);

reg [DW-1:0] data;
reg [AW-1:0] addr;

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        PREADY <= 1'b0;
        PRDATA <= {DW{1'b0}};
    end else if (PSEL && PENABLE) begin
        if (PWRITE) begin
            for (int i = 0; i < DW/8; i++) begin
                if (PWSTRB[i]) begin
                    data[(i*8)+:8] <= PWDATA[(i*8)+:8];
                end
            end
        end else begin
            PRDATA <= data;
        end
        PREADY <= 1'b1;
    end else if (PSEL && ~PENABLE) begin
        PREADY <= 1'b0;
    end else begin
        PREADY <= 1'b0;
    end
end

assign PSLVERR = 1'b0;

endmodule
