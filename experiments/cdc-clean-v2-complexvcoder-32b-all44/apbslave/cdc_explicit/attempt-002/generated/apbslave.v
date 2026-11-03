module apbslave #(
        parameter   C_APB_ADDR_WIDTH = 12,
        parameter   C_APB_DATA_WIDTH = 32,
        localparam  AW = C_APB_ADDR_WIDTH,
        localparam  DW = C_APB_DATA_WIDTH,
        localparam  APBLSB = $clog2(C_APB_DATA_WIDTH)-3
    ) (
        input   wire            PCLK, PRESETn,
        input   wire            PSEL,
        input   wire            PENABLE,
        output  reg             PREADY,
        input   wire    [AW-1:0]  PADDR,
        input   wire            PWRITE,
        input   wire    [DW-1:0]  PWDATA,
        input   wire    [DW/8-1:0] PWSTRB,
        input   wire    [2:0]     PPROT,
        output  reg     [DW-1:0]  PRDATA,
        output  wire            PSLVERR
    );

    // Internal registers
    reg [DW-1:0] data_reg;
    reg          ready_reg;
    reg          pslverr_reg;
    reg [AW-1:0] addr_reg;
    reg          write_reg;
    reg [DW-1:0] wdata_reg;
    reg [DW/8-1:0] wstrb_reg;

    // State machine
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;
    reg [1:0] state, next_state;

    // State transition logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (PSEL && PENABLE) begin
                    next_state = ACCESS;
                end else if (PSEL) begin
                    next_state = SETUP;
                end
            end
            SETUP: begin
                if (PENABLE) begin
                    next_state = ACCESS;
                end
            end
            ACCESS: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 1'b0;
            PRDATA <= 32'b0;
            PSLVERR <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    PREADY <= 1'b0;
                    PRDATA <= 32'b0;
                    PSLVERR <= 1'b0;
                end
                SETUP: begin
                    // Capture address, write, data and strobe
                    if (PSEL && !PENABLE) begin
                        addr_reg <= PADDR;
                        write_reg <= PWRITE;
                        wdata_reg <= PWDATA;
                        wstrb_reg <= PWSTRB;
                    end
                end
                ACCESS: begin
                    PREADY <= 1'b1;
                    PSLVERR <= 1'b0; // Assuming in-range access
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
                end
            endcase
        end
    end

endmodule
