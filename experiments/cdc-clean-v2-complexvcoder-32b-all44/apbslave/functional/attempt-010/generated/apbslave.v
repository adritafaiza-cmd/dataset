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
        output wire PSLVERR
    );

    // Internal signals
    reg [1:0] state, next_state;
    reg [DW-1:0] data_reg;
    reg ready_reg, slverr_reg;

    // State definitions
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

    // State machine
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            ready_reg <= 0;
            slverr_reg <= 0;
            data_reg <= 0;
        end else begin
            state <= next_state;
            ready_reg <= (state == ACCESS) ? 1 : 0;
            if (state == ACCESS && PWRITE) begin
                for (integer i = 0; i < DW/8; i = i + 1) begin
                    if (PWSTRB[i]) begin
                        data_reg[i*8 +: 8] <= PWDATA[i*8 +: 8];
                    end
                end
            end
            if (state == ACCESS && !PWRITE) begin
                PRDATA <= data_reg;
            end
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (PSEL) begin
                    next_state = SETUP;
                end else begin
                    next_state = IDLE;
                end
            end
            SETUP: begin
                if (PENABLE) begin
                    next_state = ACCESS;
                end else begin
                    next_state = SETUP;
                end
            end
            ACCESS: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // PSLVERR is low for in-range accesses
    assign PSLVERR = 0;

    // PREADY is asserted in the ACCESS state
    assign PREADY = ready_reg;

endmodule
