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
    reg [AW-1:0] aw;
    reg [DW-1:0] dw;
    reg [DW-1:0] read_data;
    reg [DW-1:0] write_data;
    reg [DW/8-1:0] write_strobe;
    reg [1:0] state;
    reg [1:0] next_state;

    // State definitions
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

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

    // Output and internal logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 32'b0;
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
            aw <= AW'b0;
            dw <= DW'b0;
            read_data <= DW'b0;
            write_data <= DW'b0;
            write_strobe <= (DW/8)'b0;
        end else begin
            case (state)
                IDLE: begin
                    PRDATA <= 32'b0;
                    PREADY <= 1'b0;
                    PSLVERR <= 1'b0;
                    aw <= AW'b0;
                    dw <= DW'b0;
                    read_data <= DW'b0;
                    write_data <= DW'b0;
                    write_strobe <= (DW/8)'b0;
                end
                SETUP: begin
                    aw <= PADDR;
                    dw <= PWDATA;
                    write_strobe <= PWSTRB;
                end
                ACCESS: begin
                    PREADY <= 1'b1;
                    if (PWRITE) begin
                        // Perform write operation
                        // For simplicity, just store the data
                        write_data <= dw;
                    end else begin
                        // Perform read operation
                        // For simplicity, just return a fixed value
                        read_data <= {DW{1'b1}};
                    end
                    PRDATA <= read_data;
                    PSLVERR <= 1'b0; // Assuming in-range accesses
                end
                default: begin
                    PRDATA <= 32'b0;
                    PREADY <= 1'b0;
                    PSLVERR <= 1'b0;
                end
            endcase
        end
    end

endmodule
