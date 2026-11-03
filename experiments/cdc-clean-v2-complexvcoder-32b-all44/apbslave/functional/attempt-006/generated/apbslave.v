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

    // Internal signals
    reg [1:0] state, next_state;
    reg [DW-1:0] read_data;
    reg write_enable;

    // State definitions
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

    // Memory model (simplified)
    reg [DW-1:0] memory [0:(1<<AW)-1];

    // State machine
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
                    next_state = SETUP;
                end
            end
            SETUP: begin
                next_state = ACCESS;
            end
            ACCESS: begin
                if (PENABLE) begin
                    next_state = ACCESS;
                end else begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Output logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;
        end else begin
            case (state)
                IDLE: begin
                    PREADY <= 0;
                    PRDATA <= 0;
                    PSLVERR <= 0;
                end
                SETUP: begin
                    if (PENABLE) begin
                        PREADY <= 1;
                    end
                end
                ACCESS: begin
                    if (PWRITE) begin
                        for (integer i = 0; i < DW/8; i = i + 1) begin
                            if (PWSTRB[i]) begin
                                memory[PADDR][8*i +: 8] <= PWDATA[8*i +: 8];
                            end
                        end
                    end else begin
                        read_data <= memory[PADDR];
                        PRDATA <= read_data;
                    end
                    PREADY <= 1;
                    PSLVERR <= 0; // Assuming all accesses are in-range
                end
            endcase
        end
    end

endmodule
