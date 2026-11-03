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

    // State machine states
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

    // Internal signals
    reg [1:0] state, next_state;
    reg [AW-1:0] addr_latched;
    reg [DW-1:0] write_data_latched;
    reg [DW/8-1:0] write_strobe_latched;
    reg [DW-1:0] read_data;
    reg slverr;

    // Memory model
    reg [DW-1:0] memory [(1<<AW)-1:0];

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
                if (PSEL && !PENABLE) begin
                    next_state = SETUP;
                end
            end
            SETUP: begin
                if (PSEL && PENABLE) begin
                    next_state = ACCESS;
                end
            end
            ACCESS: begin
                next_state = IDLE;
            end
        endcase
    end

    // State actions
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;
        end else begin
            case (state)
                IDLE: begin
                    PREADY <= 0;
                    PSLVERR <= 0;
                end
                SETUP: begin
                    addr_latched <= PADDR;
                    write_data_latched <= PWDATA;
                    write_strobe_latched <= PWSTRB;
                end
                ACCESS: begin
                    if (PWRITE) begin
                        // Write operation with strobes
                        for (integer i = 0; i < DW/8; i = i + 1) begin
                            if (write_strobe_latched[i]) begin
                                memory[addr_latched][8*i +: 8] <= write_data_latched[8*i +: 8];
                            end
                        end
                    end else begin
                        // Read operation
                        read_data <= memory[addr_latched];
                    end
                    PRDATA <= read_data;
                    PREADY <= 1;
                    // Simple address range check (modify as needed)
                    if (addr_latched >= (1<<AW)) begin
                        PSLVERR <= 1;
                    end else begin
                        PSLVERR <= 0;
                    end
                end
            endcase
        end
    end

endmodule
