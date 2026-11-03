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
    input wire [DW/8-1:0] PWSTRB,
    input wire [2:0] PPROT,
    output reg [DW-1:0] PRDATA,
    output wire PSLVERR
);

    // Internal signals
    reg [1:0] state, next_state;
    reg [DW-1:0] data_reg;
    reg ready_reg;
    reg slverr_reg;
    reg [AW-1:0] addr_reg;
    reg write_reg;
    reg [DW-1:0] wdata_reg;
    reg [DW/8-1:0] wstrb_reg;

    // State definitions
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

    // State transition logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            data_reg <= {DW{1'b0}};
            ready_reg <= 1'b0;
            slverr_reg <= 1'b0;
            addr_reg <= {AW{1'b0}};
            write_reg <= 1'b0;
            wdata_reg <= {DW{1'b0}};
            wstrb_reg <= {DW/8{1'b0}};
        end else begin
            state <= next_state;
            if (state == SETUP) begin
                addr_reg <= PADDR;
                write_reg <= PWRITE;
                wdata_reg <= PWDATA;
                wstrb_reg <= PWSTRB;
            end
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (PSEL && !PENABLE)
                    next_state = SETUP;
            end
            SETUP: begin
                next_state = ACCESS;
            end
            ACCESS: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 1'b0;
            PRDATA <= {DW{1'b0}};
            PSLVERR <= 1'b0;
        end else begin
            PREADY <= ready_reg;
            PRDATA <= data_reg;
            PSLVERR <= slverr_reg;
            if (state == ACCESS) begin
                ready_reg <= 1'b1;
                if (write_reg) begin
                    // Perform write operation
                    for (integer i = 0; i < DW/8; i = i + 1) begin
                        if (wstrb_reg[i]) begin
                            data_reg[i*8 +: 8] <= wdata_reg[i*8 +: 8];
                        end
                    end
                end else begin
                    // Perform read operation
                    PRDATA <= data_reg;
                end
                // Check address range (for simplicity, assuming all addresses are valid)
                slverr_reg <= 1'b0;
            end else begin
                ready_reg <= 1'b0;
            end
        end
    end

endmodule
