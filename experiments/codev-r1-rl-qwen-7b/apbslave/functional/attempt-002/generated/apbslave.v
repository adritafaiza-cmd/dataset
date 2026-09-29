module apbslave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam APBLSB = $clog2(DW) - 3
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

    // Data register to store written data
    reg [DW-1:0] data_reg;

    // Combinational logic for PREADY (assert during access phase)
    always @* begin
        PREADY = PSEL & PENABLE;
    end

    // Write logic with byte strobes
    integer i;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            data_reg <= 0;
        end else begin
            if (PSEL && PENABLE && PWRITE) begin
                for (i = 0; i < (DW/8); i = i + 1) begin
                    if (PWSTRB[i]) begin
                        data_reg[i*8 +:8] <= PWDATA[i*8 +:8];
                    end
                end
            end
        end
    end

    // Read logic
    always @* begin
        if (PSEL && PENABLE && !PWRITE) begin
            PRDATA = data_reg;
        end else begin
            PRDATA = 0;
        end
    end

    // PSLVERR tied to 0 (no error handling)
    assign PSLVERR = 0;

endmodule
