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
    reg [DW-1:0] read_data;
    reg [DW/8-1:0] write_enable;
    reg [DW-1:0] write_data;
    reg ready, slverr;

    // State definitions
    localparam IDLE = 2'b00;
    localparam ACCESS = 2'b01;
    localparam DONE = 2'b10;

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
        case (state)
            IDLE: begin
                if (PSEL && PENABLE) begin
                    next_state = ACCESS;
                end else begin
                    next_state = IDLE;
                end
            end
            ACCESS: begin
                next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output and internal logic
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
                ACCESS: begin
                    if (PSEL && PENABLE) begin
                        if (PWRITE) begin
                            // Handle write operation
                            write_enable <= PWSTRB;
                            write_data <= PWDATA;
                        end else begin
                            // Handle read operation
                            read_data <= 32'hDEADBEEF; // Placeholder for actual read data
                            PRDATA <= read_data;
                        end
                        PSLVERR <= (PADDR >= (1<<AW)) ? 1'b1 : 1'b0; // Check for out-of-range access
                    end
                end
                DONE: begin
                    PREADY <= 1'b1;
                end
            endcase
        end
    end

endmodule
