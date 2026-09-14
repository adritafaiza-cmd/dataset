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

    // Internal signals
    reg [1:0] state;
    reg [DW-1:0] data_reg;
    reg [AW-1:0] addr_reg;
    reg write_en;
    reg ready_reg;

    // State definitions
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;

    // State machine
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            data_reg <= 0;
            addr_reg <= 0;
            write_en <= 0;
            ready_reg <= 0;
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (PSEL && PENABLE) begin
                        state <= WRITE;
                        addr_reg <= PADDR;
                        write_en <= PWRITE;
                        PREADY <= 1;
                        if (PWRITE) begin
                            data_reg <= PWDATA & {8{PWSTRB}};
                        end
                    end else begin
                        PREADY <= 0;
                    end
                end
                READ: begin
                    PREADY <= 1;
                    PRDATA <= data_reg;
                    state <= IDLE;
                end
                WRITE: begin
                    PREADY <= 1;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                    PREADY <= 0;
                end
            endcase
        end
    end

endmodule
