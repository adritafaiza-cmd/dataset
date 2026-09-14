module apbslave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam APBLSB = $clog2(C_APB_DATA_WIDTH)-3
) (
    input wire PCLK, PRESETn,
    input wire PSEL,
    input wire PENABLE,
    output reg PREADY,
    input wire [AW-1:0] PADDR,
    input wire PWRITE,
    input wire [DW-1:0] PWDATA,
    input wire [DW/8-1:0] PWSTRB,
    input wire [2:0] PPROT,
    output reg [DW-1:0] PRDATA,
    output reg PSLVERR
);

    reg [AW-1:0] addr_reg;
    reg [DW-1:0] data_reg;
    reg write_reg;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;
            addr_reg <= 0;
            data_reg <= 0;
            write_reg <= 0;
        end else begin
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;

            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    // Write operation
                    data_reg[PADDR*DW +: DW] <= PWDATA;
                end else begin
                    // Read operation
                    PRDATA <= data_reg[PADDR*DW +: DW];
                end
                PREADY <= 1;
            end
        end
    end

endmodule
