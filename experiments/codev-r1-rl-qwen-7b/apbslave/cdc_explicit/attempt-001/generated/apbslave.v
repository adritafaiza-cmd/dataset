module apbslave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam APBLSB = $clog2(C_APB_DATA_WIDTH)-3
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

    // Memory array
    reg [DW-1:0] mem [0 : (1 << AW) -1];

    // PSLVERR tied to 0
    assign PSLVERR = 1'b0;

    // PREADY is high during access phase
    always @* begin
        PREADY = PSEL & PENABLE;
    end

    // Write logic
    integer i;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Reset: no action on memory
        end else begin
            if (PSEL && PENABLE && PWRITE) begin
                for (i = 0; i < (DW/8); i = i + 1) begin
                    if (PWSTRB[i]) begin
                        mem[PADDR][i*8 +:8] <= PWDATA[i*8 +:8];
                    end
                end
            end
        end
    end

    // Read logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 0;
        end else begin
            if (PSEL && PENABLE && !PWRITE) begin
                PRDATA <= mem[PADDR];
            end
        end
    end

endmodule
