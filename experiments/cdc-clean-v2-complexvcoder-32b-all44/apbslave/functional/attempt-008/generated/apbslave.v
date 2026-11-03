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
    reg [1:0] state;
    reg [1:0] next_state;
    reg [DW-1:0] read_data;
    reg write_enable;

    // State machine states
    localparam IDLE = 2'b00;
    localparam ACCESS = 2'b01;

    // Memory model (simplified as a register file)
    reg [DW-1:0] memory [0:(1<<AW)-1];

    // State machine
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;
        end else begin
            state <= next_state;
            if (PREADY) begin
                PREADY <= 0;
            end
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (PSEL && PENABLE) begin
                    next_state = ACCESS;
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

    // Output logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 0;
            PSLVERR <= 0;
        end else begin
            if (state == ACCESS) begin
                if (PWRITE) begin
                    // Write operation
                    for (integer i = 0; i < DW/8; i = i + 1) begin
                        if (PWSTRB[i]) begin
                            memory[PADDR][8*i +: 8] <= PWDATA[8*i +: 8];
                        end
                    end
                    PSLVERR <= 0;
                end else begin
                    // Read operation
                    read_data <= memory[PADDR];
                    PRDATA <= read_data;
                    PSLVERR <= 0;
                end
                PREADY <= 1;
            end
        end
    end

endmodule
