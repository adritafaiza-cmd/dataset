module apbslave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam APBLSB = $clog2(C_APB_DATA_WIDTH) - 3
) (
    input wire PCLK, PRESETn,
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

    // Memory declaration
    reg [DW-1:0] mem [0 : (1 << AW) -1];

    // PSLVERR tied to 0 (no error handling)
    assign PSLVERR = 1'b0;

    integer i;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Reset to idle state
            PREADY <= 1'b1;
            PRDATA <= {DW{1'b0}};
        end else begin
            // Default assignments
            PREADY <= 1'b0;

            // Access phase when PSEL and PENABLE are high
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;

                if (PWRITE) begin
                    // Byte-strobed write
                    for (i = 0; i < (DW/8); i = i + 1) begin
                        if (PWSTRB[i]) begin
                            mem[PADDR][i*8 +:8] <= PWDATA[i*8 +:8];
                        end
                    end
                end else begin
                    // Read operation
                    PRDATA <= mem[PADDR];
                end
            end
        end
    end

endmodule
